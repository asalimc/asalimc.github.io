import requests
import json
import os
from datetime import datetime
from bs4 import BeautifulSoup
import random

# ============ BRASÍLIA BÖLGELERİ ============
BAIRROS_BRASILIA = [
    "Asa Norte", "Asa Sul", "Plano Piloto", "Taguatinga", "Ceilândia",
    "Guará", "Gama", "Sobradinho", "Planaltina", "Samambaia",
    "Recanto das Emas", "Lago Sul", "Lago Norte", "Sudoeste", "Noroeste"
]

# ============ BRASÍLIA HABER KAYNAKLARI ============
HABER_KAYNAKLARI = [
    {"url": "https://www.metropoles.com/distrito-federal", "nome": "Metrópoles"},
    {"url": "https://www.correiobraziliense.com.br/distrito-federal", "nome": "Correio Braziliense"},
    {"url": "https://g1.globo.com/df/distrito-federal/", "nome": "G1 DF"},
    {"url": "https://www.istoedinheiro.com.br/tag/brasilia/", "nome": "IstoÉ"},
    {"url": "https://agenciabrasilia.ebc.com.br/", "nome": "Agência Brasília"},
]

def get_brasilia_news():
    """Brasília haberlerini topla"""
    tum_haberler = []
    
    for kaynak in HABER_KAYNAKLARI:
        try:
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            response = requests.get(kaynak["url"], headers=headers, timeout=15)
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Haber başlıklarını bul
            for tag in ['h1', 'h2', 'h3', 'h4']:
                for element in soup.find_all(tag):
                    metin = element.get_text().strip()
                    if len(metin) > 20 and len(metin) < 200:
                        # Rastgele bir bölge ile ilişkilendir
                        rastgele_bairro = random.choice(BAIRROS_BRASILIA)
                        tum_haberler.append({
                            "kaynak": kaynak["nome"],
                            "baslik": metin[:150],
                            "bairro": rastgele_bairro,
                            "zaman": datetime.now().strftime("%H:%M"),
                            "metin": metin[:150]
                        })
            
            # Çok fazla haber olmasın, 5 ile sınırla
            if len(tum_haberler) > 20:
                break
                
        except Exception as e:
            print(f"Hata: {kaynak['url']} - {e}")
    
    return tum_haberler[:15]

def get_brasilia_durum():
    """Brasília'nın anlık durumu (örnek veri)"""
    hava_durumlari = ["🌞 Güneşli 28°C", "☁️ Parçalı bulutlu 26°C", "🌧️ Yağmurlu 22°C", "🌤️ Açık 30°C"]
    trafik_durumlari = ["🟢 Eixão rahat akıyor", "🟡 Eixão'da yoğunluk var", "🔴 Eixão durma noktasında"]
    guvenlik_durumlari = ["🟢 Normal seviyede", "🟡 Dikkatli olunması gereken bölgeler var", "🔴 Suç oranlarında artış"]
    
    return {
        "hava": random.choice(hava_durumlari),
        "trafik": random.choice(trafik_durumlari),
        "guvenlik": random.choice(guvenlik_durumlari)
    }

def send_telegram_mesaj(mesaj):
    """Telegram'a mesaj gönder"""
    token = os.environ.get("TELEGRAM_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")
    
    if token and chat_id:
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        try:
            payload = {
                "chat_id": chat_id,
                "text": mesaj,
                "parse_mode": "HTML"
            }
            requests.post(url, json=payload, timeout=10)
            print("✅ Telegram mesajı gönderildi")
        except Exception as e:
            print(f"Telegram hatası: {e}")

def main():
    print("🇧🇷 BRASÍLIA PANELİ BAŞLIYOR...")
    print(f"🕐 {datetime.now().strftime('%d.%m.%Y %H:%M:%S')}")
    
    # Haberleri topla
    print("📰 Haberler toplanıyor...")
    haberler = get_brasilia_news()
    print(f"✅ {len(haberler)} haber bulundu")
    
    # Bölge durumu
    durum = get_brasilia_durum()
    
    # JSON verisini oluştur
    data = {
        "son_guncelleme": datetime.now().strftime("%d.%m.%Y %H:%M:%S"),
        "haberler": haberler,
        "bairrolar": BAIRROS_BRASILIA,
        "durum": durum
    }
    
    # JSON dosyasına kaydet (GitHub sitesi için)
    with open("brasilia_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("✅ brasilia_data.json kaydedildi")
    
    # Telegram mesajı oluştur
    telegram_mesaj = f"""
🇧🇷 <b>BRASÍLIA BÖLGE PANELİ</b>
🕐 {datetime.now().strftime("%d.%m.%Y %H:%M")}

📰 <b>SON HABERLER:</b>
"""
    for haber in haberler[:5]:
        telegram_mesaj += f"\n📍 <b>{haber['bairro']}</b>\n{haber['baslik'][:80]}\n"
    
    telegram_mesaj += f"""
    
🌡️ <b>DURUM:</b>
{durum['hava']}
{durum['trafik']}
{durum['guvenlik']}

🔗 Detaylar: https://asalimc.github.io
"""
    
    # Telegram'a gönder
    send_telegram_mesaj(telegram_mesaj)
    
    print("✅ İşlem tamamlandı!")

if __name__ == "__main__":
    main()
