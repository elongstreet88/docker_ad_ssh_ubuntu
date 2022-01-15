# Variables
KERBEROS_REALM="YOURDOMAIN.COM"
LDAP_BASE_DN="OU=Admin,DC=yourdomain,DC=com"
LDAP_BIND_DN="CN=An Ldap Service Account,OU=Admin,DC=yourdomain,DC=com"
LDAP_URI="ldap://ad1.yourdomain.com/"
LDAP_BIND_PASSWORD="test123"
ALLOWED_SSH_DOMAIN_GROUPS="Domain Admins,Group A,Group B"
ALLOWED_SUDO_DOMAIN_GROUPS="Domain Admins"

# Run
docker build -t jump-farm .

# Tips
echo '\n'
echo 'Useful Commands'
echo 'SSH with creds:    [ssh domain_samaccountname@localhost -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no]'
echo 'See SSSD logs:     [tail -f /var/log/sssd/*.log]'
echo 'Test SSSD working: [id domain_samaccountname]'
echo 'Debug this build:  [./run.sh bash]'
echo '\n'

# Run
docker run \
--env KERBEROS_REALM="$KERBEROS_REALM" \
--env LDAP_BASE_DN="$LDAP_BASE_DN" \
--env LDAP_BIND_DN="$LDAP_BIND_DN" \
--env LDAP_BIND_PASSWORD="$LDAP_BIND_PASSWORD" \
--env LDAP_URI="$LDAP_URI" \
--env ALLOWED_SSH_DOMAIN_GROUPS="$ALLOWED_SSH_DOMAIN_GROUPS" \
--env ALLOWED_SUDO_DOMAIN_GROUPS="$ALLOWED_SUDO_DOMAIN_GROUPS" \
-p 2222:22 \
-it jump-farm "$@"