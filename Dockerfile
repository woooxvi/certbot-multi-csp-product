FROM certbot/certbot
RUN pip install certbot-dns-tencentcloud certbot-dns-aliyun

# 腾讯云cli
RUN pip install --upgrade pip
RUN pip install tccli

# 阿里云cli
COPY aliyun /usr/local/bin/aliyun
RUN chmod +x /usr/local/bin/aliyun

# 创建挂载目录
RUN mkdir -p /domains

# 复制启动脚本到容器内
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 修改入口点
ENTRYPOINT ["/bin/sh"]
CMD ["/start.sh"]