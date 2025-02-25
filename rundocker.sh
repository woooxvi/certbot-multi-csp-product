docker build --build-arg http_proxy=http://192.168.0.182:808 --build-arg https_proxy=http://192.168.0.182:808 -t certbot-domains .

# 检查 certbot-domains-everyday 容器是否存在
if docker ps -a --format '{{.Names}}' | grep -q 'certbot-domains-everyday'; then
    # 如果存在，则停止并删除该容器
    echo "Stopping and removing existing certbot-domains-everyday container..."
    docker stop certbot-domains-everyday
    docker rm certbot-domains-everyday
fi

docker run -it -d --restart=always --name=certbot-domains-everyday \
  -v /srv/certbot/domains:/domains \
  -v /srv/certbot/letsencrypt:/etc/letsencrypt \
  -v /srv/certbot/letsencrypt_temp:/var/lib/letsencrypt \
  certbot-domains