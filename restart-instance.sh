set -e

id=$1  # ilk çıktıyı id ye atıcak(i-0w7v...)
sleep_duration=5   
start_time=$(date +%s)

function check_parameter () {    #instance parametre kontrolü 
	if echo "$1" | grep -E '^i-[a-zA-Z0-9]{8,}' > /dev/null; then
		return 0
	else
		echo "Instance ID parametresi gerekli. Örnek: i-0w7vjth3"
		return 1
	fi
}

function stop_instance () { 
	aws ec2 stop-instances --instance-ids $1
}

function start_instance () {
	aws ec2 start-instances --instance-ids $1
}

function check_status () {
	aws ec2 describe-instances --instance-ids $1 \ 
		--query "Reservations[].Instances[].State.Name" --output text 
}

function check_running () {
	status=$(check_status $1)
	if [ "$status" != "running" ]; then
		echo "Instance tekrar başlatılamaz, instance durumu Çalışır halde olmalı."
		return 1
	fi
}

function wait_for_status () {
	status=$(check_status $1)
	while [ "$status" != "$2" ]; do
		echo "Instance daha $2 durumunda değil, bekleniyor"
		sleep $sleep_duration
		status=$(check_status $1)
	done
}

function main () {
	check_parameter $id
	check_running $id
	stop_instance $id
	wait_for_status $id durduruldu
	start_instance $id
	wait_for_status $id çalışıyor
	end_time=$(date +%s)
	duration=$((end_time - start_time))
	echo "$id numaralı instance tekrar başlatmanız başarılı oldu."
	echo "bu script $duration saniyede tamamlandı."
}

main