#!/bin/sh
domain_dir="$1"
config_key_prefix="$2"
account_ini="${domain_dir}/account.ini"

# 拼接 AccessKey ID 和 Secret 的键名
access_key_id_key="${config_key_prefix}_AccessKeyId"
access_key_secret_key="${config_key_prefix}_AccessKeySecret"

if [ -f "$account_ini" ]; then
    # 从 account.ini 中读取阿里云的 AccessKey ID 和 Secret
    access_key_id=$(grep "$access_key_id_key" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    access_key_secret=$(grep "$access_key_secret_key" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    
    if [ -n "$access_key_id" ] && [ -n "$access_key_secret" ]; then
        # 配置阿里云 CLI
        aliyun configure set --access-key-id "$access_key_id" --access-key-secret "$access_key_secret" --region cn-hangzhou --profile "$access_key_id"
        echo "阿里云CLI配置完成"
    else
        echo "未在 $account_ini 中找到有效的阿里云 AccessKey ID 或 Secret，跳过此域名。"
        exit 1
    fi
else
    echo "未找到 $account_ini 配置文件，跳过此域名。"
    exit 1
fi