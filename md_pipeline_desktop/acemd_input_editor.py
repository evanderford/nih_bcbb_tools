# Edits and moves various ACEMD input files for the MD Pipeline

import fileinput
import shutil
import yaml
import re
import os

# Find and replace with regular expressions
def find_replace(filename, s, g):
    myfile = fileinput.FileInput(filename, inplace=True)
    for line in myfile:
        line = re.sub(s, g, line.rstrip())
        print(line)

# Load yaml config file
with open('md_pipeline.yaml', 'r') as yaml_file:
    dict = yaml.load(yaml_file)

# Creates disulfide bonds in pdb and psf if specified
disulfide_bonds = dict.get('disulfide_bonds')
if disulfide_bonds == True:
    tcl_file = open("disulfide.tcl", "w")
    tcl_file.write("package require psfgen\nresetpsf\nreadpsf cg_input.psf pdb cg_input.pdb \
    \nmol new cg_input.psf\nmol addfile cg_input.pdb\ntopology top_all36_prot.rtf\n")

    l = dict['disulfide_bond_list']

    if len(l) > 0:
        l_length = len(l)
        for x in range(0, l_length):
            innerlist = l[x]
            i_l = innerlist.split(' ')
            a = i_l[0]
            b = i_l[1]
            c = i_l[2]
            d = i_l[3]
            tcl_file = open("disulfide.tcl", "a")
            tcl_file.write("patch DISU %s:%s %s:%s\n" % (a, b, c, d))
            tcl_file.close()
    else:
        pass

    tcl_file = open("disulfide.tcl", "a")
    tcl_file.write("writepsf cg_input.psf\nwritepdb cg_input.pdb\nexit")
    tcl_file.close()

    os.system('vmd -dispdev text -e disulfide.tcl')
else:
    pass

# Replace acemd_equil.inp presets with custom values from md_pipeline.yaml config file
if 'output' in dict:
    output = dict.get('output')
    find_replace(filename='acemd_equil.inp', s='set outputname.*', g='set outputname  %s' % output)
else:
    pass

if 'minimization_num_steps' in dict:
    min_steps = dict.get('minimization_num_steps')
    find_replace(filename='acemd_equil.inp', s='set steps_min.*', g='set steps_min   %s' % min_steps)
else:
    pass

if 'nvt_num_steps' in dict:
    nvt_steps = dict.get('nvt_num_steps')
    find_replace(filename='acemd_equil.inp', s='set steps_nvt.*', g='set steps_nvt   %s' % nvt_steps)
else:
    pass

if 'npt1_num_steps' in dict:
    npt1_steps = dict.get('npt1_num_steps')
    find_replace(filename='acemd_equil.inp', s='set steps_npt1.*', g='set steps_npt1  %s' % npt1_steps)
else:
    pass

if 'npt2_num_steps' in dict:
    npt2_steps = dict.get('npt2_num_steps')
    find_replace(filename='acemd_equil.inp', s='set steps_npt2.*', g='set steps_npt2  %s' % npt2_steps)
else:
    pass

if 'temperature' in dict:
    temperature = dict.get('temperature')
    find_replace(filename='acemd_equil.inp', s='set temperature.*', g='set temperature %s' % temperature)
else:
    pass

if 'pme' in dict:
    pme = dict.get('pme')
    if pme == True:
        find_replace(filename='acemd_equil.inp', s='pme .*', g='pme             on')
    elif pme == False:
        find_replace(filename='acemd_equil.inp', s='pme .*', g='pme             off')
    else:
        pass
else:
    pass

if 'dcd_freq' in dict:
    dcd_freq = dict.get('dcd_freq')
    find_replace(filename='acemd_equil.inp', s='dcdfreq.*', g='dcdfreq         %s' % dcd_freq)
else:
    pass

if 'log_freq' in dict:
    log_freq = dict.get('log_freq')
    find_replace(filename='acemd_equil.inp', s='set logfreq.*', g='set logfreq     %s' % log_freq)
