# MDFF Pipeline (for use on Biowulf HPC)

## Input files

* `xxx.pdb`, the protein structure you want to use
* `xxx.mrc`, the cryo-EM map (in .mrc format) that you want to use

## Instructions

### Preparation

For this pipeline, you will need to be logged in to the NIH Biowulf HPC cluster.

Download the files in this directory (folder), then place your desired input files (`xxx.pdb` and `xxx.mrc`) in the same directory.

You should now have the following files in your directory:
* `xxx.pdb`
* `xxx.mrc`
* `mdff_pipeline_biowulf.sh`
* `mdff_solvent_step1.tcl`
* `mdff_solvent_step2.tcl`
* `mdff_solvent_step3.sb`

### Running an interactive job

Next, you will need to start an interactive job on Biowulf. To do this, type

    sinteractive

into the command line. Wait for a few lines of text to indicate that you are up and running.

### Executing the MDFF pipeline script

NOTE: Before you do this step, consider whether you want the MDFF job to be submitted automatically or if you want to do so manually. If you want to submit the job yourself (harder but more customizable), read on. If you want the HPC job to be submitted automatically, skip down to the "Submitting MDFF job on Biowulf automatically (option 2)" and follow the instructions there; after that, you'll come back up here and do this part.

It is now time for you to run the pipeline. To do so, type

    ./mdff_pipeline_biowulf.sh -i xxx.pdb -m xxx.mrc -r your_resolution_here

into the command line, where `xxx.pdb` and `xxx.mrc` are your input files, and your_resolution_here is the resolution of the cryo-EM map.

For example, if my crystal structure were 1abc.pdb, my cryo-EM map file were map.mrc, and my resolution were 5.0 Å, I would type

    ./mdff_pipeline_biowulf.sh -i 1abc.pdb -m map.mrc -r 5.0

### Submitting MDFF job on Biowulf manually (option 1)

Now that you've run the script, you now have all the necessary input files for an MDFF job. All the files you'll need are in the `mdff_files/` directory. Enter that directory by typing

    cd mdff_files/

and you'll notice a couple files entitled `mdff_run-step1.namd` and `mdff_run-step2.namd`. These are the files you'll call with the NAMD program.

Additionally, if you want to customize the parameters of your MDFF simulation, these are the files you'll want to edit.

You will need to load NAMD on Biowulf by typing

    module load NAMD/2.12-openmpi

The lines you'll need to add to a batch submission file will be

    namd2 mdff_run-step1.namd > mdff_run-step1.log
    namd2 mdff_run-step2.namd > mdff_run-step2.log

You'll then need to edit the batch file to specify things like walltime and # of CPU's, then you'll execute your batch file.

If that sounds too complex for you, there's...

### Submitting MDFF job on Biowulf automatically (option 2)

Within the `mdff_pipeline_biowulf.sh` file, find the lines (271-272)

    #cd namd_files/
    #sbatch mdff_solvent_step3.sb

Now delete the hashes at the beginning of each of these lines. Save the file and get back to where you were before. Now, go back to the beginning of this section where it says "It is now time for you to run the pipeline" and start from there.

### After MDFF run has completed

Once your HPC job is complete, you'll have a lot of files to sift through. The important ones are:

* `ionized.psf`
* `ionized.pdb`
* `mdff_run-step1.dcd`
* `mdff_run-step2.dcd`

The "ionized" files are your starting configurations, and the `.dcd` files are the trajectories that MDFF produced.

To view your trajectory, it's probably best to download these files to a local machine. Then, using VMD, you can execute

	vmd -f ionized.psf ionized.pdb mdff_run-step1.dcd mdff_run-step2.dcd

in the command line.

Note: turning solvent molecules off makes visualization 100x easier.

---

## Limitations/Hangups

### Map file format

The cryo-EM map must be in `.mrc` format. You can use Situs or EMAN2 to convert between map formats easily.

### Symmetry

If your `.pdb` file needs to be replicated around an axis of symmetry to fit in the `.mrc` file, you will need to do this before running the MDFF pipeline.

### Authority to execute script

If you do not have the correct permissions to run `mdff_pipeline_biowulf.sh`, try

    chmod u+x mdff_pipeline_biowulf.sh
