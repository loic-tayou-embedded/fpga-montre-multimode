# Fichier .do : script de simulation en langage tcl/tk

if {[file exists "work"]} {
    file delete -force work
}

vlib work

vcom -93 ../src/FDIV.vhd
vcom -93 ../src/CHENILLIARD.vhd
vcom -93 ../src/ALARM_BELL.vhd
vcom -93 ALARM_BELL_tb.vhd


vsim -voptargs="+acc" work.ALARM_BELL_tb

view signals
add wave *

# lancer la simulation
run -all

### Fermer proprement la simulation
#quit -sim