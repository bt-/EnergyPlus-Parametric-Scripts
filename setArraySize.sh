#!/bin/bash

#========= FILE FOR SETTING MULTIPLYING COLLECTORS TO NUMBER REQUIRED FOR ARRAY AREA ===
# ARGUMENT 1 ====  E+ FILENAME WITH .idf EXTENSION
# ARGUMENT 2 ====  ARRAY AREA


# .idf should contain the following search strings:
#-----------------------------------------------------
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
#======================================================

#Sets user terminal input in array
args=("$@")
arrayArea=${args[1]}

echo "RECEIVED ARGS:"
echo "ARG0 origIdffile: ${args[0]}"
echo "ARG1 arrayArea: ${args[1]}"

#Determines dimensions of collectors for spacing collectors
vert1x=$(awk -F, '/sHELLcOLLECTOR1vERTEX1/ {vert1x=$1}; END {printf "%05.12f",vert1x}' "${args[0]}")
vert3x=$(awk -F, '/sHELLcOLLECTOR1vERTEX4/ {vert3x=$1}; END {printf "%05.12f",vert3x}' "${args[0]}")
echo
echo "vert1x: $vert1x"
echo "vert3x: $vert3x"  

#Determines number of collector required for array area by finding the gross area of each collector as defined in .idf
set $( awk -F, -v VAR=$arrayArea '
	/sHELLcOLLECTORaREA/{		#.idf file must have comment in line with gross area of collector "sHELLcOLLECTORaREA"
		colArea = $1
		}
	END {
		numCol = VAR/colArea
		printf("%5.0f", numCol)
	}' ${args[0]})
numCol=$1
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in 1st awk"
fi
echo "numCol:	$numCol"

#Determines where the shade surface definitions for the collectors to be multiplied begin and ends
set $(awk -F, '
	/sHELLcOLLsHADEoBJECT/ {
		shSurfBlockStart = NR
		}
	END {
		print shSurfBlockStart
		shSurfBlockEnd = shSurfBlockStart + 8
		print shSurfBlockEnd
		shSurfBlockEndSpace = shSurfBlockStart + 9
		print shSurfBlockEndSpace
	}' ${args[0]})
shSurfBlockStart=$1
shSurfBlockEnd=$2
shSurfBlockEndSpace=$3
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in 2nd awk"
fi
#echo "start: $shSurfBlockStart"
#echo "end: $shSurfBlockEnd"
#echo "endSpace: $shSurfBlockEndSpace"

#COPIES ORIGINAL INPUT FILE TO PRESERVE IT UNCHANGED
cp ${args[0]} FINISHED${args[0]}

#THIS BLOCK COPIES THE ENTIRE SHADING SURFACE OBJ DESCRIPTION THE SPECIFIED NUMBER OF TIMES W/O CHANGES
count=1
while [ $count -lt $numCol ]; do
	ed -s FINISHED${args[0]} <<-EOF
		H
	 	$shSurfBlockStart , $shSurfBlockEnd t $shSurfBlockEndSpace
	 	w
	 	q
	EOF
	if [ "$?" -ne "0" ]; then
		echo
		echo "ERROR: problem in $count loop of copy shad surf block"
	fi
	let count++
#	echo "number of collectors: $count"
done



count=1
while [ $count -lt $numCol ]; do
ed -s FINISHED${args[0]} <<EOF
H
/sHELLbRANCHlISTnAME/
a
    Collector 1 Branch,       !- sHELLbRANCHlISTnAME
.
/sHELLsPLITTERlISTnAME/
a
    Collector 1 Branch,       !- sHELLsPLITTERlISTnAME
.
/sHELLmIXERlISTnAME/
a
    Collector 1 Branch,       !- sHELLmIXERlISTnAME
.
w
q
EOF
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in $count loop of branch, splitter, mixer copy"
fi
let count++
#echo "number of collectors: $count"
done

#Determines where the shade surface definitions for the collectors to be multiplied begin and ends
set $(awk -F, '
	/sHELLbRANCHbLOCKsTART/ {
		BranchBlockStart = NR
		}
	END {
		print BranchBlockStart
		BranchBlockEnd = BranchBlockStart + 17
		print BranchBlockEnd
		BranchBlockEndSpace = BranchBlockStart + 18
		print BranchBlockEndSpace
	}' FINISHED${args[0]})
BranchBlockStart=$1
BranchBlockEnd=$2
BranchBlockEndSpace=$3
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in finding branch block location"
fi
#echo "start: $BranchBlockStart"
#echo "end: $BranchBlockEnd"
#echo "endSpace: $BranchBlockEndSpace"

#THIS BLOCK COPIES THE COLLECTOR BRANCH AND OBJ ENTIRE SHADING SURFACE OBJ DESCRIPTION THE SPECIFIED NUMBER OF TIMES W/O CHANGES
count=1
while [ $count -lt $numCol ]; do
	ed -s FINISHED${args[0]} <<-EOF
		H
	 	$BranchBlockStart , $BranchBlockEnd t $BranchBlockEndSpace
	 	w
	 	q
	EOF
	if [ "$?" -ne "0" ]; then
		echo
		echo "ERROR: problem in $count loop of copy branch block"
	fi
	let count++
#	echo "number of collectors: $count"
done


#exit

		
#THIS BLOCK OF CODE REPLACES THE COLLECTOR NAME WITH A NUMERICALLY ITERATED NAME AND ITERATES THE VERTICE VALUES
awk -F, -v numCol=$numCol -v vert1x=$vert1x -v vert3x=$vert3x '
BEGIN {
	surfCount = 0; vert2x = vert1x; vert4x = vert3x
	spacing = vert3x - vert1x + 0.25
	vertOneCount = 0; vertTwocount 0; vertThreeCount = 0; vertFourCount = 0; sblName = 0; sslName = 0; smlName = 0
	}

/sHELLcOLLECTORnAMEfLAG/ {
	surfCount = surfCount + 1 
	printf("	Collector Surface %i,		!- Collector %i Surface Name\n",surfCount,surfCount)
	}

/sHELLcOLLECTOR1vERTEX1/ {
	vertOneCount = vertOneCount + 1
	printf("    %3.12f,%3.12f,%3.12f,   	!-X,Y,Z ===> Collector %i Vertex 1\n",vert1x,$2,$3,vertOneCount)
	vert1x = vert1x + spacing
	}
	
/sHELLcOLLECTOR1vERTEX2/ {
	vertTwoCount = vertTwoCount + 1
	printf("    %3.12f,%3.12f,%3.12f,		!-X,Y,Z ===> Collector %i Vertex 2\n",vert2x,$2,$3,vertTwoCount)
	vert2x = vert2x + spacing
	}

/sHELLcOLLECTOR1vERTEX3/ {
	vertThreeCount = vertThreeCount + 1
	printf("    %3.12f,%3.12f,%3.12f,		!-X,Y,Z ===> Collector %i Vertex 3\n",vert3x,$2,$3,vertThreeCount)
	vert3x = vert3x + spacing
	}

/sHELLcOLLECTOR1vERTEX4/{
	vertFourCount = vertFourCount + 1
	printf("    %3.12f,%3.12f,%3.12f;		!-X,Y,Z ===> Collector %i Vertex 4\n",vert4x,$2,$3,vertFourCount)
	vert4x = vert4x + spacing
	}
	
/sHELLbRANCHlISTnAME/ {
	sblName = sblName + 1
	printf("    Collector %i Branch,          !- Collector Branch Name %i\n",sblName,sblName)
	}

/sHELLsPLITTERlISTnAME/ {
	sslName = sslName + 1
	if (sslName < numCol) printf("    Collector %i Branch,          !- Collector Branch Name %i\n",sslName,sslName);
	else if (sslName == numCol) printf("    Collector %i Branch;        !- Collector Branch Name %i\n",sslName,sslName);
	}
	
/sHELLmIXERlISTnAME/ {
	smlName = smlName + 1
	if (smlName < numCol) printf("    Collector %i Branch,		 !- Collector Branch Name %i\n",smlName,smlName);
	else if (smlName == numCol) printf("    Collector %i Branch;		 !- Collector Branch Name %i\n",smlName,smlName);
	}	
	
/sHELLhOTnODEnAME/ {
	printf("    Collector %i Outlet Node, !- Hot Node Name\n",numCol)
	}
	
!/(sHELLcOLLECTORnAMEfLAG)|(sHELLcOLLECTOR1vERTEX1)|(sHELLcOLLECTOR1vERTEX2)|(sHELLcOLLECTOR1vERTEX3)|(sHELLcOLLECTOR1vERTEX4)|(sHELLbRANCHlISTnAME)|(sHELLsPLITTERlISTnAME)|(sHELLmIXERlISTnAME)|(sHELLhOTnODEnAME)/ {
	print
	}' FINISHED${args[0]} > TEMP_FINISHED${args[0]}
	
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in shad surf incremented replacement"
fi

#Deletes original file and changes name of TEMP file to name of original file
rm FINISHED${args[0]}
mv TEMP_FINISHED${args[0]} FINISHED${args[0]}


	
awk 'BEGIN {colCompName = 0; colCompInNode = 0; colCompOutNode = 0; colName = 0; colSurfName = 0; colNNN = 0; colONN = 0; sbName = 0}
/sHELLbRANCHnAME/ {
	sbName = sbName + 1
	printf("    Collector %i Branch,		 !- Collector Branch Name %i\n",sbName,sbName)
	}
	
/sHELLcOLLECTORcOMPONENT1nAME/ {
	colCompName = colCompName + 1
	printf("    Collector %i,                !- Collector Component %i Name\n",colCompName,colCompName)
	}

/sHELLcOMPONENT1iNLETnODEnAME/ {
	colCompInNode = colCompInNode + 1
	printf("    Collector %i Inlet Node,     !- Collector Component %i Inlet Node Name\n",colCompInNode,colCompInNode)
	}
	
/sHELLcOMPONENT1oUTLETnODEnAME/ {
	colCompOutNode = colCompOutNode + 1
	printf("    Collector %i Outlet Node,    !- Collector Component %i Outlet Node Name\n",colCompOutNode,colCompOutNode)
	}
	
/sHELLcOLLECTORnAME1/ {
	colName = colName + 1
	printf("    Collector %i,                    !- Collector Name %i\n",colName,colName)
	}
	
/sHELLcOLLECTORsURFnAME1/ {
	colSurfName = colSurfName + 1
	printf("    Collector Surface %i,         !- Collector Surf Name %i\n",colSurfName,colSurfName)
	}
	
/sHELLcOLLECTORiNLETnODEnAME1/ {
	colNNN = colNNN + 1
	printf("    Collector %i Inlet Node,      !- Collector Inlet Node Name %i\n",colNNN,colNNN)
	}
	
/sHELLcOLLECTORoUTLETnODEnAME1/ {
	 colONN =  colONN + 1
	 printf("   Collector %i Outlet Node,     !- Collector Outlet Node Name %i\n",colONN,colONN)
	}
	
	
 !/(sHELLbRANCHnAME)|(sHELLcOLLECTORcOMPONENT1nAME)|(sHELLcOMPONENT1iNLETnODEnAME)|(sHELLcOMPONENT1oUTLETnODEnAME)|(sHELLcOLLECTORnAME1)|(sHELLcOLLECTORsURFnAME1)|(sHELLcOLLECTORiNLETnODEnAME1)|(sHELLcOLLECTORoUTLETnODEnAME1)/ {
	print
	}' FINISHED${args[0]} > $arrayArea${args[0]}
if [ "$?" -ne "0" ]; then
	echo
	echo "ERROR: problem in branch block incremented replacement"
fi
	