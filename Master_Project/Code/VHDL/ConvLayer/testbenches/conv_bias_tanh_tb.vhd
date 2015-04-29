library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

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
      weight_data	: in float32;
      pixel_in		: in float32;
      pixel_valid	: out std_logic;
      pixel_out 	: out float32
      );
  END COMPONENT;

  signal float_size : float32;
  
  constant kernel0 : float32 := to_float(0.4, float_size);
  constant kernel1 : float32 := to_float(0.7, float_size);
  constant kernel2 : float32 := to_float(0.3, float_size);
  constant kernel3 : float32 := to_float(0.4, float_size);
  constant kernel4 : float32 := to_float(-0.1, float_size);
  constant kernel5 : float32 := to_float(-0.8, float_size);
  constant kernel6 : float32 := to_float(-0.7, float_size);
  constant kernel7 : float32 := to_float(0.4, float_size);
  constant kernel8 : float32 := to_float(-0.3, float_size);
  
  constant input0 : float32 := to_float(-0.6, float_size);
  constant input1 : float32 := to_float(-0.4, float_size);
  constant input2 : float32 := to_float(0.6, float_size);
  constant input3 : float32 := to_float(0.4, float_size);
  constant input4 : float32 := to_float(0.8, float_size);
  constant input5 : float32 := to_float(0.6, float_size);
  
  constant input6 : float32 := to_float(-0.9, float_size);
  constant input7 : float32 := to_float(0.9, float_size);
  constant input8 : float32 := to_float(0.5, float_size);
  constant input9 : float32 := to_float(0.6, float_size);
  constant input10 : float32 := to_float(0.9, float_size);
  constant input11 : float32 := to_float(-0.6, float_size);
  
  constant input12 : float32 := to_float(-0.7, float_size);
  constant input13 : float32 := to_float(0.5, float_size);
  constant input14 : float32 := to_float(-0.8, float_size);
  constant input15 : float32 := to_float(-0.2, float_size);
  constant input16 : float32 := to_float(-0.2, float_size);
  constant input17 : float32 := to_float(1.0, float_size);
  
  constant input18 : float32 := to_float(0.5, float_size);
  constant input19 : float32 := to_float(0.7, float_size);
  constant input20 : float32 := to_float(-0.9, float_size);
  constant input21 : float32 := to_float(-0.3, float_size);
  constant input22 : float32 := to_float(-0.5, float_size);
  constant input23 : float32 := to_float(0.8, float_size);
  
  constant input24 : float32 := to_float(1.0, float_size);
  constant input25 : float32 := to_float(0.7, float_size);
  constant input26 : float32 := to_float(0.7, float_size);
  constant input27 : float32 := to_float(1.0, float_size);
  constant input28 : float32 := to_float(-0.2, float_size);
  constant input29 : float32 := to_float(0.3, float_size);
  
  constant input30 : float32 := to_float(0.5, float_size);
  constant input31 : float32 := to_float(0.3, float_size);
  constant input32 : float32 := to_float(0.5, float_size);
  constant input33 : float32 := to_float(-0.9, float_size);
  constant input34 : float32 := to_float(0.4, float_size);
  constant input35 : float32 := to_float(-0.2, float_size);
  
  constant OUTPUT_DIM : Natural := (IMG_DIM-KERNEL_DIM+1)/POOL_DIM;
  type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of float32;
  type kernel_array is array ((KERNEL_DIM*KERNEL_DIM)+3 downto 0) of float32;
  type pooled_array is array ((OUTPUT_DIM*OUTPUT_DIM)-1 downto 0) of float32;
  
  signal image 	: img_array := (
    input35, input34, input33, input32, input31, input30,
    input29, input28, input27, input26, input25, input24,
    input23, input22, input21, input20, input19, input18,
    input17, input16, input15, input14, input13, input12,
    input11, input10, input9, input8, input7, input6,
    input5, input4, input3, input2, input1, input0
    );
    
    constant test_float : float32 := "01000100101001110010000000000000";
    
  signal kernel 	: kernel_array := (
      --to_float(1, float_size), -- scale factor
      test_float,
      to_float(0, float_size), -- bias
      to_float(0.25, float_size), -- avg pool
      to_float(0, float_size), -- bias
      kernel8, kernel7, kernel6,
      kernel5, kernel4, kernel3,
      kernel2, kernel1, kernel0
  );
  
  
  signal clk 				: std_logic := '0';
  signal reset			: std_logic := '0';
  signal conv_en			: std_logic := '0';
  signal layer_nr        : std_logic := '0';
  signal weight_data	: float32 := (others => '0');
  signal weight_we		: std_logic := '0';
  signal pixel_in		: float32 := (others => '0');
  signal pixel_valid	: std_logic := '0';
  signal pixel_out 		: float32 := (others => '0');
  
  constant clk_period : time := 1 ns; 

  signal test_slv : std_logic_vector(31 downto 0) := "01000100101001110010000000000000";
  signal float_test : float32;
  

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

    float_test <= to_float(test_slv, float_test);
    weight_we <= '1';
    for i in 0 to KERNEL_DIM*KERNEL_DIM+3 loop
      weight_data <= kernel(KERNEL_DIM*KERNEL_DIM+3-i);
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
