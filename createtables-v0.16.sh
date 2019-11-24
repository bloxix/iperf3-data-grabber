#!/bin/bash
################################################################################################
# This script creates the iperf3_data database and creates the table structure of all grabber  #
# tables. Run it right after your grabber container has been launched for the first time.      #
################################################################################################


# iperf3 data grabber testtool to upload test run data to mysql database
# create db and tables

#DB INFO
DB_USER="iperf3"
DB_PASSWORD="Iperf321*" 
DB_NAME="iperf3_data"

mysql -u${DB_USER} -p${DB_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} "

mysql_cmd=( "CREATE TABLE iperf3_config_data( \
    IPERF3_LOCAL_RUN boolean, \
	IPERF3_CLIENT varchar(255), \
    IPERF3_CLIENT_USER varchar(255), \
    IPERF3_SERVER varchar(255), \
    IPERF3_SERVER_USER varchar(255), \
    IPERF3_PORT int, \
    IPERF3_PROTOCOL varchar(10), \
    IPERF3_BANDWIDTH varchar(10), \
    IPERF3_TIME int, \
    IPERF3_PARALLEL int, \
    IPERF3_OTHER varchar(255), \
    IPERF3_REVERSE boolean, \
    IPERF3_TEST_RUN_DELAY int, \
    IPERF3_RUN_PING boolean, \
    IPERF3_EXIT_ON_JSON_ERROR boolean, \
    TEST_RUNS int \

);"

   "CREATE TABLE iperf3_general_info( \
   test_id int not null primary key, \
   test_time datetime, \
   test_name varchar(255), \
   test_user varchar(255), \
   iperf3_client varchar(20), \
   iperf3_server varchar(20), \
   test_runs int, \
   args varchar(255), \
   test_complete BOOLEAN
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
   time datetime,
   test_id int not null,
   test_run int,
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
   time datetime,
   test_id int not null,
   test_run int,
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
   time datetime, \
   test_id int not null, \
   test_run int, \
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
);" 

   "CREATE TABLE iperf3_ping_table ( \
   time datetime, \
   test_id int not null,   \
   test_run int, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   remote_host varchar(20), \
   bytes int,
   icmp_seq int,
   ttl int,
   icmp_rtt double \
);"

   "CREATE TABLE iperf3_ping_summary_table ( \
   time datetime, \
   test_id int not null,   \
   test_run int, \
   FOREIGN KEY fk_test_id(test_id) \
   REFERENCES iperf3_general_info(test_id) \
   ON UPDATE CASCADE \
   ON DELETE CASCADE, \
   remote_host varchar(20), \
   remote_host2 varchar(20), \
   bytes_pp_sent int,
   bytes_pp_received int,
   packets_transmitted int,
   packets_received int,
   packet_loss double,
   total_time int,
   rtt_min double,
   rtt_avg double,
   rtt_max double,
   rtt_mdev double
);" )

for i in "${mysql_cmd[@]}"
do
  echo will execute the following sql query:
  echo $i
  mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$i"
done
