#!/bin/sh

###
### CONSTANTS
###

app="/app"
appnweb="$app/nweb"
conf="/app/etc/"
e2g_ssl="$conf/ssl"
e2g_servercerts="$e2g_ssl/servercerts"
e2g_gencerts="$e2g_ssl/generatedcerts"
e2g_capubkeycrt="$e2g_servercerts/cacertificate.crt"
e2g_capubkeyder="$e2g_servercerts/my_rootCA.der"
nweb_crt="$appnweb/cacertificate.crt"
nweb_der="$appnweb/my_rootCA.der"



###
### MAIN
###

#Set UID and GID of e2guardian account
#-------------------------------------
groupmod -o -g $PGID e2guardian
usermod -o -u $PUID e2guardian

#Remove any existing .pid file that could prevent e2guardian from starting
#-------------------------------------------------------------------------
rm -rf $app/pid/e2guardian.pid

#Ensure correct ownership and permissions
#----------------------------------------
chown -R e2guardian:e2guardian /app
#chmod -R 755 $e2g_servercerts
#chmod -R 700 $e2g_servercerts/*.pem $e2g_gencerts

#Prep E2Guardian
#---------------
#[[ "$E2G_MITM" = "on" ]] && args="e" || args="d"
#e2g-mitm.sh -$args


#Start e2guardian
#----------------
e2guardian -N -c $conf/e2guardian.conf
