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
		conv_en				: in std_logic;
		weight_we			: in std_logic;
		weight_data 		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
      output_valid		: out std_logic; 
		pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
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
	
	component fifo
		Generic (
			constant FIFO_DEPTH 	: positive := IMAGE_DIM-KERNEL_DIM;
			constant FRAC_WIDTH	: positive := FRAC_WIDTH;
			constant INT_WIDTH	: positive := INT_WIDTH
		);
		Port ( 
			clk     	: in  STD_LOGIC;                                       
			conv_en 	: in  STD_LOGIC;                                       
			data_in 	: in  ufixed (INT_WIDTH - 1 downto -FRAC_WIDTH);      
			data_out : out ufixed (INT_WIDTH - 1 downto -FRAC_WIDTH)     
		);
	end component;
	
	component conv_controller
		generic (	
			IMAGE_DIM 	: integer := IMAGE_DIM;
			KERNEL_DIM 	: integer := KERNEL_DIM
		);
		port (
			clk 					: in  std_logic;
			conv_en		 		: in  std_logic;
			output_valid 		: out  std_logic
		);
	end component;
	
	type ufixed_acc_array is array (KERNEL_DIM - 1 downto 0, KERNEL_DIM downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type ufixed_weight_array is array (KERNEL_DIM - 1 downto 0, KERNEL_DIM-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal acc_value 		: ufixed_acc_array;
	signal weight_values : ufixed_weight_array;
	signal final_result 	: ufixed(INT_WIDTH downto -FRAC_WIDTH);
	signal bias				: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
		
	
	
begin

	controller : conv_controller port map (
		clk => clk,
		conv_en => conv_en,
		output_valid => output_valid
	);
	
	gen_mac_rows: for i in 0 to KERNEL_DIM-1 generate
		gen_mac_columns: for j in 0 to KERNEL_DIM-1 generate
		begin
			mac_first_leftmost : if j = 0 and i = 0 generate
			begin
				maci : mac port map (
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
				macx : mac port map (
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
				macx : mac port map (
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
				macx : mac port map (
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
			
			gen_fifo : if i < KERNEL_DIM-1 and j = KERNEL_DIM-1 generate
			begin
				fifox : fifo port map (
						clk => clk,
						conv_en => conv_en,
						data_in => acc_value(i,KERNEL_DIM),                                       
						data_out => acc_value(i+1, 0)
				);
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
	
	acc_value(0, 0) <= (others => '0');
	final_result <= acc_value(KERNEL_DIM-1,KERNEL_DIM)+bias;
	pixel_out <= (others => '1') when final_result(8) = '1' else final_result(INT_WIDTH-1 downto -FRAC_WIDTH);
	

end Behavioral;

