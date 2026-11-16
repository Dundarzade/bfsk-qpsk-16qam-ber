%% BFSK: VERİCİDEN ALICIYA ADIM ADIM
% EE451 dönem projesi - BFSK modülasyonu, AWGN kanal ve korelasyon alıcısı
%
% Zincir:   bitler -> (1) BFSK verici -> (2) AWGN kanal -> (3-4) korelatör alıcı
%           -> (5) karar -> (6) sonuç
%
% Her bölüm (%%) tek başına çalıştırılabilir (Ctrl+Enter). Bölümler sırayla
% çalışmalı, çünkü her biri bir öncekinin değişkenlerini kullanır.
% Diyagram: docs/bfsk/bfsk_sistem.svg

clear; clc; close all;

%% 0) PARAMETRELER
Nbits   = 10;       % gönderilecek bit sayısı
Tb      = 1;        % bit süresi [s]
fs      = 1000;     % örnekleme frekansı [Hz] -> bir bitte fs*Tb = 1000 örnek
f1      = 9;        % bit 1'in frekansı [Hz] -> bir bitte 9 tam dalga
f2      = 3;        % bit 0'ın frekansı [Hz] -> bir bitte 3 tam dalga
EbN0_dB = 5;        % kanalın Eb/N0 değeri [dB]; küçüldükçe gürültü artar

% Ortogonallik şartı: (f1-f2)*Tb ve (f1+f2)*Tb tam sayı olmalı.
% 9 ve 3 Hz için bunlar 6 ve 12 -> iki ton bir bit boyunca birbirine "dik".
% Deneme: f2 = 3.3 yap ve 3. bölümdeki z2'ye bak; artık 0'a inmez.

% rng(1);           % yorumu kaldırırsan her çalıştırmada aynı bitler ve gürültü gelir
bits = randi([0 1], 1, Nbits);   % 10 adet rastgele bit, 0 ve 1 eşit olasılıklı

%% 1) VERİCİ: bitlerden BFSK sinyaline
% Her bit Tb süresince bir tonla gönderilir:
%     b = 1  ->  s(t) = cos(2*pi*f1*t)
%     b = 0  ->  s(t) = cos(2*pi*f2*t)          0 <= t < Tb
% Bilgi genlikte değil, FREKANSTA taşınır; genlik hep 1.

t_bit = 0:1/fs:Tb-1/fs;      % tek bir bitin zaman ekseni
N     = length(t_bit);       % bir bitteki örnek sayısı (1000)

c1 = cos(2*pi*f1*t_bit);     % f1 tonu: vericide bit 1 için, alıcıda 1. referans
c2 = cos(2*pi*f2*t_bit);     % f2 tonu: vericide bit 0 için, alıcıda 2. referans

s = zeros(1, Nbits*N);       % BFSK sinyali için yer ayır
for k = 1:Nbits
    idx = (k-1)*N + (1:N);   % k'ıncı bitin örnek indeksleri
    if bits(k) == 1
        s(idx) = c1;
    else
        s(idx) = c2;
    end
end

t = (0:length(s)-1)/fs;      % tüm sinyalin zaman ekseni (0 ... 10 s)

% Bitlerin kendi dalga şekilleri (sadece görselleştirme için)
b_unipolar = repelem(bits, N);    % 0 -> 0,  1 -> +1   (her bit N örnek boyunca)
b_polar    = 2*b_unipolar - 1;    % 0 -> -1, 1 -> +1   (ortalaması sıfır, DC yok)
t_stem     = (0:Nbits-1)*Tb + Tb/2;   % her bitin ortası

% ---- Figür 1: aynı bitlerin üç gösterimi ----
figure('Name', '1a - Bit gösterimleri');
ax = gobjects(3,1);

