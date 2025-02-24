#!/bin/sh
domain_dir="$1"
config_key_prefix="$2"
account_ini="${domain_dir}/account.ini"

# 拼接 AccessKey ID 和 Secret 的键名
access_key_id_key="${config_key_prefix}_SecretId"
access_key_secret_key="${config_key_prefix}_SecretKey"

if [ -f "$account_ini" ]; then
    # 读取 account.ini 中的 SecretId 和 SecretKey
    secret_id=$(grep "$access_key_id_key" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    secret_key=$(grep "$access_key_secret_key" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')

    if [ -n "$secret_id" ] && [ -n "$secret_key" ]; then
        # 配置 tccli 使用读取到的密钥
        tccli configure set secretId "$secret_id"
        tccli configure set secretKey "$secret_key"
        tccli configure set region ap-guangzhou  # 根据实际情况修改区域
    else
        echo "未在 $account_ini 中找到有效的 SecretId 或 SecretKey，跳过此域名。"
        exit 1
    fi
else
    echo "未找到 $account_ini 配置文件，跳过此域名。"
    exit 1
fi