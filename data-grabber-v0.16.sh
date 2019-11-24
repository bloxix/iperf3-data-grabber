#!/bin/bash
################################################################################################
# This bash script implements an iperf3 test tool which retrieves network test data from       #
# iperf3, the network speed test tool. The produced test data is uploaded to a mysql database  #
# where it can be further analysed, e.g. through Grafana. It uses iperf version 3.1.3 that can #
# be downloaded here: https://iperf.fr/iperf-download.php and jq https://stedolan.github.io/jq/# 
# to filter json data. The tool is run in client mode and uses the same (optional) command     #
#line arguments as iperf3 where applicable:                                                    #
# [-c host_ip] [-p port] [-x protocol] [-b bandwidth] [-t time] [-P Parallel] [-o other]       #
# [-r runs] [-R] [-C client_host_ip]                                                           #
# [-c host_ip]   specifies the destination host where the iperf server component resides.      #
#                Default is localhost.                                                         #
# [-C chost_ip]  specifies the client host where the iperf client component resides.           #
#                Default is localhost.                                                         #
# [-p port]      specifies the destination host where the iperf server component resides.      #
#                Default is the iperf3 default port 5201.                                      #
# [-x protocol]  specifies the protocol to be used, which can be 'tcp' or 'udp'. If omitted,   #
#                'tcp' will be used.                                                           #
# [-b bandwidth] specifies the bandwidth, same as in iperf. if omitted, the maximum available  #
#                bandwidth will be used (-b 0).                                                #
# [-t time]      specifies the time of each test run in seconds, same as in iperf.             #
# [-P Parallel]  streams, specifies the number of concurrent streams, same as in iperf.        #
# [-R ]          will run tests in reverse mode (server transmits), same as in iperf.          #
# [-o 'other']   allows you to include other iperf switches, that will be passed over the      #
#                command line. Use single quotes ' '. Note this option has not been tested.    #
# [-r runs]      specifies the number of test runs the tool will carry out. Default is one.    #
# [-v]           prints the current Grabber version and exits.
################################################################################################

################################################################################################
#Variables
#Define Default values used by IPERF and other script variables
################################################################################################

IPERF3_LOCAL_RUN=1                     # 0 = run the iperf client from the local machine, 1 = ssh into client & server
IPERF3_CLIENT='127.0.0.1'              # IPERF3_CLIENT ip address
IPERF3_CLIENT_USER='iperf3'            # used to login to IPERF3_CLIENT
IPERF3_SERVER='127.0.0.1'              # IPERF3_SERVER ip address
IPERF3_SERVER_USER='iperf3'            # used to login to IPERF3_SERVER
IPERF3_PORT=5201                       # default port
IPERF3_PROTOCOL='tcp'                  # default 'tcp' or 'udp'
IPERF3_BANDWIDTH=0                     # default 0 - max bandwidth
IPERF3_TIME=10                         # default 10 seconds per test run
IPERF3_PARALLEL=1                      # Nr of parallel streams
IPERF3_OTHER=''                        # other iperf switches must be enclosed by ''
IPERF3_ARGS=''
IPERF3_REVERSE=0                       # reverse test = 1, default=0
IPERF3_TEST_RUN_DELAY=1                # delay in seconds between test runs, default=1
IPERF3_RUN_PING=1                      # set to 1 run ping tests
IPERF3_EXIT_ON_JSON_ERROR=1            # if set to 1 will exit when an error is returned in the iperf3 json
IPERF3_GRABBER_VERSION='0.16'          # current grabber version

# Other default values
TEST_RUNS=1                            # Number of test runs, default=1
TEST_ID=$(date '+%s')
TEST_NAME=$(echo IPERF3_TEST $TEST_ID)
PATH_TO_JQ='/usr/bin/jq'

#DB INFO
DB_USER="iperf3"                       # mysql user
DB_PASSWORD="Iperf321*"                # mysql password
DB_NAME="iperf3_data"                  # mysql db name


################################################################################################
# Parse command line arguments                                                                 #
################################################################################################

