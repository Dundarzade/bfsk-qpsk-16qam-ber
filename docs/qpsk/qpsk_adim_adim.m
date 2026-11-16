%% QPSK: VERİCİDEN ALICIYA ADIM ADIM
% EE451 dönem projesi - QPSK modülasyonu, AWGN kanal ve korelasyon alıcısı
%
% Zincir:   bitler -> (1) S/P + Gray eşleme + I/Q taşıyıcılar -> (2) AWGN kanal
%           -> (3-4) iki korelatör -> (5) işaret kararı + P/S -> (6) sonuç
%
% Her bölüm (%%) tek başına çalıştırılabilir (Ctrl+Enter). Bölümler sırayla
% çalışmalı, çünkü her biri bir öncekinin değişkenlerini kullanır.
% Diyagram: docs/qpsk/qpsk_sistem.svg

clear; clc; close all;

%% 0) PARAMETRELER
Nbits   = 10;       % gönderilecek bit sayısı (QPSK'da çift olmalı: 2 bit = 1 sembol)
k       = 2;        % sembol başına bit
Nsym    = Nbits/k;  % sembol sayısı -> 5
Ts      = 1;        % sembol süresi [s]  (bir bit süresi Tb = Ts/k = 0.5 s)
fs      = 1000;     % örnekleme frekansı [Hz] -> bir sembolde fs*Ts = 1000 örnek
fc      = 4;        % taşıyıcı frekansı [Hz] -> bir sembolde 4 tam dalga
EbN0_dB = 5;        % kanalın Eb/N0 değeri [dB]

% fc*Ts tam sayı seçildi: o zaman cos ve sin bir sembol boyunca ortogonal,
%     integral_0^Ts cos(2*pi*fc*t)*sin(2*pi*fc*t) dt = 0
% ve alıcıda I ve Q kolları birbirine hiç karışmaz.

% rng(1);           % yorumu kaldırırsan her çalıştırmada aynı bitler ve gürültü gelir
bits = randi([0 1], 1, Nbits);   % 10 adet rastgele bit

%% 1) VERİCİ
% 1a) S/P (seri -> paralel): bitler ikişer gruplanır, [b1 b2]
%     b1 I eksenine (cos), b2 Q eksenine (-sin) gider.
bp = reshape(bits, k, Nsym);     % 2 x 5: her sütun bir sembolün bitleri
b1 = bp(1,:);                    % I bitleri
b2 = bp(2,:);                    % Q bitleri

% 1b) Gray eşleme:  bit 0 -> +1,  bit 1 -> -1,  sonra /sqrt(2)
%     00 -> (+1+j)/sqrt2   01 -> (+1-j)/sqrt2   10 -> (-1+j)/sqrt2   11 -> (-1-j)/sqrt2
%     Komşu noktalar tek bitte farklı. /sqrt(2): |a|^2 = aI^2 + aQ^2 = 1 olsun diye.
aI = (1 - 2*b1)/sqrt(2);
aQ = (1 - 2*b2)/sqrt(2);

% 1c) Taşıyıcılar ve modülasyon:
%     s(t) = aI*cos(2*pi*fc*t) - aQ*sin(2*pi*fc*t)      0 <= t < Ts
t_sym = 0:1/fs:Ts-1/fs;          % tek bir sembolün zaman ekseni
N     = length(t_sym);           % bir semboldeki örnek sayısı
cI    =  cos(2*pi*fc*t_sym);     % I taşıyıcısı (alıcıda da referans)
cQ    = -sin(2*pi*fc*t_sym);     % Q taşıyıcısı (eksi işareti tanımın parçası)

s  = zeros(1, Nsym*N);
sI = zeros(1, Nsym*N);           % sadece görselleştirme: aI*cos kısmı
sQ = zeros(1, Nsym*N);           % sadece görselleştirme: -aQ*sin kısmı
for m = 1:Nsym
    idx     = (m-1)*N + (1:N);   % m'inci sembolün örnekleri
    sI(idx) = aI(m)*cI;
    sQ(idx) = aQ(m)*cQ;
    s(idx)  = sI(idx) + sQ(idx);
end
t = (0:length(s)-1)/fs;

% ---- Figür 1a: bitler -> semboller ----
figure('Name', '1a - S/P ve Gray eşleme');
ax = gobjects(3,1);
Tb = Ts/k;
ax(1) = subplot(3,1,1);
stem((0:Nbits-1)*Tb + Tb/2, bits, 'filled', 'LineWidth', 1.5);
for m = 1:Nsym                   % her sembolün bit çiftini üstüne yaz
    text((m-1)*Ts + Ts/2, 1.35, sprintf('[%d %d]', b1(m), b2(m)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
ylim([-0.2 1.6]); grid on; ylabel('bit');
title('Bitler, ikişer gruplanmış (her grup = 1 sembol)');

ax(2) = subplot(3,1,2);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [aI aI(end)], 'LineWidth', 2);
ylim([-1 1]); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('a_I'); title('I seviyesi: a_I = (1 - 2b_1)/\surd2');

ax(3) = subplot(3,1,3);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [aQ aQ(end)], 'LineWidth', 2);
ylim([-1 1]); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('a_Q'); xlabel('t (s)'); title('Q seviyesi: a_Q = (1 - 2b_2)/\surd2');

