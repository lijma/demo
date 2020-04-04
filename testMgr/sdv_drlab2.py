# ------ values generated manually ----------------------
# ------------------------------------------------------------------------------
#       File:           sdv_drlab2.py (Setup Default Variables)
#
#       Description:    a variable file to record drlab2 enviroment
#						generate from sdv_template.py
# ------------------------------------------------------------------------------
#       Copyright (c) Nokia Siemems Networks 2017-2018
# ------------------------------------------------------------------------------
SDV_VERSION="1.0"

#--examples: 
#key values
#	SDV_ROOT_USER="root"
#list values: 
#	LIST__SDV_MTOOLS_INSTALLED_HOSTS=["drlab1vm1", "drlab1vm2", "drlab1vm3", "drlab1vm4", "drlab1vm5", "drlab1vm5"];

#Common settings
SDV_ROOT_USER="root"
SDV_ROOT_PASSWORD="arthur"
SDV_DR_USER="dradmin"
SDV_DRPG_SB_IP="10.91.209.5" #Southbound IP for VM where DR package installed

#Service Host Configurations
SDV_DB_HOST="drlab2vm4"
SDV_LDAP_HOST="drlab2vm3"
SDV_DMGR_HOST="drlab2vm20"
SDV_WAS_HOSTS=["drlab1vm20", "drlab1vm21", "drlab1vm21", "drlab1vm22"];

#IP Configurations for DR Active Site
SDV_AS_DB_DR_IP="10.91.209.69"
SDV_AS_LDAP_DR_IP="10.91.209.68"
SDV_AS_DMGR_DR_IP="10.91.209.85"

#IP Configurations for DR Standby Site
SDV_SS_DB_DR_IP="10.91.209.133"
