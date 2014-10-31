	library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity conv_controller is
	generic (	
		IMAGE_DIM 	: integer := 32;
		KERNEL_DIM 	: integer := 5
	);
	port (
		clk 				: in  std_logic;
		conv_en 			: in  std_logic;
		output_valid 	: out std_logic;
		final_pixel		: out std_logic
	);
end conv_controller;

architecture Behavioral of conv_controller is

	signal nof_cycles 				: integer := 0;
	signal output_valid_buf			: std_logic;
	constant CYCLES_BEFORE_VALID 	: integer := (IMAGE_DIM*(KERNEL_DIM-1)) + KERNEL_DIM - 1;
	constant TOTAL_NOF_CYCLES		: integer := (IMAGE_DIM*IMAGE_DIM)+1;
	constant INVALID_INTERVAL		: integer := KERNEL_DIM-1;

begin
	count_pixels : process (clk)
	begin
		if rising_edge(clk) then
			if conv_en = '1' then
				nof_cycles <= nof_cycles + 1;
			else
				nof_cycles <= 0;
			end if;
		end if;
	end process;
	
	is_output_valid : process(clk)
	begin
		if rising_edge(clk) then
			if nof_cycles > CYCLES_BEFORE_VALID 	
				and nof_cycles < TOTAL_NOF_CYCLES 
				and ((nof_cycles mod IMAGE_DIM) > INVALID_INTERVAL 
						or (nof_cycles mod IMAGE_DIM) = 0) 
				then
				output_valid_buf <= '1';
			else 
				output_valid_buf <= '0';
			end if;
		end if;
	end process;
	
	output_valid <= output_valid_buf;
	final_pixel <= (output_valid_buf) and (not conv_en); 

end Behavioral;

