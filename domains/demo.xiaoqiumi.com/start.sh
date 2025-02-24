#!/bin/sh
# 单个域名的程序
echo "当前只是演示"
exit(0)

domain_dir=$(dirname "$0")
domain=$(basename "$domain_dir")
cert_output_dir="${domain_dir}/certs"

# 生成证书
sh /domains/common/certonly-aliyun.sh "$domain" "$cert_output_dir"


# 登录阿里云
sh /domains/common/logaliyuncli.sh "$domain_dir" "all"

# 上传证书
sh /domains/common/certupload-aliyun.sh "$domain" "$cert_output_dir"

# 设置证书到 CDN
sh /domains/common/setcdn-aliyun.sh "$domain" "$cert_output_dir"