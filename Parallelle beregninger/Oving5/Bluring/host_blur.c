#include "host_blur.h"

void host_blur(unsigned char* inputImage, unsigned char* outputImage, int size) {
	for(int i = 1; i < 511; i++) {
        for(int j = 1; j < 511; j++){

            outputImage[i * 512 + j] = 0;
            for(int k = -1; k < 2; k++){
                for(int l = -1; l < 2; l++){
                    outputImage[i * 512 + j] += (inputImage[(i+k)*512 + j+l] / 9.0);
                }
            }
        }
	}
}

