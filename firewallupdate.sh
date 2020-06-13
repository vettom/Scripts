#!/bin/bash
# ----------------------------------------------------------------------------
#
# Script:       Script to update firewall rules on Instance to allow port forwarding on 443
#
# Author:       Denny Vettom
#
# Usage:        No arguments, can run on any instance
#
# Dependencies:  Firewall-cmd
#
# Additions:
#
# ----------------------------------------------------------------------------
# History:
# ----------------------------------------------------------------------------
# Name          Date            Comment                         Version
# ----------------------------------------------------------------------------
# DV            1/03/18        Initial creation.                V1.0
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


if [ -d /mnt/crx/publish ]
then
	firewall-cmd --permanent --service=aem-author --add-port=5433/tcp
	firewall-cmd --permanent --service=aem-author --remove-port=8443/tcp
	firewall-cmd --permanent --add-service=https
	firewall-cmd --permanent --remove-forward-port=port=443:proto=tcp:toport=8443
	firewall-cmd --permanent --add-forward-port=port=443:proto=tcp:toport=5433
	firewall-cmd --reload
	firewall-cmd  --list-forward-ports
	firewall-cmd --list-services

elif [ -d /mnt/crx/author ]
then
	firewall-cmd --permanent --service=aem-publish --add-port=5433/tcp
	firewall-cmd --permanent --service=aem-publish --remove-port=8443/tcp
	firewall-cmd --permanent --add-service=https
	firewall-cmd --permanent --remove-forward-port=port=443:proto=tcp:toport=8443
	firewall-cmd --permanent --add-forward-port=port=443:proto=tcp:toport=5433
	firewall-cmd --reload
	firewall-cmd  --list-forward-ports
	firewall-cmd --list-services

elif [ -d /etc/httpd ]
then
	firewall-cmd --permanent --add-service=https
	firewall-cmd --permanent --remove-forward-port=port=443:proto=tcp:toport=8443
	firewall-cmd --reload
	firewall-cmd  --list-forward-ports
	firewall-cmd --list-services

fi
