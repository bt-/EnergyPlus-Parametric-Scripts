#!/bin/bash

#======================================================
#========= SCRIPT TO RUN MULTIPLE PARAMETRIC SOLAR THERMAL SIMULATIONS USING E+ TO FIND DESIGN SPACE =====
#========================================================

# Script runs setArraySize.sh, paraVolSetup.sh, ePParaTemAdj.sh to produce results for 
#plotting SF vs. (storage volume/collector area) curves

# Script then runs simulations to find the array size necessary to obtain a set SF at specified
# (storage volume/collector area) ratio. A parametric simulation is then performed wiht the new array size.


#TO RUN:
#Script should be run from file with a modified .idf file, .rvi file and any other supporting files
#necessary to run the E+ simulation

# ARGUMENT 1 ====  NAME OF THE WEATHER FILE WITH .epw EXTENSION
# ARGUMENT 2 ====  ANNUAL LOAD IN MWh
# ARGUMENT 3 ====  NUMBER OF PARAMETRIC RUNS
# ARGUMENT 4 ====  Ratio of storage volume to collector area for start of parametric runs
# ARGUMENT 5 ====  Ratio of storage volume to collector area for end of parametric runs

#NOTE: DIRECTORY CONTAINING .idf FILE SHOULD ALSO CONTAIN A .rvi FILE
#NOTE: THE .csv FILENAME INSIDE THE .rvi FILE SHOULD BE filenamecsv1.csv
#NOTE: PARAMETRIC IDF FILE MUST HAVE NUMERIC SUFFIX SPECIFIED



# The .idf file should contain the following search strings:
#============================================

# Used in this script file:
#---------------------------------------
# sHELLtANKvOLUMEhEATER -on the TANK VOLUME line of the "WaterHeater:Mixed" object for the storage tank
# sHELLlOSScOEFFhEATER -on the OFF-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
#					   -also on the ON-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
#-----------------------------------------

# Used in setArraySize.sh:
#-----------------------------------------
# sHELLcOLLECTORaREA -on the line within the Collector Performance Object with the gross area of the collector

# sHELLcOLLsHADEoBJECT -first line of shade object to be copied by setArraySize.sh
# sHELLcOLLECTORnAMEfLAG -on the NAME line of the "Shading:Site:Detailed" object for the collector
# sHELLcOLLECTOR1vERTEX1 -on the line with the first vertice coordinates
# sHELLcOLLECTOR1vERTEX2 
# sHELLcOLLECTOR1vERTEX3
# sHELLcOLLECTOR1vERTEX4

# sHELLbRANCHlISTnAME -on the line with the collector branch within the BranchList Object for the collectors
# sHELLsPLITTERlISTnAME -on the line with the name of the splitter within the Connector:Splitter Object for the collectors
# sHELLmIXERlISTnAME -on the line with the name of the mixer within the Connector:Mixter Object for the collectors

# sHELLbRANCHbLOCKsTART -on the first line of the Branch Object for the collector
# sHELLbRANCHnAME -on the NAME line of the BRANCH object for the collector
# sHELLcOLLECTORcOMPONENT1nAME -on the COMPONENT NAME line of the "Branch" object for the collector
# sHELLcOMPONENT1iNLETnODEnAME -on the COMPONENT INLET NODE NAME line of the "Branch" object for the collector
# sHELLcOMPONENT1oUTLETnODEnAME -on the COMPONENT OUTLET NODE NAME line of the "Branch" object for the collector

# sHELLcOLLECTORnAME1 -on the NAME line of the "SolarCollector:FlatPlate:Water" object for the collector
# sHELLcOLLECTORsURFnAME1 -on the SURFACE NAME line of the "SolarCollector:FlatPlate:Water" object for the collector
# sHELLcOLLECTORiNLETnODEnAME1 -on the INLET NODE NAME line of the "SolarCollector:FlatPlate:Water" object for the collector
# sHELLcOLLECTORoUTLETnODEnAME1 -on the OUTLET NODE NAME line of the "SolarCollector:FlatPlate:Water" object for the collector
#---------------------------------------

# Used in paraVolSet.sh:
#----------------------------------------
# sHELLwATERhEATERmIXED -on the first line of the "WaterHeater:Mixed" object for the storage tank
# sHELLtANKvOLUMEhEATER -on the TANK VOLUME line of the "WaterHeater:Mixed" object for the storage tank
# sHELLlOSScOEFFhEATER -on the OFF-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
#					   -also on the ON-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
#----------------------------------------

