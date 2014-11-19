library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity convolution is
	generic 	(
		IMAGE_DIM	: integer := 5;
		KERNEL_DIM 	: integer := 3;
		INT_WIDTH	: integer := 8;
		FRAC_WIDTH	: integer := 8
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
end convolution;

architecture Behavioral of convolution is

	component mac
		port (
			clk 			: in std_logic;
			reset			: in std_logic;
			weight_we 	: in std_logic;
			weight_in	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			multi_value	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			acc_value 	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			weight_out	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			result 		: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	component ufixed_buffer is
		generic (
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
		);
		Port ( 
			clk 		: in std_logic;
			reset		: in std_logic;
			we 		: in std_logic;
			data_in 	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out : out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;

	
	component conv_controller
		generic (	
			IMAGE_DIM 	: integer := IMAGE_DIM;
			KERNEL_DIM 	: integer := KERNEL_DIM
		);
		port (
			clk 					: in  std_logic;
			conv_en			 	: in  std_logic;
			output_valid 		: out  std_logic
		);
	end component;
	
	type ufixed_acc_array is array (KERNEL_DIM - 1 downto 0, KERNEL_DIM downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type ufixed_weight_array is array (KERNEL_DIM - 1 downto 0, KERNEL_DIM-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type ufixed_shift_reg_array is array (KERNEL_DIM - 2 downto 0, IMAGE_DIM-KERNEL_DIM-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	
	signal acc_value 			: ufixed_acc_array;
	signal weight_values 	: ufixed_weight_array;
	signal shift_reg_values : ufixed_shift_reg_array;
	signal final_result 		: ufixed(INT_WIDTH downto -FRAC_WIDTH);
	signal bias					: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
		
	
	
begin

	controller : conv_controller port map (
		clk => clk,
		conv_en => conv_en_in,
		output_valid => output_valid
	);
	
	gen_mac_rows: for i in 0 to KERNEL_DIM-1 generate
		gen_mac_columns: for j in 0 to KERNEL_DIM-1 generate
		begin
			mac_first_leftmost : if j = 0 and i = 0 generate
			begin
				mac_f_lm : mac port map (
					clk => clk,
					reset => reset,
					weight_we => weight_we,
					weight_in => weight_data,
					multi_value => pixel_in,
					acc_value => acc_value(i, j),
					weight_out => weight_values(i,j),
					result => acc_value(i,j+1)
				);
			end generate;
			
			mac_other_leftmost : if j = 0 and i > 0 generate
			begin
				mac_o_lm : mac port map (
					clk => clk,
					reset => reset,
					weight_we => weight_we,
					weight_in => weight_values(i-1,KERNEL_DIM-1),
					multi_value => pixel_in,
					acc_value => acc_value(i, j),
					weight_out => weight_values(i, j),
					result => acc_value(i,j+1)
				);
			end generate;
			
			mac_others : if j > 0 and j < KERNEL_DIM-1 generate
			begin
				mac_o : mac port map (
					clk => clk,
					reset => reset,
					weight_we => weight_we,
					weight_in => weight_values(i, j-1),
					multi_value => pixel_in,
					acc_value => acc_value(i,j),
					weight_out => weight_values(i, j),
					result => acc_value(i,j+1)
				);
			end generate;
			
			mac_rightmost : if j = KERNEL_DIM-1 generate
			begin
				mac_rm : mac port map (
					clk => clk,
					reset => reset,
					weight_we => weight_we,
					weight_in => weight_values(i, j-1),
					multi_value => pixel_in,
					acc_value => acc_value(i,j),
					weight_out => weight_values(i, j),
					result => acc_value(i,j+1)
				);
			end generate;
			
--			gen_fifo : if i < KERNEL_DIM-1 and j = KERNEL_DIM-1 generate
--			begin
--				fifox : fifo port map (
--						clk => clk,
--						conv_en_in => conv_en_in,
--						data_in => acc_value(i,KERNEL_DIM),                                       
--						data_out => acc_value(i+1, 0)
--				);
--			end generate;
			
			gen_shift_regs : if i < KERNEL_DIM-1 and j = KERNEL_DIM-1 generate
				gen_regs_loop : for x in 0 to IMAGE_DIM-KERNEL_DIM-1 generate
				begin
					first_reg : if x = 0 generate
					begin
						shift_reg : ufixed_buffer port map (
							clk 		=> clk,
							reset		=> reset,
							we 		=> conv_en_in,
							data_in 	=> acc_value(i, KERNEL_DIM),
							data_out => shift_reg_values(i, 0)
						);
					end generate;
					
					last_reg : if x = IMAGE_DIM-KERNEL_DIM-1 generate
					begin
						shift_reg : ufixed_buffer port map (
							clk 		=> clk,
							reset		=> reset,
							we 		=> conv_en_in,
							data_in 	=> shift_reg_values(i, x-1),
							data_out => acc_value(i+1, 0)
						);
					end generate;
					
					
					other_reg : if x > 0 and x < IMAGE_DIM-KERNEL_DIM-1 generate
					begin
						shift_reg : ufixed_buffer port map (
							clk 		=> clk,
							reset		=> reset,
							we 		=> conv_en_in,
							data_in 	=> shift_reg_values(i, x-1),
							data_out => shift_reg_values(i, x)
						);
					end generate;
				end generate;
			end generate;
			
		end generate;
	end generate;
	
	bias_register : process(clk)
	begin
		if rising_edge(clk) then
			if (weight_we = '1') then
				bias <= weight_values(KERNEL_DIM-1, KERNEL_DIM-1);
			end if;
		end if;
	end process;
	
	conv_register : process(clk)
	begin
		if rising_edge(clk) then
			conv_en_out <= conv_en_in;
		end if;
	end process;
	
	bias_out <= bias;
	acc_value(0, 0) <= (others => '0');
	pixel_out <= acc_value(KERNEL_DIM-1,KERNEL_DIM);
	

end Behavioral;