else:
    pass

if 'restart_freq' in dict:
    restart_freq = dict.get('restart_freq')
    find_replace(filename='acemd_equil.inp', s='restartfreq.*', g='restartfreq     %s' % restart_freq)
else:
    pass

# Replace acemd_prod.inp presets with custom values from md_pipeline.yaml config file
if 'output' in dict:
    output_prod = dict.get('output')
    find_replace(filename='acemd_prod.inp', s='set outputname.*', g='set outputname  %s' % output_prod)
else:
    pass

if 'production_num_steps' in dict:
    production_num_steps = dict.get('production_num_steps')
    find_replace(filename='acemd_prod.inp', s='set numSteps.*', g='set numSteps    %s' % production_num_steps)
else:
    pass

if 'temperature' in dict:
    temp_prod = dict.get('temperature')
    find_replace(filename='acemd_prod.inp', s='set temperature.*', g='set temperature %s' % temp_prod)
else:
    pass

if 'timestep' in dict:
    timestep_prod = dict.get('timestep')
    find_replace(filename='acemd_prod.inp', s='timestep.*', g='timestep        %s' % timestep_prod)
else:
    pass

if 'hydrogenscale' in dict:
    hydrogenscale_prod = dict.get('hydrogenscale')
    find_replace(filename='acemd_prod.inp', s='hydrogenscale.*', g='hydrogenscale   %s' % hydrogenscale_prod)
else:
    pass

if 'pme' in dict:
    pme_prod = dict.get('pme')
    if pme_prod == True:
        find_replace(filename='acemd_prod.inp', s='pme .*', g='pme             on')
    elif pme_prod == False:
        find_replace(filename='acemd_prod.inp', s='pme .*', g='pme             off')
    else:
        pass
else:
    pass

if 'thermostat' in dict:
    thermostat = dict.get('thermostat')
    if thermostat == True:
        find_replace(filename='acemd_prod.inp', s='langevin .*', g='langevin        on')
    elif pme_prod == False:
        find_replace(filename='acemd_prod.inp', s='langevin .*', g='langevin        off')
    else:
        pass
else:
    pass

if 'barostat' in dict:
    barostat = dict.get('barostat')
    if barostat == True:
        find_replace(filename='acemd_prod.inp', s='berendsenpressure .*', g='berendsenpressure   on')
    elif barostat == False:
        find_replace(filename='acemd_prod.inp', s='berendsenpressure .*', g='berendsenpressure   off')
    else:
        pass
else:
    pass

if 'dcd_freq' in dict:
    dcd_freq_prod = dict.get('dcd_freq')
    find_replace(filename='acemd_prod.inp', s='set dcdfreq.*', g='set dcdfreq         %s' % dcd_freq_prod)
else:
    pass

if 'log_freq' in dict:
    log_freq_prod = dict.get('log_freq')
    find_replace(filename='acemd_prod.inp', s='set logfreq.*', g='set logfreq     %s' % log_freq_prod)
else:
    pass

if 'restart_freq' in dict:
    restart_freq_prod = dict.get('restart_freq')
    find_replace(filename='acemd_prod.inp', s='set resfreq.*', g='set resfreq     %s' % restart_freq_prod)
else:
    pass

# Parse work directory from config file and edit input files accordingly
work_dir = dict.get('work_dir')
find_replace(filename='acemd_equil.inp', s='set dir.*', g='set dir         %s' % work_dir)
find_replace(filename='acemd_prod.inp', s='set dir.*', g='set dir         %s' % work_dir)

# Move parameter files to designated location
shutil.move("toppar_water_ions_namd.str", work_dir)
shutil.move("par_all36_prot.prm", work_dir)
shutil.move("acemd_equil.inp", work_dir)
shutil.move("acemd_prod.inp", work_dir)
shutil.copy("cg_input.psf", work_dir)
shutil.copy("cg_input.pdb", work_dir)
