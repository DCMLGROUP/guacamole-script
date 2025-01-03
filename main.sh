# Mise à jour du système et installation des dépendances
apt-get update
apt-get install -y wget curl build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev tomcat9 mysql-server mysql-client

# Installation des dépendances additionnelles pour activer toutes les fonctionnalités
apt-get install -y libavformat-dev libpulse-dev libwebsockets-dev kubernetes-client libavformat-dev libpulse-dev libwebsockets-dev libsystemd-dev

# Installation de Java
apt-get install -y openjdk-11-jdk maven
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
source /etc/environment

cd ~
wget https://downloads.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz
tar -xzf guacamole-server-1.5.5.tar.gz
cd guacamole-server-1.5.5

# Configuration et compilation avec toutes les fonctionnalités activées
./configure --with-systemd --enable-allow-freerdp-snapshots
make
make install
ldconfig

# Création du service guacd
cat > /etc/systemd/system/guacd.service << EOF
[Unit]
Description=Guacamole proxy daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/guacd -f
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Création de la base de données
mysql -u root -p <<EOF
DROP DATABASE IF EXISTS guacamole_db;
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Téléchargement des extensions Guacamole
cd ~
mkdir -p /etc/guacamole/extensions
cd /etc/guacamole/extensions

# Extension Auth JDBC (MySQL)
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar -xzf guacamole-auth-jdbc-1.5.5.tar.gz
mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar .
rm -rf guacamole-auth-jdbc-1.5.5*

# Extension Auth LDAP
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-ldap-1.5.5.tar.gz
tar -xzf guacamole-auth-ldap-1.5.5.tar.gz
mv guacamole-auth-ldap-1.5.5/guacamole-auth-ldap-1.5.5.jar .
rm -rf guacamole-auth-ldap-1.5.5*

# Extension Auth TOTP
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-totp-1.5.5.tar.gz
tar -xzf guacamole-auth-totp-1.5.5.tar.gz
mv guacamole-auth-totp-1.5.5/guacamole-auth-totp-1.5.5.jar .
rm -rf guacamole-auth-totp-1.5.5*

# Extension Auth Duo
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-duo-1.5.5.tar.gz
tar -xzf guacamole-auth-duo-1.5.5.tar.gz
mv guacamole-auth-duo-1.5.5/guacamole-auth-duo-1.5.5.jar .
rm -rf guacamole-auth-duo-1.5.5*

# Extension Auth Header
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-header-1.5.5.tar.gz
tar -xzf guacamole-auth-header-1.5.5.tar.gz
mv guacamole-auth-header-1.5.5/guacamole-auth-header-1.5.5.jar .
rm -rf guacamole-auth-header-1.5.5*

# Extension Auth JSON
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-json-1.5.5.tar.gz
tar -xzf guacamole-auth-json-1.5.5.tar.gz
mv guacamole-auth-json-1.5.5/guacamole-auth-json-1.5.5.jar .
rm -rf guacamole-auth-json-1.5.5*

# Extension Auth SAML
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-saml-1.5.5.tar.gz
tar -xzf guacamole-auth-saml-1.5.5.tar.gz
mv guacamole-auth-saml-1.5.5/guacamole-auth-saml-1.5.5.jar .
rm -rf guacamole-auth-saml-1.5.5*

# Extension Auth OpenID
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-openid-1.5.5.tar.gz
tar -xzf guacamole-auth-openid-1.5.5.tar.gz
mv guacamole-auth-openid-1.5.5/guacamole-auth-openid-1.5.5.jar .
rm -rf guacamole-auth-openid-1.5.5*

# Extension Vault
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-vault-1.5.5.tar.gz
tar -xzf guacamole-vault-1.5.5.tar.gz
mv guacamole-vault-1.5.5/guacamole-vault-1.5.5.jar .
rm -rf guacamole-vault-1.5.5*

# Nettoyage des fichiers temporaires
rm -f *.tar.gz

# Téléchargement et installation du connecteur MySQL pour Guacamole
cd /etc/guacamole
mkdir -p lib
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz
tar -xzf mysql-connector-j-8.0.33.tar.gz
mv mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar lib/
rm -rf mysql-connector-j-8.0.33*
rm -f mysql-connector-j-8.0.33.tar.gz

