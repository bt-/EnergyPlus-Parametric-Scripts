*******************************************************************

SEE MY REPOSITORY "ePlusMinWorkingEx" FOR EXAMPLE INPUT ENERGYPLUS FILES

*******************************************************************

SYSTEM NOTES:
Original results were produced using EnergyPlus version 6.0.0 on a MacBook Pro running Snow Leopard.

Working example for EnergyPlus version 8.0.0.008
Operating System- OSX 10.8.4
bash --version, gives:
GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin12)


OVERVIEW:
These scripts collectively will run parametric simulations of solar thermal systems.  The intent is to run enough simulations with varying collector area to storage volume ratios to define a real-world design space.  

The ePlusDesSpaceFunc.sh script will run EnergyPlus simulations of a given range of storage to collector ratios when provided a weather file, an annual load in MWh, a number of parametric simulations to run, a starting storage volume to collector area ratio, and an ending storage volume to collector area ratio.

These scripts were developed as part of my Master's thesis, which can be viewed at the following link.
http://goo.gl/e00Ptk

Section 3.2.2.5 of the thesis provides an explanation of the algorithm implemented in these scripts.

TIPS:
Update E+ runenergyplus executable so output files will be produced in the same directory as the input files.  This is necessary to have .rvi files work with these batch scripts.

This command is useful for processing the results into solar fractions:
count=1; while [ "$count" -le "21" ]; do sf.sh 779.01input $count; let count++; done >> resultsSF.csv