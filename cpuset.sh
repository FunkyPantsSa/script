#!/bin/bash


##修改容器的cpuset.cpus，调度到指定的cpu核心上
# 获取容器ID
container_ids=$(crictl ps --no-trunc | grep srv-ai-adapter | grep -v cce-pause | awk '{print $1}')

# 检查是否获取到容器ID
if [ -z "$container_ids" ]; then
    echo "No container IDs found matching the criteria."
    exit 1
fi

# 遍历容器ID
for id in $container_ids; do
    # 使用容器ID作为grep的值
    result=$(ls -l /sys/fs/cgroup/cpuset/| grep "$id" |awk {'print $9'})

    # 检查是否有输出结果
    if [ -z "$result" ]; then
        echo "No matching files for container ID $id"
        continue
    fi

    # 输出结果并写入到cpuset.cpus文件中
    echo '0-19,40-59' > "/sys/fs/cgroup/cpuset/${result}/cpuset.cpus"
    echo "Written to /sys/fs/cgroup/cpuset//${result}/cpuset.cpus"
    cat /sys/fs/cgroup/cpuset/${result}/cpuset.cpus
done