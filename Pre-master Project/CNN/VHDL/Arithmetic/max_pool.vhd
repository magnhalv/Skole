library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity max_pool is
	generic (
		POOL_DIM 	: integer := 4;
		INT_WIDTH 	: integer := 8;
		FRAC_WIDTH 	: integer := 8
	);
	Port ( 
		clk 				: in std_logic;
      conv_en			: in std_logic;
		input_valid		: in std_logic;
		data_in			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		data_out			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		output_valid 	: out std_logic
		
	);
end max_pool;

architecture Behavioral of max_pool is

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

	type states is (find_max, end_of_row,wait_for_new_row, finished); 
	type ufixed_array is array(POOL_DIM-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal buffer_values : ufixed_array;
	signal reset_buffers : std_logic;
	signal write_buffers : std_logic;
	signal current_state : states;
	signal current_max	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal interval_y : integer range 0 to POOL_DIM := 0;
	signal interval_x : integer range 0 to POOL_DIM := 0;
	
begin

	data_out <= current_max;

	generate_buffers : for i in 0 to POOL_DIM-1 generate
	begin
		first_buffer : if i = 0 generate
		begin
			uf_buffer : ufixed_buffer port map (
				clk 		=> clk,
				reset 	=> reset_buffers,
				we 		=> write_buffers,
				data_in 	=> current_max,
				data_out => buffer_values(i)
			);
		end generate;
		
		other_buffers : if i > 0 generate
		begin
			uf_buffer : ufixed_buffer port map (
				clk 		=> clk,
				reset 	=> reset_buffers,
				we 		=> write_buffers,
				data_in 	=> buffer_values(i-1),
				data_out => buffer_values(i)
			);
		end generate;
	end generate;

	change_state : process(clk)
	begin
		if rising_edge(clk) then
			case current_state is
			
				when find_max =>
					if (input_valid = '0') then
						interval_x <= 1;
						current_state <= end_of_row;
					else
						if interval_x = POOL_DIM then
							interval_x <= 1;	
							if (data_in < buffer_values(POOL_DIM-2)) then
								current_max <= buffer_values(POOL_DIM-2);
							else
								current_max <= data_in;
							end if;
						else
							interval_x <= interval_x + 1;
							if (current_max < data_in) then
								current_max <= data_in;
							end if;
						end if;
					end if;
				
				when end_of_row =>
					if (interval_y = POOL_DIM) then
						interval_y <= 1;
					else
						interval_y <= interval_y + 1;
					end if;
					
					if (conv_en = '0') then
						current_state <= finished;
					elsif (input_valid = '1') then
						if (buffer_values(POOL_DIM-1) > data_in) then
							current_max <= buffer_values(POOL_DIM-1);
						else
							current_max <= data_in;
						end if;
						current_state <= find_max;
					else
						current_state <= wait_for_new_row;
					end if;
					
				when wait_for_new_row =>
					if (input_valid = '1') then
						if (buffer_values(POOL_DIM-1) > data_in) then
							current_max <= buffer_values(POOL_DIM-1);
						else
							current_max <= data_in;
						end if;
						current_state <= find_max;
					end if;
					
				when finished =>
					if (conv_en = '1' and input_valid = '1') then
						current_state <= find_max;
						interval_y <= 1;
						interval_x <= 1;
						current_max <= data_in;
					end if;
			end case;	
		end if;
	end process;
	
	state_operations : process(current_state, interval_x, interval_y) 
	begin
		case current_state is
			when find_max =>
				if (interval_y = POOL_DIM and interval_x = POOL_DIM) then
					output_valid <= '1';
					write_buffers <= '1';
					reset_buffers <= '0';
				elsif (interval_x = POOL_DIM) then
					output_valid <= '0';
					write_buffers <= '1';
					reset_buffers <= '0';
				else
					output_valid <= '0';
					write_buffers <= '0';
					reset_buffers <= '0';
				end if;
			when end_of_row =>
				if (interval_y = pool_dim) then
					output_valid <= '0';
					write_buffers <= '0';
					reset_buffers <= '1';
				else
					output_valid <= '0';
					write_buffers <= '0';
					reset_buffers <= '0';
				end if;
				
			when wait_for_new_row =>
				output_valid <= '0';
				write_buffers <= '0';
				reset_buffers <= '0';
			when finished =>
				write_buffers <= '0';
				output_valid <= '0';
				reset_buffers <= '1';
		end case;
	end process;
	

end Behavioral;

