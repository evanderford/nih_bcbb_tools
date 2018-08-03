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

# Creates correct parameter file
echo '* Toplogy and parameter information for water and ions.
*

!Testcase
!test_water_ions.inp

! IMPORTANT NOTE: this file contains NBFixes between carboxylates and sodium,
! which will only apply if the main files containing carboxylate atom types
! have been read in first!

!references
!
!TIP3P water model
!
!W.L. Jorgensen; J.Chandrasekhar; J.D. Madura; R.W. Impey;
!M.L. Klein; "Comparison of simple potential functions for
!simulating liquid water", J. Chem. Phys. 79 926-935 (1983).
!
!IONS
!
!Ions from Roux and coworkers
!
!Beglov, D. and Roux, B., Finite Representation of an Infinite
!Bulk System: Solvent Boundary Potential for Computer Simulations,
!Journal of Chemical Physics, 1994, 100: 9050-9063
!
!ZINC
!
!Stote, R.H. and Karplus, M. Zinc Binding in Proteins and
!Solution: A Simple but Accurate Nonbonded Representation, PROTEINS:
!Structure, Function, and Genetics 23:12-31 (1995)

!test "append" to determine if previous toppar files have been read and
!add append to "read rtf card" if true
!set nat ?NATC
!set app
!We are exploiting what is arguably a bug in the parser. On the left hand side,
!the quotes have priority, so NAT is correctly substituted. On the right hand
!side, the ? has priority and NATC" (sic) is not a valid substitution...
!if "@NAT" ne "?NATC" if @nat ne 0 set app append

!read rtf card @app
* Topology for water and ions
*
!31  1

ATOMS
MASS  1   HT    1.00800 ! TIPS3P WATER HYDROGEN
MASS  2   HX    1.00800 ! hydroxide hydrogen
MASS  3   OT   15.99940 ! TIPS3P WATER OXYGEN
MASS  4   OX   15.99940 ! hydroxide oxygen
MASS  5   LIT  	6.94100 ! Lithium ion
MASS  6   SOD  22.98977 ! Sodium Ion
MASS  7   MG   24.30500 ! Magnesium Ion
MASS  8   POT  39.09830 ! Potassium Ion
MASS  9   CAL  40.08000 ! Calcium Ion
MASS  10  RUB  85.46780 ! Rubidium Ion
MASS  11  CES 132.90545 ! Cesium Ion
MASS  12  BAR 137.32700 ! Barium Ion
MASS  13  ZN   65.37000 ! zinc (II) cation
MASS  14  CAD 112.41100 ! cadmium (II) cation
MASS  15  CLA  35.45000 ! Chloride Ion

BONDS
!
!V(bond) = Kb(b - b0)**2
!
!Kb: kcal/mole/A**2
!b0: A
!
!atom type Kb          b0
!
HT    HT      0.0       1.5139  ! from TIPS3P geometry (for SHAKE w/PARAM)
HT    OT    450.0       0.9572  ! from TIPS3P geometry
OX    HX    545.0       0.9700  ! hydroxide ion

ANGLES
!
!V(angle) = Ktheta(Theta - Theta0)**2
!
!V(Urey-Bradley) = Kub(S - S0)**2
!
!Ktheta: kcal/mole/rad**2
!Theta0: degrees
!Kub: kcal/mole/A**2 (Urey-Bradley)
!S0: A
!
!atom types     Ktheta    Theta0   Kub     S0
!
HT   OT   HT     55.0      104.52   ! FROM TIPS3P GEOMETRY

DIHEDRALS
!
!V(dihedral) = Kchi(1 + cos(n(chi) - delta))
!
!Kchi: kcal/mole
!n: multiplicity
!delta: degrees
!
!atom types             Kchi    n   delta
!


!
IMPROPER
!
!V(improper) = Kpsi(psi - psi0)**2
!
!Kpsi: kcal/mole/rad**2
!psi0: degrees
!note that the second column of numbers (0) is ignored
!
!atom types           Kpsi                   psi0
!

NONBONDED nbxmod  5 atom cdiel shift vatom vdistance vswitch -
cutnb 14.0 ctofnb 12.0 ctonnb 10.0 eps 1.0 e14fac 1.0 wmin 1.5

!TIP3P LJ parameters
HT       0.0       -0.046     0.2245
OT       0.0       -0.1521    1.7682

!for hydroxide
OX     0.000000  -0.120000     1.700000 ! ALLOW   POL ION
                ! JG 8/27/89
