## openvpn 支持本地文件用户密码和ldap认证
``` shell
 git clone https://github.com/greatwl/openvpn.git 
 cd openvpn/
 docker build -t openvpn ./
```

### file认证
``` shell
docker stop openvpn
docker rm openvpn
rm -rf /data/openvpn/
docker run -d --name openvpn --hostname openvpn --privileged \
  -p 1194:1194 \
  -v /data/openvpn/etc:/etc/openvpn \
  -v /data/openvpn/logs:/var/log/openvpn \
  -e SERVER_IP="x.x.x.x:1194" \
  -e OVPN_PORT="1194" \
  -e OVPN_PRROTO="tcp" \
  -e OVPN_SERVER="10.66.66.0" \
  -e OVPN_PUSH="route 192.168.250.0 255.255.255.0" \
  -e OVPN_AUTH="file" \
openvpn
```

### ldap认证
``` shell
docker stop openvpn
docker rm openvpn
rm -rf /data/openvpn/
docker run -d --restart always --name openvpn --hostname openvpn --privileged \
-p 1194:1196 \
-v /data/openvpn/etc:/etc/openvpn \
-v /data/openvpn/logs:/var/log/openvpn \
-e SERVER_IP="x.x.x.x:65535" \ #客户端连接地址
-e OVPN_PORT="1196" \ #openvpn运行端口 1024-65535
-e OVPN_PRROTO="tcp" \ #使用协议 tcp udp
-e OVPN_SERVER="10.66.88.0" \ #openvpn私有网段
-e OVPN_PUSH="route 172.19.88.0 255.255.255.0" \ #向客户端push路由
-e OVPN_AUTH="ldap" \ #认证方式 ldap file
-e LDAP_URL="ldaps://x.x.x.x:636" \ #ldap ldapurl
-e LDAP_BASE="dc=wl166,dc=com" \ #ldap基础信息
-e LDAP_USERS="ou=people,dc=wl166,dc=com" \ #用户所在组织
openvpn
``` 

### 以当前容器为例
>* 客户端配置文件:/data/openvpn/etc/Client.ovpn
>*  ldap登录日志:/data/openvpn/logs/openvpn_ldap_login.log

>*  file认证文件:/data/openvpn/etc/scripts/openvpn_user.txt(空格分割，账号密码。)
>* file认证日志:/var/log/openvpn/openvpn_user_login.log

