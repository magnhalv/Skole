// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4 (lin64) Build 1071353 Tue Nov 18 16:47:07 MST 2014
// Date        : Fri Jan 23 14:57:50 2015
// Host        : Cyberspace running 64-bit Ubuntu 14.10
// Command     : write_verilog -force -mode synth_stub
//               /home/magnhalv/Github/Skole/Master_Project/VHDL/ConvLayer/IP/dual_block_mem/_cg/dual_block_mem_stub.v
// Design      : dual_block_mem
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_2,Vivado 2014.4" *)
module dual_block_mem(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[6:0],dina[15:0],clkb,addrb[6:0],doutb[15:0]" */;
  input clka;
  input [0:0]wea;
  input [6:0]addra;
  input [15:0]dina;
  input clkb;
  input [6:0]addrb;
  output [15:0]doutb;
endmodule
