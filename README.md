# slaunch: SLURM jobs take off easily

slaunch is a tiny shell script helping you to start jobs in SLURM without all the hassel. It is originally inspired by Yaping's ssubexc scripts, with several additional features. slaunch has been tested on PSC Bridges nodes. It should work, at least in theory, in other environments as long as they use SLURM as the workload manager.

## Getting Started

A quick glance

```
slaunch -- do_something_fancy -i input.file
```

The above command will immediately submit a job to the SLURM queue, which runs `do_something_fancy -i input.file`

### Features overview

- Provides a bunch of options and flags enabling job submission tweaks with ease.
- Dry run mode: review your jobs prior to submission.
- Optionally loads the configuration file, in which you may place common settings and save some typing.
- By default, SLURM redirects job standard output to text files located in the directory where you run `sbatch` (this behavior can be changed through `sbatch` options). Without prudent handling, it leads to output files scattering all over the file system, which may not be what you want. With slaunch, you can specify a directory to store SLURM output files.
- In addition to centralized output files, shell scripts generated by slaunch will also be placed in the directory. I find this practice very useful for troubleshooting and reviewing purposes.
- Can be run from any directory, even where you don't have the write permission.

### Prerequisites

slaunch requires nothing special. A standard bash environment is more than enough.

### Installation

Clone the git repository: `git clone https://github.com/haizi-zh/slaunch.git`

Then copy (or make a symolic link) slaunch.sh to anywhere in your `$PATH`. We recommend placing it in: `$HOME/.local/bin`, following the guidance of [PEP 370 -- Per user site-packages directory](https://www.python.org/dev/peps/pep-0370/) and [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

(Optional) Create the configuration file:

```
mkdir -p $HOME/.config
touch $HOME/.config/slaunch.config
```

See Configuration below for more details.

## Usage

`slaunch [options] -- commands_to_run`

### Examples

The following command dry-runs a job submission, which converts `input.bam` to `output.bam`, using an RM-shared instance with 16 cores.

`slaunch --dry-run -p RM-shared --ntasks-per-node 16 -- samtools view -@ 16 -b input.sam > output.bam`

The following command submits a similar job, with output redirected to a certain directory:

`slaunch -p RM-shared --ntasks-per-node 16 -w $HOME/slurm_output -- samtools view -@ 16 -b input.sam > output.bam`

### Command line arguments

`-p|--partition`: Specify the partition type. Default: RM. Other values: RM-shared, etc

`-J|--job-name`: Name your SLURM job.

`--dry-run`: When set, slaunch will print the shell script it generates, without actually submitting the job. This is a good way for reviewing the job submission.

`-w|--work-dir`: Set the working directory of the batch script to directory before it is executed. See `-D, --chdir=<directory>` at [sbatch man page](https://slurm.schedmd.com/sbatch.html).

`-o|--output-dir`: Set the output directory so that:

1. Job standard outputs and error messages will be redirected here. The file name is `slurm-{job id}-{user name}-{job name}.out`
2. Generated shell scripts will be placed here. The file name is `slurm-{job id}.sh`

`-h|--help`: Print a usage message summarizing the most useful command-line options.

Other options: see [sbatch man page](https://slurm.schedmd.com/sbatch.html) for the following settings:

- `-t|--wall-time`
- `--ntasks-per-node`
- `-n|--ntasks`
- `--email-addr`

### Configuration

Upon startup, slaunch will try to load the configuration file at: `$HOME/.config/slaunch.config`. Notice: all settings in the configuration file CAN BE OVERRIDDEN by corresponding command line arguments.

The following is a self-explanatory example configuration file.

```bash
# Uncomment following items to take effect
#
# partition=RM-shared
# job_name=
# email_addr=
# wall_time=12:00:00
# ntasks=
# ntasks_per_node=
# work_dir=
# output_dir=
```

You may want to place some common settings here, such as `email_addr`, `output_dir`, `partition`, etc.

## Contributors

Thanks to the following people who have contributed to this project:

- Yaping Liu
- Haizi Zheng

## Contact

If you want to contact me you can reach me at haizi.zheng@cchmc.org.

## License

This project uses the following license: MIT License.
