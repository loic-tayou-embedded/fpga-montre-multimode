-- ALARM_BELL_tb.vhd
-- ---------------------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

entity ALARM_BELL_tb is
end entity;

architecture ALARM_BELL_tb_rtl of ALARM_BELL_tb is

signal CLK      : std_logic := '0';
signal RST      : std_logic := '1';
signal START    : std_logic := '0';
signal TICK1MS  : std_logic := '0';
signal LED      : std_logic_vector(7 downto 0);

signal stop     : boolean := False;

constant Fclock : positive := 1E8;
constant FTick  : positive := 2E6;
constant N      : positive := 2;

begin

	ALARM_BELL_pm : 	entity work.ALARM_BELL
						generic map(Fclock => Fclock, FTick => FTick, N => N)
						PORT MAP(
									CLK   => CLK,
									RST   => RST,
									START => START,
									LED   => LED
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
		
		wait for 5020 ns;
		report "test after 5 us" severity note;
		assert LED=x"0F" report "Error on FSM chenillard" severity warning;

		wait for 3020 ns;
		report "test after 8 us" severity note;
		assert LED=x"7F" report "Error on FSM chenillard" severity warning;

		wait for 2020 ns;
		report "test after 10 us" severity note;
		assert LED=x"00" report "Error on FSM chenillard" severity warning;
		
		wait for 3020 ns;
		report "test after 13 us" severity note;
		assert LED=x"E0" report "Error on FSM chenillard" severity warning;
		
		wait for 6020 ns;
		
		report "End of test. Verify that no error was reported.";
		
		stop <= true;
		wait;
	end process;

end architecture;
