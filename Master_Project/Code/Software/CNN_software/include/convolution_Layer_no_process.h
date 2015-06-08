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
class convolutional_layer_no_process : public partial_connected_layer<N, Activation> {
public:
    typedef partial_connected_layer<N, Activation> Base;
    typedef typename Base::Optimizer Optimizer;

    convolutional_layer_no_process(int in_width, int in_height, int window_size, int in_channels, int out_channels)
    : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, (in_width - window_size + 1) * (in_height - window_size + 1) * out_channels,
    window_size * window_size * in_channels * out_channels, out_channels),
    in_(in_width, in_height, in_channels),
    out_((in_width - window_size + 1), (in_height - window_size + 1), out_channels),
    weight_(window_size, window_size, in_channels*out_channels),
    window_size_(window_size)
    {
        init_connection(connection_table());
    }

    convolutional_layer_no_process(int in_width, int in_height, int window_size, int in_channels, int out_channels, const connection_table& connection_table)
        : partial_connected_layer<N, Activation>(in_width * in_height * in_channels, (in_width - window_size + 1) * (in_height - window_size + 1) * out_channels,
        window_size * window_size * in_channels * out_channels, out_channels),
        in_(in_width, in_height, in_channels),
        out_((in_width - window_size + 1), (in_height - window_size + 1), out_channels),
        weight_(window_size, window_size, in_channels*out_channels),
        connection_(connection_table),
        window_size_(window_size)
    {
        init_connection(connection_table);
        this->remap();
    }

    virtual const vec_t& forward_propagation(const vec_t& in, int index) {
//		for_(this->parallelize_, 0, this->out_size_, [&](const blocked_range& r) {
//			for (int i = r.begin(); i < r.end(); i++) {
//				const wi_connections& connections = out2wi_[i];
//				float_t a = 0.0;
//
//				for (auto connection : connections)// 13.1%
//					a += this->W_[connection.first] * in[connection.second]; // 3.2%
//				a *= scale_factor_;
//				a += this->b_[out2bias_[i]];
//				this->output_[index][i] = this->a_.f(a); // 9.6%
//			}
//		});

		return this->next_ ? this->next_->forward_propagation(this->output_[index], index) : this->output_[index]; // 15.6%
	}

//    void weight_to_image(image& img) {
//        const int border_width = 1;
//        const int pitch = window_size_ + border_width;
//        const int width = out_.depth_ * pitch + border_width;
//        const int height = in_.depth_ * pitch + border_width;
//        const image::intensity_t bg_color = 255;
//
//        img.resize(width, height);
//        img.fill(bg_color);
//
//        auto minmax = std::minmax_element(this->W_.begin(), this->W_.end());
//
//        for (int r = 0; r < in_.depth_; r++) {
//            for (int c = 0; c < out_.depth_; c++) {
//                if (!connection_.is_connected(c, r)) continue;
//
//                const int top = r * pitch + border_width;
//                const int left = c * pitch + border_width;
//
//                for (int y = 0; y < window_size_; y++) {
//                    for (int x = 0; x < window_size_; x++) {
//                        const float_t w = this->W_[weight_.get_index(x, y, c * in_.depth_ + r)];
//
//                        img.at(left + x, top + y)
//                            = (image::intensity_t)rescale<float_t, int>(w, *minmax.first, *minmax.second, 0, 255);
//                    }
//                }
//            }
//        }
//    }

private:
    void init_connection(const connection_table& table) {
        for (int inc = 0; inc < in_.depth_; inc++) {
            for (int outc = 0; outc < out_.depth_; outc++) {
                if (!table.is_connected(outc, inc)) {
                    continue;
                }

                for (int y = 0; y < out_.height_; y++)
                    for (int x = 0; x < out_.width_; x++)
                        connect_kernel(inc, outc, x, y);
            }
        }

        for (int outc = 0; outc < out_.depth_; outc++)
            for (int y = 0; y < out_.height_; y++)
                for (int x = 0; x < out_.width_; x++)
                    this->connect_bias(outc, out_.get_index(x, y, outc));
    }

    void connect_kernel(int inc, int outc, int x, int y) {
        for (int dy = 0; dy < window_size_; dy++)
            for (int dx = 0; dx < window_size_; dx++)
                this->connect_weight(
                    in_.get_index(x + dx, y + dy, inc),
                    out_.get_index(x, y, outc),
                    weight_.get_index(dx, dy, outc * in_.depth_ + inc));
    }

    tensor3d in_;
    tensor3d out_;
    tensor3d weight_;
    connection_table connection_;
    int window_size_;
};

} // namespace tiny_cnn
