#!/bin/sh
domain="$1"
cert_output_dir="$2"

# 定义证书文件路径
CERT_FILE="${cert_output_dir}/live/${domain}/fullchain.pem"
KEY_FILE="${cert_output_dir}/live/${domain}/privkey.pem"

# 检查证书文件是否存在
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "证书文件未找到，无法执行上传证书到腾讯云。"
    exit 1
fi

# 获取当前时间戳
current_timestamp=$(date +%s)
# 获取证书文件的修改时间戳
cert_modify_timestamp=$(stat -c %Y "$CERT_FILE")
# 计算时间差（秒）
time_difference=$((current_timestamp - cert_modify_timestamp))

if [ $time_difference -gt 3600 ]; then
    echo "证书 $cert_modify_timestamp 不是最近一小时生成的，无需上传到腾讯云。"
    exit 0
fi

echo "证书是最近一小时生成的，开始上传到腾讯云..."

# 读取证书文件内容
CERT_CONTENT=$(cat "$CERT_FILE")
KEY_CONTENT=$(cat "$KEY_FILE")

# 上传证书到腾讯云
UPLOAD_RESULT=$(tccli ssl UploadCertificate --CertificatePublicKey "$CERT_CONTENT" --CertificatePrivateKey "$KEY_CONTENT" --Alias "$domain" 2>&1)

# 检查上传是否成功
if echo "$UPLOAD_RESULT" | grep -q "CertificateId"; then
    CERT_ID=$(echo "$UPLOAD_RESULT" | grep -o '"CertificateId": "[^"]*"' | awk -F '"' '{print $4}')
    echo "证书上传成功，证书 ID 为: $CERT_ID"
    # 将证书 ID 存储到临时文件，供后续设置 CDN 时使用
    echo "$CERT_ID" > "${cert_output_dir}/.last_uploaded_cert_id"
else
    echo "证书上传失败: $UPLOAD_RESULT"
    exit 1
fi