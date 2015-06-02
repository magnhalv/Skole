#include <vector>
#include <iostream>
#include "Testdata.h"

int main () {
    std::vector<float> out(10*10,0);
    //std::vector<std::vector<float>> images = {g_image1, g_image2, g_image3};
    //std::vector<std::vector<float>> weights = {g_kernel1, g_kernel2, g_kernel3};

    std::vector<float> image1;
    std::vector<float> image2;
    std::vector<float> kernel1(5*5, 1);

    for (int i = 0; i < 14*14; i++) {
        image1.push_back(i+1);
        image2.push_back(14*14-i);
    }
    
    std::vector<std::vector<float>> images = {image1, image1, image2};
    std::vector<std::vector<float>> weights = {kernel1, kernel1, kernel1};
    
    int img_dim = 10;
    int w_dim = 5;
    for (int image = 0; image < 3; image++) {
        for (int i_y = 0; i_y < img_dim; i_y++) {
            for (int i_x = 0; i_x < img_dim; i_x++) {
                float val = 0;
                for (int w_y = 0; w_y < w_dim; w_y++) {
                    for (int w_x = 0; w_x < w_dim; w_x++) {
                        val += images[image][(i_y*14+i_x)+w_y*14+w_x]*weights[image][w_y*w_dim+w_x];
                    }
                }
                out[i_y*img_dim+i_x] += val;
            
            }
        }
    }

    for (int i = 0; i < 14; i++) {
        for (int j = 0; j < 14; j++) {
            std::cout << image1[(14*14)-1-(i*14+j)] << ", ";
        }
        std::cout << std::endl;
    }
    
    for (int y = 0; y < img_dim; y++) {
        for (int x = 0; x < img_dim; x++) {
            std::cout << out[y*img_dim+x] << ", ";
        }
        std::cout << std::endl;
    }

    
    return 0;
}
