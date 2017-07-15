#! /bin/bash

# Must use ROOT or sudo to execute

# Enable the MySQL repo
mv /etc/yum.repos.d/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7.repo.bak
sed '/ol7_MySQL57/{ n; n; n; n; n; s/enabled=0/enabled=1/; }' \
	/etc/yum.repos.d/public-yum-ol7.repo.bak > \
	/etc/yum.repos.d/public-yum-ol7.repo

# Install MySQL 5.7 and Keepalived
yum install -y mysql-community-server keepalived

mv /tmp/my$1.cnf /etc/my.cnf
mv /tmp/keepalived$1.conf /etc/keepalived/keepalived.conf

mkdir -p /usr/local/mysql/bin/
mv /tmp/mysql.sh /usr/local/mysql/bin/mysql.sh
chmod +x /usr/local/mysql/bin/mysql.sh

systemctl start mysqld

# Read the temp root password and reset
mysqlpwd=$(grep 'temporary password' /var/log/mysqld.log \
	| egrep -o 'localhost.+' | sed -e 's/localhost: //g')
mysql -u root -p$mysqlpwd --connect-expired-password \
	-e "SET PASSWORD = PASSWORD('Welcome#123')"
mysql -u root -pWelcome#123 \
	-e "grant all on *.* to ha@'192.168.2.%' identified by 'Welcome#123';"
if test $1 = "1" ; then
	mysql -u root -pWelcome#123 \
		-e "change master to master_host='192.168.2.12',master_user='ha',master_password='Welcome#123',master_log_file='mysql-bin.000002',master_log_pos=398;"
else
	mysql -u root -pWelcome#123 \
		-e "change master to master_host='192.168.2.11',master_user='ha',master_password='Welcome#123',master_log_file='mysql-bin.000002',master_log_pos=398;"
fi

mysql -u root -pWelcome#123 -e "start slave;"

systemctl reload keepalived
systemctl start keepalived

mkdir -p /root/.opc/profiles
mv /tmp/default /root/.opc/profiles
mv /tmp/pwd /root/.opc/profiles
chmod 600 /root/.opc/profiles/*
chmod +x /tmp/opc
mv /tmp/opc /usr/local/bin

rm -fr /tmp/my*.cnf /tmp/keepalived*.conf
