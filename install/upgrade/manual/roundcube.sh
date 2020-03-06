source $HESTIA/func/main.sh

mkdir -p /var/lib/roundcube
mkdir -p /etc/roundcube
mkdir -p /var/log/roundcube

# Destroy and recreate the database to clear it
mysql -e "drop database roundcube"
mysql -e "create database roundcube"
# Connect the existing roundcube user to the new database
mysql -e "grant all on roundcube.* to roundcube@localhost"
# Download/install the latest complete version to the working directory
wget -P /tmp/ https://github.com/roundcube/roundcubemail/releases/download/1.4.3/roundcubemail-1.4.3-complete.tar.gz
tar -C /var/lib/roundcube/ -xzf /tmp/roundcubemail-1.4.3-complete.tar.gz --strip 1
# Do some cleaning
rm /tmp/roundcubemail-1.4.3-complete.tar.gz
# Install initial database
mysql roundcube < /var/lib/roundcube/SQL/mysql.initial.sql
# Backup default config and log directories or remove them
mkdir -p /usr/share/roundcube/plugins/password/drivers/

mv /var/lib/roundcube/config /var/lib/roundcube/config_backup
mv /var/lib/roundcube/logs /var/lib/roundcube/logs_backup
# Link the config and log locations to the existing locations
ln -s /etc/roundcube/ /var/lib/roundcube/config
ln -s /var/log/roundcube/ /var/lib/roundcube/logs

cp -f $HESTIA_INSTALL_DIR/roundcube/main.inc.php /etc/roundcube/config.inc.php
cp -f $HESTIA_INSTALL_DIR/roundcube/db.inc.php /etc/roundcube/debian-db-roundcube.php
cp -f $HESTIA_INSTALL_DIR/roundcube/config.inc.php /etc/roundcube/plugins/password/
cp -f $HESTIA_INSTALL_DIR/roundcube/hestia.php /usr/share/roundcube/plugins/password/drivers/

touch /var/log/roundcube/errors
chmod 640 /etc/roundcube/config.inc.php
chown root:www-data /etc/roundcube/config.inc.php
chmod 640 /etc/roundcube/debian-db-roundcube.php
chown root:www-data /etc/roundcube/debian-db-roundcube.php
chmod 640 /var/log/roundcube/errors
chown www-data:adm /var/log/roundcube/errors

r="$(gen_pass)"
rcDesKey="$(openssl rand -base64 30 | tr -d "/" | cut -c1-24)"
mysql -e "CREATE DATABASE roundcube"
mysql -e "GRANT ALL ON roundcube.*
    TO roundcube@localhost IDENTIFIED BY '$r'"
sed -i "s/%password%/$r/g" /etc/roundcube/debian-db-roundcube.php
sed -i "s/%des_key%/$rcDesKey/g" /etc/roundcube/config.inc.php
sed -i "s/localhost/$servername/g" /etc/roundcube/plugins/password/config.inc.php
mysql roundcube < /usr/share/dbconfig-common/data/roundcube/install/mysql

 # Add robots.txt
echo "User-agent: *" > /var/lib/roundcube/robots.txt
echo "Disallow: /" >> /var/lib/roundcube/robots.txt

phpenmod mcrypt > /dev/null 2>&1