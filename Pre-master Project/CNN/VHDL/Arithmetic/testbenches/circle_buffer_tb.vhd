
		
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY circle_buffer_tb IS
END circle_buffer_tb;

ARCHITECTURE behavior OF circle_buffer_tb IS 

	COMPONENT circle_buffer
		Generic (
			constant MEM_SIZE_BIG 		: positive := 10;
			constant MEM_SIZE_SMALL 	: positive := 5;
			constant FRAC_WIDTH			: positive := 8;
			constant INT_WIDTH			: positive := 8
		);
		Port ( 
			clk     		: in std_logic;
			reset 		: in std_logic;
			we	 			: in std_logic; 
			conv_en		: in std_logic;
			first_layer : in std_logic;
			data_in  	: in  ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out 	: out ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
			final_pixel	: out std_logic
			
		);
	END COMPONENT;

	signal clk     		: std_logic;
	signal reset 			: std_logic;
	signal we	 			: std_logic; 
	signal conv_en			: std_logic;
	signal first_layer	: std_logic;
	signal data_in  		: ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
	signal data_out 		: ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
	signal final_pixel	: std_logic;

	constant clk_period : time := 1 ns;

BEGIN

	test_buffer: circle_buffer PORT MAP(
			clk     		=> clk,
			reset 		=> reset,
			we	 			=> we,
			conv_en		=> conv_en,
			first_layer => first_layer,
			data_in  	=> data_in,
			data_out 	=> data_out,
			final_pixel	=> final_pixel
	);

	clock : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process;

	create_input : process
	begin
		reset <= '1';
		wait for 10*clk_period;
		
		reset <= '0';
		we <= '1';
		conv_en <= '1';
		first_layer <= '1';
		
		for i in 1 to 10 loop
			data_in <= to_ufixed(i, data_in);
			wait for clk_period;
		end loop;
		
		for i in 1 to 10 loop
			data_in <= to_ufixed(i, data_in);
			wait for clk_period;
		end loop;
		
		
	end process;
	
	assert_output : process
	begin
		wait for clk_period*10;
		wait for clk_period;
		for i in 1 to 10 loop
			assert data_out = to_ufixed(i, INT_WIDTH-1, -FRAC_WIDTH);
				report "Expected: " & to_string (to_ufixed(i, INT_WIDTH-1, -FRAC_WIDTH)) &
					". Actual : " & to_string (data_out) & "."
				severity error;
			wait for clk_period;
		end loop;
	end process;

END;
