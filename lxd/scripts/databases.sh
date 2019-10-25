#!/usr/bin/env bash

set -o errexit

main() {

  export DEBIAN_FRONTEND='noninteractive'
  __install_packages
  __mysql_setup
  __turn_off_all
}

__install_packages() {
  # repo not have arm64 vesion
  #sudo apt-add-repository 'deb http://www.apache.org/dist/cassandra/debian 39x main'
  #sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net --recv-keys A278B781FE4B2BDA
  #wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
  #echo 'deb https://debian.neo4j.org/repo stable/' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
  sudo apt-get update -yqq
  sudo apt-get install -yqq \
    --no-install-suggests \
    --no-install-recommends \
    couchdb \
    mongodb-server;

    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password'
    sudo apt-get -y install mysql-server
}

__mysql_setup(){
  mysql -h localhost -NBe "CREATE USER 'travis'@'%' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO 'travis'@'%'; CREATE USER 'travis'@'localhost' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO 'travis'@'localhost'; CREATE USER 'travis'@'127.0.0.1' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO 'travis'@'127.0.0.1'"

  echo "[mysqld]
innodb_flush_log_at_trx_commit=0" > /etc/mysql/conf.d/innodb_flush_log_at_trx_commit.cnf
  chmod 644 /etc/mysql/conf.d/innodb_flush_log_at_trx_commit.cnf

  echo "[mysqld]
performance_schema=OFF" > /etc/mysql/conf.d/performance-schema.cnf
  chmod 644 /etc/mysql/conf.d/performance-schema.cnf

  echo "[client]
default-character-set = utf8
port = 3306
user = root
password =
socket = /var/run/mysqld/mysqld.sock

[mysql]
default-character-set = utf8" > /home/travis/.my.cnf
  chmod 640 /home/travis/.my.cnf
  chown travis:travis /home/travis/.my.cnf

  echo "export MYSQL_UNIX_PORT=/var/run/mysqld/mysqld.sock" > /home/travis/.bash_profile.d/travis-mysql.bash
  chmod 644 /home/travis/.bash_profile.d/travis-mysql.bash
  chown travis:travis /home/travis/.bash_profile.d/travis-mysql.bash

}

__turn_off_all() {
  systemctl stop couchdb mysql
  systemctl disable couchdb mysql
}

main "$@"
