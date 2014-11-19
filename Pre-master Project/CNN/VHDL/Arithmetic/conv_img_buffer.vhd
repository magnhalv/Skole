library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity conv_img_buffer is
	generic (
		IMG_SIZE		: integer := 4;
		INT_WIDTH 	: positive := 8;
		FRAC_WIDTH 	: positive := 8
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
end conv_img_buffer;

architecture Behavioral of conv_img_buffer is
	
	component dual_block_mem
		port (
			clka		: in std_logic;
			wea		: in std_logic_vector(0 downto 0);
			addra		: in std_logic_vector(6 downto 0);
			dina		: in std_logic_vector(15 downto 0);
			clkb		: in std_logic;
			addrb		: in std_logic_vector(6 downto 0);
			doutb		: out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal write_addr 		: integer range 0 to IMG_SIZE-1;
	signal write_addr_buf 		: integer range 0 to IMG_SIZE-1;
	signal read_addr 			: integer range 0 to IMG_SIZE-1;
	
	
	signal looped				: boolean;
	signal pixel_sum			: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal pixel_sum_buf		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal input_valid_buf	: std_logic_vector(0 downto 0);
	
	signal doutb_buffer		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal doutb 				: std_logic_vector(15 downto 0);
	signal addra 				: std_logic_vector(6 downto 0);
	signal addrb 				: std_logic_vector(6 downto 0);
	
begin

	addra <= std_logic_vector(to_unsigned(write_addr_buf, 7));
	addrb <= std_logic_vector(to_unsigned(read_addr, 7));
	
	img_buffer : dual_block_mem port map(
		clka 	=> clk,
		wea 	=> input_valid_buf,
		addra	=> addra,
		dina 	=> to_slv(pixel_sum_buf),
		clkb 	=> clk,
		addrb => addrb,
		doutb => doutb
		
	);
	
	pixel_out <= pixel_sum_buf;
	output_valid <= input_valid_buf(0);
	
	write_buffer : process(clk)
	begin
		if rising_edge(clk) then
			pixel_sum_buf <= pixel_sum;
			input_valid_buf(0) <= input_valid;
			conv_en_out <= conv_en_in;
			write_addr_buf <= write_addr;
		end if;
	end process;
	
	read_buffer : process(clk)
	begin
		if rising_edge(clk) then
			doutb_buffer <= to_ufixed(doutb, doutb_buffer);
		end if;
	end process;
	
	update_index : process(clk)
		variable one_cycle_delayed : boolean;
	begin
		if rising_edge(clk) then
			if (conv_en_in = '0' and input_valid='0') then
				looped <= false;
				read_addr <= 1;
				write_addr <= 0;
				one_cycle_delayed := false;
			elsif (input_valid = '1') then
			
				if not one_cycle_delayed then
					one_cycle_delayed := true;
				elsif (write_addr = IMG_SIZE-1) then
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
	
	add_pixels : process(pixel_in, looped, doutb, doutb_buffer)
		variable pixel_sum_temp : ufixed(INT_WIDTH downto -FRAC_WIDTH);
	begin
		if looped then
			pixel_sum_temp := doutb_buffer + pixel_in;
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

