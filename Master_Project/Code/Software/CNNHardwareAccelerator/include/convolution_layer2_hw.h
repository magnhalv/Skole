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
#pragma once
#include "util.h"
#include "partial_connected_layer.h"
#include "image.h"
#include <assert.h>
#include <c++/4.8.3/algorithm>



namespace tiny_cnn {


template<typename N, typename Activation>
class convolutional_layer2_hw : public partial_connected_layer<N, Activation> {
public:

    convolutional_layer2_hw(int in_width, int in_height, int window_size, int in_channels, int out_channels)
    : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, ((in_width - window_size + 1)/2) * ((in_width - window_size + 1)/2) * out_channels,
    window_size * window_size * in_channels * out_channels, out_channels)
    {
    	avg_pool_coffs.resize(out_channels);
    	avg_pool_bias.resize(out_channels);
    }

    convolutional_layer2_hw(int in_width, int in_height, int window_size, int in_channels, int out_channels, const connection_table& connection_table)
    : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, ((in_width - window_size + 1)/2) * ((in_width - window_size + 1)/2) * out_channels,
        window_size * window_size * in_channels * out_channels, out_channels)

    {
    	avg_pool_coffs.resize(out_channels);
		avg_pool_bias.resize(out_channels);
    	conn_table = connection_table;
        this->remap();
    }

    void print_weights() {

    	xil_printf("Kernel: \n\r");
    	for (int nof_times = 0; nof_times < 6; nof_times++) {
    		for (int i = 0; i < 5; i++) {
				for (int j = 0; j < 5; j++) {
					printf("%f - ", this->W_[1350+i*5+j+25*nof_times]);
				}
				printf("\n\r");
			}
    		printf("\n\r");
    	}
    	printf("bias: %f\n\r", this->b_[15]);
    	printf("avg_pool_coff: %f\n\r", this->avg_pool_coffs[15]);
    	printf("avg_bias: %f\n\r", this->avg_pool_bias[15]);
    }

    virtual const vec_t& forward_propagation(const vec_t& in, int index) {


    	int w_index[6][16] = {
    		{0,  0,   0,   0,   300,  375, 450, 0,   0,   750, 850, 950,  1050,    0, 1250, 1350},
    		{25, 75,  0,   0,   0,    400, 475, 550, 0,   0,   875, 975,  1075, 1150, 0,    1375},
    		{50, 100, 150, 0,   0,    0,   500, 575, 650, 0,   0,   1000, 0,    1175, 1275, 1400},
    		{0,  125, 175, 225, 0,    0,   525, 600, 675, 775, 0,   0,    1100, 0,    1300, 1425},
    		{0,  0,   200, 250, 325,  0,   0,   625, 700, 800, 900, 0,    1125, 1200, 0,    1450},
    		{0,  0,   0,   275, 350,  425, 0,   0,   725, 825, 925, 1025, 0,    1225, 1325, 1475}
    	};
    	const int nof_output_maps = 16;
    	const int nof_input_maps = 6;
    	const int img_dim = 14*14;
    	for (int i = 0; i < nof_output_maps; i++) {
    		std::vector<ConvLayerValues> clv_vec;
    		for (int j = 0; j < nof_input_maps; j++) {
    			if (conn_table.is_connected(i,j)) {
					ConvLayerValues clv = {
							in.begin()+img_dim*j,
							this->W_.begin()+w_index[j][i],
							14,
							5,
							this->b_[i],
							avg_pool_coffs[i],
							avg_pool_bias[i],
							0.25
					};
					clv_vec.push_back(clv);
    			}
    		}
    		CalculateClUsingHWAccelerator(clv_vec, this->output_[index].begin()+i*5*5);

		}

//		for (int i = 0; i < this->out_size_; i++) {
//			const wi_connections& connections = this->out2wi_[i];
//			float_t a = 0.0;
//
//			for (auto connection : connections)// 13.1%
//				a += this->W_[connection.first] * in[connection.second]; // 3.2%
//
//			a *= this->scale_factor_;
//			a += this->b_[this->out2bias_[i]];
//			float out_val = this->a_.f(a);
//
//			float e = all_fm[i];
//			if(!CompareFloats(e, out_val)) {
//				printf("Expected: %f. Actual: %f.\n\r", out_val, e);
//			}
//			this->output_[index][i] = out_val; // 9.6%
//		}


		return this->next_ ? this->next_->forward_propagation(this->output_[index], index) : this->output_[index]; // 15.6%
	}

	virtual void load(std::istream& is) {
		int count = 0;
		for (auto& w : this->W_){
			float f;
			is.read((char*)&f, sizeof(f));
			w = f;
			count++;
		}
		for (auto& b : this->b_) {
			float f;
			is.read((char*)&f, sizeof(f));
			b = f;
			count++;
		}
		for (auto& c : avg_pool_coffs) {
			float f;
			is.read((char*)&f, sizeof(f));
			c = f;
			count++;
		}

		for (auto& avg_b : avg_pool_bias) {
			float f;
			is.read((char*)&f, sizeof(f));
			avg_b = f;
			count++;
		}
		xil_printf("Count is: %d\n\r", count);
	}




private:
	vec_t avg_pool_coffs;
	vec_t avg_pool_bias;
	connection_table conn_table;
};


template <typename Char, typename CharTraits, typename N, typename Activation>
std::basic_istream<Char, CharTraits>& operator >> (std::basic_istream<Char, CharTraits>& os, convolutional_layer2_hw<N, Activation>& v) {
	v.load(os);
    return os;
}

} // namespace tiny_cnn
