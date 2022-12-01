#!/bin/bash



if [[ $# -ne 1 ]]
then
	echo "Invalid input."
	exit 1
fi

#echo "Packet Analysis Result:"

####### Pre-Infection Analysis ########

echo "Pre-Infection Checks:" > report.txt #Start New Report (>> will append)


#_#_#_#_#_#_#_#_#_ Hash Check _#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#

# Get tcp stream index (that contains zip in GET request)
zip_stream_list="$(tshark -r $1 -Y "(http.request or ssl.handshake.type == 1) 
				and !(ssdp) 
				and http.request.uri contains "zip"" -O tcp,http -l | grep "Stream index" | awk 'match($0, /([0-9]+)/, matches) {print matches[1]}')"
				# -T fields -e tcp.stream
# Export http objects
#Run Only Once -- otherwise it will make duplicate
#(tshark -2 -r $1 --export-object "http,malware_check")
#tshark -2 -r $1 -Y "tcp.stream eq $stream_num" -z follow,tcp,ascii,$stream_num -x --export-object "http,malware_export"
# [Make sure there is no space between http,malware_export or there will be issues with directory name.]

# Check tcp streams for zip file requests
echo "Hash Check:" >> report.txt

for stream_num in $zip_stream_list
do
zip_stream="$(tshark -2 -r $1 -Y "tcp.stream eq $stream_num" -z follow,tcp,ascii,$stream_num -x)"

malware_file="malware_export/dd05ce3a-a9c9-4018-8252-d579eed1e670.zip"

zip_directory='malware_check/'
zip_file="$zip_directory$(echo "$zip_stream" | grep -oP '(?<=GET /).*(?=HTTP)')"

hash_1="$(sha256sum $malware_file | awk -F" " '{print $1}')"
hash_2="$(sha256sum $zip_file | awk -F" " '{print $1}')"

if [[ "$hash_1" == "$hash_2" ]]; then
echo "******************************************" >> report.txt
#echo "$(vt file $hash_2)"
echo "In stream: $zip_file - Hash: $hash_2" >> report.txt
echo "Malware  : $malware_file - Hash: $hash_1" >> report.txt
echo "******************************************" >> report.txt
echo >> report.txt
echo >> report.txt
#echo "<<<<<<<<<<< Malware Infected Zip file found. >>>>>>>>>>>"
fi

done

# Get tcp stream index for malicious host ip
# exe file from 144.91.69.195 is not exported by --export-object
mal_stream_list="$(tshark -r $1 -Y "(http.request or ssl.handshake.type == 1) and !(ssdp) and http.host==144.91.69.195" -O http,tcp -l -T fields -e tcp.stream)"
for stream_num in $mal_stream_list
do
echo "******************************************" >> report.txt

mal_stream="$(tshark -2 -r $1 -Y "tcp.stream eq $stream_num" -z follow,tcp,ascii,$stream_num -x)"
mal_stream_info="$(echo "$mal_stream" | grep "Follow" -A28)"
echo "Malicious Stream Info:" >> report.txt
echo "$mal_stream_info" >> report.txt

echo "******************************************" >> report.txt
done
###

#_#_#_#_#_#_#_#_#_ Hash Check _#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#



#_#_#_#_#_#_#_#_#_ Host Check _#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#
malicious_requests="$(tshark -r $1 -Y "(http.request or ssl.handshake.type == 1) 
				and !(ssdp) 
				and (http.host==144.91.69.195 or http.host==www.dchristjan.com)" -O http -l -T fields -e http.host)"
malicious_request_count="$(echo "$malicious_requests" |wc -l)"
				
if [[ $malicious_request_count -gt 0 ]]
then
echo >> report.txt
echo "******************************************" >> report.txt
echo "Host check:" >> report.txt
echo "No. of requests to malicious site: $malicious_request_count" >> report.txt
echo $malicious_requests >> report.txt
echo "******************************************" >> report.txt
echo >> report.txt
echo >> report.txt
fi
#_#_#_#_#_#_#_#_#_ Host Check _#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#



####### Post-Infection Analysis ########



#grep -oP '(?<=GET /).*(?=HTTP)'
#-z follow,http,ascii,7
#-O tcp -S "###" 
#-Y "(http.request or ssl.handshake.type == 1) and !(ssdp)" 
#-T fields -e ip.addr udp
#and http.host==www.dchristjan.com
#captured/2019-09-25-Trickbot-gtag-ono19-infection-traffic.pcap 

#echo "$zip_stream"


#### list of filters and regular expressions

#Two pass:		-2
#General filter:	-Y "(http.request or ssl.handshake.type == 1) and !(ssdp)"
#URL filter:		-Y "http.request.uri contains "/google/""
#tcp conv show:		-z conv,tcp
#Output view:		-O tcp,http
#Output pkt separator:	-S "###" 
#Output fields(!view):	-T fields -e ip.addr
#











#tshark -r captured/nmap_scan.pcapng -O arp -Y "arp" -x
#tshark -t ad -r captured/nmap_scan.pcapng -Y "arp"
#tshark -t ad -r captured/nmap_scan.pcapng -Y "arp and arp.opcode==2"

#echo $allARP

(cat report.txt)