function parse_args()
{
  local cflag=
  local Cflag=
  local pflag=
  local xflag=
  local bflag=
  local tflag=
  local Pflag=
  local oflag=
  local rflag=
  local Rflag=
  local vflag=
  
  while getopts 'c:C:p:x:b:t:P:o:r:R:v' OPTION
  do
    case $OPTION in
      c) cflag=1
	     IPERF3_SERVER="$OPTARG"
         ;;
      C) Cflag=1
	     IPERF3_CLIENT="$OPTARG"
         ;;
      p) pflag=1
         IPERF3_PORT="$OPTARG"
         ;;
      x) xflag=1
         IPERF3_PROTOCOL="$OPTARG"
         ;;
      b) bflag=1
         IPERF3_BANDWIDTH="$OPTARG"
         ;;
      t) tflag=1
         IPERF3_TIME="$OPTARG"
         ;;
      P) Pflag=1
         IPERF3_PARALLEL="$OPTARG"
         ;;
      o) oflag=1
         IPERF3_OTHER="$OPTARG"
         ;;
      r) rflag=1
         TEST_RUNS="$OPTARG"
         ;;
      R) Rflag=1
         IPERF3_REVERSE=1
         ;;
	  v) printf "Iperf3 Grabber version: $IPERF3_GRABBER_VERSION\n"
         exit 2
         ;;
	  ?) printf "Usage: %s: [-c host_ip] [-p port] [-x protocol] [-b bandwidth] [-t time] [-P Parallel] [-o other] [-r runs] [-R] [-v]\n" $(basename $0) >&2
         exit 2
         ;;
      esac
  done
  shift $(($OPTIND - 1))

  if [ "$cflag" ]
  then
    printf 'Option -c "%s" specified\n' "$IPERF3_SERVER"
  fi
  if [ "$Cflag" ]
  then
    printf 'Option -C "%s" specified\n' "$IPERF3_CLIENT"
  fi
  if [ "$pflag" ]
  then
    printf 'Option -p "%s" specified\n' "$IPERF3_PORT"
  fi
  if [ "$xflag" ]
  then
    printf 'Option -x "%s" specified\n' "$IPERF3_PROTOCOL"
  fi
  if [ "$bflag" ]
  then
    printf 'Option -b "%s" specified\n' "$IPERF3_BANDWIDTH"
  fi
  if [ "$tflag" ]
  then
    printf 'Option -t "%s" specified\n' "$IPERF3_TIME"
  fi
  if [ "$Pflag" ]
  then
    printf 'Option -P "%s" specified\n' "$IPERF3_PARALLEL"
  fi
  if [ "$oflag" ]
  then
    printf 'Option -o "%s" specified\n' "$IPERF3_OTHER"
  fi
  if [ "$rflag" ]
  then
    printf 'Option -r "%s" specified\n' "$TEST_RUNS"
  fi
  if [ "$Rflag" ]
  then
    printf 'Option -R specified\n'
  fi

  local args="-c $IPERF3_SERVER -p $IPERF3_PORT -b $IPERF3_BANDWIDTH -t $IPERF3_TIME -P $IPERF3_PARALLEL"

  if [[ $IPERF3_PROTOCOL == "udp" ]]
  then
    args="$args -u"
  fi
  
  if [[ $IPERF3_REVERSE == 1 ]]
  then
    args="$args -R"
  fi

  IPERF3_ARGS="$args -J $IPERF3_OTHER"
}

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
# update general info table                                                                          #
################################################################################################
function update_iperf3_general_info()
{
  local table="iperf3_general_info"
  local test_time=$(date +'%F %T')
  local test_name=$TEST_NAME
  local test_id=$TEST_ID
  local test_user=$(whoami)
  local args=$IPERF3_ARGS
  local test_runs=$TEST_RUNS
  local iperf3_client=$IPERF3_CLIENT
  local iperf3_server=$IPERF3_SERVER
	
  #update the general info table
  local mysql_cmd="INSERT INTO "$table" (test_id,test_time,test_name,test_user,iperf3_client,iperf3_server,test_runs,args,test_complete) VALUES (\""$test_id"\",\""$test_time"\","\"$test_name"\","\"$test_user"\","\"$iperf3_client"\","\"$iperf3_server"\","\"$test_runs"\","\"$args"\",false);"

  execute_mysql_cmd "$mysql_cmd"
}


