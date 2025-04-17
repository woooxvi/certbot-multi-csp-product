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


# 检查本地是否存在 .last_uploaded_cert_id 文件
if [ -f "${cert_output_dir}/.last_uploaded_cert_id" ]; then
    LAST_UPLOADED_CERT_ID=$(cat "${cert_output_dir}/.last_uploaded_cert_id")
    # 查询该证书 ID 在阿里云上是否存在
    CERT_INFO=$(aliyun cdn DescribeCertificateInfoByID --CertId "$LAST_UPLOADED_CERT_ID" 2>&1)
    if echo "$CERT_INFO" | grep -q "CertId"; then
        echo "阿里云上已存在该证书，证书 ID 为: $LAST_UPLOADED_CERT_ID，无需上传。"
        exit 0
    else
        echo "阿里云上不存在该证书 $LAST_UPLOADED_CERT_ID ，$CERT_INFO 开始上传到阿里云..."
    fi
else
    echo "本地没有证书记录，不能判断阿里云有无证书..."
fi


# 读取证书文件内容
CERT_CONTENT=$(cat "$CERT_FILE")
KEY_CONTENT=$(cat "$KEY_FILE")

# 获取今天的日期，格式为 年_月_日
TODAY=$(date +"%Y_%m_%d")
CERT_NAME="${domain}_${TODAY}"

if test -e "CMD.sh"; then
    rm "CMD.sh"
    echo "上一次执行的 CMD.sh 已删除"
fi

echo -n "aliyun cas UploadUserCertificate --region cn-hangzhou --Cert='" >> "CMD.sh"
echo -n $(cat "$CERT_FILE") >> "CMD.sh"
echo -n "' --Key='" >> "CMD.sh"
echo -n $(cat "$KEY_FILE") >> "CMD.sh"
echo -n "' --Name '" >> "CMD.sh"
echo -n $CERT_NAME >> "CMD.sh"
echo "'" >> "CMD.sh"

chmod +x CMD.sh

UPLOAD_RESULT=$(./CMD.sh)

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
