-- CHRONO_tb.vhd
-- ---------------------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

entity CHRONO_tb is
end entity;

architecture TEST of CHRONO_tb is

signal CLK      : std_logic := '0';
signal RST      : std_logic := '1';
signal START    : std_logic := '0';
signal TICK1MS  : std_logic := '0';
signal UNITIES, TENS, HUNDREDS, THOUSNDS : std_logic_vector(3 downto 0);

signal stop  : boolean := False;

constant Fclock : positive := 1E8;
constant FTick  : positive := 2E6;
constant N      : positive := 2;

begin


	CHRONO_pm : entity work.CHRONO
				generic map(Fclock => Fclock, FTick => FTick, N => N)
				PORT MAP (
							CLK      => CLK,
							RST      => RST,
							START    => START,
							UNITIES  => UNITIES,
							TENS     => TENS,
							HUNDREDS => HUNDREDS,
							THOUSNDS => THOUSNDS
				);
				
	CLOCK_PROCESS : process
					begin
						while not stop loop
							CLK <= '0';
							wait for 5 ns;
							CLK <= '1';
							wait for 5 ns;
						end loop;
						wait;
					end process;

	process 
	begin
		RST   <= '1';
		START <= '1';
		wait for 10 ns;
		RST   <= '0';
		wait for 60 us;
		report "test after 60 us" severity note;
		assert THOUSNDS=x"0" report "Error on THOUSNDS" severity warning;
		assert HUNDREDS=x"0" report "Error on HUNDREDS" severity warning;
		assert TENS    =x"5" report "Error on TENS"  severity warning;
		assert UNITIES =x"9" report "Error on UNITS" severity warning;

		wait for 31 us;
		report "test after 60 + 31 us" severity note;
		assert THOUSNDS=x"0" report "Error on THOUSNDS" severity warning;
		assert HUNDREDS=x"1" report "Error on HUNDREDS" severity warning;
		assert TENS    =x"3" report "Error on TENS"  severity warning;
		assert UNITIES =x"0" report "Error on UNITS" severity warning;

		wait for 600 us;
		
		report "test after 60 + 31 + 601 us" severity note;
		assert THOUSNDS=x"1" report "Error on THOUSNDS" severity warning;
		assert HUNDREDS=x"1" report "Error on HUNDREDS" severity warning;
		assert TENS    =x"3" report "Error on TENS"  severity warning;
		assert UNITIES =x"0" report "Error on UNITS" severity warning;

		report "End of test. Verify that no error was reported.";
		
		stop <= true;
		wait;
	end process;

end architecture;
