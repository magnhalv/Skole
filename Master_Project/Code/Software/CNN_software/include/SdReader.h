#include <c++/4.8.3/exception>
#include <c++/4.8.3/string>
#include <c++/4.8.3/sstream>
#include "xparameters.h"	/* SDK generated parameters */
#include "xsdps.h"		/* SD device driver */
#include <stdio.h>
#include "ff.h"

void ReadFloatsFromSDFile(std::stringstream &stream, const std::string file_name);
void ReadBytesFromSDFile(std::stringstream &stream, const std::string file_name);
