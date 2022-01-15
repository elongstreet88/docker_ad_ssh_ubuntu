#!/bin/bash
set -e

# check mandatory input
[ -z "${KERBEROS_REALM}" ] && echo "KERBEROS_REALM must be defined"
[ -z "${LDAP_URI}" ] && echo "LDAP_URI must be defined"
[ -z "${LDAP_BASE_DN}" ] && echo "LDAP_BASE_DN must be defined"
[ -z "${LDAP_BIND_DN}" ] && echo "LDAP_BIND_DN must be defined"
[ -z "${LDAP_BIND_PASSWORD}" ] && echo "LDAP_BIND_PASSWORD must be defined"
[ -z "${ALLOWED_SSH_DOMAIN_GROUPS}" ] && echo "ALLOWED_SSH_DOMAIN_GROUPS must be defined"

# check optional input
[ -z "${KERBEROS_DNS_DISCOVERY_DOMAIN}" ] && KERBEROS_DNS_DISCOVERY_DOMAIN=${KERBEROS_REALM}
[ -z "${LDAP_USER_PRINCIPAL}" ] && LDAP_USER_PRINCIPAL="userPrincipalName"
[ -z "${LDAP_ENUMERATE}" ] && LDAP_ENUMERATE="false"
[ -z "${LDAP_IGNORE_GROUP_MEMBERS}" ] && LDAP_IGNORE_GROUP_MEMBERS="true"
[ -z "${LDAP_USER_MEMBEROF}" ] && LDAP_USER_MEMBEROF="memberOf"
[ -z "${SSH_TIMEOUT_SECONDS}" ] && SSH_TIMEOUT_SECONDS="3600"
[ -z "${ALLOWED_SUDO_DOMAIN_GROUPS}" ] && ALLOWED_SUDO_DOMAIN_GROUPS=""

# put config files in place
cat >/etc/krb5.conf <<EOL
[libdefaults]
    default_realm = ${KERBEROS_REALM}
    dns_lookup_realm = true
    dns_lookup_kdc = true
EOL

# Update SSD Config
cat >/etc/sssd/sssd.conf <<EOL
[sssd]
config_file_version = 2
services = nss, pam
domains = ${KERBEROS_REALM}

[domain/${KERBEROS_REALM}]
enumerate = ${LDAP_ENUMERATE}
ignore_group_members = ${LDAP_IGNORE_GROUP_MEMBERS}
cache_credentials = true
id_provider = ldap
access_provider = ldap
auth_provider = krb5
chpass_provider = krb5
ldap_uri = ${LDAP_URI}
ldap_search_base = ${LDAP_BASE_DN}
krb5_realm = ${KERBEROS_REALM}
dns_discovery_domain = ${KERBEROS_DNS_DISCOVERY_DOMAIN}
ldap_tls_reqcert = never
ldap_schema = ad
ldap_id_mapping = True
ldap_user_principal = ${LDAP_USER_PRINCIPAL}
ldap_user_member_of = ${LDAP_USER_MEMBEROF}
ldap_access_order = expire
ldap_account_expire_policy = ad
ldap_force_upper_case_realm = true
ldap_user_search_base =  ${LDAP_BASE_DN}
ldap_group_search_base =  ${LDAP_BASE_DN}
ldap_default_bind_dn = ${LDAP_BIND_DN}
ldap_default_authtok = ${LDAP_BIND_PASSWORD}
sudo_provider = none
fallback_homedir = /home/%d/%u
default_shell = /bin/bash
skel_dir = /etc/skel
krb5_auth_timeout=60
debug_level = 4
EOL

# Update NSS Config
cat >/etc/nsswitch.conf <<EOL
passwd:         compat sss
group:          compat sss
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files
netgroup:       nis sss
EOL

# fix permissions
chmod 600 /etc/sssd/sssd.conf

# create db directory if not exists
mkdir -p /var/lib/sss/db
mkdir -p /var/lib/sss/pipes/private
mkdir -p /var/lib/sss/mc

# Set MOTD
cat >/etc/motd <<EOL

+++++++++++++++++++++++++++++++++++++++++++
  Welcome to the Jump Farm!
+++++++++++++++++++++++++++++++++++++++++++

A few notes/tips:
1. SSH access is only available to the domain groups:
     [${ALLOWED_SSH_DOMAIN_GROUPS}]
2. Running [sudo] is only available to the domain groups:
     [${ALLOWED_SUDO_DOMAIN_GROUPS}]
3. Changes to this jump farm such as [apt install] will be lost, make changes to the image source only.
4. Use screen! It persists your session even if you lose connection.
     screen -h

EOL

# Enable automated creation of hom directory
pam-auth-update --enable mkhomedir

# Allowed sudo users
IFS=, read -ra vals <<< ${ALLOWED_SUDO_DOMAIN_GROUPS}
for v in "${vals[@]}"
do
  #Replace " " with "\ "
  group_formatted=${v//\ /\\ }
  echo "%$group_formatted  ALL=(ALL:ALL) ALL" >> /etc/sudoers
done

# Allowed ssh groups
# Replace " " with "?" 
groups_formatted=${ALLOWED_SSH_DOMAIN_GROUPS//\ /?}
# Replace "," with " " 
groups_formatted=${groups_formatted//,/ }
echo "AllowGroups ${groups_formatted}" >> /etc/ssh/sshd_config

# SSH Timeout
echo "ClientAliveInterval ${SSH_TIMEOUT_SECONDS}" >> /etc/ssh/sshd_config

# Start SSH (runs in background)
service ssh start

# Start [CMD] passed in
exec "$@"