for i = 1:3
    for m = 1:Nsym-1
        xline(ax(i), m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nsym*Ts]);

% ---- Figür 1b: I ve Q bileşenleri, toplam sinyal ----
figure('Name', '1b - QPSK sinyali');
ax = gobjects(3,1);
ax(1) = subplot(3,1,1); plot(t, sI); grid on; ylim([-1 1]);
title('I bileşeni: a_I cos(2\pi f_c t)');
ax(2) = subplot(3,1,2); plot(t, sQ); grid on; ylim([-1 1]);
title('Q bileşeni: -a_Q sin(2\pi f_c t)');
ax(3) = subplot(3,1,3); plot(t, s, 'r'); grid on; ylim([-1.2 1.2]);
title('s(t) = a_I cos - a_Q sin   (her sembolde faz değişir, genlik sabit)');
xlabel('t (s)');
for i = 1:3
    for m = 1:Nsym-1
        xline(ax(i), m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nsym*Ts]);

% ---- Figür 1c: yıldız diyagramı ----
figure('Name', '1c - QPSK yıldız diyagramı');
hold on; grid on; axis equal;
for g = 0:3                      % 4 ideal nokta ve Gray etiketleri
    gb1 = floor(g/2); gb2 = mod(g,2);
    px = (1-2*gb1)/sqrt(2); py = (1-2*gb2)/sqrt(2);
    plot(px, py, 'o', 'MarkerSize', 10, 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
    text(px, py+0.18, sprintf('%d%d', gb1, gb2), 'HorizontalAlignment', 'center');
end
plot(aI, aQ, 'r.', 'MarkerSize', 25);            % gönderilen semboller
for m = 1:Nsym
    text(aI(m)+0.08, aQ(m)-0.12, sprintf('s%d', m), 'Color', 'r');
end
xline(0, 'k-', 'HandleVisibility', 'off'); yline(0, 'k-', 'HandleVisibility', 'off');
xlim([-1.3 1.3]); ylim([-1.3 1.3]);
xlabel('I'); ylabel('Q'); title('Gönderilen semboller (kırmızı) ve Gray etiketleri');

%% 2) KANAL: AWGN
%     r(t) = s(t) + n(t)
% Sembol enerjisi:  Es = integral_0^Ts s^2 dt = |a|^2 * Ts/2 = Ts/2   (|a|^2 = 1)
% Bit enerjisi:     Eb = Es/k
% Gürültü:          N0 = Eb/10^(EbN0_dB/10),  örnek başına sigma = sqrt(N0*fs/2)

Es    = sum(cI.^2)/fs;            % = Ts/2 = 0.5  (ortalama |a|^2 = 1 olduğu için)
Eb    = Es/k;
N0    = Eb / 10^(EbN0_dB/10);
sigma = sqrt(N0*fs/2);

n = sigma * randn(1, length(s));
r = s + n;

figure('Name', '2 - Kanal');
subplot(2,1,1); plot(t, s); grid on; title('Gönderilen s(t)');
subplot(2,1,2); plot(t, r); grid on; xlabel('t (s)');
title(sprintf('Alınan r(t) = s(t) + n(t),   E_b/N_0 = %g dB', EbN0_dB));

%% 3) ALICI - tek bir sembolü yakından incele
% İki korelatör:
%     zI = (2/Ts) * integral_0^Ts r(t)*cos(2*pi*fc*t) dt
%     zQ = (2/Ts) * integral_0^Ts r(t)*(-sin(2*pi*fc*t)) dt
% r = aI*cos - aQ*sin + n yazınca:
%     r*cos    = aI*cos^2  - aQ*sin*cos + n*cos  -> integral = aI*Ts/2 + gürültü
%     r*(-sin) = -aI*cos*sin + aQ*sin^2 - n*sin  -> integral = aQ*Ts/2 + gürültü
% (2/Ts) çarpanı Ts/2'yi götürür:  zI = aI + nI,  zQ = aQ + nQ

m_incele = 1;                        % incelenecek sembol (1..Nsym)
idx = (m_incele-1)*N + (1:N);
r_m = r(idx);

pI = r_m .* cI;                      % çarpımlar
pQ = r_m .* cQ;
intI = (2/Ts) * cumsum(pI)/fs;       % koşan integral; son değerleri zI, zQ
intQ = (2/Ts) * cumsum(pQ)/fs;

figure('Name', sprintf('3 - Korelatörler, sembol %d', m_incele));
subplot(3,1,1);
plot(t_sym, r_m); hold on; plot(t_sym, cI, '--'); plot(t_sym, cQ, ':');
legend('r(t)', 'cos', '-sin', 'Location', 'eastoutside'); grid on;
title(sprintf('Sembol %d, bitler [%d %d]: alınan parça ve referanslar', ...
    m_incele, b1(m_incele), b2(m_incele)));

