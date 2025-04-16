#!/bin/sh
domain="$1"
cert_output_dir="$2"
lb_id="$3"
listen_id="$4"
CDN_DOMAIN="$domain"

# 检查是否有新上传的证书 ID
CERT_ID_FILE="${cert_output_dir}/.last_uploaded_cert_id"
if [ ! -f "$CERT_ID_FILE" ]; then
    echo "未找到新上传的证书 ID，无法设置 CDN 证书。"
    exit 1
fi

# 检查是否传入 lb_id
if [ -z "$lb_id" ]; then
    echo "需要传入负载均衡 ID。"
    exit 1
fi

# 检查是否传入 listen_id
if [ -z "$listen_id" ]; then
    echo "需要传入负载均衡 的监听ID。"
    exit 1
fi


CERT_ID=$(cat "$CERT_ID_FILE")
# 删除临时文件
# rm "$CERT_ID_FILE"

# 更新 CDN 配置，使用新的证书
UPDATE_RESULT=$(tccli clb ModifyDomainAttributes --cli-unfold-argument --LoadBalancerId "$lb_id" --ListenerId "$listen_id" --Domain "$domain" --Certificate.CertId "$CERT_ID" --Certificate.SSLMode 'UNIDIRECTIONAL' 2>&1)

# 检查更新是否成功
if echo "$UPDATE_RESULT" | grep -q "RequestId"; then
    echo "CDN 配置更新成功，已使用新证书。"
else
    echo "CDN 配置更新失败: $UPDATE_RESULT"
    exit 1
fi