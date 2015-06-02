library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

ENTITY conv_interface_layer1_dyn_tb IS
  generic (
      C_S_AXI_DATA_WIDTH : Natural := 32;
      IMG_DIM         : Natural := 32;
      KERNEL_DIM 		: Natural := 5;
      POOL_DIM 	    : Natural := 2;
      INT_WIDTH       : Natural := 16;
      FRAC_WIDTH 		: Natural := 16
  );
END conv_interface_layer1_dyn_tb;

ARCHITECTURE behavior OF conv_interface_layer1_dyn_tb IS

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

    constant zero : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    constant one : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
    constant two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(2, INT_WIDTH-1, -FRAC_WIDTH);
    constant three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(3, INT_WIDTH-1, -FRAC_WIDTH);
    constant four : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(4, INT_WIDTH-1, -FRAC_WIDTH);
    constant five : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(5, INT_WIDTH-1, -FRAC_WIDTH);
    
    signal sfix : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    constant clk_period : time := 1 ns;

    constant nof_sets : integer := 2;
    constant img_size_l2 : integer := ((IMG_DIM-KERNEL_DIM+1)/2)*((IMG_DIM-KERNEL_DIM+1)/2);
    constant fifo_array_size : integer := nof_sets*((KERNEL_DIM*KERNEL_DIM)+img_size_l2+4)-1;
    type fifo_array is array (fifo_array_size downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);

    constant fifo : fifo_array := (

        to_sfixed(196, sfix), to_sfixed(195, sfix), to_sfixed(194, sfix), to_sfixed(193, sfix), to_sfixed(192, sfix), to_sfixed(191, sfix), to_sfixed(190, sfix), to_sfixed(189, sfix), to_sfixed(188, sfix), to_sfixed(187, sfix), to_sfixed(186, sfix), to_sfixed(185, sfix), to_sfixed(184, sfix), to_sfixed(183, sfix), 
        to_sfixed(182, sfix), to_sfixed(181, sfix), to_sfixed(180, sfix), to_sfixed(179, sfix), to_sfixed(178, sfix), to_sfixed(177, sfix), to_sfixed(176, sfix), to_sfixed(175, sfix), to_sfixed(174, sfix), to_sfixed(173, sfix), to_sfixed(172, sfix), to_sfixed(171, sfix), to_sfixed(170, sfix), to_sfixed(169, sfix), 
        to_sfixed(168, sfix), to_sfixed(167, sfix), to_sfixed(166, sfix), to_sfixed(165, sfix), to_sfixed(164, sfix), to_sfixed(163, sfix), to_sfixed(162, sfix), to_sfixed(161, sfix), to_sfixed(160, sfix), to_sfixed(159, sfix), to_sfixed(158, sfix), to_sfixed(157, sfix), to_sfixed(156, sfix), to_sfixed(155, sfix), 
        to_sfixed(154, sfix), to_sfixed(153, sfix), to_sfixed(152, sfix), to_sfixed(151, sfix), to_sfixed(150, sfix), to_sfixed(149, sfix), to_sfixed(148, sfix), to_sfixed(147, sfix), to_sfixed(146, sfix), to_sfixed(145, sfix), to_sfixed(144, sfix), to_sfixed(143, sfix), to_sfixed(142, sfix), to_sfixed(141, sfix), 
        to_sfixed(140, sfix), to_sfixed(139, sfix), to_sfixed(138, sfix), to_sfixed(137, sfix), to_sfixed(136, sfix), to_sfixed(135, sfix), to_sfixed(134, sfix), to_sfixed(133, sfix), to_sfixed(132, sfix), to_sfixed(131, sfix), to_sfixed(130, sfix), to_sfixed(129, sfix), to_sfixed(128, sfix), to_sfixed(127, sfix), 
        to_sfixed(126, sfix), to_sfixed(125, sfix), to_sfixed(124, sfix), to_sfixed(123, sfix), to_sfixed(122, sfix), to_sfixed(121, sfix), to_sfixed(120, sfix), to_sfixed(119, sfix), to_sfixed(118, sfix), to_sfixed(117, sfix), to_sfixed(116, sfix), to_sfixed(115, sfix), to_sfixed(114, sfix), to_sfixed(113, sfix), 
        to_sfixed(112, sfix), to_sfixed(111, sfix), to_sfixed(110, sfix), to_sfixed(109, sfix), to_sfixed(108, sfix), to_sfixed(107, sfix), to_sfixed(106, sfix), to_sfixed(105, sfix), to_sfixed(104, sfix), to_sfixed(103, sfix), to_sfixed(102, sfix), to_sfixed(101, sfix), to_sfixed(100, sfix), to_sfixed(99, sfix), 
        to_sfixed(98, sfix), to_sfixed(97, sfix), to_sfixed(96, sfix), to_sfixed(95, sfix), to_sfixed(94, sfix), to_sfixed(93, sfix), to_sfixed(92, sfix), to_sfixed(91, sfix), to_sfixed(90, sfix), to_sfixed(89, sfix), to_sfixed(88, sfix), to_sfixed(87, sfix), to_sfixed(86, sfix), to_sfixed(85, sfix), 
        to_sfixed(84, sfix), to_sfixed(83, sfix), to_sfixed(82, sfix), to_sfixed(81, sfix), to_sfixed(80, sfix), to_sfixed(79, sfix), to_sfixed(78, sfix), to_sfixed(77, sfix), to_sfixed(76, sfix), to_sfixed(75, sfix), to_sfixed(74, sfix), to_sfixed(73, sfix), to_sfixed(72, sfix), to_sfixed(71, sfix), 
        to_sfixed(70, sfix), to_sfixed(69, sfix), to_sfixed(68, sfix), to_sfixed(67, sfix), to_sfixed(66, sfix), to_sfixed(65, sfix), to_sfixed(64, sfix), to_sfixed(63, sfix), to_sfixed(62, sfix), to_sfixed(61, sfix), to_sfixed(60, sfix), to_sfixed(59, sfix), to_sfixed(58, sfix), to_sfixed(57, sfix), 
        to_sfixed(56, sfix), to_sfixed(55, sfix), to_sfixed(54, sfix), to_sfixed(53, sfix), to_sfixed(52, sfix), to_sfixed(51, sfix), to_sfixed(50, sfix), to_sfixed(49, sfix), to_sfixed(48, sfix), to_sfixed(47, sfix), to_sfixed(46, sfix), to_sfixed(45, sfix), to_sfixed(44, sfix), to_sfixed(43, sfix), 
        to_sfixed(42, sfix), to_sfixed(41, sfix), to_sfixed(40, sfix), to_sfixed(39, sfix), to_sfixed(38, sfix), to_sfixed(37, sfix), to_sfixed(36, sfix), to_sfixed(35, sfix), to_sfixed(34, sfix), to_sfixed(33, sfix), to_sfixed(32, sfix), to_sfixed(31, sfix), to_sfixed(30, sfix), to_sfixed(29, sfix), 
        to_sfixed(28, sfix), to_sfixed(27, sfix), to_sfixed(26, sfix), to_sfixed(25, sfix), to_sfixed(24, sfix), to_sfixed(23, sfix), to_sfixed(22, sfix), to_sfixed(21, sfix), to_sfixed(20, sfix), to_sfixed(19, sfix), to_sfixed(18, sfix), to_sfixed(17, sfix), to_sfixed(16, sfix), to_sfixed(15, sfix), 
        to_sfixed(14, sfix), to_sfixed(13, sfix), to_sfixed(12, sfix), to_sfixed(11, sfix), to_sfixed(10, sfix), to_sfixed(9, sfix), to_sfixed(8, sfix), to_sfixed(7, sfix), to_sfixed(6, sfix), to_sfixed(5, sfix), to_sfixed(4, sfix), to_sfixed(3, sfix), to_sfixed(2, sfix), to_sfixed(1, sfix),  

        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        
        zero, zero, zero, zero,

        to_sfixed(196, sfix), to_sfixed(195, sfix), to_sfixed(194, sfix), to_sfixed(193, sfix), to_sfixed(192, sfix), to_sfixed(191, sfix), to_sfixed(190, sfix), to_sfixed(189, sfix), to_sfixed(188, sfix), to_sfixed(187, sfix), to_sfixed(186, sfix), to_sfixed(185, sfix), to_sfixed(184, sfix), to_sfixed(183, sfix), 
        to_sfixed(182, sfix), to_sfixed(181, sfix), to_sfixed(180, sfix), to_sfixed(179, sfix), to_sfixed(178, sfix), to_sfixed(177, sfix), to_sfixed(176, sfix), to_sfixed(175, sfix), to_sfixed(174, sfix), to_sfixed(173, sfix), to_sfixed(172, sfix), to_sfixed(171, sfix), to_sfixed(170, sfix), to_sfixed(169, sfix), 
        to_sfixed(168, sfix), to_sfixed(167, sfix), to_sfixed(166, sfix), to_sfixed(165, sfix), to_sfixed(164, sfix), to_sfixed(163, sfix), to_sfixed(162, sfix), to_sfixed(161, sfix), to_sfixed(160, sfix), to_sfixed(159, sfix), to_sfixed(158, sfix), to_sfixed(157, sfix), to_sfixed(156, sfix), to_sfixed(155, sfix), 
        to_sfixed(154, sfix), to_sfixed(153, sfix), to_sfixed(152, sfix), to_sfixed(151, sfix), to_sfixed(150, sfix), to_sfixed(149, sfix), to_sfixed(148, sfix), to_sfixed(147, sfix), to_sfixed(146, sfix), to_sfixed(145, sfix), to_sfixed(144, sfix), to_sfixed(143, sfix), to_sfixed(142, sfix), to_sfixed(141, sfix), 
        to_sfixed(140, sfix), to_sfixed(139, sfix), to_sfixed(138, sfix), to_sfixed(137, sfix), to_sfixed(136, sfix), to_sfixed(135, sfix), to_sfixed(134, sfix), to_sfixed(133, sfix), to_sfixed(132, sfix), to_sfixed(131, sfix), to_sfixed(130, sfix), to_sfixed(129, sfix), to_sfixed(128, sfix), to_sfixed(127, sfix), 
        to_sfixed(126, sfix), to_sfixed(125, sfix), to_sfixed(124, sfix), to_sfixed(123, sfix), to_sfixed(122, sfix), to_sfixed(121, sfix), to_sfixed(120, sfix), to_sfixed(119, sfix), to_sfixed(118, sfix), to_sfixed(117, sfix), to_sfixed(116, sfix), to_sfixed(115, sfix), to_sfixed(114, sfix), to_sfixed(113, sfix), 
        to_sfixed(112, sfix), to_sfixed(111, sfix), to_sfixed(110, sfix), to_sfixed(109, sfix), to_sfixed(108, sfix), to_sfixed(107, sfix), to_sfixed(106, sfix), to_sfixed(105, sfix), to_sfixed(104, sfix), to_sfixed(103, sfix), to_sfixed(102, sfix), to_sfixed(101, sfix), to_sfixed(100, sfix), to_sfixed(99, sfix), 
        to_sfixed(98, sfix), to_sfixed(97, sfix), to_sfixed(96, sfix), to_sfixed(95, sfix), to_sfixed(94, sfix), to_sfixed(93, sfix), to_sfixed(92, sfix), to_sfixed(91, sfix), to_sfixed(90, sfix), to_sfixed(89, sfix), to_sfixed(88, sfix), to_sfixed(87, sfix), to_sfixed(86, sfix), to_sfixed(85, sfix), 
        to_sfixed(84, sfix), to_sfixed(83, sfix), to_sfixed(82, sfix), to_sfixed(81, sfix), to_sfixed(80, sfix), to_sfixed(79, sfix), to_sfixed(78, sfix), to_sfixed(77, sfix), to_sfixed(76, sfix), to_sfixed(75, sfix), to_sfixed(74, sfix), to_sfixed(73, sfix), to_sfixed(72, sfix), to_sfixed(71, sfix), 
        to_sfixed(70, sfix), to_sfixed(69, sfix), to_sfixed(68, sfix), to_sfixed(67, sfix), to_sfixed(66, sfix), to_sfixed(65, sfix), to_sfixed(64, sfix), to_sfixed(63, sfix), to_sfixed(62, sfix), to_sfixed(61, sfix), to_sfixed(60, sfix), to_sfixed(59, sfix), to_sfixed(58, sfix), to_sfixed(57, sfix), 
        to_sfixed(56, sfix), to_sfixed(55, sfix), to_sfixed(54, sfix), to_sfixed(53, sfix), to_sfixed(52, sfix), to_sfixed(51, sfix), to_sfixed(50, sfix), to_sfixed(49, sfix), to_sfixed(48, sfix), to_sfixed(47, sfix), to_sfixed(46, sfix), to_sfixed(45, sfix), to_sfixed(44, sfix), to_sfixed(43, sfix), 
        to_sfixed(42, sfix), to_sfixed(41, sfix), to_sfixed(40, sfix), to_sfixed(39, sfix), to_sfixed(38, sfix), to_sfixed(37, sfix), to_sfixed(36, sfix), to_sfixed(35, sfix), to_sfixed(34, sfix), to_sfixed(33, sfix), to_sfixed(32, sfix), to_sfixed(31, sfix), to_sfixed(30, sfix), to_sfixed(29, sfix), 
        to_sfixed(28, sfix), to_sfixed(27, sfix), to_sfixed(26, sfix), to_sfixed(25, sfix), to_sfixed(24, sfix), to_sfixed(23, sfix), to_sfixed(22, sfix), to_sfixed(21, sfix), to_sfixed(20, sfix), to_sfixed(19, sfix), to_sfixed(18, sfix), to_sfixed(17, sfix), to_sfixed(16, sfix), to_sfixed(15, sfix), 
        to_sfixed(14, sfix), to_sfixed(13, sfix), to_sfixed(12, sfix), to_sfixed(11, sfix), to_sfixed(10, sfix), to_sfixed(9, sfix), to_sfixed(8, sfix), to_sfixed(7, sfix), to_sfixed(6, sfix), to_sfixed(5, sfix), to_sfixed(4, sfix), to_sfixed(3, sfix), to_sfixed(2, sfix), to_sfixed(1, sfix),  

        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        one, one, one, one, one,
        
        zero, zero, zero, zero
                
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
        s_axi_wdata <= (1 => '1', others => '0');
        wait for clk_period;
        s_axi_waddr <= "010";
        s_axi_wdata <= (1 => '1', others => '0');
        wait for clk_period*1;
        s_axi_waddr <= "000";
        s_axi_wdata <= (others => '0');
        wait for clk_period;
        s_axi_we <= '0';
        wait for clk_period;

        wait;
    end process;
    
end behavior;
