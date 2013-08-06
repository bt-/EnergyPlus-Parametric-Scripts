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
