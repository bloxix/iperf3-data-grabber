#!/bin/bash
# iperf3 data grabber testtool to upload test run data to mysql database
# test tables

#DB INFO
DB_USER="iperf3"
DB_PASSWORD="Iperf321*" 
DB_NAME="iperf3_data"

mysql_cmd=( "DESCRIBE iperf3_general_info;"

   "DESCRIBE iperf3_start;"

   "DESCRIBE iperf3_start_connected;"

   "DESCRIBE iperf3_start_timestamp;"

   "DESCRIBE iperf3_start_connecting_to;"

   "DESCRIBE iperf3_start_test_start;"

   "DESCRIBE iperf3_intervals_streams;"

   "DESCRIBE iperf3_intervals_sum;"

   "DESCRIBE iperf3_end_streams;"
   
   "DESCRIBE iperf3_end_sum;"

   "DESCRIBE iperf3_end_cpu_utilization;"
   
   "DESCRIBE iperf3_ping_table;"
   
   "DESCRIBE iperf3_ping_summary_table;"
)

for i in "${mysql_cmd[@]}"
do
  echo will execute the following sql query:
  echo "$i"
  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$i"
done
