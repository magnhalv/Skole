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
        final_set   : in std_logic;
		layer_nr	: in Natural;
		weight_we	: in std_logic;
		weight_data	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_valid	: out std_logic;
		pixel_out 	: out std_logic_vector(INT_WIDTH+FRAC_WIDTH-1 downto 0);
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
			layer_nr        : in natural;
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
            KERNEL_DIM : Natural := KERNEL_DIM;
            POOL_DIM : Natural := POOL_DIM;
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
            );
        Port ( 
            clk : in std_logic;
            reset : in std_logic;
            conv_en : in std_logic;
            layer_nr : in natural;
            weight_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            weight_we : in std_logic;
            input_valid : in std_logic;
            data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            output_valid : out std_logic;
            output_weight : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
            
        );
	end component;
	
	component sfixed_fifo is
		generic (
			INT_WIDTH 	: Natural := INT_WIDTH;
			FRAC_WIDTH 	: Natural := FRAC_WIDTH;
            FIFO_DEPTH : Natural := (((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)*(((IMG_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)
		);
		Port ( 
            clk		 : in  std_logic;
            reset	 : in  std_logic;
            write_en : in  std_logic;
            layer_nr    : in  Natural;
            data_in	 : in  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)			
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
	


	signal bias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal bias2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal weight_avgPoolToBias2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal scale_factor : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
	signal convEn_convToMux : std_logic;
	signal outputValid_convToMux : std_logic;
    signal pixelOut_convToMux : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    signal pixel_BufToMux : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal buffer_we      : std_logic;
    
    signal pixel_MuxToBias : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal valid_MuxToBias : std_logic;

    signal pixel_MuxToF2F : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal pixelValid_MuxToF2F : std_logic;
    
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

    signal pixelValid_Tanh2ToOut : std_logic;
    signal pixelOut_Tanh2ToOut : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    signal pixelValid_F2FToOut : std_logic;
    signal pixelOut_F2FToOut : float32;

    signal float_size : float32;

    signal is_layer_1 : std_logic;
begin

	conv : convolution port map (
		clk				=> clk,
		reset			=> reset,
		conv_en 		=> conv_en,
		layer_nr        => layer_nr,
		weight_we		=> weight_we,
		weight_data 	=> weight_data,
		pixel_in 		=> pixel_in,
		output_valid	=> outputValid_convToMux,--dv_conv_to_buf_and_mux,
		conv_en_out		=> convEn_convToMux,
		pixel_out 		=> pixelOut_convToMux,--data_conv_to_buf_and_mux,
		bias    		=> bias
	
	);

    is_layer_1_process : process (layer_nr)
    begin
        if layer_nr = 1 or layer_nr = 2 then
            is_layer_1 <= '1';
        else
            is_layer_1 <= '0';
        end if;
    end process;
    
    buffer_we <= is_layer_1 and outputValid_convToMux;
    
    intermediate_buffer : sfixed_fifo port map (
        clk => clk,
        reset => reset,
        write_en => buffer_we,
        layer_nr => layer_nr,
        data_in => pixelOut_convToMux,
        data_out => pixel_bufToMux
    );

    mux : process(clk)
    begin
        if rising_edge(clk) then
            if layer_nr = 0 then
                pixel_MuxToBias <= pixelOut_convToMux;
                valid_MuxToBias <= outputValid_convToMux;
            elsif layer_nr = 1 or layer_nr = 2 then
                if final_set = '1' then
                    pixel_MuxToBias <= resize(pixelOut_convToMux + pixel_bufToMux, INT_WIDTH-1, -FRAC_WIDTH);
                    valid_MuxToBias <= outputValid_convToMux;
                else
                    pixel_MuxToBias <= (others => '0');
                    valid_MuxToBias <= '0';
                end if;
            end if;
        end if;

    end process;
	
	add_bias : process(clk)
	begin
	   if rising_edge(clk) then
	       pixel_biasToTanh <= resize(bias + pixel_MuxToBias, INT_WIDTH-1, -FRAC_WIDTH);
	       valid_biasToTanh <= valid_MuxToBias;
	   end if;
	end process;
	
    activation_function : tan_h port map (
	    clk => clk,
	    input_valid => valid_biasToTanh,
        x => pixel_biasToTanh(INT_WIDTH-1 downto -FRAC_WIDTH),
        output_valid => pixelValid_TanhToAvgPool,
        y => pixelOut_TanhToAvgPool
	);
	
	avg_pooler : average_pooler port map ( 
		clk 			=> clk,
        reset           => reset,
        conv_en			=> conv_en,
        layer_nr        => layer_nr,
        weight_in       => bias,
        weight_we       => weight_we,
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
        output_valid => pixelValid_Tanh2ToOut,
        y => pixelOut_Tanh2ToOut
	);

    FixedToFloat : process (clk)
    begin
        if rising_edge(clk) then
            pixelOut_F2FToOut <= to_float(pixelOut_TanhToAvgPool);
            pixelValid_F2FToOut <= pixelValid_TanhToAvgPool;
        end if;
    end process;

    OutputProcess : process(clk)
    begin
        if rising_edge(clk) then
            if layer_nr = 0 then
                pixel_out <= to_slv(pixelOut_Tanh2ToOut);
                pixel_valid <= pixelValid_Tanh2ToOut;
            elsif layer_nr = 1 then
                pixel_out <= to_slv(pixelOut_Tanh2ToOut); 
                pixel_valid <= pixelValid_Tanh2ToOut and (final_set);
            else
                pixel_out <= to_slv(pixelOut_F2FToOut);
                pixel_valid <= pixelValid_F2FToOut;
            end if;
        end if;
    end process;
    
    bias2_register : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias2 <= (others => '0');
            elsif weight_we = '1' then
                bias2 <= weight_avgPoolToBias2; 
           end if;
        end if;     
    end process;

    scale_factor_reg : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                scale_factor <= (others => '0');
            elsif weight_we = '1' then
                scale_factor <= bias2;
            end if;
        end if;
    end process;
	

end Behavioral;