ax(1) = subplot(3,1,1);
stem(t_stem, bits, 'filled', 'LineWidth', 1.5);
for k = 1:Nbits
    text(t_stem(k), bits(k)+0.25, num2str(bits(k)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
ylim([-0.2 1.5]); grid on; ylabel('bit');
title('Ayrık bitler (her Tb için bir değer)');

ax(2) = subplot(3,1,2);
plot(t, b_unipolar, 'LineWidth', 2);
ylim([-1.5 1.5]); grid on; ylabel('genlik');
title('Unipolar NRZ (0 \rightarrow 0, 1 \rightarrow +1)');

ax(3) = subplot(3,1,3);
plot(t, b_polar, 'LineWidth', 2);
ylim([-1.5 1.5]); grid on; ylabel('genlik'); xlabel('t (s)');
title('Polar NRZ (0 \rightarrow -1, 1 \rightarrow +1)');

for i = 1:3                  % bit sınırları; HandleVisibility off -> legend'a girmez
    for k = 1:Nbits-1
        xline(ax(i), k*Tb, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nbits*Tb]);

% ---- Figür 2: BFSK sinyali ----
figure('Name', '1b - BFSK sinyali');
ax = gobjects(2,1);

ax(1) = subplot(2,1,1);
plot(t, s);
ylim([-1.5 1.5]); grid on; ylabel('genlik');
title(sprintf('BFSK sinyali (1 \\rightarrow %g Hz, 0 \\rightarrow %g Hz)', f1, f2));

ax(2) = subplot(2,1,2);
plot(t, b_polar, 'LineWidth', 2); hold on;
plot(t, s, 'r');
ylim([-1.5 1.5]); grid on; ylabel('genlik'); xlabel('t (s)');
title('Polar bitler ve BFSK sinyali üst üste');
legend('Polar bitler', 'BFSK', 'Location', 'eastoutside');

for i = 1:2
    for k = 1:Nbits-1
        xline(ax(i), k*Tb, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nbits*Tb]);

%% 2) KANAL: AWGN (toplamsal beyaz Gauss gürültü)
%     r(t) = s(t) + n(t)
% Gürültünün gücünü Eb/N0 ile ayarlıyoruz:
%     Eb = bir bitin enerjisi = integral_0^Tb cos^2(2*pi*f*t) dt = Tb/2
%     N0 = Eb / 10^(EbN0_dB/10)              (dB -> doğrusal)
% Sürekli zamanda gürültünün güç yoğunluğu N0/2. fs ile örneklenince her
% örneğin varyansı (N0/2)*fs olur -> std sapma sigma = sqrt(N0*fs/2).

Eb    = sum(c1.^2)/fs;        % sayısal integral -> 0.5 (= Tb/2)
N0    = Eb / 10^(EbN0_dB/10);
sigma = sqrt(N0*fs/2);        % örnek başına gürültü std sapması

n = sigma * randn(1, length(s));   % beyaz Gauss gürültü
r = s + n;                         % alıcıya ulaşan sinyal

figure('Name', '2 - Kanal');
subplot(2,1,1); plot(t, s);
grid on; ylabel('genlik'); title('Gönderilen s(t)');
subplot(2,1,2); plot(t, r);
grid on; ylabel('genlik'); xlabel('t (s)');
title(sprintf('Alınan r(t) = s(t) + n(t),   E_b/N_0 = %g dB', EbN0_dB));

%% 3) ALICI - tek bir biti yakından incele (korelatör nasıl çalışıyor?)
% Korelatör: alınan parça referansla çarpılır ve bir bit boyunca integre edilir
%     z1 = integral_0^Tb r(t)*c1(t) dt
%     z2 = integral_0^Tb r(t)*c2(t) dt
% Bit 1 gönderildiyse:  r*c1 = cos^2 + gürültü  -> hep pozitif -> z1 ~ Eb
%                       r*c2 = cos*cos(farklı) + gürültü -> +/- -> z2 ~ 0
% Bit 0 için roller yer değiştirir.

k_incele = 1;                        % incelenecek bit (1..Nbits), değiştirip dene
idx = (k_incele-1)*N + (1:N);
r_k = r(idx);                        % bu bitin alınan parçası

p1 = r_k .* c1;                      % çarpımlar
p2 = r_k .* c2;
int1 = cumsum(p1)/fs;                % 0'dan t'ye integral ("koşan" integral)
int2 = cumsum(p2)/fs;                % son değerleri = z1, z2

figure('Name', sprintf('3 - Korelatör, bit %d', k_incele));
subplot(3,1,1);
plot(t_bit, r_k); hold on;
plot(t_bit, c1, '--'); plot(t_bit, c2, ':');
legend('r(t)', 'c_1 (f_1)', 'c_2 (f_2)', 'Location', 'eastoutside');
title(sprintf('Bit %d (gönderilen = %d): alınan parça ve referanslar', ...
    k_incele, bits(k_incele)));
grid on;

