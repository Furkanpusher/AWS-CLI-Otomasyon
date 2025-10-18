# Kullanım: aws_port_checker.sh <instance_id> <bölge_kodu>
INSTANCE_ID=$1
REGION=$2

# =================================================================
# Parametre Kontrolü
# =================================================================
if [ -z "$INSTANCE_ID" ]; then
    echo "Hata: Birinci parametre olarak Instance ID (örneğin i-0w7vjth3) gereklidir."
    exit 1
fi
if [ -z "$REGION" ]; then
    echo "Hata: İkinci parametre olarak AWS bölge kodu (örneğin eu-central-1) gereklidir."
    exit 1
fi
# =================================================================

echo "--- EC2 AÇIK PORT VE GÜVENLİK KONTROLÜ BAŞLATILDI ---"
echo "Instance ID: $INSTANCE_ID | Bölge: $REGION"
echo "--------------------------------------------------------"

# 1. Adım: Instance'a bağlı tüm Security Group ID'lerini al
SG_IDS=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].SecurityGroups[].GroupId" \
    --output text 2>/dev/null)

if [ -z "$SG_IDS" ]; then
    echo "UYARI: Instance'a bağlı Güvenlik Grubu (Security Group) bulunamadı veya Instance mevcut değil."
    exit 1
fi

echo "Bağlı SG ID'ler: $SG_IDS"
echo "--------------------------------------------------------"
echo "PORT | PROTOKOL | KAYNAK IP/SG | AÇIKLAMA"
echo "--------------------------------------------------------"

# 2. Adım: Her SG için gelen kuralları (Inbound Rules) sorgula
for SG_ID in $SG_IDS; do

    # Güvenlik Grubu kurallarını JSON formatında al
    RULES_JSON=$(aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --region "$REGION" \
        --query "SecurityGroups[0].IpPermissions" \
        --output json)

    # JSON çıktısını jq ile işleyerek kuralları tek tek listele
    echo "$RULES_JSON" | jq -c '.[]' | while read rule; do
        
        # Protokolü ve Port aralığını çek
        PROTOCOL=$(echo "$rule" | jq -r '.IpProtocol')
        PORT_FROM=$(echo "$rule" | jq -r '.FromPort')
        PORT_TO=$(echo "$rule" | jq -r '.ToPort')
        
        # Açıklamayı çek (eğer yoksa boş döner)
        DESCRIPTION=$(echo "$rule" | jq -r '.IpRanges[0].Description // empty')
        
        # Port aralığını formatla
        if [ "$PORT_FROM" == "$PORT_TO" ]; then
            PORT="$PORT_FROM"
        elif [ "$PORT_FROM" == "null" ]; then
            PORT="TÜMÜ" # Örneğin ICMP gibi protokoller için
        else
            PORT="$PORT_FROM-$PORT_TO"
        fi

        # Kaynak (Source) bilgisini belirleme
        SOURCE_INFO=""
        
        # CIDR IP kaynaklarını işle
        if [ "$(echo "$rule" | jq '.IpRanges | length')" -gt 0 ]; then
            echo "$rule" | jq -r '.IpRanges[].CidrIp' | while read ip; do
                printf "%-4s | %-8s | %-12s | %s\n" "$PORT" "$PROTOCOL" "$ip" "$DESCRIPTION"
            done
        fi
        
        # Başka bir SG kaynağını işle (SG'den SG'ye erişim)
        if [ "$(echo "$rule" | jq '.UserIdGroupPairs | length')" -gt 0 ]; then
            echo "$rule" | jq -r '.UserIdGroupPairs[].GroupId' | while read sg_source; do
                 # Açıklama SG'ye özgü olabilir
                 SG_DESC=$(echo "$rule" | jq -r '.UserIdGroupPairs[].Description // empty')
                 printf "%-4s | %-8s | %-12s | %s\n" "$PORT" "$PROTOCOL" "$sg_source" "$SG_DESC"
            done
        fi

    done
done

echo "--------------------------------------------------------"
echo "Kontrol Tamamlandı."