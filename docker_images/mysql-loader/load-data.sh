#!/bin/sh

mysql_user=$1
mysql_password=$2
mysql_host=$3
mysql_port=$4
mysql_database=$5

usage () {
	printf "USAGE:\n\tbash load-data-compose.sh USER PASSWORD HOST PORT DATABASE\n\n"
	exit 1
}

# User
if [[ -z "$mysql_user" ]]; then
	echo "User not provided. Attempting container environment variable..."
	mysql_user=$MYSQL_USER
fi

if [[ -z "$mysql_user" ]]; then
	echo "Unable to get user."
	usage
fi

if [[ -z "$mysql_password" ]]; then
	echo "Password not provided. Attempting container environment variable..."
	mysql_password=$MYSQL_PASSWORD
fi

if [[ -z "$mysql_password" ]]; then
	echo "Unable to get password."
	usage
fi

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

if [[ -z "$mysql_database" ]]; then
	echo "Database not provided. Using inventorydb..."
	mysql_database='inventorydb'
fi

# load data
while !(mysql -u${mysql_user} -p${mysql_password} --host ${mysql_host} --port ${mysql_port} <load-data.sql)
do
  printf "Waiting for MySQL to fully initialize\n\n"
  sleep 1
    echo "trying to load data again"
done

#rm load-data.sql testdata
printf "\n\nData loaded to %s.items.\n\n" "${mysql_database}"
exit 0