#!/bin/bash

#========= FILE FOR RUNNING E+ SOLAR THERMAL SIMULATION AND CHECK BEGINING AND END OF YEAR TANK TEMPERATURES ===
# ARGUMENT 1 ====  E+ PARAMETRIC FILENAME WITHOUT .idf EXTENSION
# ARGUMENT 2 ====  NAME OF THE WEATHER FILE WITH .epw EXTENSION
#==========================================================



args=("$@")    #Stores the arguments given by user in command line

	tempTest=0
	iterCount=0
	
	while [ $tempTest -ne 1 ]; do
		#This line runs energyplus using the idf files produced by the parametricpreprocessor 
		#(E+ auxiliary  program) and the weather file input to this script by user
		echo "============= RUN ENERGY PLUS FILE ARG:	${args[0]}.idf"
		runenergyplus ${args[0]}".idf" ${args[1]}
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
				}' ${args[0]}".csv")
		storTempStart=$1
		storTempEnd=$2
		delT=$3
		tempTest=$4
		echo "storTempStart: $storTempStart"
		echo "storTempEnd:   $storTempEnd"
		echo "delT: $delT"
		echo "tempTest: $tempTest"
		#Sets next simulation start tank temp as the end tank temp of the last simulation if annual recalc needed
		if [ $tempTest -eq 0 ]; then
		awk -F, -v VAR=$storTempEnd  '/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
			printf(" UNTIL: 1:00, %2.1f, !- sHELLsTORAGEtANKsTARTtEMPERATURE \n",VAR)
			}
			!/sHELLsTORAGEtANKsTARTtEMPERATURE/ {
			print
			}' ${args[0]}".idf" > ${args[0]}".idfawkTemp"
		rm ${args[0]}".idf"
		mv ${args[0]}".idfawkTemp" ${args[0]}".idf"
		fi
	done
