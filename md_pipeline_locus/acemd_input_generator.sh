# Create ACEMD submission scripts
echo '# Configure time variables
set steps_min   50      ; # Number of steps to minimize
set steps_nvt   25000   ; # Number of steps for NVT
set steps_npt1  250000  ; # Number of steps for NPT with constraints
set steps_npt2  250000  ; # Number of steps for NPT without constraints
set numSteps    [expr $steps_nvt + $steps_npt1 + $steps_npt2]    ; # Total number of steps for the simulation.

# Set reusable variables
set inputname   input
set dir         /path/to/work/dir

#set outputname
set outputname  traf3_v1
set temperature 310
set logfreq     1000

# Set inputs
structure       ${dir}/cg_input.psf
coordinates     ${dir}/cg_input.pdb
parameters      ${dir}/par_all36_prot.prm
parameters      ${dir}/toppar_water_ions_namd.str

# Set outputs
energyfreq      $logfreq
restart         on
restartfreq     25000
restartname     $outputname.restart
outputname      $outputname
dcdfreq         25000
dcdfile         $outputname.dcd

# Set box dimensions, manually or via extendedsystem
celldimension   74.0 74.0 74.0

# Configure holonomic restraints
rigidbonds      all

# Configure integration
timestep        2
hydrogenscale   1

# Configure electrostatics
pme             on
pmegridsizex    90
pmegridsizey    72
pmegridsizez    90
pmegridspacing  1.0
cutoff          9
switching       on
switchdist      7.5
exclude         scaled1-4
1-4scaling      1.0
fullelectfrequency 2

# Configure thermostat
langevin        on
langevintemp    $temperature
langevindamping 1

# Configure barostat
berendsenpressure   on
berendsenpressuretarget 1.01325
berendsenpressurerelaxationtime  800

# Run minimization
minimize $steps_min
# Run simulation
run $numSteps

################################################################################
#### Tcl Settings (still part of input template)
################################################################################

tclforces on
tclforcesfreq   1

proc calcforces_init {} {
  global steps_nvt steps_min
  global steps_nvt steps_npt1 steps_npt2

  set t [ getstep ]
  if { $t == 0 } {
    puts "Running $steps_min steps of energy minimization"
  } else {
    puts "Restarting"
    if { $t < $steps_nvt } {
      puts "Running $steps_nvt steps of NVT"
      berendsenpressure off
      tclforcesfreq [expr $steps_nvt ]
    } elseif { $t < [expr $steps_nvt + $steps_npt1 ] } {
      puts "Running $steps_npt1 steps of NPTs"
      berendsenpressure on
      tclforcesfreq [expr $steps_nvt + $steps_npt1 ]
    } else {
      puts "Running $steps_npt2 steps of NPT without constraints"
      constraintsclaing 0.
    }
  }
}

proc calcforces {} {
  global steps_nvt steps_npt1 steps_npt2
  set t [ getstep ]


  if { $t == 1 } {
    puts "Running $steps_nvt steps of NVT"
    berendsenpressure off
    tclforcesfreq $steps_nvt
  }
  if { $t == $steps_nvt } {
    # turn barostat on
    puts "Running $steps_npt1 steps of NPT"
    berendsenpressure on
    tclforcesfreq [expr $steps_nvt + $steps_npt1 ]
  }
  if { $t == [expr $steps_nvt + $steps_npt1] } {
    # turn constraints off
    constraintscaling  0.
    puts "Running $steps_npt2 steps of NPT without constraints"
  }

}' > acemd_equil.inp

echo '# Configure time variables
set numSteps    125000000  ; # Total number of steps for the simulation.

# Set reusable variables
set logfreq     2500
set dcdfreq     25000
set resfreq     250000
set dir         /path/to/work/dir

#set outputname
set outputname  output
set temperature 310
set logfreq     $logfreq

# Set inputs
structure       ${dir}/cg_input.psf
coordinates     ${dir}/cg_input.pdb
parameters      ${dir}/par_all36_prot.prm
parameters      ${dir}/toppar_water_ions_namd.str

# Set outputs
energyfreq      $logfreq
restart         on
restartfreq     $resfreq
restartname     $outputname.restart
outputname      $outputname
dcdfreq         $dcdfreq
dcdfile         $outputname.dcd

# Starting velocity and coordinate files
bincoordinates  ${outputname}.restart.coor
binindex        ${outputname}.restart.idx
binvelocities   ${outputname}.restart.vel

# Set box dimensions, manually or via extendedsystem
extendedsystem  ${outputname}.restart.xsc

# Configure holonomic restraints
rigidbonds      all

# Configure integration
timestep        4
hydrogenscale   4

# Configure electrostatics
 pme             on
 pmegridsizex    90
 pmegridsizey    72
 pmegridsizez    90
 pmegridspacing  1.0
#pmefreq         2
 cutoff          9
 switching       on
 switchdist      7.5
 exclude         scaled1-4
 1-4scaling      1.0
 fullelectfrequency 2

# Configure thermostat
langevin        on
langevintemp    $temperature
langevindamping 1

# Configure barostat
berendsenpressure   off
#berendsenpressuretarget 1.01325
#berendsenpressurerelaxationtime  800

# Run simulation
run $numSteps' > acemd_prod.inp
