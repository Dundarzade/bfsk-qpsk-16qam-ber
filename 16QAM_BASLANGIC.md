# 16-QAM bölümünü çalıştırma

**16-QAM katkısı: Emir Dündar ([@Dundarzade](https://github.com/Dundarzade)).**

ZIP'i bir klasöre aç, MATLAB'de bu klasörü Current Folder yap ve şunu yaz:

```matlab
start_qam16
```

40 000 bit ve 0/6/12 dB ile **Gönder** düğmesine bas. BER, alınan 16-QAM noktaları, hata sayıları ve bit şeridi görünür. **Hangi deneye bakılsın?** menüsüyle gürültü düzeyini değiştir. **I/Q ve dalga** sekmesi genlik seviyelerini ve gerçek taşıyıcı sinyali gösterir.

Communications Toolbox gerekmez. Arayüz, `src/` içindeki ortak modülatör/çözücü ve deney fonksiyonlarını kullanır; klasörleri birlikte tut.

## Konuyu anlatmak için

- [Teknik anlatım ve sistem şemaları](docs/qam16/README.md)
- [2–3 dakikalık sunum ve hoca soruları](docs/qam16/sunum_notlari.md)
- [Ölçülen simülasyon sonuçları ve grafikler](results/qam16/README.md)
- `docs/qam16/qam16_adim_adim.m`: üç sembolü adım adım incelemek için.

Her dört bit bir I/Q noktası seçer. Örneğin `1011`, `(3+j)/sqrt(10)` noktasını verir. Alıcı, cos ve −sin korelatörleriyle I/Q'yu geri bulur; her eksende −3, −1, +1, +3 seviyelerinden en yakınını seçer. Gray etiketleri en yakın komşu hatalarının bit etkisini azaltır.

## Doğrulama

```matlab
addpath('src','gui')
test_mod_demod
test_qam16
test_qam16_gui
run_qam16_analysis
```

MATLAB R2026b Prerelease Update 1'de mevcut temel testler, 16-QAM fiziksel/sayısal testleri ve gerçek arayüz callback testleri geçti. Hatalı bit sayısı ve taşıyıcı ayarından toparlanma, deney seçimi ve sıfır hata üst sınırı kontrol edildi. Koyu/açık tema ve I/Q sekmesi görüntüleri `results/qam16/` altındadır.

0:2:14 dB taramasında her noktada 2 milyon bit gönderildi. 12 dB'de 279 hata / 2 milyon bit = 0.0001395; tam teori 0.0001387. 14 dB'de yalnız üç hata var; hassas sonuç sayılmaz. Bu ideal senkronlu simülasyondur; ESP32 donanım ölçümü yapılmış değildir.
