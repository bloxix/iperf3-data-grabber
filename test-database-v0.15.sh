#!/usr/bin/bash
# iperf3 data grabber testtool to upload test run data to mysql database
# test tables

#DB INFO
DB_USER="iperf3"
DB_PASSWORD="Iperf321*" 
DB_NAME="iperf3_data"

mysql_cmd=( "SELECT * FROM iperf3_general_info;"

   "SELECT * FROM iperf3_start;"

   "SELECT * FROM iperf3_start_connected;"

   "SELECT * FROM iperf3_start_timestamp;"

   "SELECT * FROM iperf3_start_connecting_to;"

   "SELECT * FROM iperf3_start_test_start;"

   "SELECT * FROM iperf3_intervals_streams;"

   "SELECT * FROM iperf3_intervals_sum;"

   "SELECT * FROM iperf3_end_streams;"
   
   "SELECT * FROM iperf3_end_sum;"

   "SELECT * FROM iperf3_end_cpu_utilization;"
)

for i in "${mysql_cmd[@]}"
do
  echo will execute the following sql query:
  echo "$i"
  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$i"
done