################################################################################################
# update start tables                                                                          #
################################################################################################
function update_iperf3_start()
{
  local JSON="$1"
  local run="$2"
  
  local test_id=$TEST_ID

  #update the start table

  local table="iperf3_start"
  local version=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.version ')
  local system_info=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.system_info ')
  local cookie=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.cookie ')
  local tcp_mss_default=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.tcp_mss_default ')
	
  if [[ $IPERF3_PROTOCOL == 'tcp' ]] # in case of udp tests set this to need to add extra \"
  then
	mysql_cmd="INSERT INTO "$table" (test_id,version,system_info,cookie,tcp_mss_default) VALUES (\""$test_id"\",\""$version"\","\"$system_info"\","\"$cookie"\","\"$tcp_mss_default"\");"
  else
    mysql_cmd="INSERT INTO "$table" (test_id,version,system_info,cookie) VALUES (\""$test_id"\",\""$version"\","\"$system_info"\","\"$cookie"\");"
  fi
  
  execute_mysql_cmd "$mysql_cmd"
  
  #update the iperf3_start_connected table
	
  local socket=""
  local local_host=""
  local local_port=""
  local remote_host=""
  local remote_port=""
  table="iperf3_start_connected"

  echo $JSON | $(echo $PATH_TO_JQ) -r '.connected[] | [.[]] | @csv ' | sed 's/,/ /g' > tmp.csv
    
  while read socket local_host local_port remote_host remote_port
  do
    mysql_cmd=$(echo "INSERT INTO $table (test_id,socket,local_host,local_port,remote_host,remote_port) VALUES ($test_id,$socket,$local_host,$local_port,$remote_host,$remote_port);")
	
    execute_mysql_cmd "$mysql_cmd"  
	
  done < tmp.csv
    
  #update the iperf3_start_timestamp table
  local timevalue=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.timestamp.time ')
  local timesecs=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.timestamp.timesecs ')
  table="iperf3_start_timestamp"

  mysql_cmd="INSERT INTO "$table" (test_id,time,timesecs) VALUES (\""$test_id"\",\""$timevalue"\","\"$timesecs"\");"
  execute_mysql_cmd "$mysql_cmd"
  
  #update the iperf3_start_connecting_to table
  local myhost=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.connecting_to.host ')
  local myport=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.connecting_to.port ')
  table="iperf3_start_connecting_to"
	
  execute_mysql_cmd "$mysql_cmd"
  
  mysql_cmd="INSERT INTO "$table" (test_id,host,port) VALUES (\""$test_id"\",\""$myhost"\","\"$myport"\");"
  execute_mysql_cmd "$mysql_cmd"
	
  #update the iperf3_start_test_start table
  local protocol=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.protocol ')
  local num_streams=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.num_streams ')
  local blksize=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.blksize ')
  local omit=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.omit ')
  local duration=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.duration ')
  local bytes=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.bytes ')
  local blocks=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.blocks ')
  local reverse=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.test_start.reverse ')
  table="iperf3_start_test_start"

  mysql_cmd="INSERT INTO "$table" (test_id,protocol,num_streams,blksize,omit,duration,bytes,blocks,reverse) VALUES (\""$test_id"\",\""$protocol"\","\"$num_streams"\",\""$blksize"\",\""$omit"\","\"$duration"\",\""$bytes"\","\"$blocks"\","\"$reverse"\");"
	
  execute_mysql_cmd "$mysql_cmd"
}

