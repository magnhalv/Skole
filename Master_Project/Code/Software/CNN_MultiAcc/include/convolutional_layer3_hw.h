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
class convolutional_layer3_hw : public partial_connected_layer<N, Activation> {
public:

    convolutional_layer3_hw(int in_width, int in_height, int window_size, int in_channels, int out_channels, ClAccDriver &acc)
    : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, ((in_width - window_size + 1)/2) * ((in_width - window_size + 1)/2) * out_channels,
    window_size * window_size * in_channels * out_channels, out_channels),
    acc_driver(acc)
    {

    }

    convolutional_layer3_hw(int in_width, int in_height, int window_size, int in_channels, int out_channels, const connection_table& connection_table, ClAccDriver &acc)
    : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, ((in_width - window_size + 1)/2) * ((in_width - window_size + 1)/2) * out_channels,
        window_size * window_size * in_channels * out_channels, out_channels),
        acc_driver(acc)

    {

    	conn_table = connection_table;
        this->remap();
    }

    void print_weights() {

    	xil_printf("Nof weights: %d\n\r", this->W_.size());
    	xil_printf("Nof bias: %d\n\r", this->b_.size());
    }

    virtual const vec_t& forward_propagation(const vec_t& in, int index) {
    	float scale = 0.25;
		int n = FloatToFixed(scale);
		float scale_factor;
		memcpy((void*)&scale_factor, (void*)&n, sizeof(float));

		const int nof_output_maps = 120;
		const int nof_input_maps = 16;
    	const int img_size = 5*5;

    	feature_map_parameters fmp;

		for (int i = 0; i < nof_output_maps; i++) {
			std::vector<ConvLayerValues> clv_vec;
			for (int j = 0; j < nof_input_maps; j++) {
				int output_index = j*img_size+i*img_size*nof_input_maps;
				ConvLayerValues clv = {
						in.begin()+output_index,
						this->W_.begin()+output_index,
						{scale_factor, 0, 0, this->b_[i]},
						5,
						5,
						this->output_[index].begin()+i
				};
				clv_vec.push_back(clv);

			}
			fmp.push_back(clv_vec);
		}
		acc_driver.CalculateLayer(fmp, 4);

		return this->next_ ? this->next_->forward_propagation(this->output_[index], index) : this->output_[index]; // 15.6%
	}

	virtual void load(std::istream& is) {
		for (int i = 0; i < this->W_.size(); i=i+25) {
			vec_t temp_W;
			for (int j = 0; j < 25; j++) {

				float f;
				float w;
				is.read((char*)&f, sizeof(f));
				int n = FloatToFixed(f);
				memcpy((void*)&w, (void*)&n, sizeof(float));
				temp_W.push_back(w);
			}
			std::reverse_copy(temp_W.begin(), temp_W.end(), this->W_.begin()+i);
		}

		for (auto& b : this->b_) {
			float f;
			is.read((char*)&f, sizeof(f));
			int n = FloatToFixed(f);
			memcpy((void*)&b, (void*)&n, sizeof(float));
		}
	}




private:
	connection_table conn_table;
	ClAccDriver &acc_driver;
};


template <typename Char, typename CharTraits, typename N, typename Activation>
std::basic_istream<Char, CharTraits>& operator >> (std::basic_istream<Char, CharTraits>& os, convolutional_layer3_hw<N, Activation>& v) {
	v.load(os);
    return os;
}

} // namespace tiny_cnn
