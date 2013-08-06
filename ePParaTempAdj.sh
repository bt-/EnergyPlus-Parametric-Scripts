#!/bin/bash

#	LICENSE:
#    Script to run parametric EnergyPlus solar thermal simulations.
#    Copyright (C) 2013 Benjamin G. Taylor
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


#========= FILE FOR BATCH PROCESSING PARAMETRIC E+ FILES =====
# ARGUMENT 1 ====  E+ PARAMETRIC FILENAME WITHOUT .idf EXTENSION
# ARGUMENT 2 ====  NAME OF THE WEATHER FILE WITH .epw EXTENSION
# ARGUMENT 3 ====  NUMBER OF PARAMETRIC VARIABLES IN PARAMETRIC .idf FILE

# The .idf should contain the following search strings:
# sHELLsTORAGEtANKsTARTtEMPERATURE -on the line within the Hot Water Setpoint Temp Schedule that sets the temperature for the first hour of the simulation
# EnergyPlus seems to set the storage tank temperature at the start of the simulation to the hot water setpoint for the beginning of the simulation
#===============================


args=("$@")    #Stores the arguments given by user in command line


# DISPLAYS INPUT VALUES BACK TO USER
echo "Energyplus parametric file name without .idf extentsion: ${args[0]}"
echo "Weather file name: ${args[1]}"
echo "Number of parametric runs specified in E+ file:  ${args[2]}"


# RUNS THE E+ PARAMETRICPREPROCESSOR GENERATING .idf FILES
parametricpreprocessor ${args[0]}".idf"


#set output of parametricpreprocessor to array and print array values
array=(${args[0]}*".idf")
len=${#array[*]}
echo "The array has $len members. They are:"
i=0
while [ "$i" -lt "$len" ]; do
	echo "$i: ${array[$i]}"
	let i++
done

#exit

#=========== CREATING RVI FILES FOR EACH RUN AND RUNNING E+ =====
nRuns=${args[2]}
count=1
cnt=1
rcount=2

while [ $count -le $nRuns ]; do

	#This line uses sed to replace the filename of the csv file within the .rvi file for each run
	sed 's/'${args[0]}'1.csv/'${args[0]}$rcount'.csv/g' ${args[0]}-1.rvi > ${args[0]}-$rcount.rvi          	
	
	
	tempTest=0
	iterCount=0
	
	while [ $tempTest -ne 1 ]; do
		#This line runs energyplus using the idf files produced by the parametricpreprocessor 
		#(E+ auxiliary  program) and the weather file input to this script by user
		runenergyplus ${args[0]}"-"$cnt".idf" ${args[1]}
		awkCsv=`expr $rcount - 1`
		echo "awk csv: ${args[0]}$cnt.csv"
		#Get tank temp at start and end of year         
		set $( awk -F, '
			/01\/01  01:00:00/ {
				startTemp = $4
				print startTemp
				}
			/12\/31  24:00:00/ {
				endTemp = $4
				print endTemp
				}
			END {
				delT = endTemp-startTemp
				print delT
				if (delT > 0 && delT < 1.0) print 1;
				else if (delT < 0 && delT > -1.0) print 1;
				else print 0;
				}' ${args[0]}$cnt".csv")
		storTempStart=$1
		storTempEnd=$2
		delT=$3
		tempTest=$4
		echo "*************  Ending Temps  ***************"
		echo "storTempStart: $storTempStart"
		echo "storTempEnd:   $storTempEnd"
		echo "delT: $delT"
		echo "tempTest: $tempTest"
		#Sets next simulation start tank temp as the end tank temp of the last simulation if annual recalc needed
		if [ $tempTest -eq 0 ]; then
		awk -F, -v VAR=$storTempEnd  '/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
			printf("UNTIL: 1:00, %2.1f, !- sHELLsTORAGEtANKsTARTtEMPERATURE \n",VAR)
			}
			!/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
			print
			}' ${args[0]}"-"$cnt".idf" > awkTemp${args[0]}"-"$cnt".idf"
		rm ${args[0]}"-"$cnt".idf"
		mv awkTemp${args[0]}"-"$cnt".idf" ${args[0]}"-"$cnt".idf"
		fi
	done
	#GET AND DISPLAY SF FOR RUN
	SF=$(sf.sh ${args[0]} $cnt)
	echo "*************  Solar Fraction  ***************"
	echo "SF:    $SF"

	let rcount++
	let count++
	let cnt++
	#Sets next simulation start tank temp as the end tank temp of the last simulation
	
	
	
	
#	awk -F, -v VAR=$storTempEnd  '/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
#		printf(" UNTIL: 1:00, %2.1f, !- sHELLsTORAGEtANKsTARTtEMPERATURE \n",VAR)
#		}
#		!/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
#		print
#		}' ${args[0]}"-"$cnt".idf" > awkTemp${args[0]}"-"$cnt".idf"
#	rm ${args[0]}"-"$cnt".idf"
#	mv awkTemp${args[0]}"-"$cnt".idf" ${args[0]}"-"$cnt".idf"	
done

rcount=`expr $rcount - 1`
rm ${args[0]}"-"$rcount".rvi"  # DELETING EXTRA .rvi FILE THAT COMES OUT OF THE LOOP

#CELEBRATORY MESSSAGE
echo "Success, my friend! Now, deal with all that data."
