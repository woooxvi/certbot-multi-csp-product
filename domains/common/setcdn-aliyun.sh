#!/bin/sh
domain="$1"
cert_output_dir="$2"
CDN_DOMAIN="$domain"

# 检查是否有新上传的证书 ID
CERT_ID_FILE="${cert_output_dir}/.last_uploaded_cert_id"
if [ ! -f "$CERT_ID_FILE" ]; then
    echo "未找到新上传的证书 ID，无法设置 CDN 证书。"
    exit 1
fi

CERT_ID=$(cat "$CERT_ID_FILE")
# 删除临时文件
rm "$CERT_ID_FILE"

# 更新 CDN 配置，使用新的证书
# UPDATE_RESULT=$(tccli cdn ModifyDomainConfig --Domain "$CDN_DOMAIN" --Route 'Https.CertInfo.CertId' --Value "{\"update\":\"$CERT_ID\"}" 2>&1)

if test -e "CMD.sh"; then
    rm "CMD.sh"
    echo "上一次执行的 CMD.sh 已删除"
fi

echo -n "aliyun dcdn SetDcdnDomainSSLCertificate --region cn-hangzhou --DomainName='" >> "CMD.sh"
echo -n $CDN_DOMAIN >> "CMD.sh"
echo -n "' --SSLProtocol on --CertId '" >> "CMD.sh"
echo -n $CERT_ID >> "CMD.sh"
echo "'" >> "CMD.sh"

chmod +x CMD.sh

UPDATE_RESULT=$(./CMD.sh)


# UPDATE_RESULT=$(aliyun dcdn SetDcdnDomainSSLCertificate --region 'cn-hangzhou' --DomainName "$CDN_DOMAIN" --SSLProtocol on --CertId $CERT_ID 2>&1)


# 检查更新是否成功
if echo "$UPDATE_RESULT" | grep -q "RequestId"; then
    echo "CDN 配置更新成功，已使用新证书。"
else
    echo "CDN 配置更新失败: $UPDATE_RESULT"
    exit 1
fi