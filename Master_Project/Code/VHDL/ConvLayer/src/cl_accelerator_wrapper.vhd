library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity cl_accelerator_wrapper is
	generic (
        C_S_AXI_DATA_WIDTH  : Natural := 32;
        NOF_ACCELERATORS    : Natural := 3;
        IMG_DIM             : Natural := 6;
        KERNEL_DIM          : Natural := 3;
        POOL_DIM            : Natural := 2;
        INT_WIDTH           : Natural := 16;
        FRAC_WIDTH          : Natural := 16
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
    
    
     
end cl_accelerator_wrapper;

architecture Behavioral of cl_accelerator_wrapper is
     component sfixed_fifo is
     Generic (
         constant INT_WIDTH : positive := 16;
         constant FRAC_WIDTH : positive := 16
         constant FIFO_DEPTH	: positive := 8
     );
     Port ( 
         clk		: in  STD_LOGIC;
         reset		: in  STD_LOGIC;
         WriteEn	: in  STD_LOGIC;
         DataIn	    : in  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
         ReadEn	    : in  STD_LOGIC;
         DataOut	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
         Empty	    : out STD_LOGIC;
         Full	    : out STD_LOGIC
     );
     end sfixed_fifo;

     type bus_array is array (0 to NOF_ACCELERATORS-1) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
     type bit_array is array (0 to NOF_ACCELERATORS-1) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
     
     signal fifo_writeEn : bit_array;
     signal fifo_dataIn : bus_array;
     signal fifo_readEn : bit_array;
     signal fifo_dataOut : bus_array;
     signal fifo_empty : bit_array;
     signal fifo_full : bit_array;

     signal fifoSize_reg : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

     signal reset_all : std_logic;
     
begin

    WriteControlRegisters : process(clk)
    begin
        if rising_edge(clk) then
            if s_axi_we = '1' then
                case s_axi_waddr is
                    when "000" =>
                        fifoSize_reg <= s_axi_wdata;
                    when others =>
                end case;
            end if;
        end if;
    end process;

    StreamDataIn : process(clk)
        variable nof_writes : natural;
        variable fifo_nr    : natural;
    begin
        if rising_edge(clk) then
            if reset_all = '0' then
                nof_writes := 0;
                fifo_nr := 0;
            elsif s_axis_tvalid = '1' then
                
            end if;
        end if;
    end process;


    m_axis_tkeep <= "1111";
    
    StreamDataOut : process(clk)
        variable nof_reads : natural;
        variable fifo_nr : natural;
    begin
        if rising_edge(clk) then
            if reset_all = '0' then
                nof_reads := 0;
                fifo_nr := 0;
                fifo_readEn <= '0';

                m_axis_tvalid <= '0';
                m_axis_tdata <= (others => '0');
                m_axis_tlast <= '0';        
            elsif m_axis_tready = '1' then

                m_axis_tvalid <= '1';
                m_axis_tdata <= fifo_dataOut(fifo_nr);
                fifo_readEn <= '1';

                if nof_reads = to_integer(unsigned(fifoSize_reg))-1 then
                    nof_reads := 0;
                    if fifo_nr = NOF_ACCELERATORS-1 then
                        fifo_nr := 0;
                        m_axis_tlast <= '1';
                    else
                        m_axis_tlast <= '0';
                        fifo_nr := fifo_nr + 1;
                    end if;
                else
                    m_axis_tlast <= '0';        
                    nof_reads := nof_reads + 1;
                end if;
                
            else
                m_axis_tvalid <= '0';
                m_axis_tdata <= (others => '0');
                fifo_readEn <= '0';
                m_axis_tlast <= '0';
            end if;
        end if; 
    end process;

    
    gen_fifos: for i in 0 to NOF_ACCELERATORS-1 generate
        fifox : sfixed_fifo port map (
            clk => clk,
            reset => reset_all,
            WriteEn => fifo_writeEn(i),
            DataIn => fifo_dataIn(i),
            ReadEn => fifo_readEn(i),
            DataOut => fifo_dataOut(i),
            Empty => fifo_empty(i),
            Full => fifo_full(i)
        );
    end generate;
        
        
    
end Behavioral;