################################################################################################
# update interval tables                                                                       #
################################################################################################
function update_iperf3_intervals()
{
  #Determine the CSV for intervals stream data
  # Print out all 'intervals'series data as a CSV, this is our core data
  local TOTAL_JSON="$1"
  local m="$2" #current test run
  local table="iperf3_intervals_streams" 
  local i=0
 
  if [[ $IPERF3_PROTOCOL == 'tcp' ]]
  then
    if [[ $IPERF3_REVERSE == 0 ]]
    then
	  #update intervals data
      echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .streams[] | [.[]] | @csv' | while read -r line
      do
	    #TCP non-reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6","$7","$8","$9",null,null,null,null,"$10 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp.csv
	  #update intervals sum data
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .sum | [.[]] | @csv' | while read -r line
      do
	    #TCP non-reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,"$7 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp2.csv
	  
    else
    #TCP reverse
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .streams[] | [.[]] | @csv' | while read -r line
      do
	    #TCP reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,null,null,"$7 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp.csv
	  #update intervals sum data
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .sum | [.[]] | @csv' | while read -r line
      do
	    #TCP reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5",null,null,null,null,null,"$6 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp2.csv
	fi  
  elif [[ $IPERF3_PROTOCOL == 'udp' ]]
  then
    if [[ $IPERF3_REVERSE == 0 ]]
    then
	  #UDP non-reverse
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .streams[] | [.[]] | @csv' | while read -r line
      do
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,"$7",null,"$8 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp.csv
	  #update intervals sum data
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .sum | [.[]] | @csv' | while read -r line
      do
	    #UDP non-reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5",null,null,null,"$6",null,"$7 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp2.csv
	else
	  #UDP reverse
      echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .streams[] | [.[]] | @csv' | while read -r line
      do
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,"$7","$8","$9","$10","$11 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp.csv
	  #update intervals sum data
	  echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .sum | [.[]] | @csv' | while read -r line
      do
	    #UDP reverse
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5",null,"$6","$7","$8","$9","$10 }' )
        nd=$(date '+%F %T' --date="@$((d + i))")
        echo "\"$nd\",$TEST_ID,$m,$line"
        ((i++))
      done > tmp2.csv
    fi
  fi
  
  #insert interval streams data to mysql
  while read line
  do
    mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,socket,start,end,seconds,bytes,bits_per_second,retransmits,snd_cwnd,rtt,jitter_ms,lost_packets,packets,lost_percent,omitted) VALUES ($line);")
    execute_mysql_cmd "$mysql_cmd"
	  
  done < tmp.csv
  
  #insert interval sum data to mysql
  table="iperf3_intervals_sum"
  while read line
  do
    mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,start,end,seconds,bytes,bits_per_second,retransmits,jitter_ms,lost_packets,packets,lost_percent,omitted) VALUES ($line);")
    execute_mysql_cmd "$mysql_cmd"  
  done < tmp2.csv
}

################################################################################################
# update end tables                                                                            #
################################################################################################

