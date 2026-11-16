# gui

## `ber_gui.m` – BFSK BER deneyi

```matlab
>> ber_gui
```

Tek dosyadan oluşuyor, başka hiçbir dosyaya ihtiyaç duymuyor. İstediğin klasöre koyup çalıştırabilirsin. Bu hafta sadece BFSK var. QPSK ve 16-QAM sonradan eklenecek.

1. **Kaç bit gönderilsin?** Örneğin 1000 (en fazla 100 000).
2. **3 adet Eb/N0 (dB)**: Gürültü seviyesi. Büyük dB = az gürültü. Varsayılanlar 0, 4, 8.
3. **Gönder**

Her Eb/N0 için rastgele bitler şu zincirden geçer: BFSK verici → AWGN kanal → korelatör alıcı. Alıcının yanlış tahmin ettiği bitler sayılır.

| Çıktı | Ne gösteriyor |
|---|---|
| BER eğrisi | Çizgi teorik BER: $Q(\sqrt{E_b/N_0})$. Noktalar deneyde ölçülen değerler, üstlerinde "hatalı/gönderilen" yazar. Hiç hata çıkmazsa aşağı bakan üçgen konur. |
| Alıcı neden yanılıyor? | Karar değişkeni $d = z_1 - z_2$ için histogram. Gönderilen 1'ler mavi tepe olarak $+E_b$ civarında, 0'lar turuncu tepe olarak $-E_b$ civarında toplanır. Eşik 0'dır. Çizginin yanlış tarafına taşan bitler alıcının yanıldığı bitlerdir. |
| Tablo | Gönderilen bit, hatalı bit, ölçülen ve teorik BER. "Anlamı" sütunu sonucu "yaklaşık her 18 bitte 1 hata" gibi düz bir cümleyle yazar. |
| Hatalar nerede? | İlk 200 bit tek şeritte gösterilir: doğru tahmin yeşil, yanlış tahmin kırmızı. |

"Hangi deneye bakılsın?" menüsü, histogramın ve şeridin hangi Eb/N0 için çizileceğini seçer.

Verici, kanal ve alıcı `docs/bfsk/bfsk_adim_adim.m` ile aynıdır ($f_1 = 9$ Hz, $f_2 = 3$ Hz, $T_b = 1$ s, koherent korelatör). Fark sadece örnekleme frekansındadır: hız için $f_s = 100$ Hz kullanılır, 9 Hz'lik ton için bu yeterlidir.
