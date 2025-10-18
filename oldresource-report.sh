# Kullanım: oldresource_report.sh <gün_sayısı> <bölge_kodu>
DAYS_THRESHOLD=$1  # İlk parametre: Kaç günden eski (örneğin 30)
REGION=$2          # İkinci parametre: Bölge kodu (örneğin eu-central-1)

# =================================================================
# Gerekli parametre kontrolü
# =================================================================
if [ -z "$DAYS_THRESHOLD" ] || ! [[ "$DAYS_THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Hata: Birinci parametre olarak kaç günden eski kaynakları listeleyeceğinizi (sayı) belirtmelisiniz."
    echo "Kullanım: oldresource_report.sh 30 eu-central-1"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo "Hata: İkinci parametre olarak AWS bölge kodunu (örneğin eu-north-1) belirtmelisiniz."
    echo "Kullanım: oldresource_report.sh 30 eu-central-1"
    exit 1
fi
# =================================================================

echo "--- AWS ESKİ KAYNAK RAPORU BAŞLATILDI ($DAYS_THRESHOLD günden eski) ---"
echo "Bölge: $REGION"
echo "------------------------------------------------------------------"

# Mevcut tarihi saniye cinsinden al
CURRENT_DATE_SEC=$(date +%s)
# Eşik tarihini (N gün öncesini) saniye cinsinden hesapla
THRESHOLD_SEC=$((CURRENT_DATE_SEC - (DAYS_THRESHOLD * 86400))) # 86400 = saniye/gün

# =================================================================
# FONKSİYON 1: Eski EBS Birimlerini (Volume) Raporlama
# =================================================================
echo "### 1. EBS Birimleri (Detached/Kullanılmayanlar dahil)"
aws ec2 describe-volumes \
    --region $REGION \
    --query "Volumes[*].{ID:VolumeId, CreateTime:CreateTime, State:State, Size:Size, Attached:Attachments[0].InstanceId}" \
    --output json | jq -c '.[]' | while read volume; do

    ID=$(echo "$volume" | jq -r '.ID')
    CREATE_TIME_ISO=$(echo "$volume" | jq -r '.CreateTime')
    STATE=$(echo "$volume" | jq -r '.State')
    SIZE=$(echo "$volume" | jq -r '.Size')
    ATTACHED=$(echo "$volume" | jq -r '.Attached')

    # ISO zamanını saniyeye çevir
    CREATE_TIME_SEC=$(date -d "$(echo $CREATE_TIME_ISO | cut -f1 -d'.')" +%s 2>/dev/null)

    # Tarih kontrolü
    if [ "$CREATE_TIME_SEC" -lt "$THRESHOLD_SEC" ]; then
        ATTACH_INFO="Durum: $STATE, Bağlı Olduğu Instance: ${ATTACHED:-YOK}"
        echo " [VOLUME] $ID (Boyut: ${SIZE}GB) - Oluşturulma: $(date -d @$CREATE_TIME_SEC +%Y-%m-%d). $ATTACH_INFO"
    fi
done

echo ""

# =================================================================
# FONKSİYON 2: Eski EC2 Snapshot'ları Raporlama
# =================================================================
echo "### 2. EC2 Snapshot'ları"
aws ec2 describe-snapshots \
    --owner-ids self \
    --region $REGION \
    --query "Snapshots[*].{ID:SnapshotId, CreateTime:StartTime, Desc:Description, Size:VolumeSize}" \
    --output json | jq -c '.[]' | while read snapshot; do

    ID=$(echo "$snapshot" | jq -r '.ID')
    CREATE_TIME_ISO=$(echo "$snapshot" | jq -r '.CreateTime')
    DESC=$(echo "$snapshot" | jq -r '.Desc')
    SIZE=$(echo "$snapshot" | jq -r '.Size')

    # ISO zamanını saniyeye çevir
    CREATE_TIME_SEC=$(date -d "$(echo $CREATE_TIME_ISO | cut -f1 -d'.')" +%s 2>/dev/null)

    # Tarih kontrolü
    if [ "$CREATE_TIME_SEC" -lt "$THRESHOLD_SEC" ]; then
        echo " [SNAPSHOT] $ID (Boyut: ${SIZE}GB) - Oluşturulma: $(date -d @$CREATE_TIME_SEC +%Y-%m-%d). Açıklama: $DESC"
    fi
done

echo "------------------------------------------------------------------"
echo "Rapor Tamamlandı."