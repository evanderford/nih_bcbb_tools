#!/bin/bash
#
# Usage: ./md_pipeline.sh
#
# Required files (included):   md_pipeline.sh; md_pipeline.yaml; charmm_guisubmitter.py; acemd_input_generator.sh;
#                              acemd_input_editor.py; toppar_water_ions_namd.str; par_all36_prot.prm
#
# MUST edit md_pipeine.yaml config file

# Run CHARMM-GUI submission script
python charmmgui_submitter.py

# Wait for download to complete
wd="$PWD/charmm-gui.tgz"

while ! test -f $wd; do
    sleep 20
    echo "Downloading..."
done

echo "Download complete"

# Unzip charmm-gui.tgz
tar xzf charmm-gui.tgz
#rm -f charmm-gui.tgz

# Move relevant files to work directory
cd charmm-gui/
cp step3_pbcsetup.psf ../cg_input.psf
cp step3_pbcsetup.pdb ../cg_input.pdb
cp step3_pbcsetup.str ../cg_input.str
cd ../

# Run ACEMD input generator
chmod u+x acemd_input_generator.sh
./acemd_input_generator.sh

echo "ACEMD inputs generated"

# Edit box dimensions
x=$(grep "SET A =" cg_input.str | tr -s ' ' | cut -d ' ' -f 5)
y=$(grep "SET B =" cg_input.str | tr -s ' ' | cut -d ' ' -f 5)
z=$(grep "SET C =" cg_input.str | tr -s ' ' | cut -d ' ' -f 5)

sed -i.bak "s/celldimension .*/celldimension   $x $y $z/g" acemd_equil.inp

echo "Box dimensions updated"

# Run ACEMD input editor
cp acemd_equil.inp ./acemd_equil.bak
cp acemd_prod.inp ./acemd_prod.bak
python acemd_input_editor.py

echo "ACEMD input files updated"

mkdir misc/
mv cg_input.str misc/
mv *.bak misc/
mv charmm-gui.tgz misc/

echo "done"
