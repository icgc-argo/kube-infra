

# sh /opt/bitnami/kafka/filesink/restore.sh
# restore_topic=connect1
# restore_files=/opt/bitnami/kafka/filesink/snapshot/connect*.sink
# kafka_server=kafka
# restore_from_time="2021-01-19T15:57"
params=$#
if [ "$#" -ne 4 ]; then
    echo "Illegal number of parameters: required: 4, supplied: $params"
    echo
    echo "Usage $0 restore_topic kafka_server \"restore_files\"  \"restore_from_time\""
    echo
    echo "restore_topic: destination topic to restore to"
    echo "kafka_server: kafka server"
    echo "restore_files: path to the files to restore from, example \"/opt/bitnami/kafka/filesink/connect*.sink\" - must be in quotes"
    echo "restore_from_time: timestamp to restore from, example \"2021-01-19T15:57\" - must be in quotes"
    echo
    echo "Example:"
    echo
    echo "sh /opt/bitnami/kafka/filesink/restore.sh connect1 kafka \"/opt/bitnami/kafka/filesink/snapshot/connect*.sink\"  \"2021-01-19T15:57\""

    exit
fi

restore_topic=$1
kafka_server=$2
restore_files=$3
restore_from_time=$4

printf "\033c"

echo "Restoring topic: $restore_topic"
echo "Kafka server: $kafka_server"
echo
echo "Restoring from: $restore_files"
ls $restore_files
echo
echo "Restoring from timestamp: $restore_from_time"

#check if the files are readable
for file in $restore_files
  do
    [ -f $file ] || exit
    echo $file
  done

restore_source="/tmp/restoredata.$(date +%s)"
touch $restore_source || exit
[ -w $restore_source ] || exit
# ls -la $restore_source



cat $restore_files | awk -F'utcTime":"|"}}' '$2 >= "'$restore_from_time'"' > $restore_source

read -p "Continue (yes/no)?" choice
case "$choice" in
  yes ) echo "Executing restore...";;
  * )
    echo "Exiting."
    exit
  ;;
esac

kafka-console-producer.sh --broker-list $kafka_server:9092 --topic $restore_topic < $restore_source
