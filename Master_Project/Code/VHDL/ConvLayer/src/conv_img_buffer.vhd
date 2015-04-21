library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity conv_img_buffer is
	generic (
		IMG_SIZE	: Natural;
		INT_WIDTH 	: positive;
		FRAC_WIDTH 	: positive
	);
	Port ( 
		clk 				: in std_logic;
		input_valid			: in std_logic;
		conv_en_in			: in std_logic;
		pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		output_valid		: out std_logic;
		conv_en_out			: out std_logic;
		pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		
	);
end conv_img_buffer;

architecture Behavioral of conv_img_buffer is
	
	
	signal write_addr 		: Natural range 0 to IMG_SIZE-1;
	signal read_addr 			: Natural range 0 to IMG_SIZE-1;
	
	signal prev_valid 		: boolean;
	
	signal looped				: boolean;
	signal pixel_sum			: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal read_buffer		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal doutb 				: std_logic_vector(15 downto 0);
	signal addra 				: std_logic_vector(6 downto 0);
	signal addrb 				: std_logic_vector(6 downto 0);
	
	
	
begin

	addra <= std_logic_vector(to_unsigned(write_addr, 7));
	addrb <= std_logic_vector(to_unsigned(read_addr, 7));
	
	
	update_prev_valid : process(clk) 
	begin
		if rising_edge(clk) then
			if input_valid = '1' then
				prev_valid <= true;
			else
				prev_valid <= false;
			end if;
		end if;
	end process;
	
	
	update_output : process(clk) 
	begin
		if rising_edge(clk) then
			output_valid <= input_valid;
			pixel_out <= pixel_sum;
			conv_en_out <= conv_en_in;	
		end if;
	end process;
	
	update_read_buffer : process(clk)
	begin
		if rising_edge(clk) then
			if prev_valid then
				read_buffer <= to_ufixed(doutb, read_buffer);
			end if;
		end if;
	end process;
	
	update_index : process(clk)
	begin
		if rising_edge(clk) then
			if (conv_en_in = '0') then
				looped <= false;
				read_addr <= 1;
				write_addr <= 0;
			elsif (input_valid = '1') then
			
				if (write_addr = IMG_SIZE-1) then
					write_addr <= 0;
					looped <= true;
				else
					write_addr <= write_addr + 1;
				end if;
				
				if (read_addr = IMG_SIZE-1) then
					read_addr <= 0;
				else
					read_addr <= read_addr + 1;
				end if;
			end if;
		end if;
	end process;
	
	add_pixels : process(pixel_in, looped, doutb, read_buffer, prev_valid)
		variable pixel_sum_temp : ufixed(INT_WIDTH downto -FRAC_WIDTH);
	begin
		if looped then
			if prev_valid then
				pixel_sum_temp := to_ufixed(doutb, read_buffer) + pixel_in;
			else
				pixel_sum_temp := read_buffer + pixel_in;
			end if;
			
			if (pixel_sum_temp(INT_WIDTH)='0') then
				pixel_sum <= pixel_sum_temp(INT_WIDTH-1 downto -FRAC_WIDTH);
			else
				pixel_sum <= (others => '1');
			end if;
		else
			pixel_sum_temp := (others => '0');
			pixel_sum <= pixel_in;
		end if;
	end process;


end Behavioral;

