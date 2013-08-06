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


#========= FILE FOR SETTING MULTIPLYING COLLECTORS TO NUMBER REQUIRED FOR ARRAY AREA =====
# ARGUMENT 1 === E+ FILENAME WITH .IDF EXTENSION AND ARRAY SIZE PREFIX EX: 120input.idf
# ARGUMENT 2 === ARRAY SIZE
# ARGUMENT 3 === NUMBER OF PARAMETRIC SIMULATIONS DESIRED (TANK VOLUME AND HEAT LOSS COEFF BEING THE VARIABLE PARAMETERS)
# ARGUMENT 4 === STARTING RATIO OF STORAGE TANK VOLUME/COLLECTOR AREA (m^3/m^2) FOR PARAMETRIC SIMULATIONS
# ARGUMENT 5 === ENDING RATIO OF STORAGE TANK VOLUME/COLLECTOR AREA (m^3/m^2) FOR PARAMETRIC SIMULATIONS
# NOTE: Recommended range for arguments 4 & 5 is 0.001 to 10 below 0.001 is essentially equivalent to no storage 
# and above 0.5 is entering seasonal scale storage
# NOTE: Argument 5 must be greater than argument 4


# The .idf should contain the following search strings:
#----------------------------------
# sHELLwATERhEATERmIXED -on the first line of the "WaterHeater:Mixed" object for the storage tank
# sHELLtANKvOLUMEhEATER -on the TANK VOLUME line of the "WaterHeater:Mixed" object for the storage tank
# sHELLlOSScOEFFhEATER -on the OFF-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
#					   -also on the ON-CYCLE LOSS COEFFICIENT TO AMBIENT TEMPERATURE line of the "WaterHeater:Mixed" object for the storage tank
# 
# This script inserts and replaces the following strings (THEY DO NOT NEED TO BE IN THE .idf!):
# sHELLtANKvOLUME
# sHELLlOSScOEFF
# sHELLnUMERICsUFFIX
#===================================




args=("$@")

numOfParam=${args[2]}
echo "numOfParam: $numOfParam"

#===================================
#Function to insert parametric heading
paramHeadFunc ()
{
ed -s ${args[0]} <<EOF
H
/sHELLwATERhEATERmIXED/
i
${1},
${2},			!- Parameter Name
.
w
q
EOF
}

paramHeadFunc "Parametric:SetValueForRun" \$volHeatr

#=============================
#Function to insert parametric text placeholder for replacement by numeric value later
placeHoldFunc ()
{
count=1
while [ "$count" -le "$numOfParam" ]; do
ed -s ${args[0]} <<EOF
H
/sHELLwATERhEATERmIXED/
i
${1}
.
w
q
EOF
let count++
done

ed -s ${args[0]} <<EOF
H
/sHELLwATERhEATERmIXED/
i

.
w
q
EOF
}

placeHoldFunc "sHELLtANKvOLUME"


#===============================
paramHeadFunc "Parametric:SetValueForRun" \$lossCoefHeatr
placeHoldFunc "sHELLlOSScOEFF"

#==============================
paramHeadFunc "Parametric:FileNameSuffix" "suffix"
placeHoldFunc "sHELLnUMERICsUFFIX"


awk -F, '
	/sHELLtANKvOLUMEhEATER/ {
		printf("    =$volHeatr,                  !- Tank Volume {m3}\n")
	}
	
	/sHELLlOSScOEFFhEATER/ {
		printf("    =$lossCoefHeatr,             !- Heater Loss Coefficient\n")
	}
	
	!/(sHELLtANKvOLUMEhEATER)|(sHELLlOSScOEFFhEATER)/ {
		print
		}' ${args[0]} > TEMP_${args[0]}

rm ${args[0]}
mv TEMP_${args[0]} ${args[0]}



awk -F, -v VAR=${args[1]} -v endLoop=$numOfParam -v startCount=${args[3]} -v endCount=${args[4]} -v steps=$numOfParam '
BEGIN {
	steps=steps-1
	st=log(startCount*10000)/log(10)
	en=log(endCount*10000)/log(10)
	span=en-st
	step=span/steps
	sTVol = st; logTen = log(10); uaCount = st; volCount = 1; lossCount = 1; suffixCount = 1
	}

/sHELLtANKvOLUME/ {
	expTenStep = exp(logTen * sTVol)
	tankVol = (expTenStep/10000) * VAR
	if (volCount < endLoop) printf("%10.8f,\n",tankVol);
	else if (volCount == endLoop) printf("%10.8f;  !- sHELLlASTtANKvOLUME\n",tankVol);
	sTVol = sTVol + step
	volCount = volCount + 1
	}

/sHELLlOSScOEFF/ {
	uaExpTenStep = exp(logTen * uaCount)
	uaTankVol = (uaExpTenStep/10000) * VAR
	logTankVol = log(uaTankVol)
	insThick = 21.404 * exp(logTankVol * 0.3619)
	uValue = 1/(0.0004375 + ((insThick/1000)/0.02) + 0.23)
	logHeight = log((36 * uaTankVol) / ( 3.14159))
	height = exp(logHeight * (0.3333333))
	radius = height/6
	surfArea = (2 * 3.14159 * height * (radius + 0.007 + (insThick/1000))) + (2 * 3.14159 * (radius + 0.007 + (insThick/1000)) * (radius + 0.007 + (insThick/1000)))
	uaValue = surfArea * uValue
	if (lossCount < endLoop) printf("%10.6f,    \n",uaValue);
	else if (lossCount == endLoop) printf("%10.6f;   \n",uaValue);
	uaCount = uaCount + step
	lossCount = lossCount + 1
	}
	
/sHELLnUMERICsUFFIX/ {
	if (suffixCount < endLoop) printf("%2.0f,  \n",suffixCount);
	else if (suffixCount == endLoop) printf("%2.0f;    \n",suffixCount);
	suffixCount = suffixCount + 1
	}
	
!/(sHELLlOSScOEFF)|(sHELLtANKvOLUME)|(sHELLnUMERICsUFFIX)/ {
	print
	}' ${args[0]} > TEMP_${args[0]}
	
rm ${args[0]}
mv TEMP_${args[0]} ${args[0]}


		
