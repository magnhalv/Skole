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
#include <c++/4.8.3/fstream>
#include <c++/4.8.3/cstdint>
#include "../include/SdReader.h"


namespace tiny_cnn {

void reverse_endian(uint32_t &num) {
	uint32_t swapped = ((num>>24)&0xff) | ((num<<8)&0xff0000) | ((num>>8)&0xff00) | ((num<<24)&0xff000000);
	num = swapped;
}

void parse_mnist_labels(const std::string& label_file, std::vector<label_t> *labels) {
    std::stringstream ifs;
    ReadBytesFromSDFile(ifs, label_file.c_str());

    if (ifs.bad() || ifs.fail())
        throw nn_error("failed to open file:" + label_file);

    uint32_t magic_number, num_items;

    ifs.read((char*) &magic_number, 4);
    ifs.read((char*) &num_items, 4);

    reverse_endian(&magic_number);
    reverse_endian(&num_items);


    if (magic_number != 0x00000801 || num_items <= 0)
        throw nn_error("MNIST label-file format error");

    for (size_t i = 0; i < num_items; i++) {
        uint8_t label;
        ifs.read((char*) &label, 1);
        labels->push_back((label_t) label);
    }
}

struct mnist_header {
    uint32_t magic_number;
    uint32_t num_items;
    uint32_t num_rows;
    uint32_t num_cols;
};

void parse_mnist_header(std::stringstream& ifs, mnist_header& header) {
    ifs.read((char*) &header.magic_number, 4);
    ifs.read((char*) &header.num_items, 4);
    ifs.read((char*) &header.num_rows, 4);
    ifs.read((char*) &header.num_cols, 4);

    reverse_endian(&header.magic_number);
    reverse_endian(&header.num_items);
    reverse_endian(&header.num_rows);
    reverse_endian(&header.num_cols);


    if (header.magic_number != 0x00000803 || header.num_items <= 0)
        throw nn_error("MNIST image header format error");
    if (ifs.fail() || ifs.bad())
        throw nn_error("file error");
}

void parse_mnist_image(std::stringstream& ifs,
    const mnist_header& header,
    float_t scale_min,
    float_t scale_max,
    int x_padding,
    int y_padding,
    vec_t& dst) {
    const int width = header.num_cols + 2 * x_padding;
    const int height = header.num_rows + 2 * y_padding;

    std::vector<uint8_t> image_vec(header.num_rows * header.num_cols);

    ifs.read((char*) &image_vec[0], header.num_rows * header.num_cols);

    dst.resize(width * height, scale_min);

    for (size_t y = 0; y < header.num_rows; y++)
    for (size_t x = 0; x < header.num_cols; x++)
        dst[width * (y + y_padding) + x + x_padding]
        = (image_vec[y * header.num_cols + x] / 255.0) * (scale_max - scale_min) + scale_min;
}

void parse_mnist_images(const std::string& image_file,
    std::vector<vec_t> *images,
    float_t scale_min = -1.0,
    float_t scale_max = 1.0,
    int x_padding = 2,
    int y_padding = 2) {
	std::stringstream ifs;
	ReadBytesFromSDFile(ifs, image_file.c_str());

    if (ifs.bad() || ifs.fail())
        throw nn_error("failed to open file:" + image_file);

    mnist_header header;

    parse_mnist_header(ifs, header);

    for (size_t i = 0; i < header.num_items; i++) {
        vec_t image;
        parse_mnist_image(ifs, header, scale_min, scale_max, x_padding, y_padding, image);
        images->push_back(image);
    }
}

} // namespace tiny_cnn
