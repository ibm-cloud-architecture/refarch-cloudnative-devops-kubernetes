#!/bin/bash
# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
# from http://vpalos.com/537/uri-parsing-using-bash-built-in-features/
#

source ./helper.sh

# Checks for mysql "variable" set by Kubernetes secret
if [ -z ${mysql+x} ]; then 
    echo "Secret not in \"mysql\" variable. Aborting...";
    exit 1
else 
    echo "Found mysql secret"
    mysql_uri=$(echo $mysql | jq .uri | sed s%\"%%g)

    # Do the URL parsing
    uri_parser $mysql_uri

    # Construct elasticsearch url
    mysql_user=${uri_user}
    mysql_password=${uri_password}
    mysql_host=${uri_host}
    mysql_port=${uri_port}

    echo "Loading MySQL database..."
    ./load-data.sh ${mysql_user} ${mysql_password} ${mysql_host} ${mysql_port} inventorydb
fi
