# Fichier .do : script de simulation en langage tcl/tk

if {[file exists "work"]} {
    file delete -force work
}

vlib work

vcom -93 ../src/SEVEN_SEG.vhd
vcom -93 SEVEN_SEG_tb.vhd

vsim SEVEN_SEG_tb

add wave Data
add wave Segout

# lancer la simulation
run -all

### Fermer proprement la simulation
#quit -sim