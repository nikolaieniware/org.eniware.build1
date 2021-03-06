#!/bin/bash
# 
# SysV init script for the EniwareEdge daemon for Apache Felix. Designed
# to be run as an /etc/init.d service by the root user.
#
# chkconfig: 3456 99 01
# description: Control the EniwareEdge Felix server
#
# Set JAVA_HOME to the path to your JDK or JRE.
# 
# Set ENIWAREEDGE_HOME to the directory that contains the following:
# 
# + <ENIWAREEDGE_HOME>/
# |
# +--+ felix/                     <-- Felix install dir
# |  |
# |  +--+ bin/
# |     |
# |     +-- felix.jar
# |
# +--+ conf/                      <-- configuration
# |  |
# |  +-- config.properties        <-- main Felix configuration
# |  +-- system.properties        <-- custom system properties
# |  +-- eniwareedge.xml
# |  +-- db.normal.properties     <-- normal DB properties
# |  +-- db.recover.properties    <-- recover DB properties
# |
# +--+ app/                      
#    |
#    +--+ boot/                   <-- OSGi bootstrap bundles
#    +--+ main/                   <-- EniwareEdge OSGi bundles
#
#
# Set PID_FILE to the path to the same path as specified in 
# eniwareedge.properties for the Edge.pidfile setting.
# 
# Set RUNAS to the name of the user to run the process as. The script
# will use "su" to run the Edge as this user, in the background.
# 
# The application is expected to be configured such that the main
# database and log files are stored in an OS-configured RAM disk,
# such as /dev/shm. This script will use rsync when the "stop"
# command is used to sync the DB_DIR contents into DB_BAK_DIR.
# When the "start" command is used, this script checks for the 
# existence of DB_BAK_DIR and if DB_DIR does not exist, will copy
# DB_BAK_DIR to DB_DIR before starting up the application.
# 
# A typical RAM disk hierarchy looks like the following:
# 
# + <RAM_DISK>/
# |
# +--+ db/                        <-- Main database
# +--+ log/                       <-- Application logs
# 
# Modify the APP_ARGS and JVM_ARGS variables as necessary.

JAVA_HOME=/usr/lib/jvm/java-6-openjdk
ENIWAREEDGE_HOME=/home/eniware
RAM_DIR=/dev/shm/eniware
LOG_DIR=${RAM_DIR}/log
DB_DIR=${RAM_DIR}/db
VAR_DIR=${ENIWAREEDGE_HOME}/var
DB_BAK_DIR=${VAR_DIR}/db-bak
FELIX_CACHE=${RAM_DIR}/felix-cache
FELIX_HOME=${ENIWAREEDGE_HOME}/felix
PID_FILE=${ENIWAREEDGE_HOME}/var/eniwareedge-felix.pid
APP_ARGS="-Dfelix.config.properties=file:${ENIWAREEDGE_HOME}/conf/config.properties -Dfelix.system.properties=file:${ENIWAREEDGE_HOME}/conf/system.properties -Dsn.home=${ENIWAREEDGE_HOME}"
JVM_ARGS="-Xmx48m"
#JVM_ARGS="-Dcom.sun.management.jmxremote"
#JVM_ARGS="Xdebug -Xnoagent -Xrunjdwp:server=y,transport=dt_socket,address=9142,suspend=y"

RUNAS=eniware

START_CMD="${JAVA_HOME}/bin/java ${JVM_ARGS} ${APP_ARGS} -jar ${FELIX_HOME}/bin/felix.jar ${FELIX_CACHE}"
START_SLEEP=5s
STOP_TRIES=5

# function to create directory if doesn't already exist
setup_dir () {
	if [ ! -e $1 ]; then
		if [ -z "${RUNAS}" ]; then
			mkdir $1
		else
			su -c "mkdir -p $1" $RUNAS
		fi
	fi
}

# function to stop process and wait for it to terminate
stop_proc () {
	pid=$1
	count=$2
	while let count-=1 && kill "$pid" 2>/dev/null; do
		sleep 0.5
	done
}

# function to start up process
do_start () {
	echo -n "Starting Eniware Edge server... "
	# Verify ram dir exists; create if necessary
	setup_dir ${RAM_DIR}
	
	# Verify log dir exists; create if necessary
	setup_dir ${LOG_DIR}
	
	# Verify var dir exists; create if necessary
	setup_dir ${VAR_DIR}
	
	# Check to restore backup database
	if [ ! -e ${DB_DIR} -a -e ${DB_BAK_DIR} ]; then
		echo -n "restoring database... "
		cp -a ${DB_BAK_DIR} ${DB_DIR}
	fi
	
	if [ -z "${RUNAS}" ]; then
		${START_CMD} 1>${LOG_DIR}/stdout.log 2>&1 &
	else
		su -l -c "${START_CMD} 1>${LOG_DIR}/stdout.log 2>&1 &" $RUNAS
	fi
	echo -n "sleeping for ${START_SLEEP} to check PID... "
	sleep ${START_SLEEP}
	if [ -e $PID_FILE ]; then
		echo "Running as PID" `cat $PID_FILE`
	else
		echo "Eniware Edge does not appear to be running."
	fi
}

# function to stop process
do_stop () {
	pid=
	run=
	if [ -e $PID_FILE ]; then
		pid=`cat $PID_FILE`
		run=`ps -o pid= -p $pid`
	fi
	if [ -n "$run" ]; then
		echo -n "Stopping Eniware Edge $pid... "
		stop_proc $pid $STOP_TRIES
		run=`ps -o pid= -p $pid`
		
		# Backup DB to persistent storage
		if [ -z "$run" -a -e ${DB_DIR} ]; then
			echo -n "syncing database to backup dir... "
			setup_dir ${DB_BAK_DIR}
			rsync -am --delete ${DB_DIR}/* ${DB_BAK_DIR} 1>/dev/null 2>&1
		fi
		echo "done."
	else
		echo "Eniware Edge does not appear to be running."
	fi
}

# function to check status
do_status () {
	pid=
	run=
	if [ -e $PID_FILE ]; then
		pid=`cat $PID_FILE`
		run=`ps -o pid= -p $pid`
	fi
	if [ -n "$run" ]; then
		echo "Eniware Edge is running (PID $pid)"
	else
		echo "Eniware Edge does not appear to be running."
	fi
}

# Parse command line parameters.
case $1 in
	start)
		do_start
		;;

	status)
		do_status
		;;
	
	stop)
		do_stop
		;;

	*)
		# Print help
		echo "Usage: $0 {start|stop|status}" 1>&2
		exit 1
		;;
esac

exit 0

