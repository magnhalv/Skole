library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

entity convolution_layer is
	generic (
		IMG_DIM 		: Natural := 32;
		KERNEL_DIM 		: Natural := 5;
		POOL_DIM    	: Natural := 2;
		INT_WIDTH 		: Natural := 16;
		FRAC_WIDTH 		: Natural := 16
	);
	
	port ( 
		clk 		: in std_logic;
		reset		: in std_logic;
		conv_en		: in std_logic;
		layer_nr	: in std_logic;
		weight_we	: in std_logic;
		weight_data	: in float32;
		pixel_in	: in float32;
		pixel_valid	: out std_logic;
		pixel_out 	: out float32;
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
	
	component average_pooler
        generic (
            IMG_DIM : Natural := IMG_DIM-KERNEL_DIM+1;
            POOL_DIM : Natural := POOL_DIM;
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
            );
        Port ( 
            clk : in std_logic;
            reset : in std_logic;
            conv_en : in std_logic;
            weight_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            weight_we : in std_logic;
            input_valid : in std_logic;
            data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            output_valid : out std_logic;
            output_weight : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
            
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
            clk 	     : in std_logic;
			input_valid  : in std_logic;
			x 		     : in  sfixed (INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid : out std_logic;
			y 		     : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	

    signal pixelIn_FloatToFixed : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal convEn_FloatToFixed : std_logic;
    signal weightWe_FloatToFixed : std_logic;
    signal weightData_FloatToFixed : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
	signal bias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal bias2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal weight_avgPoolToBias2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal scale_factor : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
	signal convEn_convToBias : std_logic;
	signal outputValid_convToBias : std_logic;
    signal pixelOut_convToBias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    signal valid_biasToTanh : std_logic;
    signal pixel_biasToTanh : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    signal pixelValid_TanhToAvgPool : std_logic;
    signal pixelOut_TanhToAvgPool : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    signal pixelValid_AvgPoolToScaleFactor : std_logic;
    signal pixelOut_AvgPoolToScaleFactor : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    signal pixelValid_ScaleFactorToBias2 : std_logic;
    signal pixelOut_ScaleFactorToBias2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    signal pixelValid_Bias2ToTanh2 : std_logic;
    signal pixelOut_Bias2ToTanh2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    signal pixelValid_TanhToF2F : std_logic;
    signal pixelOut_TanhToF2F : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    signal float_size : float32;
    
begin

    FloatToFixed : process(clk)
    begin
        if rising_edge(clk) then
            pixelIn_FloatToFixed <= to_sfixed(pixel_in, pixelIn_FloatToFixed);
            convEn_FloatToFixed <= conv_en;
            weightWe_FloatToFixed <= weight_we;
            weightData_FloatToFixed <= to_sfixed(weight_data, weightData_FloatToFixed);
        end if;
    end process;

	conv : convolution port map (
		clk				=> clk,
		reset			=> reset,
		conv_en 		=> convEn_FloatToFixed,
		layer_nr        => layer_nr,
		weight_we		=> weightWe_FloatToFixed,
		weight_data 	=> weightData_FloatToFixed,
		pixel_in 		=> pixelIn_FloatToFixed,
		output_valid	=> outputValid_convToBias,--dv_conv_to_buf_and_mux,
		conv_en_out		=> convEn_convToBias,
		pixel_out 		=> pixelOut_convToBias,--data_conv_to_buf_and_mux,
		bias    		=> bias
	
	);
	
	add_bias : process(clk)
	begin
	   if rising_edge(clk) then
	       
    --        pixel_out <= resize(bias + pixelOut_convToBias, pixel_biasToTanh);
    --        pixel_valid <= outputValid_convToBias;
	       pixel_biasToTanh <= resize(bias + pixelOut_convToBias, INT_WIDTH-1, -FRAC_WIDTH);
	       valid_biasToTanh <= outputValid_convToBias;
	   end if;
	end process;
	
    activation_function : tan_h port map (
	    clk => clk,
	    input_valid => valid_biasToTanh,
        x => pixel_biasToTanh(INT_WIDTH-1 downto -FRAC_WIDTH),
        output_valid => pixelValid_TanhToAvgPool,
        y => pixelOut_TanhToAvgPool
	);
	
	
	
	
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
	
	
	avg_pooler : average_pooler port map ( 
		clk 			=> clk,
        reset           => reset,
        conv_en			=> conv_en,
        weight_in       => bias,
        weight_we        => weightWe_FloatToFixed,
        input_valid		=> pixelValid_TanhToAvgPool,
        data_in         => pixelOut_TanhToAvgPool,
        data_out		=> pixelOut_AvgPoolToScaleFactor,
	  	output_valid 	=> pixelValid_AvgPoolToScaleFactor,
        output_weight   => weight_avgPoolToBias2
    );

    apply_scale_factor : process(clk)
    begin
        if rising_edge(clk) then
            pixelOut_ScaleFactorToBias2 <= resize(scale_factor*pixelOut_AvgPoolToScaleFactor, INT_WIDTH-1, -FRAC_WIDTH);
            pixelValid_ScaleFactorToBias2 <= pixelValid_AvgPoolToScaleFactor;
        end if;
    end process;
    
    
    add_bias_after_ap : process(clk)
    begin
       if rising_edge(clk) then
           pixelOut_Bias2ToTanh2 <= resize(bias2 + pixelOut_ScaleFactorToBias2, INT_WIDTH-1, -FRAC_WIDTH);
           pixelValid_Bias2ToTanh2 <= pixelValid_ScaleFactorToBias2;
       end if;
    end process;

    
    activation_function2 : tan_h port map (
	    clk => clk,
	    input_valid => pixelValid_Bias2ToTanh2,
        x => pixelOut_Bias2ToTanh2(INT_WIDTH-1 downto -FRAC_WIDTH),
        output_valid => pixelValid_TanhToF2F,
        y => pixelOut_TanhToF2F
	);

    FixedToFloat : process(clk)
    begin
        if rising_edge(clk) then
            pixel_valid <= pixelValid_TanhToF2F;
            pixel_out <= to_float(pixelOut_TanhToF2F, float_size);
        end if;
         
    end process;

    
    bias2_register : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias2 <= (others => '0');
            elsif weightWe_FloatToFixed = '1' then
                bias2 <= weight_avgPoolToBias2; 
           end if;
        end if;     
    end process;

    scale_factor_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                scale_factor <= (others => '0');
            elsif weightWe_FloatToFixed = '1' then
                scale_factor <= bias2;
            end if;
        end if;
    end process;

    dummy_bias <= bias;

end Behavioral;

