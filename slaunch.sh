#!/usr/bin/env bash

PARAMS=""

help_msg="Usage: slaunch [options] [--] CMD ...\n
\n
CMD: the actual command to submit. If CMD has its own arguments and flags, you may want to double-quote
     your command, or use the -- separator.\n
\n
Options:\n
  -p|--partition\t\tPartition type. Default: RM. Other values: RM-shared, etc\n
  -J|--job-name\t\tThe name of the job\n
  -A|--account\t\tCluster charge ID\n
  -T|--wall-time\t\tWall time. Must be in the format: HH:MM:SS\n
  -t|--time-min\t\tMinimal wall time\n
  --ntasks-per-node\tNumber of tasks per node. Usually there should be exactly one task per node\n
  -n|--ntasks\t\t\tThe total number of tasks over all nodes\n
  -w|--work-dir\t\tWorking directory\n
  -o|--output-dir\tThe output directory for redirected the standard IO and error stream\n
  -P|--output-pattern\tOutput file naming pattern\n
  --mail-addr\t\tEmail address for job event notifications\n
  --mail-type\t\tEmail notification types\n
  -d|--dry-run\t\tDry run without actually submitting the job\n
  -s|--script\t\tSave the generated script to file\n
"

# Import config files from ~/.config/slaunch
config_file="$HOME/.config/slaunch.config"
if [ -f $config_file ]; then
  source $config_file
fi

while (("$#")); do
  case "$1" in
  -p | --partition)
    partition=$2
    shift 2
    ;;
  -J | --job-name)
    job_name=$2
    shift 2
    ;;
  -A | --account)
    account=$2
    shift 2
    ;;
  -t | --wall-time)
    wall_time=$2
    shift 2
    ;;
  -T | --time-min)
    time_min=$2
    shift 2
    ;;
  --ntasks-per-node)
    ntasks_per_node=$2
    shift 2
    ;;
  -n | --ntasks)
    ntasks=$2
    shift 2
    ;;
  -w | --work-dir)
    work_dir=$2
    shift 2
    ;;
  --mail-addr)
    mail_addr=$2
    shift 2
    ;;
  --mail-type)
    mail_type=$2
    shift 2
    ;;
  -o | --output-dir)
    output_dir=$2
    shift 2
    ;;
  -P | --output-pattern)
    output_pattern=$2
    shift 2
    ;;
  -d | --dry-run)
    dry_run=1
    shift
    ;;
  -s | --script)
    save_script=$2
    shift 2
    ;;
  -h | --help)
    echo -e $help_msg
    exit 0
    ;;
  --) # end argument parsing
    shift
    PARAMS="$PARAMS $*"
    break
    ;;
  -* | --*=) # unsupported flags
    echo "Error: Unsupported flag $1" >&2
    exit 1
    ;;
  *) # preserve positional arguments
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done
# set positional arguments in their proper place
set -- "$PARAMS"

# Write the temporary SLURM job-submission file
out_file=$(mktemp --suffix .sh)
echo "#!/bin/bash" >$out_file
echo "#SBATCH -N 1" >>$out_file
echo "#SBATCH -C EGRESS" >>$out_file


read -r -d '' sbatch_script <<- EOM
#!/bin/bash
#SBATCH -N 1
EOM

if [ ! -z $partition ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH -p $partition
EOM
fi


if [ ! -z $job_name ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --job-name $job_name
EOM
fi

if [ ! -z $account ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --account $account
EOM
fi

if [ ! -z $wall_time ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --time $wall_time
EOM
fi

if [ ! -z $time_min ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --time-min $time_min
EOM
fi

if [ ! -z $ntasks_per_node ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --ntasks-per-node $ntasks_per_node
EOM
fi

if [ ! -z $ntasks ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --ntasks $ntasks
EOM
fi

if [ ! -z $mail_addr ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --mail-user $mail_addr
EOM
fi

if [ ! -z $mail_type ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --mail-type $mail_type
EOM
fi

if [ -z $output_pattern ]
then
  output_pattern="%j-%x"
fi

if [ ! -z $output_dir ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --output $output_dir/$output_pattern.log
#SBATCH --error $output_dir/$output_pattern.err
EOM
fi

if [ ! -z $work_dir ]
then
read -r -d '' sbatch_script <<- EOM
$sbatch_script
#SBATCH --chdir $work_dir
EOM
fi

read -r -d '' sbatch_script <<- EOM
$sbatch_script

set -euo pipefail
IFS=$'\n\t'
set -x

$PARAMS
EOM

read -r -d '' -t 0.1 -s pipe_input

read -r -d '' sbatch_script <<- EOM
$sbatch_script

$pipe_input
EOM

echo "$sbatch_script"


if [ -z $dry_run ]
then
sbatch <<- HEADER
$sbatch_script
HEADER
fi

exit 0