# Définition des permissions pour le connecteur MySQL
chown tomcat:tomcat lib/mysql-connector-j-8.0.33.jar
chmod 644 lib/mysql-connector-j-8.0.33.jar

# Définition des permissions
chown -R tomcat:tomcat /etc/guacamole
chmod 755 /etc/guacamole

# Création du fichier guacamole.properties avec configuration étendue
cat > /etc/guacamole/guacamole.properties << 'EOF'
# Configuration MySQL (Active)
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: votre_mot_de_passe

# Configuration réseau Guacamole (Commentée)
guacd-hostname: localhost
guacd-port: 4822
guacd-ssl: false

# Configuration LDAP (Commentée)
#ldap-hostname: ldap.exemple.com
#ldap-port: 389
#ldap-encryption-method: none
#ldap-max-search-results: 1000
#ldap-search-bind-dn: cn=admin,dc=exemple,dc=com
#ldap-search-bind-password: mot_de_passe_admin
#ldap-user-base-dn: ou=Users,dc=exemple,dc=com
#ldap-username-attribute: uid
#ldap-group-base-dn: ou=Groups,dc=exemple,dc=com
#ldap-group-name-attribute: cn
#ldap-member-attribute: member
#ldap-user-search-filter: (objectClass=inetOrgPerson)
#ldap-follow-referrals: true

# Configuration SAML (Commentée)
#saml-idp-url: https://idp.exemple.com
#saml-idp-metadata-url: https://idp.exemple.com/metadata
#saml-entity-id: https://guacamole.exemple.com
#saml-callback-url: https://guacamole.exemple.com/guacamole/
#saml-strict: true
#saml-compress-requests: true
#saml-compress-responses: true
#saml-groups-attribute: groups
#saml-debugging: false

# Configuration du comportement de l'interface (Commentée)
api-session-timeout: 60
allowed-languages: en, fr, pt
default-language: fr

# Configuration de la sécurité (Commentée)
#secret-key: votre_clé_secrète_très_longue
#disable-auth-cache: false
#enable-clipboard-integration: true
#enable-file-transfer: true

# Configuration de l'impression
enable-printing: true
printing-default-mode: rdp
printing-allow-pdf: true
printing-max-dpi: 600
printing-default-dpi: 300
printing-enable-local-redirect: true
printing-enable-rdp-printer: true
printing-rdp-printer-name: "Guacamole RDP Printer"
printing-rdp-driver: "MS Publisher Imagesetter"
printing-rdp-enable-driver-isolation: true
printing-rdp-printer-mapping: true

# Configuration des connexions (Commentée)
enable-websocket: true
websocket-connection-timeout: 60
enable-connection-history: true

# Tolérance aux pannes et performance (Commentée)
#mysql-absolute-timeout: 600
#mysql-default-max-connections-per-user: 10
#mysql-default-max-group-connections-per-user: 10
#mysql-user-required: true

# Audit et journalisation (Commentée)
enable-session-recording: true
session-recording-path: /var/lib/guacamole/recordings
recording-search-path: /var/lib/guacamole/recordings

# Configuration du proxy (Commentée)
#http-proxy-hostname: proxy.exemple.com
#http-proxy-port: 3128
#http-proxy-username: proxy_user
#http-proxy-password: proxy_password

# Configuration TOTP
totp-issuer: Guacamole
totp-digits: 6
totp-period: 30
totp-mode: sha1
totp-shared-secret-length: 32
totp-shared-secret-algorithm: HmacSHA1

# Configuration avancée de la session (Commentée)
max-concurrent-sessions: 20

# Configuration du tunnel (Commentée)
enable-force-secure: true
allow-tunnel-connect: true
tunnel-read-timeout: 600
tunnel-connect-timeout: 60
EOF

# Configuration des permissions
chown -R tomcat:tomcat /etc/guacamole
chmod 750 /etc/guacamole
chmod 640 /etc/guacamole/guacamole.properties

cd ~/guacamole-client-1.5.5
cat ./extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-mysql/schema/*.sql | mysql -u root -p guacamole_db

systemctl daemon-reload
systemctl enable guacd
systemctl start guacd
systemctl restart tomcat9

systemctl status guacd
systemctl status tomcat9