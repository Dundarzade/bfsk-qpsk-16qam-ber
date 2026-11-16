function ber_gui
%BER_GUI BFSK BER deneyi: rastgele bit gönder, alıcının hatalarını say.
%
%   Kullanım:  >> ber_gui
%   Tek dosya, başka hiçbir dosyaya ihtiyaç duymaz; istediğin klasöre koy.
%
%   1) Kaç bit gönderileceğini yaz (ör. 1000)
%   2) Üç gürültü seviyesi gir (Eb/N0, dB). Büyük dB = az gürültü.
%   3) "Gönder" -> her Eb/N0 için:
%        bitler -> BFSK verici -> AWGN kanal -> korelatör alıcı -> bitler_hat
%        hatalı bit = sum(bitler ~= bitler_hat),  BER = hatalı / gönderilen
%
%   Verici/kanal/alıcı docs/bfsk/bfsk_adim_adim.m ile aynı (koherent korelatör):
%        z1 = integral r*cos(2*pi*f1*t) dt,  z2 = integral r*cos(2*pi*f2*t) dt
%        d  = z1 - z2,   d > 0 -> 1,  d < 0 -> 0
%   Teori: Pb = Q(sqrt(Eb/N0)) = 0.5*erfc(sqrt(Eb/N0/2))

    % ---- BFSK parametreleri (adım adım script ile aynı) ----
    P.Tb = 1;      % bit süresi [s]
    P.fs = 100;    % örnekleme [Hz]; 9 Hz için yeterli, 1000 yerine 100 -> 10 kat hızlı
    P.f1 = 9;      % bit 1 frekansı [Hz]
    P.f2 = 3;      % bit 0 frekansı [Hz]

    sonuc = struct('etiket', {}, 'bits', {}, 'bits_hat', {}, 'd', {}, 'nErr', {}, 'Eb', {});

    % ================= ARAYÜZ =================
    fig = uifigure('Name', 'BFSK BER Deneyi', 'Position', [60 60 1250 760]);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {300, '1x'};

    % ---------- sol: ayarlar ----------
    L = uigridlayout(g, [10 1]);
    L.RowHeight = {44, 40, 22, 28, 22, 28, 22, 44, 44, '1x'};
    L.Padding = [12 12 12 12];

    lb = uilabel(L, 'Text', 'BFSK BER deneyi: bit gönder, hataları say', ...
        'FontSize', 16, 'FontWeight', 'bold', 'WordWrap', 'on');
    lb.Layout.Row = 1;
    lb = uilabel(L, 'WordWrap', 'on', 'FontColor', [0.4 0.4 0.4], 'Text', ...
        sprintf('bit 1 → %g Hz,  bit 0 → %g Hz,  Tb = %g s', P.f1, P.f2, P.Tb));
    lb.Layout.Row = 2;

    lb = uilabel(L, 'Text', '1) Kaç bit gönderilsin?', 'FontWeight', 'bold'); lb.Layout.Row = 3;
    nbEdit = uieditfield(L, 'numeric', 'Value', 1000, 'Limits', [10 1e5], ...
        'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d bit');
    nbEdit.Layout.Row = 4;

    lb = uilabel(L, 'Text', '2) Gürültü: 3 adet Eb/N0 (dB)', 'FontWeight', 'bold'); lb.Layout.Row = 5;
    G3 = uigridlayout(L, [1 3]); G3.Padding = [0 0 0 0]; G3.Layout.Row = 6;
    dbEdit = gobjects(1, 3);
    varsayilan = [0 4 8];
    for j = 1:3
        dbEdit(j) = uieditfield(G3, 'numeric', 'Value', varsayilan(j), ...
            'Limits', [-5 20], 'ValueDisplayFormat', '%g dB');
    end
    lb = uilabel(L, 'Text', 'büyük dB = sinyal güçlü, gürültü az', ...
        'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4]);
    lb.Layout.Row = 7;

    btn = uibutton(L, 'Text', 'Gönder', 'FontSize', 15, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @gonder);
    btn.Layout.Row = 8;

    durum = uilabel(L, 'Text', 'Ayarları seçip "Gönder"e bas.', 'WordWrap', 'on');
    durum.Layout.Row = 9;

    yardim = uitextarea(L, 'Editable', 'off', 'Value', { ...
        'NASIL OKUNUR?', ...
        '', ...
        '• Bilgisayar rastgele 0/1 bitleri üretir. Her bit bir tonla gönderilir: 1 → yüksek frekans, 0 → düşük frekans.', ...
        '• Kanal sinyale gürültü ekler. Eb/N0 büyüdükçe gürültü azalır.', ...
        '• Alıcı her bit için "hangi tona daha çok benziyor?" diye bakar ve tahmin eder. Yanlış tahmin = bit hatası.', ...
        '• BER = hatalı bit / gönderilen bit. 0.01 = her 100 bitte 1 hata.', ...
        '', ...
        'BER grafiği: çizgi teori, noktalar senin deneyin. Nokta çizgiye yakınsa simülasyon doğru. 0 hata çıkarsa aşağı üçgen konur: BER 1/N''den küçük, ölçmek için daha çok bit gönder.', ...
        '', ...
        'Alıcı neden yanılıyor? Mavi tepe gönderilen 1''ler, turuncu tepe 0''lar. Siyah çizgi (0) eşik: sağı 1, solu 0 kabul edilir. Gürültü tepeleri genişletir; çizginin yanlış tarafına taşan bitler alıcının yanıldığı bitlerdir.', ...
        '', ...
        'Hatalar nerede? İlk 200 bit: yeşil doğru, kırmızı yanlış.'});
    yardim.Layout.Row = 10;

    % ---------- sağ: sonuçlar ----------
    R = uigridlayout(g, [4 2]);
    R.RowHeight = {'1x', 120, 26, 90};

    axBer = uiaxes(R); axBer.Layout.Row = 1; axBer.Layout.Column = 1;
    axD   = uiaxes(R); axD.Layout.Row   = 1; axD.Layout.Column   = 2;
    bos_grafik();
    title(axD, 'Alıcı neden yanılıyor?');

    tbl = uitable(R, 'ColumnName', {'Eb/N0 (dB)', 'Gönderilen bit', 'Hatalı bit', ...
        'Ölçülen BER', 'Teorik BER', 'Anlamı'}, ...
        'ColumnWidth', {85, 110, 85, 100, 100, 'auto'}, 'RowName', {});
    tbl.Layout.Row = 2; tbl.Layout.Column = [1 2];

    lb = uilabel(R, 'Text', 'Hangi deneye bakılsın?  →', 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right');
    lb.Layout.Row = 3; lb.Layout.Column = 1;
    dd = uidropdown(R, 'Items', {'(önce Gönder)'}, 'Enable', 'off', ...
        'ValueChangedFcn', @(src, ~) deney_goster(src.Value));
    dd.Layout.Row = 3; dd.Layout.Column = 2;

    axStrip = uiaxes(R); axStrip.Layout.Row = 4; axStrip.Layout.Column = [1 2];
    axStrip.XTick = []; axStrip.YTick = [];
    title(axStrip, 'Hatalar nerede?');

    % ================= İŞLEM =================
    function gonder(~, ~)
        n   = nbEdit.Value;
        dBs = sort([dbEdit.Value]);
        btn.Enable = 'off'; durum.Text = 'Gönderiliyor...'; drawnow;

        sonuc = struct('etiket', {}, 'bits', {}, 'bits_hat', {}, 'd', {}, 'nErr', {}, 'Eb', {});
        satir = {};
        bos_grafik();

        EbAx = -5:0.25:20;
        plot(axBer, EbAx, Pb_teori(EbAx), '-', 'LineWidth', 1.8, ...
            'Color', [0 0.45 0.74], 'DisplayName', 'teori: Q(\surd(E_b/N_0))');

        for j = 1:3
            [bits, bits_hat, d, Eb] = bfsk_deney(n, dBs(j), P);
            nErr = sum(bits_hat ~= bits);
            berO = nErr / n;
            berT = Pb_teori(dBs(j));

            if nErr > 0
                plot(axBer, dBs(j), berO, 'o', 'MarkerSize', 10, 'LineWidth', 1.5, ...
                    'MarkerFaceColor', [0.85 0.33 0.10], 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            else   % 0 hata: log eksende 0 çizilemez -> 1/n'nin altına üçgen
                plot(axBer, dBs(j), 0.5/n, 'v', 'MarkerSize', 10, 'LineWidth', 1.5, ...
                    'MarkerEdgeColor', [0.85 0.33 0.10], 'HandleVisibility', 'off');
            end
            text(axBer, dBs(j), max(berO, 0.5/n)*2.2, sprintf('%d/%d', nErr, n), ...
                'HorizontalAlignment', 'center', 'FontSize', 10);

            if nErr == 0
                anlam = sprintf('hiç hata yok (BER < 1/%d)', n);
            else
                anlam = sprintf('yaklaşık her %d bitte 1 hata', max(1, round(n / nErr)));
            end
            satir(end+1, :) = {dBs(j), n, nErr, sprintf('%.2e', berO), ...
                sprintf('%.2e', berT), anlam}; %#ok<AGROW>

            sonuc(end+1) = struct('etiket', sprintf('%g dB', dBs(j)), 'bits', bits, ...
                'bits_hat', bits_hat, 'd', d, 'nErr', nErr, 'Eb', Eb); %#ok<AGROW>
        end

        plot(axBer, NaN, NaN, 'o', 'MarkerFaceColor', [0.85 0.33 0.10], ...
            'MarkerEdgeColor', 'k', 'DisplayName', 'deney (hatalı/gönderilen)');
        plot(axBer, NaN, NaN, 'v', 'MarkerEdgeColor', [0.85 0.33 0.10], ...
            'DisplayName', '0 hata (BER < 1/N)');
        for j = 1:3
            xline(axBer, dBs(j), ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
        end
        legend(axBer, 'Location', 'southwest');

        tbl.Data = satir;
        dd.Items = {sonuc.etiket};
        dd.ItemsData = 1:numel(sonuc);
        dd.Enable = 'on';
        dd.Value = 1;                   % en gürültülü deneyden başla
        deney_goster(1);

        durum.Text = sprintf('Tamam: 3 deney, her birinde %d bit gönderildi.', n);
        btn.Enable = 'on';
    end

    function deney_goster(idx)
        Rr = sonuc(idx);

        % ---- karar değişkeni histogramı ----
        cla(axD); legend(axD, 'off'); hold(axD, 'on'); grid(axD, 'on');
        lim   = max(abs(Rr.d)) * 1.05;
        edges = linspace(-lim, lim, 41);
        histogram(axD, Rr.d(Rr.bits == 1), edges, 'FaceColor', [0 0.45 0.74], ...
            'FaceAlpha', 0.6, 'DisplayName', 'gönderilen 1');
        histogram(axD, Rr.d(Rr.bits == 0), edges, 'FaceColor', [0.85 0.33 0.10], ...
            'FaceAlpha', 0.6, 'DisplayName', 'gönderilen 0');
        xline(axD, 0, 'k-', 'LineWidth', 2.5, 'DisplayName', 'eşik (0)');
        xline(axD,  Rr.Eb, 'k:', '+E_b', 'HandleVisibility', 'off');
        xline(axD, -Rr.Eb, 'k:', '-E_b', 'HandleVisibility', 'off');
        e10 = sum(Rr.bits == 1 & Rr.d < 0);    % 1 gönderildi, 0 sanıldı
        e01 = sum(Rr.bits == 0 & Rr.d > 0);    % 0 gönderildi, 1 sanıldı
        title(axD, sprintf('%s: eşiğin yanlış tarafına düşen %d bit (1→0: %d, 0→1: %d)', ...
            Rr.etiket, e10 + e01, e10, e01));
        xlabel(axD, 'd = z_1 - z_2   (sağ: 1 kararı, sol: 0 kararı)');
        ylabel(axD, 'bit sayısı');
        legend(axD, 'Location', 'northwest');

        % ---- hata şeridi: ilk 200 bit ----
        m = min(200, numel(Rr.bits));
        dogru = Rr.bits(1:m) == Rr.bits_hat(1:m);
        img = zeros(1, m, 3);
        img(1, dogru, 1) = 0.30;  img(1, dogru, 2) = 0.69;  img(1, dogru, 3) = 0.31;
        img(1, ~dogru, 1) = 0.90; img(1, ~dogru, 2) = 0.20; img(1, ~dogru, 3) = 0.20;
        cla(axStrip);
        image(axStrip, img);
        axStrip.XLim = [0.5 m + 0.5]; axStrip.YLim = [0.5 1.5];
        axStrip.YTick = []; axStrip.XTick = unique([1 50:50:m]);
        xlabel(axStrip, 'bit no');
        title(axStrip, sprintf('Hatalar nerede? %s: ilk %d bitin %d tanesi yanlış (kırmızı). Toplam %d bitte %d hata.', ...
            Rr.etiket, m, sum(~dogru), numel(Rr.bits), Rr.nErr));
    end

    function bos_grafik()
        cla(axBer); legend(axBer, 'off');
        hold(axBer, 'on'); grid(axBer, 'on');
        axBer.YScale = 'log';
        axBer.YLim = [1e-6 1]; axBer.XLim = [-5 20];
        xlabel(axBer, 'E_b/N_0 (dB)   \rightarrow   gürültü azalıyor');
        ylabel(axBer, 'BER (hatalı bit oranı)');
        title(axBer, 'BER eğrisi: çizgi = teori, nokta = deney');
        cla(axD); legend(axD, 'off');
    end
end

% ================= BFSK ZİNCİRİ =================
function [bits, bits_hat, d, Eb] = bfsk_deney(n, EbN0_dB, P)
% bitler -> BFSK verici -> AWGN kanal -> korelatör -> karar
% Her sütun bir bit: döngü yerine matrisle, aynı işlem.
    t_bit = (0:P.fs*P.Tb-1) / P.fs;            % bir bitin zaman ekseni
    c1 = cos(2*pi*P.f1*t_bit).';               % bit 1 tonu (sütun)
    c2 = cos(2*pi*P.f2*t_bit).';               % bit 0 tonu

    bits = randi([0 1], 1, n);                 % rastgele bitler
    S = c1 * bits + c2 * (1 - bits);           % verici: sütun k = bit k'nın sinyali

    Eb    = sum(c1.^2) / P.fs;                 % bit enerjisi = Tb/2
    N0    = Eb / 10^(EbN0_dB/10);
    sigma = sqrt(N0 * P.fs / 2);               % örnek başına gürültü std
    Rx    = S + sigma * randn(size(S));        % kanal: r = s + n

    z1 = (c1.' * Rx) / P.fs;                   % korelatör 1: integral r*c1 dt
    z2 = (c2.' * Rx) / P.fs;                   % korelatör 2: integral r*c2 dt
    d  = z1 - z2;                              % karar değişkeni
    bits_hat = double(d > 0);                  % karar
end

function Pb = Pb_teori(EbN0_dB)
% Koherent BFSK: Pb = Q(sqrt(Eb/N0)),  Q(x) = 0.5*erfc(x/sqrt(2))
    g  = 10.^(EbN0_dB/10);
    Pb = 0.5 * erfc(sqrt(g/2));
end
