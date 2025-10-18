AWS DevOps için 5 tane kullanışlı otomasyon

Bu depo, AWS CLI ve Bash kullanarak günlük tekrarlanan DevOps/Cloud mühendisliği görevlerini otomatikleştirmeyi amaçlayan bir araç otomasyon koleksiyonudur. Bu scriptler, güvenlik, port kontrolleri, maliyet optimizasyonu ve envanter yönetimi gibi kritik alanlarda hızlı ve güvenilir işlemler yapmanızı sağlar.

🛠️ Kurulum

Tüm betiklerinizi sisteminizde kolayca erişilebilir kılmak için aşağıdaki adımları izleyin.

Adım 1: Klasör Oluşturma

Tüm betikleri merkezi bir konumda toplayın ve yetkilendirin:

```bash
# bash scriptlerinin tutulacağı klasörü oluşturun
sudo mkdir -p /bin/aws-cli-scripts
```

Adım 2: Betikleri Taşıma ve İzin Verme

Oluşturduğumuz tüm .sh dosyalarını /bin/aws-cli-scripts klasörüne yerleştirin ve çalıştırma izni verin:

```bash
# Tüm betiklere çalıştırma izni verin
sudo chmod +x /bin/aws-cli-scripts/*.sh
```
Adım 3: Bağımlılıkları Kurma

AWS CLI çıktısını düzgün bir formatta almak için gerekli Linux kütüphanelerini kurun:

```bash
# JSON verilerini işlemek için JQ
sudo apt install jq -y

# Çıktıları düzenli sütunlarda göstermek için (Bu genellikle kurulu gelir)
sudo apt install bsdmainutils -y
```

Adım 4: PATH Ortam Değişkenini Ayarlama

Bu, scriptleri bulundukları tam yolu yazmadan, sadece dosya adıyla terminalden çalıştırmanızı sağlar. Bu sayede boşuna sürekli o yolu vermemiz gerekmeyecek. 

    1-Yapılandırma Dosyasını Açın: (Kullandığınız Shell'e göre ~/.bashrc veya ~/.zshrc olabilir)
```bash
        nano ~/.bashrc
```
    2-Aşağıdaki satırı dosya sonuna ekleyin ve kaydedip çıkın
```bash
        export PATH="/bin/aws-cli-scripts:$PATH"
```
    3- Terminali yenileyin ki değişikliklerin uygulandığına emin olalım.
```bash
        source ~/.bashrc
```

BASİT BİR KULLANIM ÖRNEĞİ
```bash
    healthcheck-instance.sh <instance_id> <bölge_kodu>
```



