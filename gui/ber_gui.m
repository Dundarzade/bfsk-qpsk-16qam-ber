function ber_gui
%BER_GUI Basit BER deneyi: rastgele bit gönder, alıcının hatalarını say.
%
%   Kullanım:  MATLAB'de bu klasörde  >> ber_gui
%
%   1) Modülasyon(lar)ı seç (BFSK, QPSK, 16-QAM)
%   2) Kaç bit gönderileceğini yaz (ör. 1000)
%   3) Üç gürültü seviyesi gir (Eb/N0, dB). Büyük dB = az gürültü.
%   4) "Gönder" -> her modülasyon ve her Eb/N0 için:
%        bitler = randi -> modülatör -> AWGN kanal -> demodülatör -> bitler_hat
%        hatalı bit = sum(bitler ~= bitler_hat),  BER = hatalı / gönderilen
%      Sonuçlar teorik BER eğrisinin üstüne nokta olarak konur, tabloya yazılır,
%      ve "Hatalar nerede?" şeridinde doğru bitler yeşil, yanlışlar kırmızı görünür.
%
%   Hesap repodaki fonksiyonlarla yapılır (src/): scheme_handles, awgn_channel,
%   ber_theory. Yani GUI ve ber_sim aynı modülatör/demodülatörü kullanır.
%   Not: buradaki BFSK alıcısı non-koherent (faz bilgisi gerekmez),
%   teorisi Pb = 0.5*exp(-Eb/2N0).

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, '..', 'src'));

    % ---- modülasyon listesi ----
    SC = struct('ad',   {'BFSK', 'QPSK', '16-QAM'}, ...
                'kod',  {'bfsk', 'qpsk', 'qam16'}, ...
                'renk', {[0.85 0.33 0.10], [0.00 0.45 0.74], [0.47 0.67 0.19]});

    sonuc = struct('etiket', {}, 'bits', {}, 'bits_hat', {}, 'nErr', {});  % son çalıştırma

    % ================= ARAYÜZ =================
    fig = uifigure('Name', 'BER Deneyi - BFSK / QPSK / 16-QAM', 'Position', [80 80 1200 720]);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {300, '1x'};

    % ---------- sol: ayarlar ----------
    L = uigridlayout(g, [13 1]);
    L.RowHeight = {44, 22, 22, 22, 22, 22, 28, 22, 28, 22, 44, 44, '1x'};
    L.Padding = [12 12 12 12];

    t = uilabel(L, 'Text', 'BER deneyi: bit gönder, hataları say', ...
        'FontSize', 16, 'FontWeight', 'bold', 'WordWrap', 'on');
    t.Layout.Row = 1;

    lb = uilabel(L, 'Text', '1) Modülasyon seç', 'FontWeight', 'bold'); lb.Layout.Row = 2;
    cb = gobjects(1, 3);
    for i = 1:3
        cb(i) = uicheckbox(L, 'Text', SC(i).ad, 'Value', true, 'FontColor', SC(i).renk);
        cb(i).Layout.Row = 2 + i;
    end

    lb = uilabel(L, 'Text', '2) Kaç bit gönderilsin?', 'FontWeight', 'bold'); lb.Layout.Row = 6;
    nbEdit = uieditfield(L, 'numeric', 'Value', 1000, 'Limits', [12 1e6], ...
        'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%d bit');
    nbEdit.Layout.Row = 7;

    lb = uilabel(L, 'Text', '3) Gürültü: 3 adet Eb/N0 (dB)', 'FontWeight', 'bold'); lb.Layout.Row = 8;
    G3 = uigridlayout(L, [1 3]); G3.Padding = [0 0 0 0]; G3.Layout.Row = 9;
    dbEdit = gobjects(1, 3);
    varsayilan = [0 4 8];
    for j = 1:3
        dbEdit(j) = uieditfield(G3, 'numeric', 'Value', varsayilan(j), ...
            'Limits', [-5 20], 'ValueDisplayFormat', '%g dB');
    end
    lb = uilabel(L, 'Text', 'büyük dB = sinyal güçlü, gürültü az', ...
        'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4]);
    lb.Layout.Row = 10;

    btn = uibutton(L, 'Text', 'Gönder', 'FontSize', 15, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @gonder);
    btn.Layout.Row = 11;

    durum = uilabel(L, 'Text', 'Ayarları seçip "Gönder"e bas.', 'WordWrap', 'on');
    durum.Layout.Row = 12;

    yardim = uitextarea(L, 'Editable', 'off', 'Value', { ...
        'NASIL OKUNUR?', ...
        '', ...
        '• Bilgisayar rastgele 0/1 bitleri üretir ve seçilen yöntemle sinyale çevirir.', ...
        '• Kanal sinyale gürültü ekler. Eb/N0 büyüdükçe gürültü azalır.', ...
        '• Alıcı her biti tahmin eder. Yanlış tahmin = bit hatası.', ...
        '• BER = hatalı bit / gönderilen bit. 0.01 = her 100 bitte 1 hata.', ...
        '• Çizgiler teori, noktalar senin deneyin. Nokta çizgiye yakınsa simülasyon doğru.', ...
        '• 0 hata çıkarsa (aşağı üçgen) BER 1/N''den küçüktür: ölçmek için daha çok bit gönder.', ...
        '• Aynı Eb/N0''da hangi yöntem daha az hata yapıyor? Grafikte aşağıdaki çizgi daha iyi.'});
    yardim.Layout.Row = 13;

    % ---------- sağ: sonuçlar ----------
    R = uigridlayout(g, [3 1]);
    R.RowHeight = {'1x', 165, 120};

    axBer = uiaxes(R);
    axBer.Layout.Row = 1;
    bos_grafik();

    tbl = uitable(R, 'ColumnName', {'Modülasyon', 'Eb/N0 (dB)', 'Gönderilen bit', ...
        'Hatalı bit', 'Ölçülen BER', 'Teorik BER', 'Anlamı'}, ...
        'ColumnWidth', {85, 80, 105, 80, 95, 95, 'auto'}, 'RowName', {});
    tbl.Layout.Row = 2;

    S = uigridlayout(R, [2 2]);
    S.Layout.Row = 3;
    S.RowHeight = {26, '1x'}; S.ColumnWidth = {150, '1x'};
    lb = uilabel(S, 'Text', 'Hatalar nerede?', 'FontWeight', 'bold');
    lb.Layout.Row = 1; lb.Layout.Column = 1;
    dd = uidropdown(S, 'Items', {'(önce Gönder)'}, 'Enable', 'off', ...
        'ValueChangedFcn', @(src, ~) serit_ciz(src.Value));
    dd.Layout.Row = 1; dd.Layout.Column = 2;
    axStrip = uiaxes(S);
    axStrip.Layout.Row = 2; axStrip.Layout.Column = [1 2];
    axStrip.XTick = []; axStrip.YTick = [];

    % ================= İŞLEM =================
    function gonder(~, ~)
        sec = find([cb.Value]);
        if isempty(sec)
            durum.Text = 'En az bir modülasyon seç.';
            return
        end
        Nb  = nbEdit.Value;
        dBs = sort([dbEdit.Value]);

        btn.Enable = 'off'; durum.Text = 'Gönderiliyor...'; drawnow;

        sonuc = struct('etiket', {}, 'bits', {}, 'bits_hat', {}, 'nErr', {});
        satir = {};
        bos_grafik();
        EbAx = -5:0.25:20;

        for i = sec
            [modf, demodf, k, sps] = scheme_handles(SC(i).kod);
            n = k * ceil(Nb / k);        % bit sayısı sembol başına bitin katı olmalı

            % teorik eğri
            plot(axBer, EbAx, ber_theory(SC(i).kod, EbAx), '-', 'LineWidth', 1.5, ...
                'Color', SC(i).renk, 'DisplayName', [SC(i).ad ' (teori)']);

            for j = 1:3
                % ---- deney: bitler -> modülatör -> kanal -> demodülatör ----
                bits     = randi([0 1], n, 1);
                s        = modf(bits);
                r        = awgn_channel(s, dBs(j), k, sps);
                bits_hat = demodf(r);

                nErr  = sum(bits_hat ~= bits);
                berO  = nErr / n;
                berT  = ber_theory(SC(i).kod, dBs(j));

                % ---- grafiğe nokta ----
                if nErr > 0
                    plot(axBer, dBs(j), berO, 'o', 'MarkerSize', 9, 'LineWidth', 1.5, ...
                        'MarkerFaceColor', SC(i).renk, 'MarkerEdgeColor', 'k', ...
                        'HandleVisibility', 'off');
                else   % 0 hata: log eksende 0 çizilemez, 1/n'nin altına üçgen
                    plot(axBer, dBs(j), 0.5/n, 'v', 'MarkerSize', 9, 'LineWidth', 1.5, ...
                        'MarkerFaceColor', 'w', 'MarkerEdgeColor', SC(i).renk, ...
                        'HandleVisibility', 'off');
                end

                % ---- tablo satırı ----
                if nErr == 0
                    anlam = sprintf('hiç hata yok (BER < 1/%d)', n);
                else
                    anlam = sprintf('yaklaşık her %d bitte 1 hata', max(1, round(n / nErr)));
                end
                satir(end+1, :) = {SC(i).ad, dBs(j), n, nErr, ...
                    sprintf('%.2e', berO), sprintf('%.2e', berT), anlam}; %#ok<AGROW>

                sonuc(end+1) = struct('etiket', sprintf('%s, %g dB', SC(i).ad, dBs(j)), ...
                    'bits', bits, 'bits_hat', bits_hat, 'nErr', nErr); %#ok<AGROW>
            end
        end

        % lejant için örnek işaretler (görünmez veri)
        plot(axBer, NaN, NaN, 'ko', 'MarkerFaceColor', [0.6 0.6 0.6], 'DisplayName', 'ölçülen');
        plot(axBer, NaN, NaN, 'kv', 'DisplayName', '0 hata (BER < 1/N)');
        legend(axBer, 'Location', 'southwest');
        for j = 1:3
            xline(axBer, dBs(j), ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
        end

        tbl.Data = satir;
        dd.Items = {sonuc.etiket};
        dd.ItemsData = 1:numel(sonuc);
        dd.Enable = 'on';
        dd.Value = 1;                   % en gürültülü durumdan başla
        serit_ciz(1);

        durum.Text = sprintf('Tamam: %d modülasyon × 3 Eb/N0, her deneyde ~%d bit.', ...
            numel(sec), Nb);
        btn.Enable = 'on';
    end

    function serit_ciz(idx)
        % İlk 200 bit: doğru tahmin yeşil, yanlış tahmin kırmızı kare
        Rr = sonuc(idx);
        m  = min(200, numel(Rr.bits));
        dogru = (Rr.bits(1:m) == Rr.bits_hat(1:m)).';
        img = zeros(1, m, 3);
        img(1, dogru, 1) = 0.30;  img(1, dogru, 2) = 0.69;  img(1, dogru, 3) = 0.31;
        img(1, ~dogru, 1) = 0.90; img(1, ~dogru, 2) = 0.20; img(1, ~dogru, 3) = 0.20;
        cla(axStrip);
        image(axStrip, img);
        axStrip.XLim = [0.5 m + 0.5]; axStrip.YLim = [0.5 1.5];
        axStrip.YTick = []; axStrip.XTick = [1 50 100 150 200];
        xlabel(axStrip, 'bit no');
        title(axStrip, sprintf(['%s:  ilk %d bitin %d tanesi yanlış (kırmızı).   ' ...
            'Toplam %d bitte %d hata.'], Rr.etiket, m, sum(~dogru), numel(Rr.bits), Rr.nErr));
    end

    function bos_grafik()
        cla(axBer); legend(axBer, 'off');
        hold(axBer, 'on'); grid(axBer, 'on');
        axBer.YScale = 'log';
        axBer.YLim = [1e-6 1]; axBer.XLim = [-5 20];
        xlabel(axBer, 'E_b/N_0 (dB)   \rightarrow   gürültü azalıyor');
        ylabel(axBer, 'BER (hatalı bit oranı)');
        title(axBer, 'BER eğrileri: çizgi = teori, nokta = deney');
    end
end
