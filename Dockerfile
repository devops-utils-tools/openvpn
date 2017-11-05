from centos:7.2.1511
maintainer By:liuwei "al6008@163.com"
run rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    yum install  -y net-tools make gcc-c++ autoconf openssl openssl-devel pam-devel lzo-devel iptables-services openldap-clients &&\
    yum clean all
copy openvpn-2.3.18.tar.gz /tmp
run cd /tmp &&\
    tar zxf openvpn-2.3.18.tar.gz  &&\
    cd openvpn-2.3.18 &&\
    ./configure --prefix=/usr/local/openvpn2.3.18 --sbindir=/sbin -sysconfdir=/etc/openvpn &&\
    make -j && make -j install &&\
    cd /tmp &&\
    rm -rf openvpn-2.3.18 &&\
    rm -rf openvpn-2.3.18.tar.gz &&\
    ln -sf /usr/local/openvpn2.3.18 /usr/local/openvpn &&\
    mkdir -p /usr/local/openvpn/{logs,config} 
run useradd -m -d /etc/openvpn  openvpn
copy openvpn_etc.tar.gz /tmp
workdir /tmp
copy run.sh /run.sh
cmd ["/bin/bash","/run.sh"]
