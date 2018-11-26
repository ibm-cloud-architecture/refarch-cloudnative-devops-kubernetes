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

# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
# from http://vpalos.com/537/uri-parsing-using-bash-built-in-features/

source ./helper.sh

# Checks for mysql "variable" set by Kubernetes secret
if [ -n "$mysql" ]; then
    echo "Found mysql environment variable"
    mysql_uri=$(echo $mysql | jq -r '.uri')

elif [ -n "$MYSQL_URI" ]; then
    echo "Getting elements from MYSQL_URI"
    mysql_uri=$MYSQL_URI

else
    echo "Using MySQL Community Chart"
    mysql_uri="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
fi

# Do the URL parsing
uri_parser $mysql_uri

# Extract MySQL url
mysql_user=${uri_user}
mysql_password=${uri_password}
mysql_host=${uri_host}
mysql_port=${uri_port}
# drop the leading '/' from the path
mysql_database=`echo ${uri_path} | sed -e 's/^\///'`


# Optional
if [[ -z "$mysql_host" ]]; then
	echo "Host not provided. Using localhost..."
	mysql_host='0.0.0.0'
fi

if [[ -z "$mysql_port" ]]; then
	echo "Port not provided. Using 3306..."
	mysql_port='3306'
fi

if [[ -z "$mysql_database" ]]; then
	echo "Database not provided. Attempting container environment variable..."
	mysql_database=$MYSQL_DATABASE
fi

# wget the URL of the sql file to execute
SQL_URL=$1
if [ ! -z "${SQL_URL}" ]; then
    wget ${SQL_URL} -O /load-data.sql
    if [ $? -ne 0 ]; then
        echo "Failed to download ${SQL_URL}"
        exit 1
    fi
fi

if [ ! -f "/load-data.sql" ]; then
    echo "No SQL file to execute"
    exit 0
fi

echo "Executing MySQL script ${SQL_URL} on MySQL database ${mysql_host}:${mysql_port} ..."

# load data
while !(mysql -v -u${mysql_user} -p${mysql_password} --host ${mysql_host} --port ${mysql_port} </load-data.sql)
do
  printf "Waiting for MySQL to fully initialize\n\n"
  sleep 1
  echo "trying to load data again"
done

#rm /load-data.sql testdata
printf "\n\nExecuted script at ${SQL_URL} on database %s\n\n" "${mysql_database}"