HX     0.000000  -0.046000     0.224500 ! ALLOW PEP POL SUL ARO ALC
                ! same as TIP3P hydrogen, adm jr., 7/20/89

!ions
LIT      0.0      -0.00233       1.2975  ! Lithium
                   ! From S Noskov, target ddG(Li-Na) was 23-26.0 kcal/mol (see JPC B, Lamoureux&Roux,2006)
SOD      0.0       -0.0469    1.41075  ! new CHARMM Sodium
                   ! ddG of -18.6 kcal/mol with K+ from S. Noskov
MG       0.0       -0.0150    1.18500   ! Magnesium
                   ! B. Roux dA = -441.65
POT      0.0       -0.0870    1.76375   ! Potassium
                   ! D. Beglovd and B. Roux, dA=-82.36+2.8 = -79.56 kca/mol
CAL      0.0       -0.120      1.367    ! Calcium
                   ! S. Marchand and B. Roux, dA = -384.8 kcal/mol
RUB      0.0000    -0.15      1.90      ! Rubidium
                   ! delta A with respect to POT is +6.0 kcal/mol in bulk water
CES      0.0       -0.1900    2.100     ! Cesium
                   ! delta A with respect to POT is +12.0 kcal/mol
BAR      0.0       -0.150     1.890     ! Barium
                   ! B. Roux, dA = dA[calcium] + 64.2 kcal/mol
ZN     0.000000  -0.250000     1.090000 ! Zinc
                   ! RHS March 18, 1990
CAD    0.000000  -0.120000     1.357000 ! Cadmium
                   ! S. Marchand and B. Roux, from delta delta G
CLA      0.0       -0.150      2.27     ! Chloride
                   ! D. Beglovd and B. Roux, dA=-83.87+4.46 = -79.40 kcal/mol

NBFIX
!              Emin         Rmin
!            (kcal/mol)     (A)
SOD    CLA      -0.083875   3.731 !  From osmotic pressure calibration, J. Phys.Chem.Lett. 1:183-189
POT    CLA      -0.114236   4.081 !  From osmotic pressure calibration, J. Phys.Chem.Lett. 1:183-189
END

! The following section contains NBFixes for sodium interacting with
! carboxylate oxygens of various CHARMM force fields. It will generate
! level -1 warnings whenever any of these force fields have not been
! read prior to the current stream file. Since we do not want to force
! the user to always read all the force fields, we are suppressing the
! warnings. The only side effect is that you will have "most severe
! warning was at level 0" at the end of your output. Also note that
! the user is responsible for reading the current file last if they
! want the NBFixes to apply. A more elegant solution would require new
! features to be added to CHARMM.
! parallel fix, to avoid duplicated messages in the log
!set para
!if ?NUMNODE gt 1 set para node 0

!set wrn ?WRNLEV
! Some versions of CHARMM do not seem to initialize wrnlev...
!if "@WRN" eq "?WRNLEV" set wrn 5
!set bom ?bomlev
!WRNLEV -1 @PARA
!BOMLEV -1 @PARA
!read para card flex append
* NBFix between carboxylate and sodium
*

! These NBFixes will only apply if the main files have been read in first!!!
!NBFIX
!SOD    OC       -0.075020   3.190 ! For prot carboxylate groups
!SOD    OCL      -0.075020   3.190 ! For lipid carboxylate groups
!SOD    OC2D2    -0.075020   3.190 ! For carb carboxylate groups
!SOD    OG2D2    -0.075020   3.190 ! For CGenFF carboxylate groups
!END
!BOMLEV @bom @PARA
!WRNLEV @wrn @PARA

!return' > toppar_water_ions_namd.str

# Adds water/ion parameter file to NAMD input files
sed -i.bak '/par_all36_prot.prm/ a parameters toppar_water_ions_namd.str' mdff_run-step1.namd
sed -i.bak '/par_all36_prot.prm/ a parameters toppar_water_ions_namd.str' mdff_run-step2.namd

# Moves files to relevant places
mkdir namd_files
mv ionized* namd_files/
mv map-grid.dx namd_files/
mv extrabonds.txt namd_files/
mv cispeptide.txt namd_files/
mv chirality.txt namd_files/
mv par_all36_prot.prm namd_files/
mv toppar_water_ions_namd.str namd_files/
mv mdff_template.namd namd_files/
mv mdff_run-step* namd_files/
mv mdff_solvent_step3.sb namd_files/

# Submits NAMD MDFF files to Biowulf; 4 nodes (112 threads); walltime of 10 days
#cd namd_files/
#sbatch mdff_solvent_step3.sb

echo "done"
