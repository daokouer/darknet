extern "C" {
#include "activations.h"
#include "cuda.h"
}

__device__ float linear_activate_kernel(float x){return x;}
__device__ float logistic_activate_kernel(float x){return 1./(1. + exp(-x));}
__device__ float relu_activate_kernel(float x){return x*(x>0);}
__device__ float relie_activate_kernel(float x){return x*(x>0);}
__device__ float ramp_activate_kernel(float x){return x*(x>0)+.1*x;}
__device__ float tanh_activate_kernel(float x){return (exp(2*x)-1)/(exp(2*x)+1);}
__device__ float plse_activate_kernel(float x)
{
    if(x < -4) return .01 * (x + 4);
    if(x > 4)  return .01 * (x - 4) + 1;
    return .125*x + .5;
}
 
__device__ float linear_gradient_kernel(float x){return 1;}
__device__ float logistic_gradient_kernel(float x){return (1-x)*x;}
__device__ float relu_gradient_kernel(float x){return (x>0);}
__device__ float relie_gradient_kernel(float x){return (x>0) ? 1 : .01;}
__device__ float ramp_gradient_kernel(float x){return (x>0)+.1;}
__device__ float tanh_gradient_kernel(float x){return 1-x*x;}
__device__ float plse_gradient_kernel(float x){return (x < 0 || x > 1) ? .01 : .125;}

__device__ float activate_kernel(float x, ACTIVATION a)
{
    switch(a){
        case LINEAR:
            return linear_activate_kernel(x);
        case LOGISTIC:
            return logistic_activate_kernel(x);
        case RELU:
            return relu_activate_kernel(x);
        case RELIE:
            return relie_activate_kernel(x);
        case RAMP:
            return ramp_activate_kernel(x);
        case TANH:
            return tanh_activate_kernel(x);
        case PLSE:
            return plse_activate_kernel(x);
    }
    return 0;
}

__device__ float gradient_kernel(float x, ACTIVATION a)
{
    switch(a){
        case LINEAR:
            return linear_gradient_kernel(x);
        case LOGISTIC:
            return logistic_gradient_kernel(x);
        case RELU:
            return relu_gradient_kernel(x);
        case RELIE:
            return relie_gradient_kernel(x);
        case RAMP:
            return ramp_gradient_kernel(x);
        case TANH:
            return tanh_gradient_kernel(x);
        case PLSE:
            return plse_gradient_kernel(x);
    }
    return 0;
}

__global__ void activate_array_kernel(float *x, int n, ACTIVATION a)
{
    int i = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
    if(i < n) x[i] = activate_kernel(x[i], a);
}

__global__ void gradient_array_kernel(float *x, int n, ACTIVATION a, float *delta)
{
    int i = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
    if(i < n) delta[i] *= gradient_kernel(x[i], a);
}

extern "C" void activate_array_ongpu(float *x, int n, ACTIVATION a) 
{
    activate_array_kernel<<<cuda_gridsize(n), BLOCK>>>(x, n, a);
    check_error(cudaPeekAtLastError());
}

extern "C" void gradient_array_ongpu(float *x, int n, ACTIVATION a, float *delta) 
{
    gradient_array_kernel<<<cuda_gridsize(n), BLOCK>>>(x, n, a, delta);
    check_error(cudaPeekAtLastError());
}
