#!/bin/ksh
# ----------------------------------------------------------------------------
#
# Script:   	Copy ssh key to topology group

# Author:   	Denny Vettom
# Usage:
#
# Dependencies: Assumes AWS CLI is configured, sshpass installed and .ssh directory with keys are available in scripts home.
#
# Additions:
#
# ----------------------------------------------------------------------------
# History:
# ----------------------------------------------------------------------------
# Name      	Date        	Comment                     	Version
# ----------------------------------------------------------------------------
# DV        	20/03/09    	Initial creation.
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

USER_ID=""  	#Set if script has to run as particular user
LOG=        	#User for summary log, contents of this file will me mailed.
# Declare mailprog specific variables



function FINISH
{

 case $ERROR_FLAG in
    0)
  		      echo "*** Exiting $0 `date` [process ID: $$] ***\n" | tee -ai ${LOG}
   	 SUBJECT=$SUCCESS_SUBJECT
   	 SEND_EMAIL
   	 exit
    ;;
    99)
        	echo "*** Warning $0 `date` [process ID: $$] ***\n" | tee -ai ${LOG}
   	 SUBJECT=$WARNING_SUBJECT
   	 SEND_EMAIL
    ;;
    
    *)
   		 echo "*** Exiting $0 `date` [process ID: $$] ***\n" | tee -ai ${LOG}
   	 SUBJECT=$ERROR_SUBJECT
   	 SEND_EMAIL
   	 exit
    ;;
 esac
    
}

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

#First change dir to Scripts Home and verify that .ssh directory and keys exists
cd $SCR_HOME
CHECK_FAILURE $? "Failed to Change Dir"
if [ ! -f ./.ssh/id_rsa.pub ] ; then echo ".ssh/id_rsa.pub not found in Scripts Home " ; exit; fi

if [ ! -f ~/.aws/config ]
then
echo "AWS CLI appears to not be installed (could not find ~/.aws/config)"
echo "Download https://s3.amazonaws.com/aws-cli/awscli-bundle.zip using wget or curl, and following instructions at http://docs.aws.amazon.com/cli/latest/userguide/installing.html#install-bundle-other-os"
exit 0
fi

# Ensure sshpass is installed
SSHPASSTEST=$(sshpass 2>&1)
 if [ "${SSHPASSTEST:0:14}" != "Usage: sshpass" ]
 then
   echo "SSHPASS is required for this script. Please install via apt-get/yum."
   echo "For OSx, use 'brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb'"
   exit 0
  
 fi

#If Argument passed, accept first field as Topology, if not prompt
TOPOLOGY=$1
if [ -z $TOPOLOGY ]
then
	#Accept Topology as argument
	echo -n "Enter name of Topology :"
	read TOPOLOGY
fi

#accept password for topology
echo -n "Enter Password for $TOPOLOGY :"
read PASSWORD


for REGION in `aws ec2 describe-regions | awk '{ print $3 }'`
do
 #Unset IP
 IP=""
 echo "Processing servers in $REGION"
	#Start loop of IP
	for IP in `aws ec2 describe-instances --region=$REGION --filters "Name=tag:adobe:ms:topology,Values=$TOPOLOGY" --query 'Reservations[].Instances[].[PublicIpAddress]' --output text`
	do
	 if  [ ! -z $IP ] 
	 then
	  echo Copying to $IP
	 sshpass -p "$PASSWORD" ssh -oStrictHostKeyChecking=no $IP hostname
	 sshpass -p "$PASSWORD"  scp -oStrictHostKeyChecking=no -r  .ssh $IP:~/
	  IP=""
	  fi
	done
done
