#!/bin/bash
echo "============================================================="

pwd=$(pwd)
date=$(date +%Y%m%d)
memcached_port=11211
mysql -u root -p 3dolphins -e 'select ticket_number from customer_binus' > $pwd/ticket-number-$date.txt
sed -i 's/ticket_number//g' $pwd/ticket-number-$date.txt
sed -i '/^[[:space:]]*$/d' $pwd/ticket-number-$date.txt

declare -a arr=(
`awk '1' $pwd/ticket-number-$date.txt`
)
echo "--> backup chasitor dulu guys, tungguin ya..."
for tn in "${arr[@]}"
do
valueSales=$(echo "get sales-$tn" | nc localhost 11212 | grep -v "END" | sed -n 2p)
        if [[ ! -z $valueSales ]]; then
                data_sales1=$(echo "get sales-$tn" | nc localhost $memcached_port | grep -v "END" | sed -n 1p | awk '{print$2,$3}')
                data_sales2=$(echo "get sales-$tn" | nc localhost $memcached_port | grep -v "END" | sed -n 1p | awk '{print$4}')
                echo "set $data_sales1 0 $data_sales2 \r\n$valueSales\r\n" >> chasitor-backup-$date
                valueEmail=$(echo "get sales-$tn" | nc localhost $memcached_port | grep -v "END" | sed -n 2p)
                if [[ ! -z $valueEmail ]]; then
                        data_email1=$(echo "get email-$tn" | nc localhost $memcached_port | grep -v "END" | sed -n 1p | awk '{print$2,$3}')
                        data_email2=$(echo "get email-$tn" | nc localhost $memcached_port | grep -v "END" | sed -n 1p | awk '{print$4}')
                        echo "set $data_email1 0 $data_email2 \r\n$valueEmail\r\n" >> chasitor-backup-$date
                fi
        fi
done
sed -i "s/\r//g" chasitor-backup-$date
echo "--> flush memcached $memcached_port"
#echo "flush_all" | nc localhost $memcached_port > /dev/null 2>&1
echo "--> restore chasitor"
count_chasitor=$(cat $pwd/chasitor-backup-$date | wc -l)
counter=1
until [[ $counter -gt $count_chasitor ]]; do
        cs=$(sed -n $counter'p' $pwd/chasitor-backup-$date)
        printf "$cs" | nc localhost $memcached_port
        ((counter++))
done
echo "--> finished"
echo "============================================================="
