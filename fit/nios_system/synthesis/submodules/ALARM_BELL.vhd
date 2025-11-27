-- ALARM_BELL.vhd
-- ---------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

-- ---------------------------------------
    Entity ALARM_BELL is
-- ---------------------------------------
	Generic (
				Fclock : positive := 50E6;
				FTick  : positive := 1E3;
				N      : positive := 250
	);
	port( 
			CLK        : in  std_logic;
			RST        : in  std_logic;
			START      : in  std_logic;
			LED        : out std_logic_vector(7 downto 0)
	);
end ALARM_BELL;

-- ---------------------------------------
    Architecture ALARM_BELL_RTL of ALARM_BELL is
-- ---------------------------------------

signal Tick1ms, rst_FDIV, sig_rst_FDIV : std_logic;

-- -------------------------------------

begin

sig_rst_FDIV <= RST or rst_FDIV;

FDIV_pm :	entity work.FDIV
			Generic map(Fclock => Fclock, FTick => FTick)
			Port map(  
						CLK     => CLK,
						RST     => sig_rst_FDIV,
						Tick1ms => Tick1ms
			);

CHENILLIARD_pm :	entity work.CHENILLIARD
					generic map(N => N) 
					port map( 
								CLK      => CLK,
								RST      => RST,
								START    => START,
								TICK1MS  => Tick1ms,
								rst_FDIV => rst_FDIV,
								LED      => LED
					);

end ALARM_BELL_RTL;

