#/bin/bash
#centos6
soft_dir='/root/soft'
pro_pyenv='/etc/profile.d/pyenv.sh'
new_passwd="123456"
/usr/sbin/setenforce 0
ulimit -u 65535
ulimit -n 4096
#-------------------------------------------------------------------------
function Timezone()
{   
    #egrep -i "centos" /etc/issue && SysName='centos';
	whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
	rm -rf /etc/localtime;
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;

	echo '[ntp Installing] ******************************** >>';
	[ "$SysName" == 'centos' ] && yum install -y ntp || apt-get install -y ntpdate;
	ntpdate -u pool.ntp.org;
	StartDate=$(date);
	StartDateSecond=$(date +%s);
	echo "Start time: ${StartDate}";
}

function CloseSelinux()
{
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
	setenforce 0 >/dev/null 2>&1;
}

function Install_base_env(){
    yum update -y
    yum groupinstall -y "Development tools"
    yum install  -y wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel python-devel tcl git python-pip lrzsz

}

function Install_py_env(){
    git clone git://github.com/yyuu/pyenv.git  pyenv
#-------EOF------------------------------
cat  >  ${pro_pyenv}  << EOF
#!/bin/bash
export PYENV_ROOT="$HOME/pyenv" 
export PATH="$PYENV_ROOT/bin:$PATH"  
eval "\$(pyenv init -)"
EOF
#--------------------------------------------
    source  ${pro_pyenv}
    }
	
function Install_py27(){
    pyenv install  2.7.8
    pyenv local  2.7.8
    pyenv versions
}
function Install_mod(){
    pyenv local  2.7.8
    pip install gevent protobuf flask affinity pymysql redis pycrypto
}
function Install_mysql_net(){
    yum  install  mysql-server mysql-devel
    /etc/init.d/mysql start
    mysqladmin -uroot password ${my_passwd}
    mysql -uroot -p${my_passwd} -e "delete from mysql.user where user='';"
    mysql -uroot -p${my_passwd} -e "delete from mysql.user where password='';"
}
function Install_redis(){
    mkdir -p /data/redis_db/6379
    mkdir -p /data/redis_db/log
    cd ${soft_dir}
    cp 6379.conf  /etc/redis.conf
    tar zxf redis-2.8.3.tar.gz
    cd ${soft_dir}/redis-2.8.3/src
    make
    make prefix=/usr/local/    install
    cd 
    redis-server /etc/redis.conf &
}
function Install_mysql(){
    cd ${soft_dir}
    cp my.cnf  /usr/
	#yum remove -y mysql-libs
    rpm -e --nodeps  mysql-libs-5.1.73-3.el6_5.x86_64
    rpm -ivh MySQL-devel*
    rpm -ivh MySQL-client*
    rpm -ivh MySQL-server*
    mysql_install_db --datadir=/data/mysql  --user=mysql
    /usr/bin/mysqld_safe &
    old_passwd=`cut -d: -f4 /root/.mysql_secret`
    mysql -uroot  -p${old_passwd} -e "SET PASSWORD = PASSWORD('123456');"
    echo "Mysql    root:${old_passwd}"
    echo "Mysql    root:${new_passwd}"
}
function Install_game(){
    cd ${soft_dir}
    tar zxvf traversing_v0.1.9t.tar.gz
    mv traversing_v0.1.9t   /root/games
    cd /root/games
    pyenv local  2.7.8
    python startmaster.py &
}
############################################################
Install_mysql;
