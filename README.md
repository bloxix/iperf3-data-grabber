# iperf3-data-grabber
The data grabber captures output from the well-known iperf3 traffic genereator test tool. Test data is uploaded to a mysql database, where it can be further analysed, e.g. through Grafana. The tool consists of 
- the data-grabber script, which is the main script, 
- the create-table script, which generates the initial database structure,
- a ping_test script, which allows for concurrent ping tests between iperf3 client and server,
- an iperf3 data grabber json file, which contains a grafana sample dashboard.

Details are given here: https://github.com/bloxix/iperf3-data-grabber/blob/master/IPerf3%20Data%20Grabber.pdf 

