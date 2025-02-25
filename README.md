# 基于certbot，自动申请证书、上传到阿里云、腾讯云的证书服务、设置到CDN、云直播等产品的自动化工具

## 功能描述
- 每日执行
- 剩余时间<15天 → 调用certbot申请证书
- 证书文件修改时间>now-1d → 上传证书到阿里云或腾讯云
- 证书上传成功 → 设置到CDN 或 云直播
