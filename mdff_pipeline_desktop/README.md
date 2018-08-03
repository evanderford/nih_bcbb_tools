# MDFF Pipeline (for use on local desktop)

## Input files

`xxx.pdb`, the protein structure you want to use
`xxx.mrc`, the cryo-EM map (in .mrc format) that you want to use

## Instructions

### Necessary software

To run this pipeline locally, you must have the following software installed (and in your path):

* VMD 1.9.3 (or later)
* Situs 2.8 (or later)

### Preparation

Download the files in this directory (folder), then place your desired input files (`xxx.pdb` and `xxx.mrc`) in the same directory.

You should now have the following files in your directory:
* `xxx.pdb`
* `xxx.mrc`
* `mdff_pipeline.sh`
* `mdff_solvent_step1.tcl`
* `mdff_solvent_step2.tcl`

### Executing the MDFF pipeline script

It is now time for you to run the pipeline. To do so, type

    ./mdff_pipeline.sh -i xxx.pdb -m xxx.mrc -r your_resolution_here

into the command line, where `xxx.pdb` and `xxx.mrc` are your input files, and your_resolution_here is the resolution of the cryo-EM map.

For example, if my crystal structure were 1abc.pdb, my cryo-EM map file were map.mrc, and my resolution were 5.0 Å, I would type

    ./mdff_pipeline.sh -i 1abc.pdb -m map.mrc -r 5.0

### Running the MDFF job

Now you have all the necessary input files to run an MDFF job. These files are in a directory entitled `mdff_files/`

If you want to run this on an HPC cluster, you'll need to copy the `mdff_files/` directory there. Then you can execute

    namd2 mdff_run-step1.namd > mdff_run-step1.log
    namd2 mdff_run-step2.namd > mdff_run-step2.log

within some type of batch submission file to start the MDFF job.

If you want to run locally, make sure you have NAMD available then run

    namd2 mdff_run-step1.namd > mdff_run-step1.log

After this is finished, run

    namd2 mdff_run-step2.namd > mdff_run-step2.log

---

## Limitations/Hangups

### Map file format

The cryo-EM map must be in `.mrc` format. You can use Situs or EMAN2 to convert between map formats easily.

### Symmetry

If your `.pdb` file needs to be replicated around an axis of symmetry to fit in the `.mrc` file, you will need to do this before running the MDFF pipeline.

### Authority to execute script

If you do not have the correct permissions to run `mdff_pipeline.sh`, try

    chmod u+x mdff_pipeline.sh