function update_iperf3_end()
{
  local JSON="$1"
  local test_run="$2"
  local i=0
  local sender=true
  local test_type=""
  
  # update the iperf3_end_streams table
  
  local table="iperf3_end_streams"
  if [[ $IPERF3_PROTOCOL == 'tcp' ]]
  then
    if [[ $IPERF3_REVERSE == 0 ]]
    then
	  sender=true
	  i=0
	  echo $JSON | $(echo $PATH_TO_JQ) -r '.streams[].sender | [.[]] | @csv' | while read -r line
        do
	      #TCP non-reverse sender
          line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11",null,null,null,null,null" }' )
          nd=$(date '+%F %T')
		  echo "\"$nd\",$TEST_ID,$test_run,$sender,$line"
          ((i++))
        done > tmp.csv
		
	    #insert end streams data to mysql
        while read line
        do
          mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,sender,socket,start,end,seconds,bytes,bits_per_second,retransmits,max_snd_cwnd,max_rtt,min_rtt,mean_rtt,jitter_ms,lost_packets,packets,lost_percent,out_of_order) VALUES ($line);")
          
          execute_mysql_cmd "$mysql_cmd"	  
        done < tmp.csv

	  sender=false
	  i=0
	  echo $JSON | $(echo $PATH_TO_JQ) -r '.streams[].receiver | [.[]] | @csv' | while read -r line
        do
	      #TCP non-reverse receiver
          line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,null,null,null,null,null" }' )
          nd=$(date '+%F %T')
		  echo "\"$nd\",$TEST_ID,$test_run,$sender,$line"
          ((i++))
        done > tmp.csv
		while read line
        do
          mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,sender,socket,start,end,seconds,bytes,bits_per_second,retransmits,max_snd_cwnd,max_rtt,min_rtt,mean_rtt,jitter_ms,lost_packets,packets,lost_percent,out_of_order) VALUES ($line);")
          
          execute_mysql_cmd "$mysql_cmd"	  
        done < tmp.csv
	    
	else # reverse = true
	  sender=true
	  i=0
	  echo $JSON | $(echo $PATH_TO_JQ) -r '.streams[].sender | [.[]] | @csv' | while read -r line
        do
	      #TCP reverse sender
          line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,null,null,null,null,null" }' )
          nd=$(date '+%F %T')
		  echo "\"$nd\",$TEST_ID,$test_run,$sender,$line"
          ((i++))
        done > tmp.csv
		while read line
        do
          mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,sender,socket,start,end,seconds,bytes,bits_per_second,retransmits,max_snd_cwnd,max_rtt,min_rtt,mean_rtt,jitter_ms,lost_packets,packets,lost_percent,out_of_order) VALUES ($line);")
          
          execute_mysql_cmd "$mysql_cmd"	  
        done < tmp.csv
		
	  sender=false
	  i=0
	  echo $JSON | $(echo $PATH_TO_JQ) -r '.streams[].receiver | [.[]] | @csv' | while read -r line
      do
	    #TCP reverse receiver
        line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,null,null,null,null,null" }' )
        nd=$(date '+%F %T')
		echo "\"$nd\",$TEST_ID,$test_run,$sender,$line"
        ((i++))
      done > tmp.csv
      while read line
      do
        mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,sender,socket,start,end,seconds,bytes,bits_per_second,retransmits,max_snd_cwnd,max_rtt,min_rtt,mean_rtt,jitter_ms,lost_packets,packets,lost_percent,out_of_order) VALUES ($line);")
          
        execute_mysql_cmd "$mysql_cmd"	  
      done < tmp.csv
    fi
	
	# update iperf3_end_sum table
	table="iperf3_end_sum"
	  
	#update sum sent
	test_type="sum_sent"
	  
	line=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.sum_sent | [.[]] | @csv' )
	line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null" }' )
    nd=$(date '+%F %T')
	line=$(echo	"\"$nd\",$TEST_ID,$test_run,\"$test_type\",$line")
	
	mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,type,start,end,seconds,bytes,bits_per_second,retransmits,jitter_ms,lost_packets,packets,lost_percent) VALUES ($line);")
	  
	execute_mysql_cmd "$mysql_cmd"
	  
	#update sum received
	test_type="sum_received"
	  
	line=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.sum_received  | [.[]] | @csv' )
	line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5",null,null,null,null,null" }' )
	nd=$(date '+%F %T')
	line=$(echo	"\"$nd\",$TEST_ID,$test_run,\"$test_type\",$line")
	mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,type,start,end,seconds,bytes,bits_per_second,retransmits,jitter_ms,lost_packets,packets,lost_percent) VALUES ($line);")
	  
	execute_mysql_cmd "$mysql_cmd"
	
  elif [[ $IPERF3_PROTOCOL == 'udp' ]]
  then
    if [[ $IPERF3_REVERSE == 0 ]]
    then
	  sender=true
	else
	  sender=false
	fi
	i=0
	echo $JSON | $(echo $PATH_TO_JQ) -r '.streams[].udp | [.[]] | @csv' | while read -r line
    do
	  #UDP
      line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,null,null,null,null,"$7","$8","$9","$10","$11 }' )
      nd=$(date '+%F %T')
	  echo "\"$nd\",$TEST_ID,$test_run,$sender,$line"
      ((i++))
    done > tmp.csv
	while read line
    do
      mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,sender,socket,start,end,seconds,bytes,bits_per_second,retransmits,max_snd_cwnd,max_rtt,min_rtt,mean_rtt,jitter_ms,lost_packets,packets,lost_percent,out_of_order) VALUES ($line);")
          
      execute_mysql_cmd "$mysql_cmd"	  
    done < tmp.csv
  
	# sum udp
	#update sum received
	test_type="sum_udp"
	table="iperf3_end_sum"
	
	line=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.sum | [.[]] | @csv' )
	line=$(echo $line | awk -F, '{ print $1","$2","$3","$4","$5","$6",null,"$7","$8","$9 }' )
	nd=$(date '+%F %T')
	line=$(echo	"\"$nd\",$TEST_ID,$test_run,\"$test_type\",$line")
	mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,type,start,end,seconds,bytes,bits_per_second,retransmits,jitter_ms,lost_packets,packets,lost_percent) VALUES ($line);")
	  
	execute_mysql_cmd "$mysql_cmd"  
  fi
  
  # update cpu_utilization_percent
  table="iperf3_end_cpu_utilization"  
  line=$(echo $JSON | $(echo $PATH_TO_JQ) -r '.cpu_utilization_percent | [.[]] | @csv' )
  nd=$(date '+%F %T')
  line=$(echo "\"$nd\",$TEST_ID,$test_run,$line")
  mysql_cmd=$(echo "INSERT INTO $table (time,test_id,test_run,host_total,host_user,host_system,remote_total,remote_user,remote_system) VALUES ($line);")
	  
  execute_mysql_cmd "$mysql_cmd"  
}


