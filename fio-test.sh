#!/bin/bash

# FIO 测试参数
MOUNTPOINT=/data        # 指定测试的文件系统挂载点
FILENAME=fio_test_file  # 指定测试文件的名称
RUNTIME=300             # 指定每个测试的运行时间（秒）
SIZE=5G                 # 指定测试文件的大小
BLOCKSIZE=4k            # 指定测试的块大小

# 确保测试文件系统已经被挂载
if ! mount | grep -q " ${MOUNTPOINT} "; then
    echo "错误：${MOUNTPOINT} 没有被挂载。请在运行此脚本前先挂载。"
    exit 1
fi

# 运行单个 FIO 测试的函数
run_fio_test() {
    local name=$1       # 测试名称
    local rw=$2         # 读写模式
    local direct=$3     # 是否禁用缓存（直接 I/O）

    echo "正在运行 $name 测试..."
    # 执行 fio 测试并将结果保存到文本文件
    fio --name="$name" --filename="${MOUNTPOINT}/${FILENAME}" --ioengine=libaio --rw="$rw" \
        --bs="$BLOCKSIZE" --direct="$direct" --runtime="$RUNTIME" --size="$SIZE" \
        > "${name}_result.txt"

    # 检查测试是否成功完成，并给出相应的提示
    if [ $? -eq 0 ]; then
        echo "$name 测试完成。结果已保存到 ${name}_result.txt"
    else
        echo "$name 测试失败。"
    fi
}

# 顺序测试
run_fio_test seq-read read 0
run_fio_test seq-read-nocache read 1
run_fio_test seq-write write 0
run_fio_test seq-write-nocache write 1
run_fio_test seq-readwrite readwrite 0
run_fio_test seq-readwrite-nocache readwrite 1

# 随机测试
run_fio_test rand-read randread 0
run_fio_test rand-read-nocache randread 1
run_fio_test rand-write randwrite 0
run_fio_test rand-write-nocache randwrite 1
run_fio_test rand-readwrite randrw 0
run_fio_test rand-readwrite-nocache randrw 1

echo "所有测试已完成，请检查结果文件。"
