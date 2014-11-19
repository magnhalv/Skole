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
		first_layer	: in std_logic;
		weight_we	: in std_logic;
		weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_valid	: out std_logic;
		pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		dummy_bias	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
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
			conv_en_in			: in std_logic;
			weight_we			: in std_logic;
			weight_data 		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias_out				: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
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
	
	component conv_img_buffer is
		generic (
			IMG_SIZE		: integer := (((IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM)-(KERNEL_DIM+1))*(((IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM)-(KERNEL_DIM+1));
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
		);
		Port ( 
			clk 					: in std_logic;
			input_valid			: in std_logic;
			conv_en_in			: in std_logic;
			pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic;
			conv_en_out			: out std_logic;
			pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
			
		);
	end component;
	
	component sigmoid is
		Port (
			clk 	: in std_logic;
			x 		: in  ufixed (7 downto -8);
			y 		: out ufixed(7 downto -8)
		);
	end component;
	
	signal dv_conv_to_buf_and_mux 			: std_logic; 
	signal data_conv_to_buf_and_mux			: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal conv_en_conv_to_buf_and_mux 		: std_logic;
	
	signal dv_buf_to_mux							: std_logic;
	signal conv_en_buf_to_mux					: std_logic;
	signal data_buf_to_mux						: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal bias 									: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal conv_en_mux_to_mp	: std_logic;
	signal dv_mux_to_mp			: std_logic;
	signal data_mux_to_mp		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH); 
	
begin

	conv : convolution port map (
		clk				=> clk,
		reset				=> reset,
		conv_en_in		=> conv_en,
		weight_we		=> weight_we,
		weight_data 	=> weight_data,
		pixel_in 		=> pixel_in,
		output_valid	=> dv_conv_to_buf_and_mux,
		conv_en_out		=> conv_en_conv_to_buf_and_mux,
		pixel_out 		=> data_conv_to_buf_and_mux,
		bias_out			=> bias
	
	);
	
	img_buffer : conv_img_buffer port map ( 
		clk 				=> clk,
		input_valid		=> dv_conv_to_buf_and_mux,
		conv_en_in		=> conv_en,
		pixel_in 		=> data_conv_to_buf_and_mux,
		output_valid	=> dv_buf_to_mux,
		conv_en_out		=> conv_en_buf_to_mux, 
		pixel_out 		=> data_buf_to_mux
	);
	
	layer_mux : process (first_layer, 
								conv_en_conv_to_buf_and_mux, 
								dv_conv_to_buf_and_mux,
								data_conv_to_buf_and_mux,
								conv_en_buf_to_mux,
								dv_buf_to_mux,
								data_buf_to_mux)
	begin
		if (first_layer = '1') then
			conv_en_mux_to_mp <= conv_en_conv_to_buf_and_mux;
			dv_mux_to_mp <= dv_conv_to_buf_and_mux;
			data_mux_to_mp	<= data_conv_to_buf_and_mux;
		else
			conv_en_mux_to_mp <= conv_en_buf_to_mux;
			dv_mux_to_mp <= dv_buf_to_mux;
			data_mux_to_mp <= data_buf_to_mux;
		end if;
	end process;
	
	
	mp : max_pool port map ( 
		clk 				=> clk,
		conv_en			=> conv_en_mux_to_mp,
		input_valid		=> dv_mux_to_mp,
		data_in			=> data_mux_to_mp,
		data_out			=> pixel_out,
		output_valid 	=>	pixel_valid
	);

	dummy_bias <= bias;

end Behavioral;

