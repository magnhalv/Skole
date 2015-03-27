################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

CC_SRCS += \
../src/ClAccDriver.cc 

CPP_SRCS += \
../src/SdReader.cpp \
../src/main.cpp 

CC_DEPS += \
./src/ClAccDriver.d 

OBJS += \
./src/ClAccDriver.o \
./src/SdReader.o \
./src/main.o 

CPP_DEPS += \
./src/SdReader.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.cc
	@echo 'Building file: $<'
	@echo 'Invoking: ARM g++ compiler'
	arm-xilinx-eabi-g++ -std=c++11 -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -I/home/magnhalv/Programs/Xilinx/Vivad_projects/CNN/CNN.sdk/standalone_bsp_1/ps7_cortexa9_0/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: ARM g++ compiler'
	arm-xilinx-eabi-g++ -std=c++11 -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -I/home/magnhalv/Programs/Xilinx/Vivad_projects/CNN/CNN.sdk/standalone_bsp_1/ps7_cortexa9_0/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


