#include "../include/SdReader.h"




void ReadFloatsFromSDFile(std::stringstream &stream, const std::string file_name)
{
	FIL fil;		/* File object */
	FATFS fatfs;
	FILINFO file_info;
	char *SD_File;
	std::stringstream sstream;
	FRESULT Res;

	UINT NumBytesRead;

	Res = f_mount(0, &fatfs);

	if (Res != FR_OK) throw "Could not mount SD card.";

	SD_File = (char *)file_name.c_str();

	Res = f_open(&fil, SD_File, FA_READ | FA_OPEN_EXISTING);
	if (Res) throw Res;


	Res = f_lseek(&fil, 0);
	if (Res) throw "Failed to seek opened file.";


	Res = f_stat(SD_File, &file_info);
	DWORD fil_size = file_info.fsize+1;
	for(DWORD i = 0; i < fil_size/4; i++) {

		float number;
		Res = f_read(&fil, (char*)&number, sizeof(number), &NumBytesRead);
		if (Res) throw "Failed to read file.";
		stream.write((char*)&number, sizeof(number));
	}

	Res = f_close(&fil);
	if (Res) throw "Failed to close file";
}

void ReadBytesFromSDFile(std::stringstream &stream, const std::string file_name)
{
	FIL fil;
	FATFS fatfs;
	FILINFO file_info;
	char *SD_File;
	std::stringstream sstream;
	FRESULT Res;

	UINT NumBytesRead;

	Res = f_mount(0, &fatfs);

	if (Res != FR_OK) throw "Could not mount SD card.";

	SD_File = (char *)file_name.c_str();

	Res = f_open(&fil, SD_File, FA_READ | FA_OPEN_EXISTING);
	if (Res) throw Res;


	Res = f_lseek(&fil, 0);
	if (Res) throw "Failed to seek opened file.";


	Res = f_stat(SD_File, &file_info);
	DWORD fil_size = file_info.fsize;

	const int Buff_Size = 1;
	char fbuffer[Buff_Size];
	for(DWORD i = 0; i < fil_size/Buff_Size; i++) {

		Res = f_read(&fil, fbuffer, Buff_Size, &NumBytesRead);
		if (Res) throw "Failed to read file.";
		if (NumBytesRead != 1) throw "Too many bytes read";
		stream.write(fbuffer, Buff_Size);

	}

	Res = f_close(&fil);
	if (Res) throw "Failed to close file";
}

