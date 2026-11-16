%% 16-QAM: VERİCİDEN ALICIYA ADIM ADIM
% EE451 dönem projesi - 16-QAM modülasyonu, AWGN kanal ve korelasyon alıcısı
%
% Zincir:   bitler -> (1) S/P + Gray 4-PAM eşleme + I/Q taşıyıcılar -> (2) AWGN kanal
%           -> (3-4) iki korelatör -> (5) 4 seviyeli dilimleyici + P/S -> (6) sonuç
%
% Her bölüm (%%) tek başına çalıştırılabilir (Ctrl+Enter). Bölümler sırayla
% çalışmalı, çünkü her biri bir öncekinin değişkenlerini kullanır.
% Diyagram: docs/qam16/qam16_sistem.svg

clear; clc; close all;

%% 0) PARAMETRELER
Nbits   = 12;       % 16-QAM'de 4 bit = 1 sembol, bit sayısı 4'ün katı olmalı.
                    % 10 bit 4'e bölünmez (2.5 sembol); bu yüzden 12 bit = 3 sembol.
k       = 4;        % sembol başına bit
Nsym    = Nbits/k;  % sembol sayısı -> 3
Ts      = 1;        % sembol süresi [s]  (bir bit süresi Tb = Ts/k = 0.25 s)
fs      = 1000;     % örnekleme frekansı [Hz]
fc      = 4;        % taşıyıcı frekansı [Hz]; fc*Ts tam sayı -> cos ve sin ortogonal
EbN0_dB = 12;       % 16-QAM noktaları birbirine yakın; QPSK'daki 5 dB'de çok hata
                    % olur. 5'e indirip yıldız diyagramında farkı gör.

% rng(1);           % yorumu kaldırırsan her çalıştırmada aynı bitler ve gürültü gelir
bits = randi([0 1], 1, Nbits);

%% 1) VERİCİ
% 1a) S/P: bitler dörder gruplanır, [b1 b2 b3 b4]
%     b1 b2 -> I ekseninin SEVİYESİ,  b3 b4 -> Q ekseninin seviyesi
bp = reshape(bits, k, Nsym);     % 4 x 3: her sütun bir sembol

% 1b) Gray kodlu 4-PAM, her eksen için ayrı:
%     G(00) = -3,  G(01) = -1,  G(11) = +1,  G(10) = +3
%     Komşu seviyeler tek bitte farklı (01 ile 11 gibi).
%     lut, 2*bA + bB + 1 indeksiyle okunur:  00 -> 1, 01 -> 2, 10 -> 3, 11 -> 4
lut = [-3 -1 3 1];
I_raw = lut(2*bp(1,:) + bp(2,:) + 1);    % -3, -1, +1, +3
Q_raw = lut(2*bp(3,:) + bp(4,:) + 1);

% Ham noktaların ortalama enerjisi: E[I^2] + E[Q^2] = 5 + 5 = 10
% (çünkü (1 + 9)/2 = 5). /sqrt(10) ile ortalama |a|^2 = 1 yapıyoruz.
aI = I_raw/sqrt(10);
aQ = Q_raw/sqrt(10);

% 1c) Taşıyıcılar:  s(t) = aI*cos(2*pi*fc*t) - aQ*sin(2*pi*fc*t)
t_sym = 0:1/fs:Ts-1/fs;
N     = length(t_sym);
cI    =  cos(2*pi*fc*t_sym);
cQ    = -sin(2*pi*fc*t_sym);

s = zeros(1, Nsym*N);
for m = 1:Nsym
    idx    = (m-1)*N + (1:N);
    s(idx) = aI(m)*cI + aQ(m)*cQ;
end
t = (0:length(s)-1)/fs;

