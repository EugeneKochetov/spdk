#!/usr/bin/env bash
# Target 0 is multipath target
TGT_CPUS=(0x08 0x02 0x4)
TGT_PIDS=()
PERF_CPUS=0x10

start_tgt() {
    N=$1
    [[ -z "${TGT_CPUS[$N]}" ]] && echo "Failed to start target $N" && exit 1
    ./app/nvmf_tgt/nvmf_tgt -m ${TGT_CPUS[$N]} -c nvmf_tgt$N.conf -r /var/tmp/spdk_tgt$N.sock 2>&1 > tgt$N.log &
    TGT_PIDS[$N]=$!
    echo "Started target $N, PID ${TGT_PIDS[$N]}"
    sleep 3; cat tgt$N.log
}

deactivate_tgt() {
    N=$1
    [[ -z "${TGT_CPUS[$N]}" ]] && echo "Failed to deactivate target $N" && exit 1
    ./scripts/rpc.py -s /var/tmp/spdk_tgt$N.sock delete_nvmf_subsystem nqn.2016-06.io.spdk:cnode1
    echo "Deactivated target $N"
}

stop_tgt() {
    N=$1
    [[ -z "${TGT_CPUS[$N]}" ]] && echo "Failed to stop target $N" && exit 1
    ./scripts/rpc.py -s /var/tmp/spdk_tgt$N.sock kill_instance 15
    echo "Stopped target $N"
}

run_mp_tgt() {
    start_tgt 1
    start_tgt 2
    sleep 3
    ./app/nvmf_tgt/nvmf_tgt -m ${TGT_CPUS[0]} -c nvmf_mp_tgt.conf -L vbdev_multipath
    stop_tgt 1
    stop_tgt 2
}

deactivate_path() {
    N=$1
    ./scripts/rpc.py vbdev_multipath_path_down -m MP_Nvme0 -b Nvme${N}n1
    echo "Deactivated path $N"
}

activate_path() {
    N=$1
    ./scripts/rpc.py vbdev_multipath_path_up -m MP_Nvme0 -b Nvme${N}n1
    echo "Activated path $N"
}

watch_stats() {
    watch -n1 ./scripts/rpc.py get_bdevs_iostat
}

perf() {
    TIME=$1
    [[ -z "$TIME" ]] && TIME=10
    echo "Running SPDK perf for $TIME seconds"
    ./examples/nvme/perf/perf -q 16 -o 4096 -w randread -t $TIME -c $PERF_CPUS -r 'trtype:RDMA adrfam:IPV4 traddr:1.1.79.1 trsvcid:4420'
}

stop_all() {
    kill -9 $(pidof nvmf_tgt)
}

create_lvol() {
    ./scripts/rpc.py construct_lvol_store Malloc0 lvs0
    ./scripts/rpc.py get_lvol_stores
    ./scripts/rpc.py construct_lvol_bdev -l lvs0 lvol0 64
    ./scripts/rpc.py get_bdevs
}

fn=$1
shift
$fn $@
