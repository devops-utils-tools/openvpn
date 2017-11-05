#!/bin/bash
#OpenVPN init scripts By:liuwei Mail:al6008@163.com
SERVER_IP=${SERVER_IP:-"172.16.110.14:1194"}
OVPN_PORT=${OVPN_PORT:-"1194"}
OVPN_PRROTO=${OVPN_PRROTO:-"tcp"}
OVPN_SERVER=${OVPN_SERVER:-"10.66.66.0"}
OVPN_PUSH=${OVPN_PUSH:-"route 192.168.250.0 255.255.255.0"}
OVPN_AUTH=${OVPN_AUTH:-file}
LDAP_URL=${LDAP_URL:-"ldaps://172.16.110.99:636"}
LDAP_BASE=${LDAP_BASE:-"dc=arxan,dc=com"}
LDAP_USERS=${LDAP_USERS:-"ou=people,dc=arxan,dc=com"}
init_config(){
if [ ${OVPN_AUTH} == "ldap" ];then
	#ldap config
    AUTH="/etc/openvpn/scripts/openvpn_ldap.sh"
	cat > /etc/openldap/ldap.conf <<EOF
BASE ${LDAP_BASE}
URI  ${LDAP_URL}
SIZELIMIT 12
TIMELIMIT 15
DEREF never
TLS_REQCERT allow
EOF
	sed -i "s@ldaps://172.16.110.201@${LDAP_URL}@g" /etc/openvpn/scripts/openvpn_ldap.sh
	sed -i "s@ou=people,dc=arxan,dc=com@${LDAP_USERS}@g" /etc/openvpn/scripts/openvpn_ldap.sh
else
    AUTH="/etc/openvpn/scripts/openvpn_user.sh"
fi

mkdir -p /etc/openvpn
cat >/etc/openvpn/server.conf <<EOF
#OpenVPN Config_file By:liuwei Mail:al6008@163.com
#Date $(date +"%F %T") 
port  ${OVPN_PORT}
proto ${OVPN_PRROTO}
dev tun
user openvpn
group openvpn
tcp-queue-limit 512
server ${OVPN_SERVER} 255.255.255.0
ca /etc/openvpn/easy-rsa-2.0/keys/ca.crt
cert /etc/openvpn/easy-rsa-2.0/keys/server.crt
key /etc/openvpn/easy-rsa-2.0/keys/server.key
dh /etc/openvpn/easy-rsa-2.0/keys/dh2048.pem
tls-auth /etc/openvpn/easy-rsa-2.0/keys/ta.key 0
crl-verify /etc/openvpn/easy-rsa-2.0/keys/crl.pem
auth-user-pass-verify ${AUTH} via-env
username-as-common-name
client-cert-not-required
script-security 3 system
push "${OVPN_PUSH}"
ifconfig-pool-persist /var/log/openvpn/ipp.txt
duplicate-cn
keepalive 30 360
comp-lzo
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log /var/log/openvpn/openvpn.log
verb 2
mute 5
EOF
sed -i 's@0 "@0"@g' /etc/openvpn/server.conf
mkdir -pv /var/log/openvpn/
echo 'openvpn init done by:liuwei mail:al6008@163.com' > "/etc/openvpn/server.init"
}

init_key(){
source /etc/openvpn/scripts/config.sh
outdir=$(pwd)
cd "${key_tools_dir}"
source "${key_tools_dir}/vars"
cd "${key_tools_dir}"
rm -rf "${save_path}"
rm -f "${openvpn_user_file}"
./clean-all
export KEY_SIZE=16384
#export KEY_SIZE=1024
./pkitool --initca
sleep 1
source "${key_tools_dir}/vars"
./pkitool --server server
sleep 1
./pkitool --server test
export KEY_SIZE=2048
./build-dh
sleep 1
./revoke-full test
touch "${openvpn_user_file}"
/sbin/openvpn --genkey --secret keys/ta.key
#创建一个账号密码证书
sleep 1
company_name=Client
openvpn_certificate=`cat \
    <(echo -e '<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>\n<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>')`
create_openvpn_file
}

if [ ! -e /etc/openvpn/server.init ];then
	tar xf /tmp/openvpn_etc.tar.gz -C /
	init_config
fi

if [ ! -e /etc/openvpn/easy-rsa-2.0/keys/ca.crt ];then
	cd /etc/openvpn/
	init_key
	[ ${OVPN_AUTH} == "file" ]&&echo "admin al6008@163.com" > /etc/openvpn/scripts/openvpn_user.txt
fi

#iptables https://github.com/kylemanna/docker-openvpn/blob/master/bin/ovpn_run
OVPN_SERVER=$(echo $(awk '/^server/{print $2}' /etc/openvpn/server.conf)/24)
OVPN_NATDEVICE=$(ifconfig |grep -v "^ "|grep -v "tun"|grep -v "lo" |grep -v "^$"|awk -F: '{print $1}')
iptables -t nat -C POSTROUTING -s $OVPN_SERVER -o $OVPN_NATDEVICE -j MASQUERADE || iptables -t nat -A POSTROUTING -s $OVPN_SERVER -o $OVPN_NATDEVICE -j MASQUERADE
echo 1> /proc/sys/net/ipv4/ip_forward

mkdir -pv /var/log/openvpn/ccd
touch /var/log/openvpn/openvpn.log
chown openvpn:openvpn -R /etc/openvpn
chown openvpn:openvpn -R /var/log/openvpn/

/sbin/openvpn /etc/openvpn/server.conf &>/dev/null &
tail -f /var/log/openvpn/openvpn.log
exit 0
