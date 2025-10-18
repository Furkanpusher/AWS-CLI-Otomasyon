# Kullanım: aws_health_check.sh i-xxxxxxxxxxxxxxxx
INSTANCE_ID=$1
REGION="eu-north-1"  # 📌 DİKKAT: Kendi AWS Bölgenizle değiştirin

# Gerekli parametre kontrolü
if [ -z "$INSTANCE_ID" ]; then
    echo "Hata: Instance ID (örneğin i-0w7vjth3) parametresi gereklidir."
    exit 1
fi

echo "--- AWS EC2 Sağlık Kontrolü Başlatıldı ---"

function check_status() {
    # AWS CLI kullanarak durum kontrollerini sorguluyoruz.
    # StatusChecks, hem 'system' hem de 'instance' durumlarını içerir.
    STATUS=$(aws ec2 describe-instance-status \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query "InstanceStatuses[0].InstanceStatus.Status" \
        --output text 2>/dev/null) # Hataları sessizce yoksay

    if [ "$STATUS" == "ok" ]; then
        return 0
    else
        echo "Durum: $STATUS"
        return 1
    fi
}

# 1. Aşama: Instance'ın çalışıp çalışmadığını kontrol et
RUNNING_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query "Reservations[].Instances[0].State.Name" \
    --output text 2>/dev/null)

if [ "$RUNNING_STATE" != "running" ]; then
    echo "HATA: Instance (ID: $INSTANCE_ID) 'running' durumunda değil, mevcut durum: $RUNNING_STATE"
    exit 1
else
    echo "Kontrol 1: Instance durumu 'running' ✅"
fi

# 2. Aşama: AWS Durum Kontrollerini kontrol etmeden önce instance durumundan emin olduk
echo "Kontrol 2: AWS Status Check bekleniyor..."

ATTEMPTS=0
MAX_ATTEMPTS=12  # Yaklaşık 1 dakika bekleme süresi
SLEEP_DURATION=5

while ! check_status; do
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo ""
        echo "HATA: Instance ($INSTANCE_ID), $MAX_ATTEMPTS deneme sonunda AWS Status Check'i geçemedi."
        echo "Sonuç: ❌ KRİTİK HATA"
        exit 1
    fi
    echo "Durum: AWS Status Check henüz 'ok' değil. $SLEEP_DURATION saniye bekleniyor..."
    sleep $SLEEP_DURATION
    ATTEMPTS=$((ATTEMPTS + 1))
done

echo ""
echo "Kontrol 2: AWS Status Check 'ok' ✅"
echo ""
echo "--- Instance $INSTANCE_ID Sağlıklı ve Çalışıyor ---"
exit 0