library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity max_pool is
	generic (
	    IMG_DIM : Natural := 8;
		POOL_DIM : Natural := 2;
		INT_WIDTH : Natural := 8;
		FRAC_WIDTH : Natural := 8
	);
	Port ( 
		clk : in std_logic;
        conv_en : in std_logic;
		input_valid : in std_logic;
		data_in : in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		data_out : out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		output_valid : out std_logic
		
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

    constant POOL_ARRAY_DIM : Natural := IMG_DIM/POOL_DIM;
	type states is (find_max, end_of_row,wait_for_new_row, finished); 
	type ufixed_array is array(POOL_ARRAY_DIM-2 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal buffer_values : ufixed_array;
	signal reset_buffers : std_logic;
	signal write_buffers : std_logic;
	signal current_state : states;
	signal current_max	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);

	--signal pool_y : Natural range 0 to POOL_ARRAY_DIM-1 := 0;
	signal pool_x : Natural range 0 to POOL_ARRAY_DIM-1 := 0;
	
begin

	data_out <= current_max;

	generate_buffers : for i in 0 to POOL_ARRAY_DIM-2 generate
	begin
		first_buffer : if i = 0 generate
		begin
			uf_buffer : ufixed_buffer port map (
				clk => clk,
				reset => reset_buffers,
				we => write_buffers,
				data_in => current_max,
				data_out => buffer_values(i)
			);
		end generate;
		
		other_buffers : if i > 0 generate
		begin
			uf_buffer : ufixed_buffer port map (
				clk => clk,
				reset => reset_buffers,
				we => write_buffers,
				data_in => buffer_values(i-1),
				data_out => buffer_values(i)
			);
		end generate;
	end generate;
	
    controller : process(clk)
	   variable x : integer;
	   variable y : integer;
	begin
        if rising_edge(clk) then
            if conv_en = '0' then
                output_valid <= '0';
                reset_buffers <= '0';
                write_buffers <= '0';
                x := 0;
                y := 0;
                pool_x <= 0;
            elsif input_valid = '1' then
                if x = POOL_DIM-1 and y = POOL_DIM-1 then
                    if pool_x = POOL_ARRAY_DIM-1 then
                        output_valid <= '1';
                        reset_buffers <= '0';
                        write_buffers <= '0';
                        x := 0;
                        y := 0;
                        pool_x <= 0;
                    else
                        output_valid <= '1';
                        reset_buffers <= '1';
                        write_buffers <= '1';
                        x := 0;
                        pool_x <= pool_x + 1; 
                    end if;
                elsif x = POOL_DIM-1 then
                    output_valid <= '0';
                    x := 0;
                    write_buffers <= '1';
                    reset_buffers <= '1';
                    if pool_x = POOL_ARRAY_DIM-1 then 
                        y := y + 1;
                        pool_x <= 0;
                    else
                        pool_x <= pool_x + 1;
                    end if;
                else
                    x := x + 1;
                    output_valid <= '0';
                    reset_buffers <= '1';
                    write_buffers <= '0';                        
                end if;
            else
                output_valid <= '0';
                reset_buffers <= '1';
                write_buffers <= '0';
            end if;
	   end if;
	end process;
	
	update_max : process(clk)
	begin
        if rising_edge(clk) then
            if conv_en = '0' or reset_buffers = '0' then
                current_max <= (others => '0');
            elsif input_valid = '1' then
                if write_buffers = '1' then
                    if pool_x = 0 then
                        current_max <= buffer_values(POOL_ARRAY_DIM-2);                    
                    else
                        if data_in > buffer_values(POOL_ARRAY_DIM-2) then
                            current_max <= data_in; 
                        else
                            current_max <= buffer_values(POOL_ARRAY_DIM-2);
                        end if;
                    end if;
                elsif data_in > current_max then
                    current_max <= data_in;
                end if;
             elsif write_buffers = '1' then
                current_max <= buffer_values(POOL_ARRAY_DIM-2);
             end if;
        end if;
	end process;

end Behavioral;

