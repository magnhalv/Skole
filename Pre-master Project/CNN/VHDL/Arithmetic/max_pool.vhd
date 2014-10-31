library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity max_pool is
	generic (
		pool_dim : positive := 2
	);
	Port ( 
		clk 				: in std_logic;
      conv_en			: in std_logic;
		input_valid		: in std_logic;
		buff_data_in	: in ufixed(7 downto -8);
		conv_pixel_in	: in ufixed(7 downto -8);
		buff_data_out	: out ufixed(7 downto -8);
		max_value		: out ufixed(7 downto -8);
		output_valid 	: out std_logic
		
	);
end max_pool;

architecture Behavioral of max_pool is

	type states is (find_max, circulate_buffer_and_find_max, circulate_buffer, do_nothing, finished); 
	signal current_state : states;
	signal current_max	: ufixed(7 downto -8);
	signal max_pool_en 	: boolean; 
begin

	change_state : process(clk)
		variable interval_y : integer range 0 to pool_dim := 0;
		variable interval_x : integer range 0 to pool_dim := 0;
	begin
		if rising_edge(clk) then
			case current_state is
			
				when find_max =>
					if (conv_en = '0' and valid_input = '0') then
						current_state <= finished;
					elsif (conv_en ='1' and valid_input ='0') then
						current_state <= circulate_buffer;
					elsif interval_x = kernel_dim then
						current_state <= circulate_buffer_and_find_max;
					end if;
					
				when circulate_buffer_and_find_max =>
					current_state <= find_max;
					
				when circulate_buffer =>
					if(valid_input ='1') then
						current_state <= find_max;
					else
						current_state <= do_nothing;
					end if;
					
				when do_nothing =>
					if (valid_input = '1') then
						current_state <= find_max;
					end if;
					
				when finished =>
					if (conv_en = '1' and valid_input = '1') then
						current_state <= find_max;
					end if;
				
			end case;	
		end if;
	end process;
	
	data_out <= current_max;

end Behavioral;

