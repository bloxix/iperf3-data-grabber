#!/bin/bash
#DB INFO
export DB_USER="iperf3"                       # mysql user
export DB_PASSWORD="Iperf321*"                # mysql password
export DB_NAME="iperf3_data"                  # mysql db name

################################################################################################
# execute mysql command and output command                                                     #
################################################################################################
function execute_mysql_cmd()
{
  local mysql_cmd="$1"

  # echo will execute the following sql query:
  # echo $mysql_cmd

  response=$(mysql --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" --execute="$mysql_cmd")
  myresp=$(echo ${response[0]} | awk '{ print $2 }')
  echo "$myresp"
  
}

table="iperf3_config_data"
IPERF3_LOCAL_RUN=$(execute_mysql_cmd "SELECT IPERF3_LOCAL_RUN from $table")

echo "IPERF3_LOCAL_RUN is : $IPERF3_LOCAL_RUN"

## http://blog.mclaughlinsoftware.com/2015/05/17/bash-arrays-mysql/ 
## https://www.tecmint.com/working-with-arrays-in-linux-shell-scripting/


