#!/bin/sh

# 获取阿里云域名的证书
domain="$1"
cert_output_dir="$2"
wildcard="$3"

domain_dir="/domains/${domain}"
account_ini="${domain_dir}/account.ini"

# 检查本地证书是否存在且有效
cert_file="${cert_output_dir}/live/${domain}/fullchain.pem"
key_file="${cert_output_dir}/live/${domain}/privkey.pem"
if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
    # 计算证书剩余有效期
    current_time=$(date +%s)
    # expiration_time=$(openssl x509 -enddate -noout -in "fullchain.pem" | sed 's/.*=//' | xargs -I{} date -d "{}" +%s)
    expiration_date=$(openssl x509 -enddate -noout -in "$cert_file" | sed 's/.*=//')
    expiration_time=$(python -c "import datetime; print(int(datetime.datetime.strptime('$expiration_date', '%b %d %H:%M:%S %Y %Z').timestamp()))")
    
    echo $expiration_time
    remaining_days=$(( (expiration_time - current_time) / 86400 ))
    echo "计算得到剩余有效期 $remaining_days 天, current_time: $current_time expiration_time: $expiration_time"

    if [ $remaining_days -gt 15 ]; then
        echo "本地证书有效且剩余有效期超过 15 天，无需请求新证书。"
        exit 0
    else
        echo "证书即将到期，开始重新请求新证书。"
    fi
else
    echo "证书 $cert_file $key_file 不存在，即将重新请求证书"
fi

# 执行 Certbot 命令生成证书
domain=$wildcard$domain

echo "wildcard:$wildcard"
echo "domain:$domain"
echo "cert_file:$cert_file"
echo "key_file:$key_file"
echo "account_ini:$account_ini"


certbot certonly \
  --authenticator=dns-aliyun \
  --dns-aliyun-credentials "$account_ini" \
  --agree-tos \
  --register-unsafely-without-email \
  --renew-by-default \
  --key-type rsa \
  -d "$domain" \
  --config-dir "$cert_output_dir" \
  --work-dir "$cert_output_dir" \
  --logs-dir "$cert_output_dir"

# 检查证书生成是否成功
if [ $? -eq 0 ]; then
    echo "证书生成成功，路径为: $cert_output_dir"
else
    echo "证书生成失败，请检查 Certbot 命令和配置。"
    exit 1
fi