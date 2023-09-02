NETADAPT="$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")"
export DEBIAN_FRONTEND=noninteractive
mkdir -p /etc/apt/keyrings && curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg | gpg --dearmor > /etc/apt/keyrings/openvpn-repo-public.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/openvpn-repo-public.gpg] https://build.openvpn.net/debian/openvpn/stable jammy main" > /etc/apt/sources.list.d/openvpn-aptrepo.list
apt update
apt install openvpn awscli expect -y
mkdir /etc/easy-rsa
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz
tar xf EasyRSA-unix-v3.0.6.tgz --strip-components=1 -C /etc/easy-rsa && rm EasyRSA-unix-v3.0.6.tgz
cat <<EOF >/etc/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY     "$CITY"
set_var EASYRSA_REQ_PROVINCE    "$CITY"
set_var EASYRSA_REQ_CITY        "$CITY"
set_var EASYRSA_REQ_ORG         "$ORG"
set_var EASYRSA_REQ_EMAIL       "$EMAIL"
set_var EASYRSA_REQ_OU          "RD"
set_var EASYRSA_KEY_SIZE        4096
EOF
cd /root
/etc/easy-rsa/easyrsa init-pki
wait
expect <<EOF
spawn /etc/easy-rsa/easyrsa build-ca nopass
expect -exact "\rEnter PEM pass phrase:"
send -- "$COMPANY\r"
expect -exact "\rVerifying - Enter PEM pass phrase:"
send -- "$COMPANY\r"
expect -exact "\rCommon Name (eg: your user, host, or server name) \[Easy-RSA CA\]:"
send -- "$COMPANY\r"
expect eof
EOF
wait
echo {,} | /etc/easy-rsa/easyrsa gen-req "$COMPANY"-vpn nopass
wait
SIGN="/etc/easy-rsa/easyrsa sign-req server "$COMPANY"-vpn nopass"
expect <<EOF
spawn $SIGN
expect -exact "\rConfirm request details: "
send -- "yes\r"
expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
send -- "$COMPANY\r"
expect eof
EOF
wait
cp /root/{pki/issued/"$COMPANY"-vpn.crt,pki/private/"$COMPANY"-vpn.key,pki/ca.crt} /etc/openvpn/
/etc/easy-rsa/easyrsa gen-dh
wait
expect <<EOF
spawn /etc/easy-rsa/easyrsa gen-crl
expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
send -- "$COMPANY\r"
expect eof
EOF
wait
groupadd nobody
mkdir -p /etc/openvpn/client-configs/{files,keys}
openvpn --genkey secret "/root/ta.key"
cp /root/ta.key /etc/openvpn
cp /root/pki/{crl.pem,dh.pem} /etc/openvpn/
cp /root/{ta.key,pki/ca.crt} /etc/openvpn/client-configs/keys/
cat <<EOF >/etc/openvpn/"$COMPANY"-vpn.conf
port 1194
proto udp
dev tun
ca ca.crt
cert $COMPANY-vpn.crt
key $COMPANY-vpn.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "route $VPC 255.255.255.0"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-CBC
user nobody
group nobody
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log /var/log/openvpn/openvpn.log
crl-verify /etc/openvpn/crl.pem
key-direction 0
auth SHA256
sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"
txqueuelen 10000
verb 3
EOF
PUBIP="$(curl ifconfig.me)"
cat <<EOF >/etc/openvpn/client-configs/base.conf
client
dev tun
proto udp
remote $PUBIP 1194
route $VPC 255.255.0.0
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
mssfix 0
verb 3
EOF
cat <<EOF >/root/create_vpn_user
#!/bin/bash
VPNUSER=\${1,,}
USERNAME="\$(echo "\$VPNUSER" | sed 's/.com//g; s/@/-/g')"
export EASYRSA_REQ_CN=\$USERNAME
OUTPUT_DIR=/etc/openvpn/client-configs/files
KEY_DIR=/etc/openvpn/client-configs/keys
BASE_CONFIG=/etc/openvpn/client-configs/base.conf
OPENVPN_DIR=/etc/openvpn
EASYRSA_DIR=/root
if [ "\$VPNUSER" = '' ]; then
exit 1
else
cd \$EASYRSA_DIR
/etc/easy-rsa/easyrsa --batch gen-req \$USERNAME nopass
/etc/easy-rsa/easyrsa --batch sign-req client \$USERNAME
cp \$EASYRSA_DIR/pki/private/\$USERNAME.key /etc/openvpn/client-configs/keys/
cp \$EASYRSA_DIR/pki/issued/\$USERNAME.crt /etc/openvpn/client-configs/keys/
cd \$OPENVPN_DIR/client-configs/
cat \${BASE_CONFIG} <(echo -e '<ca>') \${KEY_DIR}/ca.crt <(echo -e '</ca>\n<cert>') \${KEY_DIR}/\${USERNAME}.crt <(echo -e '</cert>\n<key>') \${KEY_DIR}/\${USERNAME}.key <(echo -e '</key>\n<tls-auth>') \${KEY_DIR}/ta.key <(echo -e '</tls-auth>') > \${OUTPUT_DIR}/\$USERNAME.ovpn
SUBJECT="New OpenVPN \$USERNAME User"
BODY="Download this configuration and run it within your OpenVPN client."
FILE="\$USERNAME.ovpn"
READ="\$(printf '%q' "\$(cat \$OUTPUT_DIR/\$USERNAME.ovpn)")"
echo '{"Data": "From: $EMAIL\nTo: '\$VPNUSER'\nSubject: '\$SUBJECT'\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/plain\n\n'\$BODY'\n\n--NextPart\nContent-Type: application/ovpn;\nContent-Disposition: attachment; filename=\"'\$FILE'\"\n\n'\${READ:2:-1}'\n--NextPart--"}' > message.json
aws ses send-raw-email --region $CITY --raw-message file://message.json
rm message.json
cd \$EASYRSA_DIR
	expect <<-EOF
    spawn /etc/easy-rsa/easyrsa gen-crl
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect eof
	EOF
