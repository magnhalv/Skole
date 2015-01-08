TDT4255 Exercise 0 Support Files
________________________________

This archive contains the skeleton code for TDT4255 Lab Exercise 0, and includes testbenches as well as the code which instantiates the infrastructure that you'll be using for testing on the FPGA.

As part of this exercise, you are supposed to fill in the missing parts from src/control.vhd and src/stack.vhd -- see the compendium for more details.

To get started, create a new (empty) ISE VHDL project as described in the compendium, then copy the "src" folder into the project folder and use the "Add Source..." command in ISE to add all the source files. 


Testing in simulation
_____________________

The src/tests subfolder contains several testbenches that you can use to test your system in simulation.


Testing on the FPGA
___________________

The src/framework subfolder contains the framework for testing on the FPGA, including the parts that talk to the host PC. When testing on the FPGA, set the top level entity to RPNSystem and use the "hostcomm" utility on the host PC to interact with the hardware. 

Make sure you add all the contents of the src/framework and src/framework/uart subfolders to your ISE project before testing on the FPGA. Do not forget to add the user constraints file (RPNSystem.ucf) and the RPNDataMem.xco file. When implementing the project for the first time, a dialog box asking whether you want to regenerate the IP cores will pop up, answer "yes".

A top-level system testbench is also provided (src/framework/rpnsystem_tb.vhd) if you want to debug the entire system in simulation, including the instruction queue implementation and other parts of the framework.
