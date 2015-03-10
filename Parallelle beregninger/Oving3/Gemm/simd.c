#include <complex.h>
#include <stdio.h>
#include <xmmintrin.h>
#include <pmmintrin.h>

void simd_complex_mult(complex float * in1,
   complex float * in2,
   complex float * out){

  __m128 t,t2,s,b;

  s = _mm_loadu_ps((float*)in1);
  b = _mm_loadu_ps((float*)in2);

  s = b + s;

  _mm_storeu_ps((float*)out, s);
  //((__m128*)out)[0] = s;

}

int main(){
    complex float in1[2] = {3 + 2*I, 4 - 2*I};
    complex float in2[2] = {0.5 + 1*I, -1 - 4*I};
    complex float out[2];

    
    out[0] = in1[0] + in2[0];
    printf("%f, %f\n",creal(out[0]),cimag(out[0]));
    simd_complex_mult(in1,in2,out);
    printf("%f, %f\n",creal(out[0]),cimag(out[0]));
}