subplot(3,1,2);
plot(t_bit, p1); hold on; plot(t_bit, p2);
yline(0, 'k-', 'HandleVisibility', 'off');
legend('r \cdot c_1', 'r \cdot c_2', 'Location', 'eastoutside');
title('Çarpımlar'); grid on;

subplot(3,1,3);
plot(t_bit, int1, 'LineWidth', 1.5); hold on;
plot(t_bit, int2, 'LineWidth', 1.5);
yline(Eb, 'k--', 'E_b', 'HandleVisibility', 'off');
legend('\int r c_1', '\int r c_2', 'Location', 'eastoutside');
title(sprintf('Koşan integral:  z_1 = %.3f,   z_2 = %.3f', int1(end), int2(end)));
xlabel('t (s)'); grid on;

%% 4) ALICI - bütün bitler için korelatör çıkışları
% 3. bölümdeki işlemin aynısı, her bit için tekrar. Burada sadece son
% değer lazım olduğu için cumsum yerine sum kullanıyoruz.

z1 = zeros(1, Nbits);
z2 = zeros(1, Nbits);
for k = 1:Nbits
    idx   = (k-1)*N + (1:N);         % k'ıncı bitin örnekleri
    r_k   = r(idx);
    z1(k) = sum(r_k .* c1)/fs;       % = integral r*c1 dt
    z2(k) = sum(r_k .* c2)/fs;       % = integral r*c2 dt
end

%% 5) KARAR
% Karar değişkeni d = z1 - z2
%     bit 1 ->  d = (Eb + n1) - n2  ~ +Eb
%     bit 0 ->  d = n1 - (Eb + n2)  ~ -Eb
% Eşik 0 (ortada). Gürültü farkı (n1 - n2) işareti çevirirse bit hatası olur.

d        = z1 - z2;
bits_hat = double(d > 0);            % d > 0 -> 1, d < 0 -> 0

%% 6) SONUÇ
hata_idx = find(bits_hat ~= bits);   % hatalı bitlerin indeksleri
hata     = numel(hata_idx);

fprintf('\nEb/N0 = %g dB,  Eb = %.3f,  N0 = %.4f\n\n', EbN0_dB, Eb, N0);
fprintf(' bit | gönderilen |    z1    |    z2    |  d=z1-z2 | karar\n');
fprintf('-----+------------+----------+----------+----------+------\n');
for k = 1:Nbits
    isaret = ' ';   % boş bırakma: fprintf boş argümanı atlar, satır sonu kaybolur
    if bits_hat(k) ~= bits(k), isaret = '  <- HATA'; end
    fprintf(' %3d |     %d      | %8.3f | %8.3f | %8.3f |   %d%s\n', ...
        k, bits(k), z1(k), z2(k), d(k), bits_hat(k), isaret);
end
fprintf('\nHatalı bit: %d / %d\n', hata, Nbits);

figure('Name', '6 - Sonuç');
subplot(2,1,1);
stem(1:Nbits, bits, 'filled', 'LineWidth', 1.5); hold on;
stem(1:Nbits, bits_hat, 'r--');
ylim([-0.2 1.3]); grid on; xlim([0.5 Nbits+0.5]);
ylabel('bit'); legend('Gönderilen', 'Tahmin', 'Location', 'eastoutside');
title(sprintf('Gönderilen ve tahmin edilen bitler: %d hata', hata));

subplot(2,1,2);
stem(1:Nbits, d, 'filled', 'LineWidth', 1.5); hold on;
if hata > 0                          % hatalı bitleri kırmızı daire ile işaretle
    plot(hata_idx, d(hata_idx), 'ro', 'MarkerSize', 12, 'LineWidth', 1.5);
end
yline(0, 'r-', 'eşik', 'HandleVisibility', 'off');
yline( Eb, 'k:', '+E_b', 'HandleVisibility', 'off');
yline(-Eb, 'k:', '-E_b', 'HandleVisibility', 'off');
xlim([0.5 Nbits+0.5]); grid on;
xlabel('bit no'); ylabel('d = z_1 - z_2');
title('Karar değişkeni (pozitif \rightarrow 1, negatif \rightarrow 0)');

% Sonraki adım: EbN0_dB'yi bir vektör yapıp (ör. 0:1:10) her değer için
% çok sayıda bitle hata oranını ölçmek -> BER eğrisi, teoriyle karşılaştırma
%     koherent BFSK:  Pb = Q(sqrt(Eb/N0)) = 0.5*erfc(sqrt(Eb/N0)/sqrt(2))
