A=$(ps -ef | grep cront.sh | grep -v grep | awk '{print $2}')

kill -9 $A