# Used in ePParaTempAdj.sh:
#---------------------------------------
# sHELLsTORAGEtANKsTARTtEMPERATURE -on the line within the Hot Water Setpoint Temp Schedule that sets the temperature for the first hour of the simulation
# EnergyPlus seems to set the storage tank temperature at the start of the simulation to the hot water setpoint for the beginning of the simulation
# NOTE: ePParaTempAdj.sh searches for a string of the form (.idf input name)1.csv on line two of the .rvi file
#----------------------------------------



# .rvi file should contain the following strings
#==========================================

#Used in this script file:
#------------------------------------------
# sHELLcSVnAME- on second line of .rvi to be replaced by names for the output .csv files
#------------------------------------------



#==========================================
#=================================================  CODE BELOW   ==========
#===================================================

args=("$@")
. ./ePlusShellFuncLib.lib

echo "args0: ${args[0]}"
echo "args1: ${args[1]}"
echo "args2: ${args[2]}"
echo "args3: ${args[3]}"
echo "args4: ${args[4]}"

weatherFileName=${args[0]}

bigComment "Start of Script"
origIdfFile=$(ls *.idf)
origRviFile=$(ls *.rvi)
echo "Original Input .idf File Name:	$origIdfFile"
echo "Original Input .rvi File Name:	$origRviFile"

#============================================================
#Calculates first guess for array size based on annual load
load=${args[1]}
arraySize=$(echo "scale=4; $load * 2" | bc)

echo "First guess Array Size:	$arraySize"


newDirFunc $arraySize

stripExtFunc $arraySize $origIdfFile
echo "Original .idf file without extension and array size prefix:  $inputNoExtension"

prepRviFunc $origRviFile 1

bigComment "FIRST GUESS PARAMETRIC RUN"
#======================================================
#Runs the setArraySize, paraVolSet, and ePParaTempAdj scripts to create curve

#Calls the script setArraySize.sh to set correct number of collectors in .idf file
bigComment "ENTERING setArraySize.sh"
echo "Sending Args:"
echo "arg1: $origIdfFile"
echo "arg2: $arraySize"
setArraySize.sh $origIdfFile $arraySize

#Calls the script paraVolSetup.sh to add E+ Parametric commands and values .idf file
bigComment "Param Volume Setup"
echo "arg1: $arraySize$origIdfFile"
echo "arg2: $arraySize"
echo "arg3: ${args[2]}"
echo "arg4: ${args[3]}"
echo "arg5: ${args[4]}"
paraVolSet.sh $arraySize$origIdfFile $arraySize ${args[2]} ${args[3]} ${args[4]}

#Calls the script ePParaTemAdj.sh to parametrically run .idf files
bigComment "Run E+ Param"
echo "arg1: $inputNoExtension"
echo "arg2: ${args[0]}"
echo "arg3: ${args[2]}"
ePParaTempAdj.sh $inputNoExtension ${args[0]} ${args[2]}


#======================================================
bigComment "seekSfFunc BOTTOM CURVE RUN"
seekSfFunc 2 ${args[2]} ${args[4]}

#======================================================
#========================================= RUN PARA FOR BOTTOM ARRAY SIZE ===
#======================================================
bigComment "BOTTOM PARA CURV RUN"
#New directory for parametric simulations with new arraySize
newDirFunc para

#STRIPS THE EXTENSION FROM THE INPUT FILE FOR USE IN THE ePParaTemAdj SCRIPT
#Resets inputNoExtension variable and resets .rvi file
stripExtFunc $arraySize $origIdfFile
prepRviFunc $origRviFile 1

#CREATE CORRECT NUMBER OF SHADE OBJECTS, SPLITTER, MIXERS, BRANCHES AND COLLECTORS
bigComment "Collector .idf Setup"
echo "Sending Args:"
echo "arg1: $origIdfFile"
echo "arg2: $arraySize"
setArraySize.sh $origIdfFile $arraySize

#ADD PARAMETRIC VOLUME AND HEAT LOSS VALUES FOR STORAGE TANK
bigComment "Param Vol Setup"
echo "arg1: $arraySize$origIdfFile"
echo "arg2: $arraySize"
echo "arg3: ${args[2]}"
echo "arg4: ${args[3]}"
echo "arg5: ${args[4]}"
paraVolSet.sh $arraySize$origIdfFile $arraySize ${args[2]} ${args[3]} ${args[4]}

