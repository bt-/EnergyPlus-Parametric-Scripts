#!/bin/bash

args=("$@")


awk -F, '
	!/Date/ {
		load += $7
		}

	!/Date/{
		solar += $2
		}

	END {
		SF = -solar/load
		printf("%1.3f\n", SF)
		}' ${args[0]}${args[1]}".csv"
