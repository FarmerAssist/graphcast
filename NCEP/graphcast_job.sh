#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30  # Use all available CPU cores
#SBATCH --time=1:30:00  # Adjust this to your estimated run time
#SBATCH --job-name=graphcast
#SBATCH --output=gc_output.txt
#SBATCH --error=gc_error.txt
#SBATCH --partition=compute


# load necessary modules
module use /contrib/spack-stack/envs/ufswm/install/modulefiles/Core/
module load stack-intel
module load wgrib2
module list

# Get the UTC hour and calculate the time in the format yyyymmddhh
current_hour=$(date -u +%H)
if (( $current_hour >= 0 && $current_hour < 6 )); then
    datetime=$(date -u -d 'today 00:00')
elif (( $current_hour >= 6 && $current_hour < 12 )); then
    datetime=$(date -u -d 'today 06:00')
elif (( $current_hour >= 12 && $current_hour < 18 )); then
    datetime=$(date -u -d 'today 12:00')
else
    datetime=$(date -u -d 'today 18:00')
fi

# Calculate time 6 hours before
#curr_datetime=$(date -u -d "$time" +'%Y%m%d%H')
curr_datetime=$( date -d "$datetime 12 hour ago" "+%Y%m%d%H" )
prev_datetime=$( date -d "$datetime 18 hour ago" "+%Y%m%d%H" )

echo "Current state: $curr_datetime"
echo "6 hours earlier state: $prev_datetime"

# Set Miniconda path
export PATH="/contrib/Sadegh.Tabas/miniconda3/bin:$PATH"

# Activate Conda environment
source /contrib/Sadegh.Tabas/miniconda3/etc/profile.d/conda.sh
conda activate mlwp

start_time=$(date +%s)
echo "start runing gdas utility to generate graphcast inputs for: $curr_datetime"
# Run the Python script gdas.py with the calculated times
python3 gdas_utility.py "$prev_datetime" "$curr_datetime" -k no

end_time=$(date +%s)  # Record the end time in seconds since the epoch

# Calculate and print the execution time
execution_time=$((end_time - start_time))
echo "Execution time for gdas_utility.py: $execution_time seconds"

start_time=$(date +%s)
echo "start runing graphcast to get real time 10-days forecasts for: $curr_datetime"
# Run another Python script
python3 run_graphcast.py -i source-gdas_date-"$curr_datetime"_res-0.25_levels-13_steps-40.nc -o "$curr_datetime"

end_time=$(date +%s)  # Record the end time in seconds since the epoch

# Calculate and print the execution time
execution_time=$((end_time - start_time))
echo "Execution time for graphcast: $execution_time seconds"
