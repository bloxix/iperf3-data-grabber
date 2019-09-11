#!/usr/bin/bash

#DB INFO
DB_USER="heiko"                        # mysql user
DB_PASSWORD="Heiko1234*"               # mysql password
DB_NAME="iperf3_data"                  # mysql db name
table="iperf3_ping_table"

remote_host="$1"
duration="$2"
test_run="$3"
test_id="$4"

echo "running ping tests with remote_host=$remote_host, duration=$duration, test_run=$test_run, test_id=$test_id"


ping_command="ping -c $duration $remote_host"
echo "$ping_command"
eval $ping_command | while read line
do echo $(date '+%Y-%m-%d %T' ) "$line" ; done | awk '/time=/{print "\"" $1 " " $2 "\"," $9}'  | sed 's/time=\(.*\)/\1/' > ping.tmp
while read line
do
  #insert mysql command
  line=$(echo "$line,$test_id,\"$remote_host\",$test_run")
  mysql_cmd=$(echo "INSERT INTO $table (time,icmp_rtt,test_id,remote_host,test_run) VALUES ($line);")
  echo will execute the following sql query:
  echo $mysql_cmd
  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$mysql_cmd"
done < ping.tmp

rm ping.tmp