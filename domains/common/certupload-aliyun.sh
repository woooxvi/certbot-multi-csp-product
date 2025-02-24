#!/bin/sh
domain="$1"
cert_output_dir="$2"


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
    echo "证书 $cert_modify_timestamp 不是最近一小时生成的，无需上传到阿里云。"
    exit 0
fi

echo "证书是最近一小时生成的，cledar开始上传到阿里云..."

# 读取证书文件内容
CERT_CONTENT=$(cat "$CERT_FILE")
KEY_CONTENT=$(cat "$KEY_FILE")

# 获取今天的日期，格式为 年_月_日
TODAY=$(date +"%Y_%m_%d")
CERT_NAME="${domain}_${TODAY}"

rm UPLOAD_CMD.sh

echo -n "aliyun cas UploadUserCertificate --region cn-hangzhou --Cert='" >> "UPLOAD_CMD.sh"
echo -n $(cat "$CERT_FILE") >> "UPLOAD_CMD.sh"
echo -n "' --Key='" >> "UPLOAD_CMD.sh"
echo -n $(cat "$KEY_FILE") >> "UPLOAD_CMD.sh"
echo -n "' --Name '" >> "UPLOAD_CMD.sh"
echo -n $CERT_NAME >> "UPLOAD_CMD.sh"
echo "'" >> "UPLOAD_CMD.sh"

chmod +x UPLOAD_CMD.sh

cat UPLOAD_CMD.sh
UPLOAD_RESULT=$(./UPLOAD_CMD.sh)

# UPLOAD_RESULT=$(aliyun cas UploadUserCertificate --Cert "$(cat "$CERT_FILE")" --Key "$(cat "$KEY_FILE")" --Name "$domain" 2>&1)

# 打印结果
echo "$UPLOAD_RESULT"

# 检查上传是否成功
if echo "$UPLOAD_RESULT" | grep -q "CertId"; then
    CERT_ID=$(echo "$UPLOAD_RESULT" | grep -o '"CertId": [^,]*' | awk -F ':' '{print $2}' | tr -d ' ')
    echo "证书上传成功，证书 ID 为: $CERT_ID"
    # 将证书 ID 存储到临时文件，供后续设置 CDN 时使用
    echo "$CERT_ID" > "${cert_output_dir}/.last_uploaded_cert_id"
else
    echo "证书上传失败: $UPLOAD_RESULT"
    exit 1
fi