#!/bin/bash
export PYTHONPATH="$PWD"

# Create logs directory if it doesn't exist
mkdir -p logs

# Function to run command with nohup and logging
run_background() {
    local cmd=$1
    local logfile=$2
    nohup $cmd > "logs/$logfile.log" 2>&1 &
    echo "Started $cmd (PID: $!, logging to logs/$logfile.log)"
    echo $! >> "logs/pids.txt"  # Store PID for later waiting
}

# Clear previous PIDs
> logs/pids.txt

# Generate Train data - Phase 1 (vh_init.py)
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8083 --task all --mode simple --usage train --num-per-apartment 500' '8083'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8084 --task all --mode full --usage train --num-per-apartment 500' '8084'

# Wait for vh_init.py processes to finish
echo "Waiting for vh_init.py (8083 & 8084) to complete..."
while read pid; do
    tail --pid=$pid -f /dev/null  # Wait for each PID to finish
done < logs/pids.txt

# Clear PIDs for next phase
> logs/pids.txt

# Generate Train data - Phase 2 (gene_data.py)
run_background 'python vh/data_gene/testing_agents/gene_data.py --mode simple --dataset_path ./vh/dataset/env_task_set_500_simple.pik --base-port 8104' 'gene_data_8104_simple'
run_background 'python vh/data_gene/testing_agents/gene_data.py --mode full --dataset_path ./vh/dataset/env_task_set_500_full.pik --base-port 8105' 'gene_data_8105_full'

# Generate Test data (all ports unique)
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8095 --task all --mode simple --usage test --num-per-apartment 50' '8095'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8096 --task all --mode full --usage test --num-per-apartment 50' '8096'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8097 --task all --mode simple --unseen-apartment --usage test --num-per-apartment 50' '8097'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8098 --task all --mode full --unseen-apartment --usage test --num-per-apartment 50' '8098'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8099 --task unseen_comp --mode full --usage test --num-per-apartment 50' '8099'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8100 --task all --mode full --unseen-item --usage test --num-per-apartment 50' '8100'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8101 --task all --mode simple --unseen-item --usage test --num-per-apartment 50' '8101'
run_background 'python vh/data_gene/gen_data/vh_init.py --port 8102 --task unseen_comp --mode full --unseen-item --usage test --num-per-apartment 50' '8102'

echo "All background processes started. Use 'jobs -l' to view running jobs."
echo "Logs are being written to the logs/directory."