cp \$EASYRSA_DIR/pki/crl.pem \$OPENVPN_DIR/crl.pem
rm \${OUTPUT_DIR}/\$USERNAME.ovpn
systemctl restart openvpn@$COMPANY-vpn
fi
EOF
chmod +x /root/create_vpn_user
cat <<EOF >/root/revoke_vpn_user
#!/bin/bash
VPNUSER=\${1,,}
USERNAME="\$(echo "\$VPNUSER" | sed 's/.com//g; s/@/-/g')"
export EASYRSA_REQ_CN=\$USERNAME
KEY_DIR=/etc/openvpn/client-configs/keys
OUTPUT_DIR=/etc/openvpn/client-configs/files
BASE_CONFIG=/etc/openvpn/client-configs/base.conf
OPENVPN_DIR=/etc/openvpn
EASYRSA_DIR=/root
if [ "\$USERNAME" = '' ]; then
exit 1
else
cd \$EASYRSA_DIR
/etc/easy-rsa/easyrsa --batch revoke \$USERNAME
	expect <<-EOF
    spawn /etc/easy-rsa/easyrsa gen-crl
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect eof
	EOF
SUBJECT="Deleted OpenVPN user \$USERNAME"
BODY="OpenVpn user \$USERNAME is deleted."
echo '{"Data": "From: $EMAIL\nTo: '\$VPNUSER'\nSubject: '\$SUBJECT'\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/plain\n\n'\$BODY'\n\n--NextPart--"}' > message.json
aws ses send-raw-email --region $CITY --raw-message file://message.json
cp \$EASYRSA_DIR/pki/crl.pem \$OPENVPN_DIR/
systemctl restart openvpn@$COMPANY-vpn
fi
EOF
chmod +x /root/revoke_vpn_user
touch /root/{list_of_new_users.txt,list_of_vpn_users.txt}
cat <<EOF >/root/create_vpn_user_list
function line_exists_in_file {
    local line=\$1
    local file=\$2
    grep -Fxq "\$line" "\$file"
}
file1="/root/list_of_new_users.txt"
file2="/root/list_of_vpn_users.txt"
echo >> "\$file1"
echo >> "\$file2"
while IFS= read -r line
do
    if ! line_exists_in_file "\$line" "\$file2"
    then
    CRE="/root/create_vpn_user \$line"
	expect <<-EOF
    spawn \$CRE
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect eof
	EOF
    wait
    fi
done < "\$file1"

while IFS= read -r line
do
    if ! line_exists_in_file "\$line" "\$file1"
    then
    REV="/root/revoke_vpn_user \$line"
	expect <<-EOF
    spawn \$REV
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect -exact "\rEnter pass phrase for /root/pki/private/ca.key:"
    send -- "$COMPANY\r"
    expect eof
	EOF
    wait
    fi
done < "\$file2"
EOF
chmod +x /root/create_vpn_user_list
cat <<-EOF >>/etc/sysctl.conf
net.ipv4.ip_forward=1
EOF
sysctl -w net.ipv4.ip_forward=1
cat <<-EOF >/root/repair-net
#!/bin/bash
iptables -I INPUT -p udp --dport 1194 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o "$NETADAPT" -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.8.0.0/16 -d 10.0.0.0/16 -o "$NETADAPT" -j MASQUERADE
iptables-save
EOF
chmod +x /root/repair-net
bash /root/repair-net
cat <<-EOF >~/vpncron
0 0 * * sat apt -y update --security
1 0 * * * /root/repair-net
EOF
crontab ~/vpncron
systemctl start openvpn@"$COMPANY"-vpn
systemctl enable openvpn@"$COMPANY"-vpn