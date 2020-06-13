#!/bin/bash
# ----------------------------------------------------------------------------
#
# Script:  Simple script to quickily create Docroot for httpd 
#
# Author:       Denny Vettom
#
# Additions:
#
# ----------------------------------------------------------------------------
# History:
# ----------------------------------------------------------------------------
# Name          Date            Comment                         Version
# ----------------------------------------------------------------------------
# DV            11/02/20        Initial creation.        V1.0
# ----------------------------------------------------------------------------
PATH=$PATH:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/opt/csw/bin:/usr/ccs/bin:/root/.local/bin/
HOSTNAME=`hostname`
DATE=`date +%Y%m%d`
TIMESTAMP=`date +%H%M.%Y%m%d`
N_ARG=$#
SCR_HOME=`dirname $0`
SCR_NAME=`basename $0`
ERROR_FLAG=0
[[ $SCR_HOME = . ]] && SCR_HOME=`pwd`

## Define/modify following variable as required.

USER=root

#Ensure script is run as root user
 CURRENT_USER_ID=`id | awk -F\( '{ print $2 }' | awk -F\) '{ print $1 }'`
 if [ $CURRENT_USER_ID != $USER ]
 then
        echo -e "  \e[1;32m INFO : Please execute command as $USER \e[0m "
        exit
 fi


function CHECK_FAILURE
{
        if [ $1 -ne 0 ]
        then
                echo -e "\e[0;41m ERROR : $2  \e[0m "  | tee -ai ${LOG}
                ERROR_FLAG=1
                FINISH
        fi
}


# Execute on Dispatchers only
if [ ! -f /etc/httpd/conf/httpd.conf ]
then
    echo -e "\e[0;41m ERROR : httpd.conf not found, it this dispatcher instance? \e[0m "
    exit 1
fi

source /etc/sysconfig/httpd
# Check for DocRoot requirement and create necessary folder
[[ -f /tmp/.docroot.txt ]] && rm -f /tmp/.docroot.txt
httpd -t > /tmp/.docroot.txt 2>&1

echo " INFO: Checkign for DocumentRoot to be created"

COUNT=`grep "AH00112: Warning: DocumentRoot" /tmp/.docroot.txt | grep "does not exist" | awk -F[ '{print $2}' | awk -F] '{print $1}'| wc -l`
[[ $COUNT -eq 0 ]] && echo " INFO: No missing DocumentRoot found. " && exit

for i in `grep "AH00112: Warning: DocumentRoot" /tmp/.docroot.txt | grep "does not exist" | awk -F[ '{print $2}' | awk -F] '{print $1}'`
do
    echo -e "  \e[1;32m INFO : Creating Directory $i \e[0m "
    mkdir -p $i
    CHECK_FAILURE $? " ERROR : Failed to create DocumentRoot $i"
    chown -R apache:apache $i
    # echo " INFO: $i created"
done



restorecon -R /etc/httpd /mnt/var/www/html
[[ -f /tmp/.docroot.txt ]] && rm -f /tmp/.docroot.txt