################################################################################################
# Main Routine                                                                                 #
################################################################################################

parse_args $@

echo will execute the command : iperf3 $IPERF3_ARGS
echo over $TEST_RUNS test runs...

if [[ $IPERF3_LOCAL_RUN == 0 ]]
then
  # will run iperf from the local command line
  IPERF3_CMD="iperf3 $IPERF3_ARGS"
else
  # start iperf server on remote host
  echo starting iperf server on "$IPERF3_SERVER"
  IPERF3_CMD="ssh $IPERF3_SERVER_USER@$IPERF3_SERVER 'iperf3 -s -p $IPERF3_PORT -D'"
  echo will execute $IPERF3_CMD
  eval $IPERF3_CMD
  # will run iperf from remote host
  IPERF3_CMD="ssh $IPERF3_CLIENT_USER@$IPERF3_CLIENT 'iperf3 $IPERF3_ARGS'"
fi

#update general info table
update_iperf3_general_info

#Cycle through the test runs
for ((m = 1 ; m <= $TEST_RUNS ; m++))
do

  # Check if ping tests are run in parallel, and run them in a separate thread...
  if [[ $IPERF3_RUN_PING == 1 ]]
    then
    ./ping_test.sh $IPERF3_SERVER $IPERF3_TIME $m $TEST_ID $IPERF3_CLIENT &
  fi
 
  d=$(date '+%s')
  echo "Test run: $m"
  echo will execute $IPERF3_CMD
  # execute run and output to json
  TOTAL_JSON=$(eval $IPERF3_CMD)
  
  #check that iperf run didn't result in errors
  string='My long string'
  if [[ $TOTAL_JSON == *"error"* ]]; then
    echo "iperf3 test resulted in error"
	echo $(echo "$TOTAL_JSON" | grep "error")
	echo "JSON dumped at iperf3_error_$d.json"
	echo "$TOTAL_JSON" > 'iperf3_error_$d.json'
	if [ $IPERF3_EXIT_ON_JSON_ERROR -eq 1 ]; then
	  exit 1
	fi
  fi
  
  #Print out 'start' data in case of first run only
  if [[ $m == 1 ]]
  then
    echo first run start
	START_JSON=$(echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.start ')
    # echo $START_JSON
	update_iperf3_start "$START_JSON" "1" 
  fi
  

  #update intervals tables
  update_iperf3_intervals "$TOTAL_JSON" "$m"
  
  i=0
  
  INTERVALS_SUM_JSON=$(echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.intervals | .[] | .sum | [.[]] | @csv' | while read -r line
  do
    nd=$(date '+%F %T' --date="@$((d + i))")
    echo "$TEST_ID,$nd,$line"
    ((i++))
  done)
  
  #echo intervals sum data for test run $m
  #echo $INTERVALS_SUM_JSON
  
  #Print out 'end' data
  
  echo "test run $m end"
  END_JSON=$(echo $TOTAL_JSON | $(echo $PATH_TO_JQ) -r '.end ')
  # echo $END_JSON
  update_iperf3_end "$END_JSON" "$m"
  
  eval "$(sleep $IPERF3_TEST_RUN_DELAY)"
done

# test complete 
# clean-up
rm tmp.csv
rm tmp2.csv

if [[ $IPERF3_LOCAL_RUN == 1 ]]
  then
  #kill any iperf server processes
  IPERF3_CMD="ssh $IPERF3_SERVER_USER@$IPERF3_SERVER 'pkill iperf3'"
  echo will execute $IPERF3_CMD
  eval $IPERF3_CMD
fi

# update test_complete flag in iperf3_general_info table
mysql_cmd=$(echo "update iperf3_general_info set test_complete=true where test_id=$TEST_ID;")  
execute_mysql_cmd "$mysql_cmd" 

################################################################################################
# End Main Routine                                                                             #
################################################################################################
