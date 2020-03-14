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
  -t|--wall-time\t\tWall time. Must be in the format: HH:MM:SS\n
  --ntasks-per-node\tNumber of tasks per node. Usually there should be exactly one task per node\n
  -n\t\t\tThe total number of tasks over all nodes\n
  -w|--work-dir\t\tWorking directory\n
  -o|--output-dir\tThe output directory for redirected the standard IO and error stream\n
  --email-addr\t\tEmail address for job event notifications\n
  --dry-run\t\tDry run without actually submitting the job\n
"

# Import config files from ~/.config/slaunch
config_file="$HOME/.config/slaunch.config"
if [ -f $config_file ]; then
  source $config_file
fi

while (( "$#" )); do
  case "$1" in
    -p|--partition)
      partition=$2
      shift 2
      ;;
    -J|--job-name)
      job_name=$2
      shift 2
      ;;
    -t|--wall-time)
      wall_time=$2
      shift 2
      ;;
    --ntasks-per-node)
      ntasks_per_node=$2
      shift 2
      ;;
    -n|--ntasks)
      ntasks=$2
      shift 2
      ;;
    -w|--work-dir)
      work_dir=$2
      shift 2
      ;;
    --email-addr)
      email_addr=$2
      shift 2
      ;;
    -o|--output-dir)
      output_dir=$2
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      echo -e $help_msg
      exit 0
      ;;
    --) # end argument parsing
      shift
      PARAMS="$PARAMS $*"
      break
      ;;
    -*|--*=) # unsupported flags
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
eval set -- "$PARAMS"

# Write the temporary SLURM job-submission file
out_file_id=$(date +%s)_$RANDOM
out_file="/tmp/slurm_tmp.$out_file_id.sh"
echo "#!/bin/sh" > $out_file
echo "#SBATCH -N 1" >> $out_file
echo "#SBATCH -C EGRESS" >> $out_file

if [ ! -z $partition ]; then
  echo "#SBATCH -p $partition" >> $out_file
fi

if [ ! -z $job_name ]; then
  echo "#SBATCH --job-name $job_name" >> $out_file
fi

if [ ! -z $wall_time ]; then
  echo "#SBATCH -t $wall_time" >> $out_file
fi

if [ ! -z $ntasks_per_node ]; then
  echo "#SBATCH --ntasks-per-node $ntasks_per_node" >> $out_file
fi

if [ ! -z $ntasks ]; then
  echo "#SBATCH --ntasks $ntasks" >> $out_file
fi

if [ ! -z $email_addr ]; then
  echo "#SBATCH --mail-type ALL" >> $out_file
  echo "#SBATCH --mail-user $email_addr" >> $out_file
fi

if [ ! -z $output_dir ]; then
  echo "#SBATCH --output $output_dir/slurm-%j-%u-%x.out" >> $out_file
  echo "#SBATCH --error $output_dir/slurm-%j-%u-%x.out" >> $out_file
fi

if [ ! -z $work_dir ]; then
  echo "#SBATCH --chdir $work_dir" >> $out_file
fi

if [ ! -z $work_dir ]; then
  echo "#SBATCH --chdir $work_dir" >> $out_file
fi

echo -e "\nset -x" >> $out_file

echo "" >> $out_file
echo $PARAMS >> $out_file

echo -e "SLURM script generated:\n"
echo -e "========"

cat $out_file

echo -e "========\n"
echo -e "SLURM script ends here\n"

if [ -z $dry_run ]; then
  sbatch_output=$(sbatch $out_file)
  echo $sbatch_output

  if [ ! -z $output_dir ]; then
    job_id=$(echo $sbatch_output | sed -e 's/Submitted batch job \([0-9]\+\).*/\1/')
    cat $out_file > "$output_dir/slurm-$job_id.sh"
  fi
fi

unlink $out_file