#CREATES .rvi FOR EACH PARAMETRIC RUN AND RUNS E+ FOR EACH PARAMETRIC RUN
#ALSO TESTS BEGINNING AND END OF YEAR TEMPERATURES OF STORAGE TANK AND REPEATES SIM IF THEY DIFFER
bigComment "Run E+ Param"
echo "arg1: $inputNoExtension"
echo "arg2: ${args[0]}"
echo "arg3: ${args[2]}"
ePParaTempAdj.sh $inputNoExtension ${args[0]} ${args[2]}







#========================================================
bigComment "seekSf RUN FOR HIGH CURVE"
cd ..
seekSfFunc 3 ${args[2]} ${args[4]}

#======================================================
#========================================= RUN PARA FOR TOP ARRAY SIZE =======
#======================================================

bigComment "RUN PARA FOR HIGH CURVE"
#New directory for parametric simulations with new arraySize
newDirFunc para

#STRIPS THE EXTENSION FROM THE INPUT FILE FOR USE IN THE ePParaTemAdj SCRIPT
#Resets inputNoExtension variable and resets .rvi file
stripExtFunc $arraySize $origIdfFile
prepRviFunc $origRviFile 1

#CREATE CORRECT NUMBER OF SHADE OBJECTS, SPLITTER, MIXERS, BRANCHES AND COLLECTORS
bigComment "Collector .idf Setup"
echo "Sending Args:"
echo "arg1: $origIdfFile"
echo "arg2: $arraySize"
setArraySize.sh $origIdfFile $arraySize

#ADD PARAMETRIC VOLUME AND HEAT LOSS VALUES FOR STORAGE TANK
bigComment "Param Vol Setup"
echo "arg1: $arraySize$origIdfFile"
echo "arg2: $arraySize"
echo "arg3: ${args[2]}"
echo "arg4: ${args[3]}"
echo "arg5: ${args[4]}"
paraVolSet.sh $arraySize$origIdfFile $arraySize ${args[2]} ${args[3]} ${args[4]}

#CREATES .rvi FOR EACH PARAMETRIC RUN AND RUNS E+ FOR EACH PARAMETRIC RUN
#ALSO TESTS BEGINNING AND END OF YEAR TEMPERATURES OF STORAGE TANK AND REPEATES SIM IF THEY DIFFER
bigComment "Run E+ Param"
echo "arg1: $inputNoExtension"
echo "arg2: ${args[0]}"
echo "arg3: ${args[2]}"
ePParaTempAdj.sh $inputNoExtension ${args[0]} ${args[2]}







#======================================================
bigComment "seekSf RUN FOR HIGHEST CURVE"
cd ..
seekSfFunc 4 ${args[2]} 0

#=====================================================
#========================================= RUN PARA FOR TOP ARRAY SIZE ===
#=======================================================

bigComment "RUN PARA FOR HIGHEST CURVE"
#New directory for parametric simulations with new arraySize
newDirFunc para

#STRIPS THE EXTENSION FROM THE INPUT FILE FOR USE IN THE ePParaTemAdj SCRIPT
#Resets inputNoExtension variable and resets .rvi file
stripExtFunc $arraySize $origIdfFile
prepRviFunc $origRviFile 1

#CREATE CORRECT NUMBER OF SHADE OBJECTS, SPLITTER, MIXERS, BRANCHES AND COLLECTORS
bigComment "Collector .idf Setup"
echo "Sending Args:"
echo "arg1: $origIdfFile"
echo "arg2: $arraySize"
setArraySize.sh $origIdfFile $arraySize

#ADD PARAMETRIC VOLUME AND HEAT LOSS VALUES FOR STORAGE TANK
bigComment "Param Vol Setup"
echo "arg1: $arraySize$origIdfFile"
echo "arg2: $arraySize"
echo "arg3: ${args[2]}"
echo "arg4: ${args[3]}"
echo "arg5: ${args[4]}"
paraVolSet.sh $arraySize$origIdfFile $arraySize ${args[2]} ${args[3]} ${args[4]}

#CREATES .rvi FOR EACH PARAMETRIC RUN AND RUNS E+ FOR EACH PARAMETRIC RUN
#ALSO TESTS BEGINNING AND END OF YEAR TEMPERATURES OF STORAGE TANK AND REPEATES SIM IF THEY DIFFER
bigComment "Run E+ Param"
echo "arg1: $inputNoExtension"
echo "arg2: ${args[0]}"
echo "arg3: ${args[2]}"
ePParaTempAdj.sh $inputNoExtension ${args[0]} ${args[2]}
