# 16-QAM sunum notları

## 2–3 dakikalık anlatım

**0:00–0:25 — Amaç ve yıldız diyagramı.** “16-QAM'de her dört bit bir sembolü seçer. İlk iki bit I, son iki bit Q seviyesini belirler. İki eksende dörder seviye olduğu için 16 nokta vardır. Bu sayede sembol başına QPSK'nin iki katı bit taşırız.” Sistem diyagramını veya arayüzdeki ideal noktaları göster.

**0:25–0:55 — Tek bir örnek.** “`1011` için I çifti `10` → +3, Q çifti `11` → +1. Normalleştirilmiş noktamız $(3+j)/\sqrt{10}$; genliği 1, fazı yaklaşık 18,4 derecedir. Verici bu katsayılarla cos ve −sin taşıyıcılarını toplar. Analog dalganın genliği ve fazı değişir.” 16 noktanın her birinin ayrı genlikte olmadığını, üç genlik yarıçapı bulunduğunu söyle.

**0:55–1:25 — Kanal ve alıcı.** “AWGN kanalı sinyale Gauss gürültüsü ekler. Alıcı, her sembol boyunca cos ve −sin ile korelasyon yaparak I ve Q'yu geri bulur. Her eksende en yakın dört seviyeden birini seçeriz; ham eşikler −2, 0 ve +2'dir. Gray kod sayesinde yatay ve düşey komşular yalnız bir bitte farklıdır.”

**1:25–2:05 — Canlı gösterim.** `start_qam16` ile aynı bit sayısında 0, 6 ve 12 dB'yi karşılaştır. “Gürültü azaldıkça bulut daralır; karar sınırını geçen noktalar hata üretir.” Hatalı noktaları, tablodaki hata sayısını ve bit hata şeridini göster. BER'i **hatalı bit / toplam bit** biçiminde oku. Hatasız görünen koşuda “Bu koşuda hata gözlemedik” de.

**2:05–2:40 — Sonuç ve sınır.** BER grafiğinde simülasyonla teoriyi karşılaştır. “Aynı bit hızında sembol hızını QPSK'ye göre yarıya indiriyoruz. Bunun bedeli daha yüksek $E_b/N_0$ gereksinimi: teoride BER $10^{-3}$ için yaklaşık 3,7 dB fark var. Burada faz ve zamanlama ideal biliniyor. ESP32 kısmı henüz plandır; genlik kalibrasyonu ve senkronizasyon donanımda ayrıca kurulmalıdır.”

Gösterimden önce `addpath('src'); run_qam16_analysis` çalıştır. Görseller ve sayısal sonuçlar [`../../results/qam16/`](../../results/qam16/) altındadır; sunumda ölçüm sayısını [`qam16_ber.csv`](../../results/qam16/qam16_ber.csv) dosyasından al. Üretilmemiş veya incelenmemiş bir sonucu tamamlanmış ölçüm gibi anlatma.

## Kod blokları ne yapıyor?

Öğretici [`qam16_adim_adim.m`](qam16_adim_adim.m), üç sembolü ayrıntılı görmek içindir. 12 bit, sağlam bir BER tahmini için yeterli değildir. Arayüzün deneyi [`qam16_experiment.m`](../../src/qam16_experiment.m), ortak [`qam16_mod.m`](../../src/qam16_mod.m) ve [`qam16_demod.m`](../../src/qam16_demod.m) işlevlerini kullanır.

### 1. Dörder gruplama ve Gray eşleme

```matlab
bp = reshape(bits, 4, []);
lut = [-3 -1 3 1];
I_raw = lut(2*bp(1,:) + bp(2,:) + 1);
Q_raw = lut(2*bp(3,:) + bp(4,:) + 1);
```

Her sütun bir semboldür. İndeksin sırası `00, 01, 10, 11` olduğu için LUT `[-3 -1 3 1]` yazılır. Seviyeleri soldan sağa sıraladığımızda Gray etiketleri `00, 01, 11, 10` olur. I ve Q'yu $\sqrt{10}$'a bölmek ortalama karmaşık sembol enerjisini 1 yapar.

### 2. Gerçek taşıyıcı ve gürültü

```matlab
s = aI*cos(2*pi*fc*t) - aQ*sin(2*pi*fc*t);
Es = Ts/2;
Eb = Es/4;
N0 = Eb/10^(EbN0_dB/10);
sigma = sqrt(N0*fs/2);
r = s + sigma*randn(size(s));
```

Bu blok tek sembolün taşıyıcı modelini özetler. Karmaşık sembollerde $\mathbb{E}|a|^2=1$ olması, buradaki fiziksel dalganın $E_s=1$ olduğu anlamına gelmez: cos/sin enerjisi nedeniyle ortalama $E_s=T_s/2$'dir. `sigma`, gerçek taşıyıcı örneğinin gürültü standart sapmasıdır; varyansı `N0*fs/2` olur.

### 3. Korelatör ve karar

```matlab
zI = (2/Ts)*sum(r_m.*cI)/fs;
zQ = (2/Ts)*sum(r_m.*cQ)/fs;
xI = sqrt(10)*zI;
xQ = sqrt(10)*zQ;
b_hat = [xI > 0; abs(xI) < 2; xQ > 0; abs(xQ) < 2];
```

