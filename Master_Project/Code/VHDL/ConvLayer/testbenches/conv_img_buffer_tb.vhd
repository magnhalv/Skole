library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_img_buffer_tb IS
	generic (
		IMG_SIZE		: Natural := 4;
		INT_WIDTH 	: positive := 8;
		FRAC_WIDTH 	: positive := 8
	);
END conv_img_buffer_tb;

ARCHITECTURE behavior OF conv_img_buffer_tb IS 

  -- Component Declaration
	component conv_img_buffer is
		generic (
			IMG_SIZE		: Natural := IMG_SIZE;
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
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
	end component;
	
	signal clk 					: std_logic := '0';
	signal input_valid		: std_logic := '0';
	signal conv_en_in			: std_logic := '0';
	signal pixel_in 			: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal output_valid		: std_logic := '0';
	signal conv_en_out		: std_logic := '0';
	signal pixel_out 			: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	
	constant clk_period : time := 1 ns;

BEGIN

	img_buffer : conv_img_buffer port map (
		clk				=> clk,
		input_valid 	=> input_valid,	
		conv_en_in 		=> conv_en_in,
		pixel_in 		=> pixel_in,				
		output_valid	=> output_valid,
		conv_en_out		=> conv_en_out,
		pixel_out		=> pixel_out
	);


	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	create_input : PROCESS
	BEGIN
		wait for clk_period*10;
		conv_en_in <= '1';
		for i in 1 to 12 loop
			input_valid <= '1';
			pixel_in <= to_ufixed(i, pixel_in);
			wait for clk_period;
			if (i=4 or i = 8) then
				input_valid <= '0';
				wait for clk_period*5;
			end if;
		end loop;
		
		input_valid <= '0';
		conv_en_in <= '0';
	
		
		wait;
	end process;
	
	assert_output : process
	begin
		wait for clk_period*11;
		
		for i in 1 to 12 loop
			if i < 5 then
				assert pixel_out = to_ufixed(i, 7, -8)
					report "Test: " & Natural'image(i) & ". Pixel_out was: " & to_string(pixel_out) & ". Should be: " & to_string(to_ufixed(i, 7, -8)) & "."
					severity error;
			elsif i < 9 then
				assert pixel_out = to_ufixed(i+(i-4), 7, -8)
					report "Test: " & Natural'image(i) & ". Pixel_out was: " & to_string(pixel_out) & ". Should be: " & to_string(to_ufixed(i+(i-4), 7, -8)) & "."
					severity error;
				
			else
				assert pixel_out = to_ufixed(3*i-12, 7, -8)
					report "Test: " & Natural'image(i) & ". Pixel_out was: " & to_string(pixel_out) & ". Should be: " & to_string(to_ufixed(i+((i-8)*2)+4, 7, -8)) & "."
					severity error;
			end if;
			wait for clk_period;
			if (i = 4 or i=8) then
				wait for clk_period*5;
			end if;
		end loop;
		wait;
	end process;


END;
