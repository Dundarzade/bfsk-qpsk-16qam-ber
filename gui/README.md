# gui

## `ber_gui.m` – BFSK BER deneyi

```matlab
>> ber_gui
```

Tek dosyadan oluşuyor, başka hiçbir dosyaya ihtiyaç duymuyor. İstediğin klasöre koyup çalıştırabilirsin. Bu hafta sadece BFSK var. QPSK ve 16-QAM sonradan eklenecek.

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