% ---- Figür 1a: bitler -> seviyeler ----
figure('Name', '1a - S/P ve Gray 4-PAM');
ax = gobjects(3,1);
Tb = Ts/k;
ax(1) = subplot(3,1,1);
stem((0:Nbits-1)*Tb + Tb/2, bits, 'filled', 'LineWidth', 1.5);
for m = 1:Nsym
    text((m-1)*Ts + Ts/2, 1.35, sprintf('[%d%d | %d%d]', bp(:,m)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
ylim([-0.2 1.6]); grid on; ylabel('bit');
title('Bitler, dörder gruplanmış: [I bitleri | Q bitleri]');

ax(2) = subplot(3,1,2);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [I_raw I_raw(end)], 'LineWidth', 2);
ylim([-4 4]); yticks(-3:2:3); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('\surd10 a_I'); title('I seviyesi: G(b_1b_2) \in \{-3, -1, +1, +3\}');

ax(3) = subplot(3,1,3);
stairs([(0:Nsym-1)*Ts, Nsym*Ts], [Q_raw Q_raw(end)], 'LineWidth', 2);
ylim([-4 4]); yticks(-3:2:3); yline(0, 'k-', 'HandleVisibility', 'off'); grid on;
ylabel('\surd10 a_Q'); xlabel('t (s)'); title('Q seviyesi: G(b_3b_4)');

for i = 1:3
    for m = 1:Nsym-1
        xline(ax(i), m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    end
end
linkaxes(ax, 'x'); xlim([0 Nsym*Ts]);

% ---- Figür 1b: 16-QAM sinyali ----
figure('Name', '1b - 16-QAM sinyali');
plot(t, s, 'r'); grid on;
for m = 1:Nsym-1
    xline(m*Ts, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
end
xlabel('t (s)'); ylabel('genlik');
title('s(t) = a_I cos - a_Q sin   (her sembolde hem genlik hem faz değişir)');

% ---- Figür 1c: yıldız diyagramı ----
figure('Name', '1c - 16-QAM yıldız diyagramı');
hold on; grid on; axis equal;
gray2 = {'00', '01', '10', '11'};
for gI = 0:3                     % 16 ideal nokta ve 4 bitlik etiketleri
    for gQ = 0:3
        px = lut(gI+1)/sqrt(10);  py = lut(gQ+1)/sqrt(10);
        plot(px, py, 'o', 'MarkerSize', 8, 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
        text(px, py+0.1, [gray2{gI+1} gray2{gQ+1}], 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end
plot(aI, aQ, 'r.', 'MarkerSize', 25);
for m = 1:Nsym
    text(aI(m)+0.05, aQ(m)-0.08, sprintf('s%d', m), 'Color', 'r');
end
xline(0, 'k-', 'HandleVisibility', 'off'); yline(0, 'k-', 'HandleVisibility', 'off');
xlim([-1.3 1.3]); ylim([-1.3 1.3]);
xlabel('I'); ylabel('Q'); title('Gönderilen semboller (kırmızı) ve Gray etiketleri (b_1b_2b_3b_4)');

%% 2) KANAL: AWGN
% Es = ortalama |a|^2 * Ts/2 = Ts/2,  Eb = Es/k = Es/4
% N0 = Eb/10^(EbN0_dB/10),  örnek başına sigma = sqrt(N0*fs/2)
Es    = sum(cI.^2)/fs;           % = Ts/2 = 0.5
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
% Korelatörler QPSK ile birebir aynı:
%     zI = (2/Ts) * integral r*cos dt  = aI + nI
%     zQ = (2/Ts) * integral r*(-sin) dt = aQ + nQ
% Fark kararda: burada 2 değil 4 seviye var.
m_incele = 1;
idx  = (m_incele-1)*N + (1:N);
r_m  = r(idx);
intI = (2/Ts) * cumsum(r_m .* cI)/fs;
intQ = (2/Ts) * cumsum(r_m .* cQ)/fs;

figure('Name', sprintf('3 - Korelatörler, sembol %d', m_incele));
subplot(2,1,1);
plot(t_sym, r_m); hold on; plot(t_sym, cI, '--'); plot(t_sym, cQ, ':');
legend('r(t)', 'cos', '-sin', 'Location', 'eastoutside'); grid on;
title(sprintf('Sembol %d, bitler [%d%d | %d%d]', m_incele, bp(:,m_incele)));

subplot(2,1,2);
plot(t_sym, sqrt(10)*intI, 'LineWidth', 1.5); hold on;
plot(t_sym, sqrt(10)*intQ, 'LineWidth', 1.5);
for lv = [-2 0 2]                % karar eşikleri
    yline(lv, 'k:', 'HandleVisibility', 'off');
end
legend('\surd10 z_I', '\surd10 z_Q', 'Location', 'eastoutside');
title(sprintf('Koşan integral (\\surd10 ölçeğinde): sonda %.2f (hedef %d) ve %.2f (hedef %d)', ...
    sqrt(10)*intI(end), I_raw(m_incele), sqrt(10)*intQ(end), Q_raw(m_incele)));
xlabel('t (s)'); grid on; ylim([-4.5 4.5]);

%% 4) ALICI - bütün semboller
zI = zeros(1, Nsym);
zQ = zeros(1, Nsym);
for m = 1:Nsym
    idx   = (m-1)*N + (1:N);
    r_m   = r(idx);
    zI(m) = (2/Ts) * sum(r_m .* cI)/fs;
    zQ(m) = (2/Ts) * sum(r_m .* cQ)/fs;
end

figure('Name', '4 - Alınan semboller');
hold on; grid on; axis equal;
[GI, GQ] = meshgrid(lut/sqrt(10));
plot(GI(:), GQ(:), 'ko', 'MarkerSize', 8, 'LineWidth', 1.2);
plot(zI, zQ, 'r.', 'MarkerSize', 25);
for m = 1:Nsym
    plot([aI(m) zI(m)], [aQ(m) zQ(m)], 'r:', 'HandleVisibility', 'off');
    text(zI(m)+0.05, zQ(m), sprintf('%d', m), 'Color', 'r');
end
for th = [-2 0 2]/sqrt(10)       % karar sınırları: her eksende -2, 0, +2 (ölçekli)
    xline(th, 'b-', 'HandleVisibility', 'off');
    yline(th, 'b-', 'HandleVisibility', 'off');
end
legend('İdeal noktalar', 'Alınan (z_I, z_Q)', 'Location', 'eastoutside');
xlabel('z_I'); ylabel('z_Q');
title('Alınan semboller; mavi çizgiler karar sınırları (16 kare)');

%% 5) KARAR (4-PAM dilimleyici) + P/S
% Ölçeği geri al: x = sqrt(10)*z  ->  gürültüsüz olsa -3, -1, +1, +3'ten biri.
% En yakın seviye = eşikler -2, 0, +2. Gray tablosu tersten okunursa:
%     1. bit (b1 veya b3) = x > 0          (sağ yarı -> 1)
%     2. bit (b2 veya b4) = |x| < 2        (iç seviyeler ±1 -> 1)
xI = sqrt(10)*zI;
xQ = sqrt(10)*zQ;
b_hat = [xI > 0; abs(xI) < 2; xQ > 0; abs(xQ) < 2];   % 4 x Nsym
bits_hat = double(reshape(b_hat, 1, []));              % P/S

%% 6) SONUÇ
hata_idx = find(bits_hat ~= bits);
hata     = numel(hata_idx);

fprintf('\nEb/N0 = %g dB,  Es = %.3f,  Eb = %.3f,  N0 = %.4f\n\n', EbN0_dB, Es, Eb, N0);
fprintf(' sembol | gönderilen | I  Q (ham) |  xI     xQ   | karar\n');
fprintf('--------+------------+------------+--------------+------\n');
for m = 1:Nsym
    isaret = ' ';   % boş bırakma: fprintf boş argümanı atlar, satır sonu kaybolur
    if any(b_hat(:,m)' ~= bp(:,m)'), isaret = '  <- HATA'; end
    fprintf('   %2d   |    %d%d%d%d    |  %+d  %+d   | %5.2f  %5.2f |  %d%d%d%d%s\n', ...
        m, bp(:,m), I_raw(m), Q_raw(m), xI(m), xQ(m), b_hat(:,m), isaret);
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

% Sonraki adım: BER eğrisi. Teori (Gray, tam):
%     u  = sqrt(4/5 * Eb/N0)
%     Pb = 1/4 * (3*Q(u) + 2*Q(3u) - Q(5u)),   Q(x) = 0.5*erfc(x/sqrt(2))
