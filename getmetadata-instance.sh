# Kullanım: get_instance_metadata.sh <instance_id> <bölge_kodu>
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

echo "--- EC2 META VERİ VE YAPILANDIRMA RAPORU BAŞLATILDI ---"
echo "Instance ID: $INSTANCE_ID | Bölge: $REGION"
echo "################################################################"

# =================================================================
# 1. Kısım: Instance Etiketlerini (Tags) Çekme
# =================================================================
echo "### 1. Instance Etiketleri (TAGS)"
echo "------------------------------------------------"

# AWS CLI ile etiketleri çek ve tablo formatında göster
TAGS=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].Tags[]" \
    --output text 2>/dev/null)

if [ -z "$TAGS" ]; then
    echo "UYARI: Instance'a tanımlanmış Etiket (Tag) bulunamadı."
else
    # Çıktı formatı: KEY<tab>VALUE
    # Bunu düzenli bir tabloya dönüştürmek için 'column -t' kullanıyoruz.
    echo "$TAGS" | awk '{print $1 "\t" $2}' | column -t -s $'\t'
fi

echo "------------------------------------------------"
echo ""

# =================================================================
# 2. Kısım: Kullanıcı Verilerini (User Data) Çekme
# =================================================================
echo "### 2. Kullanıcı Verileri (USER DATA)"
echo "(Sunucunun başlatıldığında çalıştırdığı scriptler)"
echo "------------------------------------------------"

# AWS CLI ile User Data'yı çek
USER_DATA_ENCODED=$(aws ec2 describe-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --attribute userData \
    --region "$REGION" \
    --query "UserData.Value" \
    --output text 2>/dev/null)

if [ -z "$USER_DATA_ENCODED" ] || [ "$USER_DATA_ENCODED" == "None" ]; then
    echo "UYARI: Instance için User Data (Kullanıcı Verisi) tanımlanmamış."
else
    # User Data AWS'de Base64 ile şifrelenmiş tutulur.
    echo "User Data (Base64 kodlanmış):"
    echo "$USER_DATA_ENCODED"
    echo ""
    echo "User Data (Çözümlenmiş - Decode Edilmiş):"
    
    # Base64 decode işlemi
    # Linux sistemlerinde `base64 --decode` kullanılır.
    # macOS/BSD sistemlerinde `base64 -D` kullanılır.
    # Ortak çözüm:
    echo "$USER_DATA_ENCODED" | base64 -d 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo "HATA: Base64 çözme işlemi başarısız oldu. Veri boş veya hatalı formatta olabilir."
    fi
fi

echo "------------------------------------------------"
echo "Rapor Tamamlandı."