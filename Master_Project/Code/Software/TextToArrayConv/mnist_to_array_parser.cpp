#include "minst_parser.h"
#include <iostream>
#include <fstream>

int main () {

    std::vector<vec_t> train_images, test_images;

    parse_mnist_labels("t10k-labels.idx1-ubyte", &test_labels);
    parse_mnist_images("t10k-images.idx3-ubyte", &test_images);

    std::ofstream file("labels.h");
    std::ofstream file("images.h");
}