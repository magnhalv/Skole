library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;


entity convolution_layer is
	generic (
		IMG_DIM 			: integer := 32;
		KERNEL_DIM 		: integer := 5;
		MAX_POOL_DIM 	: integer := 2;
		INT_WIDTH 		: integer := 8;
		FRAC_WIDTH 		: integer := 8
	);
	
	port ( 
		clk 			: in std_logic;
		reset			: in std_logic;
		conv_en		: in std_logic;
		weight_we	: in std_logic;
		weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_valid	: out std_logic;
		pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end convolution_layer;

architecture Behavioral of convolution_layer is
	
	component convolution
		generic 	(
			IMAGE_DIM	: integer := IMG_DIM;
			KERNEL_DIM 	: integer := KERNEL_DIM;
			INT_WIDTH	: integer := INT_WIDTH;
			FRAC_WIDTH	: integer := FRAC_WIDTH
		);
		port ( 
			clk					: in std_logic;
			reset					: in std_logic;
			conv_en				: in std_logic;
			weight_we			: in std_logic;
			weight_data 		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	component max_pool
		generic (
			POOL_DIM 	: integer := MAX_POOL_DIM;
			INT_WIDTH 	: integer := INT_WIDTH;
			FRAC_WIDTH 	: integer := FRAC_WIDTH
		);
		port ( 
			clk 				: in std_logic;
			conv_en			: in std_logic;
			input_valid		: in std_logic;
			data_in			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid 	: out std_logic	
		);
	end component;
	
	signal data_valid_convolution_to_max_pool 	: std_logic; 
	signal data_convolution_to_max_pool		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
begin

	convoluter : convolution port map (
		clk				=> clk,
		reset				=> reset,
		conv_en			=> conv_en,
		weight_we		=> weight_we,
		weight_data 	=> weight_data,
		pixel_in 		=> pixel_in,
		output_valid	=> data_valid_convolution_to_max_pool,
		pixel_out 		=> data_convolution_to_max_pool
	
	);
	
	max_pooler : max_pool port map ( 
		clk 				=> clk,
		conv_en			=> conv_en,
		input_valid		=> data_valid_convolution_to_max_pool,
		data_in			=> data_convolution_to_max_pool,
		data_out			=> pixel_out,
		output_valid 	=>	pixel_valid
	);


end Behavioral;

