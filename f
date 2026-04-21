<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>KAHVE TİCARETİ | AKILLI TERMİNAL</title>
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;900&display=swap" rel="stylesheet">
    <style>
        :root { --navy: #001f3f; --white: #ffffff; --blue: #00d4ff; --border: 4px solid #001f3f; }
        * { box-sizing: border-box; font-family: 'Sora', sans-serif; -webkit-tap-highlight-color: transparent; }
        body { background-color: var(--white); margin: 0; padding: 10px; color: var(--navy); width: 100%; min-height: 100vh; }
        .header { background: var(--navy); color: white; padding: 15px; border-radius: 12px; margin-bottom: 15px; text-align: center; box-shadow: 0 4px 0px var(--blue); }
        .header h1 { font-size: 16px; margin: 0 0 10px 0; font-weight: 900; }
        .kur-bar { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .kur-item { background: white; border: var(--border); padding: 8px; border-radius: 10px; }
        .kur-item label { font-size: 9px; font-weight: 900; color: var(--navy); display: block; text-transform: uppercase; }
        .kur-item input { width: 100%; border: none; font-size: 18px; font-weight: 900; color: #d35400; outline: none; background: transparent; }
        .main-grid { display: flex; flex-direction: column; gap: 20px; margin-top: 15px; }
        .card { background: var(--white); border: var(--border); border-radius: 20px; padding: 15px; box-shadow: 8px 8px 0px var(--navy); position: relative; }
        h2 { font-size: 15px; font-weight: 900; margin: 0 0 12px 0; border-bottom: 4px solid var(--navy); padding-bottom: 4px; }
        .input-row { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; margin-bottom: 15px; }
        .input-group label { font-size: 8px; font-weight: 900; display: block; margin-bottom: 4px; }
        .input-group input { width: 100%; padding: 12px; border: 2px solid var(--navy); border-radius: 8px; font-size: 16px; font-weight: 900; }
        .profit-input { background: #ecfdf5 !important; border-color: #059669 !important; }
        .ton-input { background: #f0faff !important; border-color: var(--blue) !important; }
        .summary-box { background: #f8fafc; padding: 12px; border-radius: 12px; border: 2px solid var(--navy); margin-bottom: 12px; }
        .line { display: flex; justify-content: space-between; margin-bottom: 5px; border-bottom: 1px dashed #cbd5e1; font-size: 11px; }
        .line b { font-weight: 900; }
        .price-row { padding: 10px; border-radius: 10px; display: flex; justify-content: space-between; align-items: center; background: var(--navy); color: white; margin-bottom: 6px; }
        .p-val { font-size: 18px; font-weight: 900; color: var(--blue); }
        .profit-final { background: #059669; }
        #notif-btn { background: #ff4757; color: white; border: none; padding: 5px 10px; border-radius: 5px; font-weight: 900; font-size: 10px; margin-top: 10px; cursor: pointer; }
    </style>
</head>
<body>

<div class="container">
    <header class="header">
        <h1>KAHVE TİCARETİ | MOBİL AKILLI TERMİNAL</h1>
        <div class="kur-bar">
            <div class="kur-item"><label>USD / TRY</label><input type="number" inputmode="decimal" id="uTry" value="34.35" oninput="saveAndCalc()"></div>
            <div class="kur-item"><label>USD / BRL</label><input type="number" inputmode="decimal" id="uBrl" value="5.85" oninput="saveAndCalc()"></div>
        </div>
        <button id="notif-btn" onclick="requestNotif()">BİLDİRİMLERİ VE TİTREŞİMİ AÇ</button>
    </header>
    <div class="main-grid" id="mainGrid"></div>
</div>

<script>
    const STATS = { gumruk: 0.08, igv: 0.05, kdv: 0.10, navlun: 350, sigorta: 0.015, limanMasraf: 150 };
    const PRODUCTS = [
        { id: 'ara', name: 'ARABICA RIO MINAS', brl: 1191, kar: 30 },
        { id: 'rob', name: 'ROBUSTA CONILON', brl: 886, kar: 5 },
        { id: 'san', name: 'ARABICA SANTOS NY2', brl: 1250, kar: 15 },
        { id: 'bou', name: 'ARABICA BOURBON', brl: 1420, kar: 10 }
    ];

    let lastKnownPrice = 0;

    // Bildirim ve Titreşim İzni
    function requestNotif() {
        Notification.requestPermission().then(permission => {
            if (permission === "granted") {
                alert("Bildirimler aktif! Fiyat değişiminde telefonunuz titreyecek.");
                document.getElementById('notif-btn').style.display = 'none';
            }
        });
    }

    function triggerAlert(msg) {
        if (Notification.permission === "granted") {
            new Notification("Fiyat Güncellemesi", { body: msg, icon: "https://cdn-icons-png.flaticon.com/512/2933/2933932.png" });
            if ("vibrate" in navigator) {
                navigator.vibrate([200, 100, 200]); // Titreşim efekti
            }
        }
    }

    function saveAndCalc() {
        localStorage.setItem('uTry', document.getElementById('uTry').value);
        localStorage.setItem('uBrl', document.getElementById('uBrl').value);
        calc();
    }

    async function checkMarket() {
        try {
            const res = await fetch('https://open.er-api.com/v6/latest/USD');
            const data = await res.json();
            if(data && data.rates) {
                const newTry = data.rates.TRY;
                const oldTry = parseFloat(localStorage.getItem('uTry')) || 0;

                // Eğer kur %0.1'den fazla değişmişse haber ver
                if (Math.abs(newTry - oldTry) > 0.05) {
                    triggerAlert(`Kur Değişti! Yeni USD/TRY: ${newTry.toFixed(2)}`);
                }

                document.getElementById('uTry').value = newTry.toFixed(2);
                document.getElementById('uBrl').value = data.rates.BRL.toFixed(2);
                saveAndCalc();
            }
        } catch (e) { console.log("Offline mod"); }
    }

    function createCards() {
        const grid = document.getElementById('mainGrid');
        PRODUCTS.forEach(p => {
            grid.innerHTML += `
                <div class="card">
                    <h2>${p.name}</h2>
                    <div class="input-row">
                        <div class="input-group"><label>BRL/60KG</label><input type="number" inputmode="decimal" id="${p.id}In" value="${p.brl}" oninput="calc()"></div>
                        <div class="input-group"><label>TON</label><input type="number" inputmode="decimal" id="${p.id}Ton" value="1" class="ton-input" oninput="calc()"></div>
                        <div class="input-group"><label>KÂR %</label><input type="number" inputmode="decimal" id="${p.id}Kar" value="${p.kar}" class="profit-input" oninput="calc()"></div>
                    </div>
                    <div class="summary-box" id="${p.id}Summary"></div>
                    <div class="price-row"><span>SATIŞ:</span><span class="p-val" id="${p.id}FinalTl">0 ₺</span></div>
                    <div class="price-row profit-final"><span>KÂR:</span><span class="p-val" id="${p.id}NetProfit" style="color:#afffd0">0 ₺</span></div>
                </div>
            `;
        });
        
        if(localStorage.getItem('uTry')) {
            document.getElementById('uTry').value = localStorage.getItem('uTry');
            document.getElementById('uBrl').value = localStorage.getItem('uBrl');
        }

        checkMarket();
        setInterval(checkMarket, 600000); // Her 10 dakikada bir kapalıyken (sekme açıksa) kontrol et
        calc();
    }

    function calc() {
        const tryKur = parseFloat(document.getElementById('uTry').value) || 0;
        const brlKur = parseFloat(document.getElementById('uBrl').value) || 0;

        PRODUCTS.forEach(p => {
            const brlPrice = parseFloat(document.getElementById(p.id + 'In').value) || 0;
            const tonMiktar = parseFloat(document.getElementById(p.id + 'Ton').value) || 0;
            const karOrani = parseFloat(document.getElementById(p.id + 'Kar').value) || 0;
            
            let tonBrlVal = (brlPrice / 60) * 1000;
            let fobUsd = (tonBrlVal / brlKur) + STATS.limanMasraf;
            let cifUsd = (fobUsd + STATS.navlun) * (1 + STATS.sigorta);
            let ddpTry = cifUsd * (1 + STATS.gumruk) * (1 + STATS.igv) * (1 + STATS.kdv) * tryKur;
            
            let kgMaliyet = ddpTry / 1000;
            let kgSatis = kgMaliyet * (1 + (karOrani / 100));
            let toplamSatis = kgSatis * 1000 * tonMiktar;
            let netKar = toplamSatis - (ddpTry * tonMiktar);

            document.getElementById(p.id+'Summary').innerHTML = `
                <div class="line">DDP Maliyet (Ton): <b>${Math.round(ddpTry).toLocaleString()} ₺</b></div>
                <div class="line">KG Maliyet: <b>${kgMaliyet.toFixed(2)} ₺</b></div>
                <div class="line">KG Satış: <b>${kgSatis.toFixed(2)} ₺</b></div>
            `;
            document.getElementById(p.id+'FinalTl').innerText = Math.round(toplamSatis).toLocaleString() + " ₺";
            document.getElementById(p.id+'NetProfit').innerText = Math.round(netKar).toLocaleString() + " ₺";
        });
    }

    window.onload = createCards;
</script>
</body>
</html>
