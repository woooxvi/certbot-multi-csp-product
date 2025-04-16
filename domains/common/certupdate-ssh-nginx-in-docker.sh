#!/bin/sh
domain="$1"
cert_output_dir="$2"
domain_dir="/domains/${domain}"
account_ini="${domain_dir}/account.ini"



# 定义证书文件路径
CERT_FILE="${cert_output_dir}/live/${domain}/fullchain.pem"
KEY_FILE="${cert_output_dir}/live/${domain}/privkey.pem"

# 检查证书文件是否存在
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "证书文件未找到，请检查生成路径。"
    exit 1
fi

# 获取当前时间戳
current_timestamp=$(date +%s)
# 获取证书文件的修改时间戳
cert_modify_timestamp=$(stat -c %Y "$CERT_FILE")
# 计算时间差（秒）
time_difference=$((current_timestamp - cert_modify_timestamp))

if [ $time_difference -gt 72000 ]; then
    echo "证书 $cert_modify_timestamp 不是最近一小时生成的，无需上传到ssh。"
    exit 0
fi

echo "证书是最近一小时生成的，cledar开始上传到远端..."

if [ -f "$account_ini" ]; then
    # 从 account.ini 中读取远端的服务器地址，账号，证书路径，容器名称
    REMOTE_HOST=$(grep "REMOTE_HOST" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    REMOTE_USER=$(grep "REMOTE_USER" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    REMOTE_CERT_DIR=$(grep "REMOTE_CERT_DIR" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    REMOTE_CONTAINER=$(grep "REMOTE_CONTAINER" "$account_ini" | cut -d '=' -f 2 | tr -d ' ')
    
    if [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_CERT_DIR" ] && [ -n "$REMOTE_CONTAINER" ]; then

        chmod 600 $domain_dir/id_rsa
        chmod 644 $domain_dir/id_rsa.pub

        # 上传证书文件
        # scp $CERT_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_CERT_DIR/
        scp -i $domain_dir/id_rsa -o StrictHostKeyChecking=no $CERT_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_CERT_DIR/
        scp_status=$?
        if [ $scp_status -eq 0 ]; then
            scp -i $domain_dir/id_rsa -o StrictHostKeyChecking=no $KEY_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_CERT_DIR/
            scp_status=$?
        fi

        if [ $scp_status -eq 0 ]; then
            echo "证书上传成功，重新加载 Nginx 配置..."
            # 重新加载 Nginx 配置
            ssh -i $domain_dir/id_rsa -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "docker exec $REMOTE_CONTAINER nginx -s reload"
            if [ $? -eq 0 ]; then
                echo "Nginx 配置重新加载成功"
            else
                echo "Nginx 配置重新加载失败"
            fi
        else
            echo "证书上传失败"
        fi
    else
        echo "没有配置齐：服务器地址，账号，证书路径，容器名称"
    fi
else
    echo "配置文件不存在"
fi