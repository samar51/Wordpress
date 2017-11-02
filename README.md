# Wordpress
Wordpress installtion script in bash script:
this script install
Nginx ,php ,mysql and Wordpress and configure nginx PHP,mysql and Wordpress.
Required Operation system
Ubuntu VERSION="16.10 (Yakkety Yak)"
*********************************************************************
1.Your script will check if PHP, Mysql & Nginx are installed. If not present, missing packages will be installed.
2.The script will then ask user for domain name. (Suppose user enters example.com)
3.Create nginx config file for example.com
4.Download WordPress latest version from http://wordpress.org/latest.zip and unzip it locally in example.com document root.
5.Create a new mysql database for new WordPress. (database name “example.com_db” )
6.Create wp-config.php with proper DB configuration. (You can use wp-config-sample.php as your template)
7.You may need to fix file permissions, cleanup temporary files, restart or reload nginx config.
8.Tell user to open example.com in browser (if all goes well) LocalHost IP
