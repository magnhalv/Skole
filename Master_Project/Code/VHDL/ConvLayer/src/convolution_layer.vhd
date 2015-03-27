library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;


entity convolution_layer is
	generic (
		IMG_DIM 		: Natural := 6;
		KERNEL_DIM 		: Natural := 3;
		MAX_POOL_DIM 	: Natural := 2;
		INT_WIDTH 		: Natural := 8;
		FRAC_WIDTH 		: Natural := 8
	);
	
	port ( 
		clk 		: in std_logic;
		reset		: in std_logic;
		conv_en		: in std_logic;
		layer_nr	: in std_logic;
		weight_we	: in std_logic;
		weight_data	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_valid	: out std_logic;
		pixel_out 	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		dummy_bias	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end convolution_layer;

architecture Behavioral of convolution_layer is
	
	component convolution
		generic 	(
			IMG_DIM	: Natural := IMG_DIM;
			KERNEL_DIM 	: Natural := KERNEL_DIM;
			INT_WIDTH	: Natural := INT_WIDTH;
			FRAC_WIDTH	: Natural := FRAC_WIDTH
		);
		port ( 
			clk				: in std_logic;
			reset			: in std_logic;
			conv_en 		: in std_logic;
			layer_nr        : in std_logic;
			weight_we		: in std_logic;
			weight_data 	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 		: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid	: out std_logic; 
			conv_en_out		: out std_logic;
			pixel_out 		: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias     		: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	component max_pool
		generic (
		    IMG_DIM     : Natural := IMG_DIM-KERNEL_DIM+1;
			POOL_DIM 	: Natural := MAX_POOL_DIM;
			INT_WIDTH 	: Natural := INT_WIDTH;
			FRAC_WIDTH 	: Natural := FRAC_WIDTH
		);
		port ( 
			clk 			: in std_logic;
			conv_en			: in std_logic;
			input_valid		: in std_logic;
			data_in			: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out	    : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid 	: out std_logic	
		);
	end component;
	
	component conv_img_buffer is
		generic (
            IMG_SIZE    : Natural := (IMG_DIM-KERNEL_DIM+1)*(IMG_DIM-KERNEL_DIM+1);--(((IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM)-(KERNEL_DIM+1))*(((IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM)-(KERNEL_DIM+1));
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
		);
		Port ( 
			clk 			: in std_logic;
			input_valid		: in std_logic;
			conv_en_in		: in std_logic;
			pixel_in 		: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid	: out std_logic;
			conv_en_out		: out std_logic;
			pixel_out 		: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
			
		);
	end component;
	
	component tan_h is
		Port (
			clk 	: in std_logic;
			x 		: in  sfixed (INT_WIDTH-1 downto -FRAC_WIDTH);
			y 		: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	signal conv_en_conv_to_buf_and_mux 		: std_logic;
	signal pixel_biasToTanh : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal bias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pixelOut_convToBias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal outputValid_convToReg : std_logic;
	
begin

	conv : convolution port map (
		clk				=> clk,
		reset			=> reset,
		conv_en 		=> conv_en,
		layer_nr        => layer_nr,
		weight_we		=> weight_we,
		weight_data 	=> weight_data,
		pixel_in 		=> pixel_in,
		output_valid	=> outputValid_convToReg,--dv_conv_to_buf_and_mux,
		conv_en_out		=> conv_en_conv_to_buf_and_mux,
		pixel_out 		=> pixelOut_convToBias,--data_conv_to_buf_and_mux,
		bias    		=> bias
	
	);
	
	add_bias : process(bias, pixelOut_convToBias)
	begin
	   pixel_biasToTanh <= resize(bias + pixelOut_convToBias, pixel_biasToTanh);
	end process;
	
	activation_function : tan_h port map (
	   clk => clk,
	   x => pixel_biasToTanh,
	   y => pixel_out
	);
	
	valid_output_reg : process(clk)
	begin
	   if rising_edge(clk) then
	       if reset = '0' then
	           pixel_valid <= '0';
	       else
	           pixel_valid <= outputValid_convToReg;
	       end if;
       end if;
	end process;
	
	
	
	
--	img_buffer : conv_img_buffer port map ( 
--		clk 			=> clk,
--		input_valid		=> dv_conv_to_buf_and_mux,
--		conv_en_in		=> conv_en,
--		pixel_in 		=> data_conv_to_buf_and_mux,
--		output_valid	=> dv_buf_to_mux,
--		conv_en_out		=> conv_en_buf_to_mux, 
--		pixel_out 		=> data_buf_to_mux
--	);
	
--	layer_mux : process (layer_nr, 
--						  conv_en_conv_to_buf_and_mux, 
--						  dv_conv_to_buf_and_mux,
--						  data_conv_to_buf_and_mux,
--						  conv_en_buf_to_mux,
--						  dv_buf_to_mux,
--						  data_buf_to_mux)
--	begin
--		if (layer_nr = '0') then
--			conv_en_mux_to_mp <= conv_en_conv_to_buf_and_mux;
--			dv_mux_to_mp <= dv_conv_to_buf_and_mux;
--			data_mux_to_mp	<= data_conv_to_buf_and_mux;
--		else
--			conv_en_mux_to_mp <= conv_en_buf_to_mux;
--			dv_mux_to_mp <= dv_buf_to_mux;
--			data_mux_to_mp <= data_buf_to_mux;
--		end if;
--	end process;
	
	
--	mp : max_pool port map ( 
--		clk 			=> clk,
--		conv_en			=> conv_en_mux_to_mp,
--		input_valid		=> dv_mux_to_mp,
--		data_in			=> data_mux_to_mp,
--		data_out		=> pixel_out,
--		output_valid 	=> pixel_valid
--	);

	dummy_bias <= bias;
	

end Behavioral;

