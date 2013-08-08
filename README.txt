*******************************************************************

SEE MY REPOSITORY "ePlusMinWorkingEx" FOR EXAMPLE INPUT ENERGYPLUS FILES

*******************************************************************

Original results were produced using EnergyPlus version 6.0.0 on a MacBook Pro running Snow Leopard.

Working example for EnergyPlus version 8.0.0.008
Operating System- OSX 10.8.4
bash --version gives:
GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin12)


TIPS:
Update E+ runenergyplus executable so output files will be produced in the same directory as the input files.  This is necessary to have .rvi files work with these batch scripts.

This command is useful for processing the results into solar fractions:
count=1; while [ "$count" -le "21" ]; do sf.sh 779.01input $count; let count++; done >> resultsSF.csv