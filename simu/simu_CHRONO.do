# Fichier .do : script de simulation en langage tcl/tk

if {[file exists "work"]} {
    file delete -force work
}

vlib work

vcom -93 ../src/FDIV.vhd
vcom -93 ../src/bcd_counter.vhd
vcom -93 ../src/CHRONO.vhd
vcom -93 CHRONO_tb.vhd


vsim -voptargs="+acc" work.CHRONO_tb

view signals

add wave rst
add wave clk
add wave START
add wave -radix unsigned UNITIES
add wave -radix unsigned TENS
add wave -radix unsigned HUNDREDS
add wave -radix unsigned THOUSNDS

# lancer la simulation
run -all

### Fermer proprement la simulation
#quit -sim