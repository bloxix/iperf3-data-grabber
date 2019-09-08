#!/usr/bin/bash
# iperf3 data grabber testtool to upload test run data to mysql database
# create db and tables

#DB INFO
DB_USER="heiko"
DB_PASSWORD="Heiko1234*" 
DB_NAME="iperf3_data"

mysql_cmd=( "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

"CREATE TABLE iperf3_general_info( \
   test_id int not null primary key, \
   test_time datetime, \
   test_name varchar(255), \
   test_user varchar(255), \
   test_runs int, \
   args varchar(255) \
);"

   "CREATE TABLE iperf3_start( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   version varchar(20), \
   system_info varchar(255), \
   cookie varchar(255), \
   tcp_mss_default int \
);"

   "CREATE TABLE iperf3_start_connected ( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   socket int, \
   local_host varchar(127), \
   local_port int, \
   remote_host varchar(127), \
   remote_port int \
);"

   "CREATE TABLE iperf3_start_timestamp ( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   time varchar(31), \
   timesecs int \
);"

   "CREATE TABLE iperf3_start_connecting_to ( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   host varchar(127), \
   port int \
);"

   "CREATE TABLE iperf3_start_test_start ( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   protocol varchar(10), \
   num_streams int, \
   blksize int, \
   omit BOOLEAN, \
   duration int,\
   bytes int, \
   blocks int, \
   reverse BOOLEAN \
);"

   "CREATE TABLE iperf3_intervals_streams (
   time datetime,
   test_id int not null,
   test_run int,
   FOREIGN KEY fk_test_id(test_id)
   REFERENCES iperf3_general_info(test_id)
   ON UPDATE CASCADE
   ON DELETE CASCADE,
   socket int,
   start double,
   end double,
   seconds double,
   bytes bigint,
   bits_per_second bigint,
   retransmits int,     
   snd_cwnd int,        
   rtt int,             
   jitter_ms double,    
   lost_packets int,    
   packets int,         
   lost_percent double, 
   omitted boolean
);"

   "CREATE TABLE iperf3_intervals_sum (
   time datetime,
   test_id int not null,
   test_run int,
   FOREIGN KEY fk_test_id(test_id)
   REFERENCES iperf3_general_info(test_id)
   ON UPDATE CASCADE
   ON DELETE CASCADE,
   start double,
   end double,
   seconds double,
   bytes bigint,
   bits_per_second bigint,
   retransmits int,               
   jitter_ms double,              
   lost_packets int,              
   packets int,                   
   lost_percent double,           
   omitted boolean
);"

   "CREATE TABLE iperf3_end_streams (
   test_id int not null,
   FOREIGN KEY fk_test_id(test_id)
   REFERENCES iperf3_general_info(test_id)
   ON UPDATE CASCADE
   ON DELETE CASCADE,
   sender BOOLEAN,
   socket int,
   start double,
   end double,
   seconds double,
   bytes bigint,
   bits_per_second bigint,
   retransmits int, 
   max_snd_cwnd int,
   max_rtt int,
   min_rtt int,
   mean_rtt int,
   jitter_ms double,
   lost_packets bigint,
   packets bigint,         
   lost_percent double,
   out_of_order bigint
);"

   "CREATE TABLE iperf3_end_sum (
   test_id int not null,
   FOREIGN KEY fk_test_id(test_id)
   REFERENCES iperf3_general_info(test_id)
   ON UPDATE CASCADE
   ON DELETE CASCADE,
   type varchar(20),
   start double,
   end double,
   seconds double,
   bytes bigint,
   bits_per_second bigint,
   retransmits int,        
   jitter_ms double,
   lost_packets bigint,
   packets bigint,         
   lost_percent double
);"

   "CREATE TABLE iperf3_end_cpu_utilization ( \
   test_id int not null, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   host_total double, \
   host_user double, \
   host_system double, \
   remote_total double, \
   remote_user double, \
   remote_system double \
);" )
 
#mysql_cmd=( "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$c7" "$c8" "$c9" "$c10" "$c11" )

for i in "${mysql_cmd[@]}"
do
  echo will execute the following sql query:
  echo $i
  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$i"
done
