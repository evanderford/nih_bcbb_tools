# Author: Elliott Vanderford
# Prepares pdb structure for rigid docking in Situs
#
# Usage: vmd mdff_solvent_step1.tcl <xxx.pdb>
#
#   where xxx.pdb = initial pdb structure filename
#
# Inputs:
#
#   xxx.pdb (initial pdb structure)
#
# Outputs:
#
#   autopsf.psf
#   autopsf.pdb
#   gridpdb.pdb
#   extrabonds.txt
#   extrabonds-cispeptide.txt
#   extrabonds-chirality.txt

# Loads initial pdb
set name [lindex $argv 0]
mol new $name

# Generates psf file 'initial_psf.psf' with autopsf package
package require autopsf
autopsf -mol 0 -prefix autopsf

quit
