# Author: Elliott Vanderford
# Prepares MDFF input files for NAMD
#
#  vmd -dispdev text -eofexit -e mdff_solvent_step2.tcl -args <psf> <pdb> <em_box_x> <em_box_y> <em_box_z>
#
# Inputs:
#   $psf = autopsf_formatted_autopsf.psf
#   $pdb = col_best_001.pdb
#
# Outputs:
#   mdff_run-step1.namd
#   mdff_run-step2.namd

# Assign variable names to command line inputs
set psf [lindex $argv 0]
set pdb [lindex $argv 1]
set x [lindex $argv 2]
set y [lindex $argv 3]
set z [lindex $argv 4]

# Load rigid-docked structure
mol new $psf
mol addfile $pdb

# Create water box with 20 angstrom padding on all sides (outputs solvate.<psf,pdb>)
#package require solvate
#solvate autopsf.psf $pdb -o solvate -t 20

# Create water box slightly larger than EM map grid
set x_new [expr $x + 2]
set y_new [expr $y + 2]
set z_new [expr $z + 2]

set xmin [expr $x_new * -0.5]
set xmax [expr $x_new * 0.5]
set ymin [expr $y_new * -0.5]
set ymax [expr $y_new * 0.5]
set zmin [expr $z_new * -0.5]
set zmax [expr $z_new * 0.5]

package require solvate
set minmax [list [list $xmin $ymin $zmin] [list $xmax $ymax $zmax]]
solvate $psf $pdb -o solvate -minmax $minmax

# Add ions to neutralize solution (outputs ionized.<psf,pdb>)
package require autoionize
autoionize -psf solvate.psf -pdb solvate.pdb -neutralize

# Generates pdb file containing per-atom scaling factors set to atomic mass
package require mdff
mdff gridpdb -psf ionized.psf -pdb ionized.pdb -o ionized-grid.pdb

# Generates secondary structure restraints
package require ssrestraints
ssrestraints -psf ionized.psf -pdb ionized.pdb -o extrabonds.txt -hbonds
mol new ionized.psf
mol addfile ionized.pdb
package require cispeptide
cispeptide restrain -o cispeptide.txt
package require chirality
chirality restrain -o chirality.txt

# Converts density map to MDFF potential
mdff griddx -i map.situs -o map-grid.dx

# Generates MDFF production file (mdff_run-step1.namd); 2 ns
mdff setup -pbc -o mdff_run -psf ionized.psf -pdb ionized.pdb -griddx map-grid.dx \
-gridpdb ionized-grid.pdb -extrab {extrabonds.txt cispeptide.txt chirality.txt} \
-gscale 0.3 -numsteps 1000000

# Generates post-hoc MDFF minimization file (mdff_run-step2.namd)
mdff setup -pbc -o mdff_run -psf ionized.psf -pdb ionized.pdb -griddx map-grid.dx \
-gridpdb ionized-grid.pdb -extrab {extrabonds.txt cispeptide.txt chirality.txt} \
-gscale 10 -minsteps 2000 -numsteps 0 -step 2

quit
