#!/bin/bash

#DB INFO
DB_USER="iperf3"                       # mysql user
DB_PASSWORD="Iperf321*"                # mysql password
DB_NAME="iperf3_data"                  # mysql db name
IPERF3_CLIENT_USER='iperf3'            # used to login to IPERF3_CLIENT
# IPERF3_SERVER="192.168.122.11"
table="iperf3_ping_table"
table2="iperf3_ping_summary_table"
remote_host="$1"
duration="$2"
test_run="$3"
test_id="$4"
iperf3_client="$5"

################################################################################################
# execute mysql command and output command                                                     #
################################################################################################
function execute_mysql_cmd()
{
  local mysql_cmd="$1"

  echo will execute the following sql query:
  echo $mysql_cmd

  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$mysql_cmd"  
}

################################################################################################
# Main Routine                                                                                 #
################################################################################################

echo "running ping tests with remote_host=$remote_host, duration=$duration, test_run=$test_run, test_id=$test_id"

ping_command="ssh $IPERF3_CLIENT_USER@$iperf3_client 'ping -c $duration $remote_host'"
echo "$ping_command"

eval $ping_command | while read line
do
  # echo "Pocessing line $line ..."
  l=""
  d=$(echo $(date '+%F %T' ))
  if [[ "$line" =~ "time=" ]]
  then
    # echo "time= found in line $line"
    l=$(echo "$line" | sed -r 's/([0-9]+) bytes.*: icmp_seq=([0-9]+) ttl=([0-9]+) time=([0-9]+\.?[0-9]*) ms/"\1","\2","\3","\4"/m')
	l=$(echo "\"$d\",$l,\"$test_id\",\"$remote_host\",$test_run")

	#insert into ping table
	mysql_cmd=$(echo "INSERT INTO $table (time,bytes,icmp_seq,ttl,icmp_rtt,test_id,remote_host,test_run) VALUES ($l);")
    execute_mysql_cmd "$mysql_cmd"
	
  elif [[ "$line" =~ "PING" ]]
  then
    # echo "PING in line $line"
    png=$(echo "$line" | sed -r 's/PING (.*) \((.*?)\) ([0-9]+)\(([0-9]+)\) bytes.*/"\1","\2",\3,\4/m')
  elif [[ "$line" =~ "packets transmitted" ]]
  then
    # echo "packets transmitted in line $line"
    packets=$(echo "$line" | sed -r 's/([0-9]+) packets transmitted, ([0-9])+ received, ([0-9]+\.?[0-9]*?)% packet loss, time ([0-9]+)ms/\1,\2,\3,\4/m')
  elif [[ "$line" =~ "rtt min" ]]
  then
    # echo "rtt min found in line $line"
    rtt=$(echo "$line" | sed -r 's/rtt min\/avg\/max\/mdev = ([0-9]+\.?[0-9]*?)\/([0-9]+\.?[0-9]*?)\/([0-9]+\.?[0-9]*?)\/([0-9]+\.?[0-9]*?) ms/\1,\2,\3,\4/m')
	
	#update time stamp
	d=$(echo $(date '+%F %T' ))
	l="\"$d\",\"$test_id\",\"$test_run\",$png,$packets,$rtt"
    mysql_cmd=$(echo "INSERT INTO $table2 (time,test_id,test_run,remote_host,remote_host2,bytes_pp_sent,bytes_pp_received,packets_transmitted,   packets_received,packet_loss,total_time,rtt_min,rtt_avg,rtt_max,rtt_mdev) VALUES ($l);")
    execute_mysql_cmd "$mysql_cmd" 
  # else
	# echo "no match found in line $line"
  fi
done