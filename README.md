# iperf3-data-grabber
The bash scripts implemens an iperf3 test tool which retrieves network test data from iperf3, the network speed test tool. The produced test data is uploaded to a mysql database, where it can be further analysed, e.g. through Grafana. 
The tool consists of two shell scripts, the data-grabber script and the create-table script. 
