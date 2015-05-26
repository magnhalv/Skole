library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

ENTITY conv_interface_tb IS
  generic (
      C_S_AXI_DATA_WIDTH : Natural := 32;
      IMG_DIM         : Natural := 6;
      KERNEL_DIM 		: Natural := 3;
      POOL_DIM 	    : Natural := 2;
      INT_WIDTH       : Natural := 16;
      FRAC_WIDTH 		: Natural := 16
  );
END conv_interface_tb;

ARCHITECTURE behavior OF conv_interface_tb IS

    component conv_layer_interface is
        generic (
            C_S_AXI_DATA_WIDTH  : Natural := C_S_AXI_DATA_WIDTH;
            IMG_DIM             : Natural := IMG_DIM;
            KERNEL_DIM          : Natural := KERNEL_DIM;
            POOL_DIM            : Natural := POOL_DIM;
            INT_WIDTH           : Natural := INT_WIDTH;
            FRAC_WIDTH          : Natural := FRAC_WIDTH
        ); 
        Port (
            
            clk             : in std_logic;
            reset           : in std_logic; -- NOTE: Is active low.
            -- Interface for controlling module
            s_axi_raddr     : in std_logic_vector(2 downto 0);
            s_axi_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_wdata     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_waddr     : in std_logic_vector(2 downto 0);
            s_axi_we        : in std_logic;
            
            -- Interface for streaming data in
            s_axis_tvalid   : in std_logic;
            s_axis_tready   : out std_logic;
            s_axis_tdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axis_tkeep    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            s_axis_tlast    : in std_logic;

            -- Interface for streaming data out
            m_axis_tvalid   : out std_logic;
            m_axis_tready   : in std_logic;
            m_axis_tdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            m_axis_tkeep    : out std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            m_axis_tlast    : out std_logic
        );
    end component;

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0'; -- NOTE: Is active low.
    -- Interface for controlling module
    signal s_axi_raddr     : std_logic_vector(2 downto  0) := (others => '0');
    signal s_axi_rdata     : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto  0) := (others => '0');
    signal s_axi_wdata     : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto  0) := (others => '0');
    signal s_axi_waddr     : std_logic_vector(2 downto  0) := (others => '0');
    signal s_axi_we        : std_logic := '0';
   
    -- Interface for streaming data in
    signal s_axis_tvalid   : std_logic := '0';
    signal s_axis_tready   : std_logic := '0';
    signal s_axis_tdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto  0) := (others => '0');
    signal s_axis_tkeep    : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto  0) := (others => '0');
    signal s_axis_tlast    : std_logic := '0';

    -- Interface for streaming data out
    signal m_axis_tvalid   : std_logic := '0';
    signal m_axis_tready   : std_logic := '0';
    signal m_axis_tdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto  0) := (others => '0');
    signal m_axis_tkeep    : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto  0) := (others => '0');
    signal m_axis_tlast    : std_logic := '0';

    constant  one : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
    constant  two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(2, INT_WIDTH-1, -FRAC_WIDTH);
    constant  three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(3, INT_WIDTH-1, -FRAC_WIDTH);
    constant  four : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(4, INT_WIDTH-1, -FRAC_WIDTH);
    constant  five : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(5, INT_WIDTH-1, -FRAC_WIDTH);
    
    
    constant clk_period : time := 1 ns;

    constant fifo_array_size : integer := (KERNEL_DIM*KERNEL_DIM)+(IMG_DIM*IMG_DIM)+3;
    type fifo_array is array (fifo_array_size downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    constant fifo : fifo_array := (

        three, three, three, three, three, three, --5
        three, three, three, three, three, three, --4
        three, three, three, three, three, three, --3
        three, three, three, three, three, three, --2
        three, three, three, three, three, three, --1
        three, three, three, three, three, three, --0

        two, two, two,
        two, two, two,
        two, two, two,
        one, one, one, one -- bias1, avg, bias2, scale factor
    );
    
begin

    interface : conv_layer_interface port map (
            
        clk => clk,              
        reset => reset,     
        -- Interface for
        s_axi_raddr => s_axi_raddr, 
        s_axi_rdata => s_axi_rdata,
        s_axi_wdata => s_axi_wdata,
        s_axi_waddr => s_axi_waddr,
        s_axi_we => s_axi_we,
        -- Interface for streaming data in
        s_axis_tvalid => s_axis_tvalid,
        s_axis_tready => s_axis_tready,
        s_axis_tdata => s_axis_tdata,
        s_axis_tkeep => s_axis_tkeep,
        s_axis_tlast => s_axis_tlast,

        -- Interface for streaming data out
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tready => m_axis_tready,
        m_axis_tdata => m_axis_tdata,
        m_axis_tkeep => m_axis_tkeep,
        m_axis_tlast => m_axis_tlast
    );
    
    m_axis_tready <= '1';
    
    clock : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    fifo_mock : process(clk)
        variable index : integer := 0;
    begin
        s_axis_tdata <= to_slv(fifo(index));
        if reset = '0' then
            index := 0;
            s_axis_tvalid <= '1';
        elsif rising_edge(clk) then
            if index = fifo_array_size then
                s_axis_tvalid <= '0';
            elsif s_axis_tready = '1' then
                index := index + 1;
            end if;
        end if;
    end process;
    
    create_input : process
    begin
        reset <= '0';
        wait for clk_period*10;
        reset <= '1';
        s_axi_we <= '1'; 
        s_axi_waddr <= "001";
        s_axi_wdata <= (0 => '1', others => '0');
        wait for clk_period;
        s_axi_waddr <= "010";
        s_axi_wdata <= (0 => '1', others => '0');
        wait for clk_period*1;
        s_axi_waddr <= "000";
        s_axi_wdata <= (others => '0');
        wait for clk_period;
        s_axi_we <= '0';
        wait for clk_period;

        wait;
    end process;
    
end behavior;
