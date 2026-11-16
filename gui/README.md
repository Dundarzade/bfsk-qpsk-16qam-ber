# gui

## `qam16_gui.m` – 16-QAM BER deneyi

Proje kökünde `start_qam16` çalıştır veya bu klasörde `qam16_gui` yaz. `../src/` içindeki ortak modülatör, alıcı, teori ve gerçek taşıyıcılı deney fonksiyonlarını kullanır; klasör yapısını koru.

- 40 000 bit, üç Eb/N0 seviyesi: 0, 6 ve 12 dB. Bit sayısı 4'ün katı olmalı.
- BER teorisi ve ölçüm; alınan semboller ve Gray karar eşikleri; BER/SER tablosu; ilk 200 bitin hata şeridi.
- İkinci sekme: I/Q seviye dağılımları, ilk dört sembolün verici ve kanal dalgası.
- Her dB'de aynı bitler ve ortak standart gürültü örnekleri kullanılır. Tohumu değiştirerek farklı deney yapabilirsin.
- Sıfır hata durumunda kesin BER=0 iddiası yapılmaz; bağımsız semboller üzerinden hesaplanan temkinli %95 üst sınır gösterilir.

Varsayılan sinyal: Ts=1 s, fs=100 Hz, fc=4 Hz. Bu, ideal senkronlu bir simülasyondur. `fs*Ts` 8–100 000 arasında tam sayı, `fc*Ts` pozitif tam sayı ve `fs>2*fc` olmalı. Bellek bloklarla sınırlanır; arayüz işlem süresi için toplam örnek sayısını 20 milyonla sınırlar.

[Teknik anlatım ve çalıştırma](../docs/qam16/README.md) · [Sonuç grafikleri](../results/qam16/README.md)

```matlab
% Tekrarlanabilir otomatik deney ve ekran çıktısı:
f = qam16_gui(struct('Visible','off','AutoRun',true, ...
    'ExportDir',fullfile(pwd,'..','results','qam16')));
data = getappdata(f,'QAM16Results');
close(f)
```

## `ber_gui.m` – BFSK BER deneyi

```matlab
>> ber_gui
```

Bu dosya tek başına BFSK çalıştırır; başka dosyaya ihtiyaç duymaz. 16-QAM için yukarıdaki `qam16_gui.m`, QPSK için adım adım script kullanılabilir.

1. **Kaç bit gönderilsin?** Örneğin 1000 (en fazla 100 000).
2. **3 adet Eb/N0 (dB)**: Gürültü seviyesi. Büyük dB = az gürültü. Varsayılanlar 0, 4, 8.
3. **Sinyal ayarları**: Tb (bit süresi, varsayılan 1 s) ve fs (örnekleme frekansı, varsayılan 100 Hz). Altındaki satır, bir bitte kaç örnek olduğunu ve tonların ortogonal olup olmadığını gösterir.
4. **Gönder**

Her Eb/N0 için rastgele bitler şu zincirden geçer: BFSK verici → AWGN kanal → korelatör alıcı. Alıcının yanlış tahmin ettiği bitler sayılır.

| Çıktı | Ne gösteriyor |
|---|---|
| BER eğrisi | Çizgi teorik BER: $Q(\sqrt{E_b/N_0})$. Noktalar deneyde ölçülen değerler, üstlerinde "hatalı/gönderilen" yazar. Hiç hata çıkmazsa aşağı bakan üçgen konur. |
| Alıcı neden yanılıyor? | Karar değişkeni $d = z_1 - z_2$ için histogram. Doğru çözülen 1'ler mavi renkte $+E_b$ civarında, doğru çözülen 0'lar turuncu renkte $-E_b$ civarında toplanır. Eşiğin (0) yanlış tarafına düşen bitler **kırmızı** gösterilir: bunlar alıcının yanıldığı bitlerdir. |
| Tablo | Gönderilen bit, hatalı bit, ölçülen ve teorik BER. "Anlamı" sütunu sonucu "yaklaşık her 18 bitte 1 hata" gibi düz bir cümleyle yazar. |
| Hatalar nerede? | İlk 200 bit tek şeritte gösterilir: doğru tahmin yeşil, yanlış tahmin kırmızı. |

"Hangi deneye bakılsın?" menüsü, histogramın ve şeridin hangi Eb/N0 için çizileceğini seçer.

Verici, kanal ve alıcı `docs/bfsk/bfsk_adim_adim.m` ile aynıdır ($f_1 = 9$ Hz, $f_2 = 3$ Hz, koherent korelatör). Varsayılan $f_s = 100$ Hz, script'teki 1000 Hz'den düşüktür. Bu hem hız sağlar hem de 9 Hz'lik ton için yeterlidir.

**Tb ve fs ile deney:** Tb veya fs değişince BER değişmez, çünkü sonucu belirleyen Eb/N0 oranıdır. Örneğin Tb = 0.5 s ya da fs = 40 Hz seçilince noktalar yine teori eğrisinin üstüne düşer. İstisna, $(f_1 \pm f_2)T_b$ değerinin tam sayı olmadığı durumdur: o zaman iki ton ortogonal olmaz ve uyarıda benzerlik katsayısı $\rho$ gösterilir. Bu durumda teori eğrisi tam geçerli değildir. Örneğin Tb = 0.25 s'de BER teoriden biraz kötü çıkar.