`sum(...)/fs` integrali yaklaşıklar. `2/Ts` taşıyıcı enerjisini giderir; `sqrt(10)` ham 4-PAM seviyelerine döndürür. Birinci bit işaretten, ikinci bit iç/dış seviyeden çıkar. Q kolu aynı işlemi diğer iki bit için yapar. Bunlar ideal faz ve sembol sınırları bilindiğinde geçerlidir.

### 4. Hata sayımı

```matlab
BER = sum(bits_hat ~= bits)/numel(bits);
symbolErrors = any(reshape(bits_hat ~= bits, 4, []), 1);
SER = mean(symbolErrors);
```

BER bitleri, SER sembolleri sayar. Bir sembolde üç bit yanlışsa BER payına 3, SER payına 1 eklenir. İki vektörün aynı yönde/sırada olması gerekir; öğretici script satır, ortak modem işlevleri sütun vektörü kullanır.

## Hocanın sorabileceği sorular

| Soru | Kısa cevap |
|---|---|
| Neden $\sqrt{10}$? | Her ham eksenin ortalama karesi 5; I ve Q toplamı 10. Genliği $\sqrt{10}$'a bölünce ortalama karesel büyüklük 1 olur. Her noktanın enerjisi aynı değildir. |
| 16 ayrı genlik mi var? | Hayır. I ve Q'nun 4×4 birleşimi 16 nokta oluşturur; üç farklı yarıçap farklı fazlarla birleşir. |
| Neden Q kolunda −sin var? | $\operatorname{Re}\{(a_I+ja_Q)e^{j2\pi f_ct}\}=a_I\cos-a_Q\sin$. Alıcı da aynı işareti kullanır. |
| Gray kod gürültüyü azaltıyor mu? | Gürültüyü veya nokta uzaklığını değiştirmez. En yakın komşuya yapılan bir sembol hatasının genellikle tek bit hatası olmasını sağlar. Düşük SNR'de daha uzak noktalara da hata olur. |
| BER, SER/4 mü? | Genel olarak hayır. Bir sembol hatası 1–4 bit hatası getirebilir. Yüksek SNR ve Gray eşlemede tek bitli komşu hataları baskınsa BER ≈ SER/4 yaklaşır. |
| Tam BER formülü hangisi? | $u=\sqrt{0{,}8E_b/N_0}$ için $[3Q(u)+2Q(3u)-Q(5u)]/4$. $0{,}75Q(u)$ yalnız yüksek SNR yaklaşımıdır. |
| Niye gürültü varyansında $F_s/2$ var? | Gerçek AWGN'nin iki taraflı yoğunluğu $N_0/2$'dir. Örnek varyansı $N_0F_s/2$; alıcıdaki $1/F_s$ integrasyon ölçeği örnekleme hızının etkisini dengeler. |
| $E_s=1$ iken kodda neden 0,5? | 1, karmaşık sembollerin ortalama karesel büyüklüğüdür. Kullanılan gerçek cos/sin taşıyıcılarıyla dalga enerjisi $T_s/2$ olur; $T_s=1$ için 0,5. |
| $f_cT_s$ neden tam sayı? | Bu deney her sembolde tam taşıyıcı periyotları kullanarak örneklenmiş cos ve −sin'in dikliğini sağlar. $F_sT_s$ de tam sayı olmalıdır. |
| Faz veya zamanlama kayarsa? | I/Q noktaları dönebilir veya komşu semboller karışabilir; sabit eşikler hatalı karar verebilir. Bu deneyde taşıyıcı ve zamanlama ideal biliniyor; geri kazanım algoritması yok. |
| QPSK'den kazancı ne? | 16-QAM 4, QPSK 2 bit/sembol taşır; aynı bit hızında 16-QAM'in sembol hızı yarıya iner. Aynı darbe şekillendirmeyle bant daralır; aynı BER için daha yüksek $E_b/N_0$ gerekir. |
| Fark her zaman 4 dB mi? | Hayır. Teorik BER $10^{-3}$ için yaklaşık 6,8 ve 10,5 dB, yani yaklaşık 3,7 dB. Fark hedef BER'e bağlıdır. |
| 12 dB'de sıfır hata gördük; BER sıfır mı? | Yalnız bu bit dizisinde hata gözlenmedi. Gerçek hata olasılığının sıfır olduğu kanıtlanmadı; daha uzun koşu gerekir. Bağımsız $N_s$ sembolde sıfır hata için %95 SER üst sınırı $1-0{,}05^{1/N_s}$; BER ≤ SER olduğu için bu ihtiyatlı BER sınırı olarak da kullanılabilir. |
| ESP32 üzerinde de ölçtünüz mü? | Henüz hayır; donanım taslak plan. Genlik/DC kalibrasyonu, faz/zamanlama ve ADC örnekleme yolu ayrıca doğrulanmalı. Klasik ESP32, IDF v5.5.1 continuous ADC için 20 kHz alt sınırı nedeniyle 8 kHz planı doğrudan uygulanmış sayılmaz. |

Formüllerin koşulları ve resmi kaynaklar [teknik README'de](README.md) açıklanır: [MathWorks analitik BER](https://www.mathworks.com/help/comm/ug/analytical-expressions-used-in-berawgn-function-and-bit-error-rate-analysis-app.html), [MathWorks AWGN ölçekleri](https://www.mathworks.com/help/comm/ref/awgnchannel.html), [Espressif ESP32 IDF v5.5.1 ADC sınırı](https://github.com/espressif/esp-idf/blob/v5.5.1/components/soc/esp32/include/soc/soc_caps.h).
