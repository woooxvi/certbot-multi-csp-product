#!/bin/sh

# 检查 /domains 是否为挂载点
if ! mountpoint -q /domains; then
    # 复制 /domains_temp 内容到 /domains，跳过已存在的同名文件
    cp -rn /domains_temp/. /domains
fi


# 容器主体，分别调用各个域名的更新
echo "start execute script start.sh"
while true; do
    # 使用 find 命令查找匹配的脚本文件
    found_scripts=false
    find /domains -type f -name "start.sh" | while read -r script; do
        found_scripts=true
        if [ -f "$script" ]; then
            # 检查脚本是否有可执行权限，如果没有则添加
            if [ ! -x "$script" ]; then
                chmod +x "$script"
            fi
            echo "START Running script: $script vvvvvvvvvvvvvvvvv"
            "$script"
            echo "END Running script: $script ^^^^^^^^^^^^^^^^^"
        fi
    done

    # 检查是否有匹配的脚本
    if [ "$found_scripts" = false ]; then
        echo "No matching start.sh scripts found. Skipping."
    fi

    echo "startsleep"
    # 休眠一天
    sleep 86400
done