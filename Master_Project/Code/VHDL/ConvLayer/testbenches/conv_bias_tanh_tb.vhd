library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_bias_tanh_tb IS
  generic (
    IMG_DIM         : Natural := 6;
    KERNEL_DIM 		: Natural := 3;
    POOL_DIM 	    : Natural := 2;
    INT_WIDTH       : Natural := 16;
    FRAC_WIDTH 		: Natural := 16
	);
END conv_bias_tanh_tb;

ARCHITECTURE behavior OF conv_bias_tanh_tb IS 

  COMPONENT convolution_layer
    generic (
      IMG_DIM 			: Natural := IMG_DIM;
      KERNEL_DIM 		: Natural := KERNEL_DIM;
      POOL_DIM 	        : Natural := POOL_DIM;
      INT_WIDTH 		: Natural := INT_WIDTH;
      FRAC_WIDTH 		: Natural := FRAC_WIDTH
      );
    
    port ( 
      clk 			: in std_logic;
      reset			: in std_logic;
      conv_en		: in std_logic;
      layer_nr      : in std_logic;
      weight_we	    : in std_logic;
      weight_data	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
      pixel_in		: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
      pixel_valid	: out std_logic;
      pixel_out 	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
      );
  END COMPONENT;
  
  constant kernel0 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.3, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel3 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel4 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.1, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel5 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.8, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel6 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel7 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant kernel8 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.3, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input0 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.6, INT_WIDTH-1, -FRAC_WIDTH);
  constant input1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant input2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.6, INT_WIDTH-1, -FRAC_WIDTH);
  constant input3 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant input4 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.8, INT_WIDTH-1, -FRAC_WIDTH);
  constant input5 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.6, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input6 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.9, INT_WIDTH-1, -FRAC_WIDTH);
  constant input7 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.9, INT_WIDTH-1, -FRAC_WIDTH);
  constant input8 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input9 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.6, INT_WIDTH-1, -FRAC_WIDTH);
  constant input10 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.9, INT_WIDTH-1, -FRAC_WIDTH);
  constant input11 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.6, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input12 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant input13 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input14 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.8, INT_WIDTH-1, -FRAC_WIDTH);
  constant input15 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.2, INT_WIDTH-1, -FRAC_WIDTH);
  constant input16 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.2, INT_WIDTH-1, -FRAC_WIDTH);
  constant input17 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1.0, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input18 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input19 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant input20 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.9, INT_WIDTH-1, -FRAC_WIDTH);
  constant input21 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.3, INT_WIDTH-1, -FRAC_WIDTH);
  constant input22 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input23 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.8, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input24 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1.0, INT_WIDTH-1, -FRAC_WIDTH);
  constant input25 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant input26 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.7, INT_WIDTH-1, -FRAC_WIDTH);
  constant input27 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1.0, INT_WIDTH-1, -FRAC_WIDTH);
  constant input28 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.2, INT_WIDTH-1, -FRAC_WIDTH);
  constant input29 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.3, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant input30 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input31 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.3, INT_WIDTH-1, -FRAC_WIDTH);
  constant input32 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.5, INT_WIDTH-1, -FRAC_WIDTH);
  constant input33 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.9, INT_WIDTH-1, -FRAC_WIDTH);
  constant input34 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.4, INT_WIDTH-1, -FRAC_WIDTH);
  constant input35 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.2, INT_WIDTH-1, -FRAC_WIDTH);
  
  constant OUTPUT_DIM : Natural := (IMG_DIM-KERNEL_DIM+1)/POOL_DIM;
  type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
  type kernel_array is array ((KERNEL_DIM*KERNEL_DIM)+1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
  type pooled_array is array ((OUTPUT_DIM*OUTPUT_DIM)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
  
  signal image 	: img_array := (
    input35, input34, input33, input32, input31, input30,
    input29, input28, input27, input26, input25, input24,
    input23, input22, input21, input20, input19, input18,
    input17, input16, input15, input14, input13, input12,
    input11, input10, input9, input8, input7, input6,
    input5, input4, input3, input2, input1, input0
    );
  signal kernel 	: kernel_array := (
      to_sfixed(0.25, INT_WIDTH-1, -FRAC_WIDTH), -- avg pool
      to_sfixed(0, INT_WIDTH-1, -FRAC_WIDTH), -- bias
      kernel8, kernel7, kernel6,
      kernel5, kernel4, kernel3,
      kernel2, kernel1, kernel0
  );
  
  
  signal clk 				: std_logic := '0';
  signal reset			: std_logic := '0';
  signal conv_en			: std_logic := '0';
  signal layer_nr        : std_logic := '0';
  signal weight_we		: std_logic := '0';
  signal weight_data	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
  signal pixel_in		: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
  signal pixel_valid	: std_logic := '0';
  signal pixel_out 		: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
  
  constant clk_period : time := 1 ns; 
  

BEGIN

  conv_layer : convolution_layer port map(
    clk 			=> clk,
    reset			=> reset,
    conv_en		=> conv_en,
    layer_nr => layer_nr,
    weight_we	=> weight_we,
    weight_data	=> weight_data,
    pixel_in		=> pixel_in,
    pixel_valid	=> pixel_valid,
    pixel_out 	=> pixel_out
	);

  clock : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  test_input : PROCESS
  BEGIN
    reset <= '0';
    wait for clk_period*10;
    reset <= '1';

    weight_we <= '1';
    weight_data <= to_sfixed(1, weight_data);
    wait for clk_period;
    
    for i in 0 to KERNEL_DIM*KERNEL_DIM+1 loop
      weight_data <= kernel(KERNEL_DIM*KERNEL_DIM+1-i);
      wait for clk_period;
    end loop;

    weight_we <= '0';
    conv_en <= '1';
    
    for i in 0 to IMG_DIM*IMG_DIM-1 loop
      pixel_in <= image(i);
      wait for clk_period;
    end loop;

    pixel_in <= (others => '0');
    
    wait for clk_period*50;
    conv_en <= '0';
    
    wait; -- will wait forever
  END PROCESS;

  END;
