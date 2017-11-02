#!/bin/bash
#remove # from set -x for debugging
#set -x
#set -e
green=`tput setaf 2`
red=`tput setaf 1`
reset=`tput sgr0`
#updating the systempackage list update"
apt-get update
echo "******************************************************************"
echo "${green}updating of the packge index is done${reset}"
dpkg -l|grep -q nginx && echo "nginx package is already present on the server" || apt-get -y install nginx
mkdir /etc/nginx/backup
cp -pr /etc/nginx/sites-available/default /etc/nginx/backup/default.bak
NginxConfig=/etc/nginx/sites-available/default
#installing mysql-server if its not present inthe server
dpkg -l|grep -q mysql-server && echo "Mysql server is already present on the server" || apt-get -y install mysql-server
#installing php if its not present inthe server
dpkg -l|grep -q php-fpm php-mysql && echo "php is already instaalled" || apt-get -y install php-fpm php-mysql
echo "*****************************************************************************************************"
echo "${green}configuring php by editing the file /etc/php/7.0/fpm/php.ini${reset}"
grep -i cgi.fix_pathinfo=0  /etc/php/7.0/fpm/php.ini && echo "Already it is set to cgi.fix_pathinfo=0 "||sed -n 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/p' /etc/php/7.0/fpm/php.ini
cat <<EOF > info.php
<?php
phpinfo();
?>
EOF
systemctl restart php7.0-fpm 2>error.log||( echo "${red}Please check some issue with php installation and check the error.log file${reset}" && sleep 20 )

echo "${green}configuring nginx for serving php and wordpress files${reset}"
echo "${green}Removing moving the empty and few commented line from nginx config file /etc/nginx/sites-available/default  ${reset}"
sed -i -e '/^#/d' -e '/^$/d' $NginxConfig
#removing comment from #location and #}
echo "${green}removing comment from the #location and #} ${reset}"
sed -i -e 's/^\s*#l/l/' -e 's/^\s*#}/}/'  $NginxConfig
echo "${green}Adding index.php file to the ngix config file${reset}"
grep "^\s*index" $NginxConfig|grep -q index.php|| sed -i '/^\s*index/ s/;/ index.php;/' $NginxConfig
sed -i '/.ht {/,// s/^\s*#\s*deny/deny/' $NginxConfig
sed -i '/.php$ /,/}/ s/^\s*#\s*include/include/' $NginxConfig
sed -i '/.php$ /,/}/ s/^\s*#\s*fastcgi_pass unix/fastcgi_pass unix/' $NginxConfig
echo "Reloading the configuration file of nginx"
sleep 3
systemctl reload nginx 2>error.log||( echo "check the nginxconfig file.some syntax error check error.log" && rm $NginxConfig && cp -pr /etc/nginx/backup/default.bak $NginxConfig && sleep 20)
echo "${green}Nginx and php has been configured${reset}"
echo " Please try in the browser IpAddress/info.php to see if php works"
read -p "please enter p for proceeding........................."

echo "sleeping for 60 second..."
sleep 10
echo "Installaing mysql-server and setting up the wordpress database and tables"
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
dpkg -l|grep -q mysql-server && "Mysql server is already present on the server" || apt-get -y install mysql-server
echo "creating database name:  wordpressDb  ,username : wordpressuser"
mysql -u root -proot <<EOF 2>>error.log
CREATE DATABASE wordpressDb;
CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpressDb.* TO wordpressuser@localhost;
FLUSH PRIVILEGES;
exit
EOF
echo "database and wordpressuser has been created "
echo "downloading wordpress from internet"
wget -c http://wordpress.org/latest.tar.gz 2>>error.log|| ( "echo some problem occured while downloading .check error.log  file for more info" && exit 1)

#checing if the file got downloaded or not
if [ -e latest.tar.gz ]
then
    tar -xzvf latest.tar.gz
        rsync -av wordpress/* /var/www/html/
else
    echo "latest.tar.gz file is not present.exiting Please check internet connection"
        sleep 3
        exit 1
fi
echo "changing the ownership of /var/www/html/ to www-data and permission to 755"
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
cd /var/www/html/ && (cp -pr wp-config-sample.php wp-config-sample.php.bak && mv wp-config-sample.php wp-config.php)|| exit 1

sed -i "/DB_NAME/ s/\s'\w\+'/ 'wordpressDb'/" wp-config.php
sed -i "/DB_USER/ s/\s'\w\+'/ 'wordpressuser'/" wp-config.php
sed -i "/DB_PASSWORD/ s/\s'\w\+'/ 'password'/" wp-config.php
systemctl restart nginx >>error.log|| ( echo "check the eoor.log file for troubleshooting" && sleep 3 && exit 1)
systemctl restart mysql.service >>error.log|| ( echo "check the eoor.log file for troubleshooting.exiting........" && sleep 3 && exit 1)
echo "wordpress installtion is compete"
echo "please use the database Name:wordpressDb  username: wordpressuser and password: password for loggin into wordpress website "
