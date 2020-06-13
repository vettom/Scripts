#!/bin/bash
# ----------------------------------------------------------------------------
#
# Script:  This file will process file created by tsx-conf.ksh and generate
# file suitable for cssh to process. Replace resulting file with /etc/cluster
# Usage:
#
# Dependencies: AWS Cli and a default account set
#
# Additions:
#
# ----------------------------------------------------------------------------
# History:
# ----------------------------------------------------------------------------
# Name      	Date        	Comment                     	Version
# ----------------------------------------------------------------------------
# DV        	26/07/16    	Initial creation.
# ----------------------------------------------------------------------------

PATH=$PATH:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/opt/csw/bin:/usr/ccs/bin
HOSTNAME=`hostname`
DATE=`date +%Y%m%d`
TIMESTAMP=`date +%H%M.%Y%m%d`
N_ARG=$#
SCR_HOME=`dirname $0`
SCR_NAME=`basename $0`
ERROR_FLAG=0
[[ $SCR_HOME = . ]] && SCR_HOME=`pwd`

## Define/modify following variable as required.




# ----------------------------------------------------------------------------
# Default functions. Avoid modifying this section
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# If USER_ID is set verify the the script is running as specified user
# ----------------------------------------------------------------------------
if [ ! -z $USER_ID ]
then
    	CURRENT_USER_ID=`id | awk -F\( '{ print $2 }' | awk -F\) '{ print $1 }'`
    	if [ ${CURRENT_USER_ID} != ${USER_ID} ];then
            	echo "	ERROR! this script must be executed as user [${USER_ID}]. Your current ID is [${CURRENT_USER_ID}]." | tee -ai $LOG
            	ERROR_FLAG=1
            	FINISH
            	exit
    	fi
fi

# ----------------------------------------------------------------------------
# function  LOGTIDY to clear old logs/files while keeping specified number copy. Accepts 2 arguments FILE-NAME and Number
# of backups required.
# ----------------------------------------------------------------------------
function LOGTIDY
{
# Two arguments are expected and if not function will fail
#ARG1= Log file name
#ARG2= Number of files to retain
ARG=$#
    	if [ $ARG -lt 2 ]
            	then
            	echo "Two arguments are expected log file name and number of backups required."
            	echo "LOGTIDY domain.log 5"
    	fi

LOGFILE=$1
VER=$2

    	while [ $VER -gt 1 ]
    	do
            	PREV_VER=`expr $VER - 1 `
            	test -f "$LOGFILE.$PREV_VER" && mv "$LOGFILE.$PREV_VER"  "$LOGFILE.$VER"
            	VER=`expr $VER - 1 `
    	done

    	test -f $LOGFILE && mv $LOGFILE $LOGFILE.1
}

# ----------------------------------------------------------------------------
# Check if a task failed or not, if failed append message to $LOG and set ERROR_FLAG and FINISH
# ----------------------------------------------------------------------------

function CHECK_FAILURE
{
    	if [ $1 -ne 0 ]
    	then
            	echo "$2" | tee -ai ${LOG}
            	ERROR_FLAG=1
            	FINISH
    	fi
}

# -------------------------------------------------------------------
#   	END of STANDARD FUNCTIONS and declaration.
# -------------------------------------------------------------------
#
#Generate clusters file from RoyalTsX file
if [ -f $SCR_HOME/TSX_all_Topologies.csv ]
then
  #Parse file to generate clusters file
  TOPOLOGY=""
   for TOPOLOGY in `cat $SCR_HOME/TSX_all_Topologies.csv | awk -F\; '{ print $1 }' | grep -v ^$ | sort | uniq`
   do
	grep $TOPOLOGY $SCR_HOME/TSX_all_Topologies.csv | awk -F\; '{print $2 }' |awk 'BEGIN { printf "'$TOPOLOGY' = " }{printf "%s",$0 " " } END {print ""}'
	#Create entry for all Publishers
	grep $TOPOLOGY $SCR_HOME/TSX_all_Topologies.csv | grep -i publish | awk -F\; '{print $2 }' |awk 'BEGIN { printf "'$TOPOLOGY-PUB' = " }{printf "%s",$0 " " } END {print ""}'
	#Create topology for Dispatcher
	grep $TOPOLOGY $SCR_HOME/TSX_all_Topologies.csv | grep -i dispatcher | awk -F\; '{print $2 }' |awk 'BEGIN { printf "'$TOPOLOGY-DIS' = " }{printf "%s",$0 " " } END {print ""}'
	#Create topology for Author
	grep $TOPOLOGY $SCR_HOME/TSX_all_Topologies.csv | grep -i author | awk -F\; '{print $2 }' |awk 'BEGIN { printf "'$TOPOLOGY-AU' = " }{printf "%s",$0 " " } END {print ""}'


   done


else
	echo "$SCR_HOME/TSX_all_Topologies.csv not found"


fi
