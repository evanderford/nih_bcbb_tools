#!/bin/bash
#
# Author: Elliott Vanderford
# Pipeline for MDFF submission files
#
# Usage ./mdff_pipeline.sh -i <xxx.pdb> -m <xxx.mrc> -r <###>
#
#   xxx.pdb = initial structure file
#   xxx.mrc = cryoEM map file
#   ### = cryoEM map resolution (in Angstroms)
#
# Inputs:
#
#   xxx.pdb
#   xxx.mrc
#

module load vmd/1.9.3
module load situs/2.8

# Creates flag options for input file, map file, and resolution
while getopts i:m:r: option
do
case "${option}"
in
i) INPUT=${OPTARG};;
m) MAP=${OPTARG};;
r) RES=${OPTARG};;
esac
done

# Prepares pdb structure for rigid docking in Situs
vmd -dispdev text -e mdff_solvent_step1.tcl -args $INPUT

# Performs rigid-body docking with Situs
    # Scale and shift density values
echo 100 | volhist $MAP > 1.txt
a=$(grep "min:" 1.txt | cut -d ' ' -f 5)
b=${a#-}

    # Convert to situs file
( echo 100; echo 1; echo $b ) | volhist $MAP map.situs

    # Run colores
colores map.situs autopsf_formatted_autopsf.pdb -res $RES

    # Get x, y, and z dimensions of EM grid box
x=$(grep "X length" 1.txt | tr -s ' ' | cut -d ' ' -f 5)
y=$(grep "Y length" 1.txt | tr -s ' ' | cut -d ' ' -f 5)
z=$(grep "Z length" 1.txt | tr -s ' ' | cut -d ' ' -f 5)

wait %1

# Prepares MDFF input files for NAMD (includes solvation, creation of grid files, generation of restraints)
vmd -dispdev text -e mdff_solvent_step2.tcl -args autopsf_formatted_autopsf.psf col_best_001.pdb $x $y $z

# Adds water/ion parameter file to NAMD input files
sed -i.bak '/par_all36_prot.prm/ a parameters \/home\/vanderfordek\/tools\/toppar_water_ions_namd.str' mdff_run-step1.namd
sed -i.bak '/par_all36_prot.prm/ a parameters \/home\/vanderfordek\/tools\/toppar_water_ions_namd.str' mdff_run-step2.namd 

# Submits NAMD MDFF files to Biowulf; 4 nodes (112 threads); walltime of 10 days
#sbatch mdff_solvent_step3.sb

echo "done"
