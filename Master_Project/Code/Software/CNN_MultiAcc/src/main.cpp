/*
    Copyright (c) 2013, Taiga Nomi
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY 
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <c++/4.8.3/iostream>
#include <c++/4.8.3/cmath>
#include <c++/4.8.3/sstream>
#include <c++/4.8.3/string>


#include "xaxidma.h"

#include "../include/SdReader.h"
#include "../include/tiny_cnn.h"
//#define NOMINMAX
//#include "imdebug.h"

void convert_images_to_fixed(std::vector<vec_t> &images);
void load_weights();

using namespace tiny_cnn;
using namespace tiny_cnn::activation;

int main() {
	try {
		load_weights();
	} catch (std::string e) {
		xil_printf("Exception: %s", e.c_str());
	}


	xil_printf("Done.\n\r");
	return 0;
}

void load_weights(void) {
    
    typedef network<mse, gradient_descent_levenberg_marquardt> CNN;
    CNN nn;
    convolutional_layer_hw<CNN, tan_h> C1(32, 32, 5, 1, 6);
    //average_pooling_layer<CNN, tan_h> S2(28, 28, 6, 2);
#define O true
#define X false
    static const bool connection[] = {
        O, X, X, X, O, O, O, X, X, O, O, O, O, X, O, O,
        O, O, X, X, X, O, O, O, X, X, O, O, O, O, X, O,
        O, O, O, X, X, X, O, O, O, X, X, O, X, O, O, O,
        X, O, O, O, X, X, O, O, O, O, X, X, O, X, O, O,
        X, X, O, O, O, X, X, O, O, O, O, X, O, O, X, O,
        X, X, X, O, O, O, X, X, O, O, O, O, X, O, O, O
    };
#undef O
#undef X
    convolutional_layer2_hw<CNN, tan_h> C3(14, 14, 5, 6, 16, connection_table(connection, 6, 16));
    //convolutional_layer<CNN, tan_h> C3(14, 14, 5, 6, 16, connection_table(connection, 6, 16));
    //average_pooling_layer<CNN, tan_h> S4(10, 10, 16, 2);
    convolutional_layer<CNN, tan_h> C5(5, 5, 5, 16, 120);
    fully_connected_layer<CNN, tan_h> F6(120, 10);
    nn.add(&C1);
    nn.add(&C3);
   // nn.add(&S4);
    nn.add(&C5);
    nn.add(&F6);

    std::stringstream stream;
    ReadFloatsFromSDFile(stream, std::string("weights.bin"));


    stream >> C1 >> C3 >> C5 >> F6;

   // C3.print_weights();



    std::vector<label_t> train_labels, test_labels;
    std::vector<vec_t> train_images, test_images;

    parse_mnist_labels("labels.bin", &test_labels);
    parse_mnist_images("images.bin", &test_images);

    convert_images_to_fixed(test_images);

    nn.test(test_images, test_labels).print_detail(std::cout);
    return;
    //C1.print_weights();
}

void convert_images_to_fixed(std::vector<vec_t> &images) {
	for (auto &image : images) {
		for (auto &pixel : image) {
			int n = FloatToFixed(pixel);
			memcpy((void*)&pixel, (void*)&n, sizeof(float));
		}
	}
}

