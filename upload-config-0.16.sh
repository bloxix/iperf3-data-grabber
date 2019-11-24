#!/bin/bash
################################################################################################
# This script is uploading the initial grabber configuration to the iperf3_config_data table   #
# in the iperf3_data database. Run it right after the create_tables.sh script.                 #
################################################################################################
#DB INFO

export DB_USER="iperf3"                       # mysql user
export DB_PASSWORD="Iperf321*"                # mysql password
export DB_NAME="iperf3_data"                  # mysql db name
table="iperf3_config_data"

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

IPERF3_LOCAL_RUN=1                     # 0 = run the iperf client from the local machine, 1 = ssh into client & server
IPERF3_CLIENT='127.0.0.1'              # IPERF3_CLIENT ip address
IPERF3_CLIENT_USER='grabber'           # used to login to IPERF3_CLIENT
IPERF3_SERVER='127.0.0.1'              # IPERF3_SERVER ip address
IPERF3_SERVER_USER='grabber'           # used to login to IPERF3_SERVER
IPERF3_PORT=5201                       # default port
IPERF3_PROTOCOL='tcp'                  # default 'tcp' or 'udp'
IPERF3_BANDWIDTH=0                     # default 0 - max bandwidth
IPERF3_TIME=10                         # default 10 seconds per test run
IPERF3_PARALLEL=1                      # Nr of parallel streams
IPERF3_OTHER=''                        # other iperf switches must be enclosed by ''
IPERF3_REVERSE=0                       # reverse test = 1, default=0
IPERF3_TEST_RUN_DELAY=1                # delay in seconds between test runs, default=1
IPERF3_RUN_PING=1                      # set to 1 run ping tests
IPERF3_EXIT_ON_JSON_ERROR=1            # if set to 1 will exit when an error is returned in the iperf3 json
# Other default values
TEST_RUNS=1                            # Number of test runs, default=1


values="\"$IPERF3_LOCAL_RUN\",\"$IPERF3_CLIENT\",\"$IPERF3_CLIENT_USER\",\"$IPERF3_SERVER\",\"$IPERF3_SERVER_USER\",\"$IPERF3_PORT\",\"$IPERF3_PROTOCOL\",\"$IPERF3_BANDWIDTH\",\"$IPERF3_TIME\",\"$IPERF3_PARALLEL\",\"$IPERF3_OTHER\",\"$IPERF3_REVERSE\",\"$IPERF3_TEST_RUN_DELAY\",\"$IPERF3_RUN_PING\",\"$IPERF3_EXIT_ON_JSON_ERROR\",\"$TEST_RUNS\""

mysql_cmd=$(echo "INSERT INTO $table (IPERF3_LOCAL_RUN,IPERF3_CLIENT,IPERF3_CLIENT_USER,IPERF3_SERVER,IPERF3_SERVER_USER,IPERF3_PORT,IPERF3_PROTOCOL,IPERF3_BANDWIDTH,IPERF3_TIME,IPERF3_PARALLEL,IPERF3_OTHER,IPERF3_REVERSE,IPERF3_TEST_RUN_DELAY,IPERF3_RUN_PING,IPERF3_EXIT_ON_JSON_ERROR,TEST_RUNS) VALUES ($values);")

execute_mysql_cmd "$mysql_cmd"

