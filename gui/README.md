# gui

## `ber_gui.m` – basit BER deneyi

```matlab
>> cd gui
>> ber_gui
```

Konuyu bilmeyen birinin de anlayabileceği kadar basit tutuldu:

1. **Modülasyon seç**: BFSK, QPSK, 16-QAM (bir veya hepsi)
2. **Kaç bit gönderilsin?**: örn. 1000
3. **3 adet Eb/N0 (dB)**: gürültü seviyesi, büyük dB = az gürültü (varsayılan 0, 4, 8)
4. **Gönder**

Her modülasyon ve her Eb/N0 için rastgele bitler gönderilir. Alıcının yanlış tahmin ettiği bitler sayılır.

| Çıktı | Ne gösteriyor |
|---|---|
| BER grafiği | Çizgi = teorik BER, nokta = deneyde ölçülen. 0 hata çıkarsa aşağı üçgen konur, çünkü log eksende 0 çizilemez. |
| Tablo | Gönderilen bit, hatalı bit, ölçülen ve teorik BER. "Anlamı" sütunu sonucu "yaklaşık her 43 bitte 1 hata" gibi düz cümleyle yazar. |
| Hatalar nerede? | İlk 200 bit tek şeritte: doğru tahmin yeşil, yanlış tahmin kırmızı. Açılır menüden hangi modülasyonun hangi Eb/N0'daki denemesine bakılacağı seçilir. |

Hesap `src/` içindeki fonksiyonlarla yapılır (`scheme_handles`, `awgn_channel`, `ber_theory`), yani GUI ve `ber_sim` aynı modülatör ve demodülatörü kullanır. BFSK alıcısı non-koherenttir, teorisi $P_b = \tfrac12 e^{-E_b/2N_0}$.

16-QAM'de bit sayısı 4'ün katına yuvarlanır, örneğin 1000 bit girilirse 1000 gönderilir, 1001 girilirse 1004.
