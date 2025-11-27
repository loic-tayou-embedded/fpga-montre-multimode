-- BCD_COUNTER.vhd
-- ---------------------------------------

library IEEE;
  use IEEE.std_logic_1164.ALL;
  use IEEE.numeric_std.ALL;


---------------------------------------
entity BCD_COUNTER is
---------------------------------------
	generic(N : positive := 1000); 
	port( 
			CLK        : in  std_logic;
			RST        : in  std_logic;
			TICK1MS    : in  std_logic;
			START      : in  std_logic;
			rst_FDIV   : out  std_logic;
			UNITIES    : out std_logic_vector(3 downto 0);
			TENS       : out std_logic_vector(3 downto 0);
			HUNDREDS   : out std_logic_vector(3 downto 0);
			THOUSNDS   : out std_logic_vector(3 downto 0)
	);
end entity BCD_COUNTER;


---------------------------------------
architecture BCD_COUNTER_RTL of BCD_COUNTER is
---------------------------------------

signal tick_N1ms, sig_UNITIES, sig_TENS, sig_HUNDREDS, sig_THOUSNDS : Natural := 0;

-- -------------------------------------

begin

UNITIES  <= std_logic_vector(to_unsigned(sig_UNITIES, 4));
TENS     <= std_logic_vector(to_unsigned(sig_TENS, 4));
HUNDREDS <= std_logic_vector(to_unsigned(sig_HUNDREDS, 4));
THOUSNDS <= std_logic_vector(to_unsigned(sig_THOUSNDS, 4));

process(RST,CLK)

begin
	if(RST = '1') then
		sig_UNITIES  <= 0;
		sig_TENS     <= 0;
		sig_HUNDREDS <= 0;
		sig_THOUSNDS <= 0;
		tick_N1ms    <= 0;
		rst_FDIV     <= '1';
	elsif(rising_edge(CLK)) then
		if(START = '1') then
			rst_FDIV <= '0';
			if (TICK1MS = '1') then
				if(tick_N1ms = N - 1) then
					tick_N1ms <= 0;
					if(sig_UNITIES = 9) then
						sig_UNITIES <= 0;
						if(sig_TENS = 5 and sig_UNITIES = 9) then
							sig_TENS <= 0;
							if(sig_HUNDREDS = 9) then
								sig_HUNDREDS <= 0;
								if((sig_THOUSNDS = 2 and sig_HUNDREDS = 3) and (sig_TENS = 5 and sig_UNITIES = 9)) then
									sig_THOUSNDS <= 0;
									sig_HUNDREDS <= 0;
								else
									sig_THOUSNDS <= sig_THOUSNDS + 1;
								end if;
							else
								sig_HUNDREDS <= sig_HUNDREDS + 1;
							end if;
						else
							sig_TENS <= sig_TENS + 1;
						end if;
					else
						sig_UNITIES <= sig_UNITIES + 1;
					end if;
				else
					tick_N1ms <= tick_N1ms + 1;
				end if;
			end if;
		else
			rst_FDIV <= '1';
		end if;
	end if;
end process;

end architecture BCD_COUNTER_RTL;