subplot(3,1,2);
plot(t_sym, pI); hold on; plot(t_sym, pQ);
yline(0, 'k-', 'HandleVisibility', 'off');
legend('r \cdot cos', 'r \cdot (-sin)', 'Location', 'eastoutside');
grid on; title('Çarpımlar');

subplot(3,1,3);
plot(t_sym, intI, 'LineWidth', 1.5); hold on; plot(t_sym, intQ, 'LineWidth', 1.5);
yline(aI(m_incele), 'b:', 'a_I', 'HandleVisibility', 'off');
yline(aQ(m_incele), 'r:', 'a_Q', 'HandleVisibility', 'off');
legend('(2/T_s)\int r cos', '(2/T_s)\int r (-sin)', 'Location', 'eastoutside');
title(sprintf('Koşan integral:  z_I = %.3f (a_I = %.3f),   z_Q = %.3f (a_Q = %.3f)', ...
    intI(end), aI(m_incele), intQ(end), aQ(m_incele)));
xlabel('t (s)'); grid on;

%% 4) ALICI - bütün semboller
zI = zeros(1, Nsym);
zQ = zeros(1, Nsym);
for m = 1:Nsym
    idx   = (m-1)*N + (1:N);
    r_m   = r(idx);
    zI(m) = (2/Ts) * sum(r_m .* cI)/fs;
    zQ(m) = (2/Ts) * sum(r_m .* cQ)/fs;
end

% Alınan noktaları yıldız diyagramında göster: gürültü noktaları ideal
% yerlerinden dağıtır. Bir nokta yanlış çeyreğe geçerse hata olur.
figure('Name', '4 - Alınan semboller');
hold on; grid on; axis equal;
ideal = [1+1j, 1-1j, -1+1j, -1-1j]/sqrt(2);
plot(real(ideal), imag(ideal), 'ko', 'MarkerSize', 10, 'LineWidth', 1.5);
plot(zI, zQ, 'r.', 'MarkerSize', 25);
for m = 1:Nsym
    plot([aI(m) zI(m)], [aQ(m) zQ(m)], 'r:', 'HandleVisibility', 'off');   % kayma
    text(zI(m)+0.06, zQ(m), sprintf('%d', m), 'Color', 'r');
end
xline(0, 'b-', 'LineWidth', 1.5, 'HandleVisibility', 'off');  % karar sınırları
yline(0, 'b-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
legend('İdeal noktalar', 'Alınan (z_I, z_Q)', 'Location', 'eastoutside');
xlabel('z_I'); ylabel('z_Q');
title('Alınan semboller; mavi çizgiler karar sınırları');

%% 5) KARAR + P/S
% Gray eşlemede en olası sembolü bulmak = her eksende işarete bakmak:
%     zI < 0 -> b1 = 1,   zQ < 0 -> b2 = 1
b1_hat = double(zI < 0);
b2_hat = double(zQ < 0);
bits_hat = reshape([b1_hat; b2_hat], 1, []);   % P/S: tekrar tek sıra bit

%% 6) SONUÇ
hata_idx = find(bits_hat ~= bits);
hata     = numel(hata_idx);

fprintf('\nEb/N0 = %g dB,  Es = %.3f,  Eb = %.3f,  N0 = %.4f\n\n', EbN0_dB, Es, Eb, N0);
fprintf(' sembol | gönderilen |   aI     aQ   |   zI      zQ   | karar\n');
fprintf('--------+------------+---------------+----------------+------\n');
for m = 1:Nsym
    isaret = ' ';   % boş bırakma: fprintf boş argümanı atlar, satır sonu kaybolur
    if b1_hat(m) ~= b1(m) || b2_hat(m) ~= b2(m), isaret = '  <- HATA'; end
    fprintf('   %2d   |    %d %d     | %6.3f %6.3f | %6.3f  %6.3f |  %d %d%s\n', ...
        m, b1(m), b2(m), aI(m), aQ(m), zI(m), zQ(m), b1_hat(m), b2_hat(m), isaret);
end
fprintf('\nHatalı bit: %d / %d\n', hata, Nbits);

figure('Name', '6 - Sonuç');
stem(1:Nbits, bits, 'filled', 'LineWidth', 1.5); hold on;
stem(1:Nbits, bits_hat, 'r--');
if hata > 0
    plot(hata_idx, bits_hat(hata_idx), 'ro', 'MarkerSize', 12, 'LineWidth', 1.5);
end
ylim([-0.2 1.3]); xlim([0.5 Nbits+0.5]); grid on;
xlabel('bit no'); ylabel('bit');
legend('Gönderilen', 'Tahmin', 'Location', 'eastoutside');
title(sprintf('Gönderilen ve tahmin edilen bitler: %d hata', hata));

% Sonraki adım: EbN0_dB'yi vektör yapıp (ör. 0:1:10) her değerde çok sayıda
% bitle hata oranını ölçmek -> BER eğrisi. Teori:
%     QPSK:  Pb = Q(sqrt(2*Eb/N0)) = 0.5*erfc(sqrt(Eb/N0))
