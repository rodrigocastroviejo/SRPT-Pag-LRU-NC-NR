#!/bin/bash -
#===============================================================================
#
#          FILE: prueba.sh
#
#         USAGE: ./prueba.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 24/04/23 11:33:17
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

marcosActuales=()
for x in $(ls); do

	marcosActuales+=($x)
done

for ind in ${!marcosActuales[*]};do
           mar=${marcosActuales[$ind]}
	   echo $mar
	   echo $ind
       done


