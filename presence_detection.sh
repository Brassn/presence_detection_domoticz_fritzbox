#!/bin/bash

#presence_detection.sh

#script Presence detection for domoticz  & Frizbox v1.02
#created by g.j fun - 21 jan 2019
#making use of  fritzconnection  url: https://pypi.org/project/fritzconnection/
#dependencies: lxml, jq and requests
#tested with: Fritzbox 7581  should work with all routers who supporting TR-064 protocol.
#place fritzconnection.py and fritzhosts.py in same directory as this script. 
#dont forget to change parameters router inside fritzconnection.py and activate TR-064 on router. 
#standard debug information is on just set debug to  false to disable it. 
# if you have a repeater please specify ip below. 

#setup device(s) change values here
ip_device1=192.168.178.22
name_device1="Iphone GJ"
ip_device2=192.168.178.27
name_device2="Iphone Pat"
idxdevice1=424
idxdevice2=428

#setup  router, extender and  domoticz change values
password_fritzbox=yourpassword
host_fritzbox=192.168.178.1
host_extender=192.168.178.21
host_domoticz=192.168.178.33:8080

#set debug to true or false to see logging information 
enable_debug=true

#current directory script
cwd=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

#get current status of device(s) in domoticz 

if [ "$enable_debug" == "true" ]; then
status_domoticz_device1=$(curl 'http://'$host_domoticz'/json.htm?type=devices&rid='$idxdevice1 | jq -r [.result][][].Data)
status_domoticz_device2=$(curl 'http://'$host_domoticz'/json.htm?type=devices&rid='$idxdevice2 | jq -r [.result][][].Data)
echo "status domoticz device 1 = $status_domoticz_device1"  
echo "status domoticz device 2 = $status_domoticz_device2"
else
status_domoticz_device1=$(curl -s 'http://'$host_domoticz'/json.htm?type=devices&rid='$idxdevice1 | jq -r [.result][][].Data)
status_domoticz_device2=$(curl -s 'http://'$host_domoticz'/json.htm?type=devices&rid='$idxdevice2 | jq -r [.result][][].Data)
fi

#get device status of devices in Route

output_router=$(python $cwd/fritzhosts.py -i $host_fritzbox -p$password_fritzbox)
echo "getting output router" ;
status_router_device1=$(grep "$ip_device1" <<<"$output_router" | grep "active") 
status_router_device2=$(grep "$ip_device2" <<<"$output_router" | grep "active") 
sleep 2;
output_extender==$(python $cwd/fritzhosts.py -i $host_extender -p$password_fritzbox)
status_extender_device1=$(grep "$ip_device1" <<<"$output_extender" | grep "active") 
status_extender_device2=$(grep "$ip_device2" <<<"$output_extender" | grep "active") 


if [ "$enable_debug" == "true" ]; then
echo "output router devices = $output_router" 
echo "output extender devices = $output_extender" 
echo "status router device 1 = $status_router_device1"
echo "status router device 2 = $status_router_device2"
echo "status extender device 1 = $status_extender_device1"
echo "status extender device2 = $status_extender_device2"
fi

if [ -z "$status_router_device1" ] && [ -z "$status_extender_device1" ]; then
# device is not active in router so set it to off
status_router_device1="Off" 
else
#device is active but so we set variable to on 
status_router_device1="On"
fi

if [ "$status_router_device1" == "$status_domoticz_device1" ]; then
# both are simular so there is nothing to change. 
echo $(date -u) "status router and domoticz for $name_device1 are simular, we do nothing"  
else
#router status vs domoticz status are not equal we set domoticz status to router status. 
#we change the value in domoticz
echo $(date -u)"status router is not simular to status domoticz. We change status domoticz for $name_device1 to  $status_router_device1" 
wget -q --delete-after "http://$host_domoticz/json.htm?type=command&param=switchlight&idx=$idxdevice1&switchcmd=$status_router_device1" >/dev/null 2>&1

#we send logging information to domoticz
wget -q --delete-after "http://$host_domoticz/json.htm?type=command&param=addlogmessage&message=presence-detection-logging $name_device1 = $status_router_device1" >/dev/null 2>&1
 
fi

if [ -z "$status_router_device2" ] && [ -z "$status_extender_device2" ]; then
# device is not active in router so set it to off
status_router_device2="Off" 
else
#device is active but so we set variable to on 
status_router_device2="On"
fi

if [ "$status_router_device2" == "$status_domoticz_device2" ]; then
# both are simular so there is nothing to change.
echo $(date -u) "status router and domoticz for $name_device2 are simular, we do nothing" 
else
#router status vs domoticz status are not equal we set domoticz status to router status. 
echo $(date -u) "status router is not simular to status domoticz. We change status domoticz for $name_device2 to  $status_router_device2" 
#we change the value in domoticz
wget -q --delete-after "http://$host_domoticz/json.htm?type=command&param=switchlight&idx=$idxdevice2&switchcmd=$status_router_device2" >/dev/null 2>&1

#we send logging information to domoticz
wget -q --delete-after "http://$host_domoticz/json.htm?type=command&param=addlogmessage&message=presence-detection-logging $name_device2 = $status_router_device2" >/dev/null 2>&1
 
fi

