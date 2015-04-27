library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_interface_tb IS
  generic (
    IMG_DIM         : Natural := 6;
    KERNEL_DIM 		: Natural := 3;
    POOL_DIM 	    : Natural := 2;
    INT_WIDTH       : Natural := 16;
    FRAC_WIDTH 		: Natural := 16
	);
END conv_interface_tb;

ARCHITECTURE behavior OF conv_interface_tb IS 

    COMPONENT convolution_layer
        generic (
            C_S_AXI_DATA_WIDTH  : Natural := 32;
            IMG_DIM             : Natural := 6;
            KERNEL_DIM          : Natural := 3;
            POOL_DIM            : Natural := 2;
            INT_WIDTH           : Natural := 16;
            FRAC_WIDTH          : Natural := 16
        );
        Port (
            clk             : in std_logic;
            reset           : in std_logic; -- NOTE: Is active low.
            -- Interface for controlling module
            s_axi_raddr     : in std_logic_vector(2 downto 0);
            s_axi_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_wdata     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_waddr     : in std_logic_vector(2 downto 0);
            s_axi_we        : in std_logic;

            -- Interface for streaming data in
            s_axis_tvalid   : in std_logic;
            s_axis_tready   : out std_logic;
            s_axis_tdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axis_tkeep    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            s_axis_tlast    : in std_logic;

            -- Interface for streaming data out
            m_axis_tvalid   : out std_logic;
            m_axis_tready   : in std_logic;
            m_axis_tdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            m_axis_tkeep    : out std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            m_axis_tlast    : out std_logic
        );    
    END COMPONENT;
  
  
  
  
  constant clk_period : time := 1 ns; 
  

BEGIN

  
  END;
