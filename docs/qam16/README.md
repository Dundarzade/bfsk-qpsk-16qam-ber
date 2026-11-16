# 16-QAM (16-Quadrature Amplitude Modulation)

Dört biti aynı anda gönderir: iki bit I ekseninin **seviyesini**, iki bit Q ekseninin seviyesini seçer. k = 4, M = 16.

| Dosya | İçerik |
|---|---|
| `qam16_verici.svg` / `.png` | Verici: S/P, her eksende Gray 4-PAM, cos / −sin taşıyıcılar |
| `qam16_alici.svg` / `.png` | Alıcı: iki korelatör, her kolda 4 seviyeli dilimleyici |
| `qam16_tam_sistem.svg` / `.png` | Verici + kanal + alıcı tek şekilde |

Gray etiketli yıldız diyagramı: [`../genel/constellations_gray.svg`](../genel/constellations_gray.svg)

## 1. Verici

![16-QAM vericisi](qam16_verici.svg)

Bitler dörder gruplanır, $[b_1\ b_2\ b_3\ b_4]$. Her eksen Gray kodlu bir 4-PAM'dir:

```math
G(00) = -3,\quad G(01) = -1,\quad G(11) = +1,\quad G(10) = +3
```

```math
a_I = \frac{G(b_1 b_2)}{\sqrt{10}}, \qquad a_Q = \frac{G(b_3 b_4)}{\sqrt{10}}
```

Neden $\sqrt{10}$? Ham seviyelerin ortalama karesi $\mathbb{E}[I^2] = (1 + 9)/2 = 5$, iki eksen $5 + 5 = 10$. Bölünce $E_s = 1$, $E_b = E_s/4$.

Örnek: `1011` → $I = G(10) = +3$, $Q = G(11) = +1$ → $(3 + j)/\sqrt{10}$.

Bir sembol süresi $T_s = 4T_b$ boyunca:

```math
s(t) = a_I\cos(2\pi f_c t) - a_Q\sin(2\pi f_c t)
```

## 2. Kanal

```math
r(t) = s(t) + n(t)
```

## 3. Alıcı – iki korelatör

![16-QAM alıcısı](qam16_alici.svg)

Korelatörler QPSK ile aynıdır:

```math
z_I = a_I + n_I, \qquad z_Q = a_Q + n_Q \qquad (\text{temel bantta } \mathrm{Re}\{r\},\ \mathrm{Im}\{r\})
```

## 4. Karar – 4 seviyeli dilimleyici

Ölçeği geri al: $x = \sqrt{10}\,z_I$ (Q kolu için $\sqrt{10}\,z_Q$). $x$ gürültüsüz olsa $\{-3, -1, +1, +3\}$'ten biri olurdu. En yakın seviyeyi seçmek = eşikler $-2,\ 0,\ +2$:

```math
\text{1. bit} = \begin{cases}1, & x > 0\\ 0, & x \le 0\end{cases}, \qquad
\text{2. bit} = \begin{cases}1, & \lvert x\rvert < 2\\ 0, & \lvert x\rvert \ge 2\end{cases}
```

I kolu $b_1 b_2$'yi, Q kolu $b_3 b_4$'ü verir (kodda `pam4_slice`). AWGN'de ve eşit olasılıklı sembollerde bu ML karardır.

## 5. BER

Gray kodlu kare 16-QAM için tam ifade:

```math
P_b = \frac14\Big[3Q(u) + 2Q(3u) - Q(5u)\Big], \qquad u = \sqrt{\frac{4E_b}{5N_0}}
```

Yüksek $E_b/N_0$'da $P_b \approx \tfrac34 Q(u)$. QPSK'daki $\sqrt{2E_b/N_0}$ ile karşılaştırınca: aynı BER için yaklaşık **4 dB** ($10\log_{10} 2.5$) daha fazla $E_b/N_0$ gerekir, karşılığında sembol başına **2 kat** bit taşınır.

## Kodda

| Adım | Fonksiyon |
|---|---|
| Verici | `src/qam16_mod.m` |
| Kanal | `src/awgn_channel.m` |
| Alıcı + karar | `src/qam16_demod.m` (`pam4_slice`) |
| Teori | `ber_theory('qam16', EbN0_dB)` |
