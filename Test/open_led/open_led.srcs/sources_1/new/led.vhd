library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led is
    Port (
        SW0  : in  STD_LOGIC;
        LED0 : out STD_LOGIC
    );
end led;

architecture Behavioral of led is
begin
    LED0 <= SW0;
end Behavioral;