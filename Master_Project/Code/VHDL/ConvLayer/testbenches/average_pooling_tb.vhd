LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY average_pooler_tb IS
	generic (
        IMG_DIM : Natural := 6;
        POOL_DIM : Natural:= 2;
        INT_WIDTH : Natural := 16;
        FRAC_WIDTH : Natural := 16
	);
END average_pooler_tb;
 
ARCHITECTURE behavior OF average_pooler_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
    component average_pooler is
        generic (
            IMG_DIM : Natural := IMG_DIM;
            POOL_DIM : Natural := POOL_DIM;
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
        );
        Port ( 
            clk : in std_logic;
            conv_en : in std_logic;
            weight_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            weight_we : in std_logic;
            input_valid : in std_logic;
            data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            output_valid : out std_logic

        );
    end component;


    --Inputs
    signal clk : std_logic := '0';
    signal conv_en : std_logic := '0';
    signal weight_in : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    signal weight_we : std_logic := '0';
    signal input_valid : std_logic := '0';
    signal data_in : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    
    --Outputs
    signal data_out : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal output_valid : std_logic;
    
   -- Clock period definitions
    constant clk_period : time := 1 ns;
    
    constant zero : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0, INT_WIDTH-1, -FRAC_WIDTH);
    constant one : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
    constant two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(2, INT_WIDTH-1, -FRAC_WIDTH);
    constant three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(3, INT_WIDTH-1, -FRAC_WIDTH); 
    constant four : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(4, INT_WIDTH-1, -FRAC_WIDTH);
    constant five : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(5, INT_WIDTH-1, -FRAC_WIDTH);
	
	type sfixed_2d_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type sfixed_pooled_array is array ((IMG_DIM/2)*(IMG_DIM/2)-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
    signal weight : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0.25, INT_WIDTH-1, -FRAC_WIDTH);
	signal input_array : sfixed_2d_array := (
	   one, one,     two, two,     three, three,
       one, one,     two, two,     three, three,
	   
	   four, four,   five, five,     one, two,
	   four, four,   five, five,     three, two,
	   
	   three, two,     one, one,     two, four,
	   three, four,    five, one,    five, five
	);
	
	signal expected : sfixed_pooled_array := (
	   one, two, three,
	   four, five, two,
	   three, two, four
	);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   avg_pooler : average_pooler PORT MAP (
          clk => clk,
          conv_en => conv_en,
          weight_in => weight_in,
          weight_we => weight_we,
          input_valid => input_valid,
          data_in => data_in,
          data_out => data_out,
          output_valid => output_valid
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
    input: process
    begin		
        wait for 10*clk_period;

        weight_we <= '1';
        weight_in <= weight;
        wait for clk_period;
        
        weight_we <= '0';
        conv_en <= '1';

        for i in 0 to IMG_DIM-1 loop
            input_valid <= '1';
            for j in 0 to IMG_DIM-1 loop
                data_in <= input_array(((IMG_DIM*IMG_DIM)-1)-((i*(IMG_DIM))+j));
                wait for clk_period;        
            end loop;
            input_valid <= '0';
            wait for 5*clk_period;
        end loop;
        
        conv_en <= '0';
        input_valid <= '0';
        
        wait;
    end process;

	assert_result : process(clk)
	   variable index : integer := 0;
	   variable nof_cycles : integer := 0;
	begin
	   if rising_edge(clk) then
	       nof_cycles := nof_cycles + 1;
	       if output_valid = '1' and index < 9 then
	           assert data_out = expected((IMG_DIM/2)*(IMG_DIM/2)-1-index)
                   report "Test " & Natural'image(index) & ". Data out was "
                   & to_string(data_out) & ". Expected " &
                   to_string(expected((IMG_DIM/POOL_DIM)*(IMG_DIM/POOL_DIM)-1-index))
                   severity error;
               index := index + 1;
	       elsif nof_cycles = 200 then
	           if index /= 9 then
	               assert 1 = 0
	                   report "Too many or too few outputs"
	                   severity error;
               end if;
	       end if;
	   end if;
	end process;

END;
