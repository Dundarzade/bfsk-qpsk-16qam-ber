"""Generate light/dark SVG diagrams for the hardware/ folder."""
import os, sys

OUT = sys.argv[1]

LIGHT = dict(bg="none", line="#444441", text="#444441", sub="#5F5E5A", frame="#888780",
             g_fill="#F1EFE8", g_st="#5F5E5A",
             p_fill="#EEEDFE", p_st="#534AB7", p_tx="#3C3489",
             t_fill="#E1F5EE", t_st="#0F6E56", t_tx="#085041",
             c_fill="#FAECE7", c_st="#993C1D", c_tx="#712B13",
             y_fill="#FAEEDA", y_st="#854F0B", y_tx="#633806",
             wire_sig="#534AB7", wire_gnd="#444441", wire_noise="#993C1D", wire_clk="#0F6E56")
DARK = dict(bg="#0d1117", line="#C9C7BE", text="#E6E4DC", sub="#B4B2A9", frame="#6E6D66",
            g_fill="#2C2C2A", g_st="#B4B2A9",
            p_fill="#26215C", p_st="#AFA9EC", p_tx="#CECBF6",
            t_fill="#04342C", t_st="#5DCAA5", t_tx="#9FE1CB",
            c_fill="#4A1B0C", c_st="#F0997B", c_tx="#F5C4B3",
            y_fill="#412402", y_st="#EF9F27", y_tx="#FAC775",
            wire_sig="#AFA9EC", wire_gnd="#C9C7BE", wire_noise="#F0997B", wire_clk="#5DCAA5")


class S:
    def __init__(s, w, h, title, desc, C):
        s.C = C
        s.o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" font-family="Helvetica, Arial, sans-serif">',
               f'<title>{title}</title><desc>{desc}</desc>',
               f'<defs><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M2 1L8 5L2 9" fill="none" stroke="{C["line"]}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></marker></defs>']
        if C["bg"] != "none":
            s.o.append(f'<rect width="{w}" height="{h}" fill="{C["bg"]}"/>')

    def box(s, x, y, w, h, t1, t2=None, k="g", t3=None):
        C = s.C
        fill, st = C[k + "_fill"], C[k + "_st"]
        tx = C.get(k + "_tx", C["text"])
        s.o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="{st}" stroke-width="0.8"/>')
        lines = [l for l in (t1, t2, t3) if l]
        n = len(lines)
        cy = y + h / 2 - (n - 1) * 10
        for i, l in enumerate(lines):
            fs, fw, col = (14, 500, tx) if i == 0 else (12, 400, st)
            s.o.append(f'<text x="{x + w / 2}" y="{cy + i * 20}" font-size="{fs}" font-weight="{fw}" fill="{col}" text-anchor="middle" dominant-baseline="central">{l}</text>')

    def frame(s, x, y, w, h, label):
        C = s.C
        s.o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="none" stroke="{C["frame"]}" stroke-width="1" stroke-dasharray="6 4"/>')
        s.o.append(f'<text x="{x + 14}" y="{y + 18}" font-size="14" font-weight="500" fill="{C["sub"]}" dominant-baseline="central">{label}</text>')

    def arrow(s, pts, col=None, dash=False, w=1.2):
        col = col or s.C["line"]
        d = "M" + " L".join(f"{a} {b}" for a, b in pts)
        da = ' stroke-dasharray="5 4"' if dash else ""
        s.o.append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}"{da} marker-end="url(#arrow)"/>')

    def wire(s, pts, col=None, w=1.6, dash=False):
        col = col or s.C["line"]
        d = "M" + " L".join(f"{a} {b}" for a, b in pts)
        da = ' stroke-dasharray="5 4"' if dash else ""
        s.o.append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}"{da} stroke-linejoin="round"/>')

    def dot(s, x, y, col=None):
        s.o.append(f'<circle cx="{x}" cy="{y}" r="3.5" fill="{col or s.C["line"]}"/>')

    def text(s, x, y, t, size=12, anchor="start", col=None, weight=400):
        s.o.append(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{col or s.C["sub"]}" text-anchor="{anchor}" dominant-baseline="central">{t}</text>')

    def resistor(s, x, y, horiz=True, label="", col=None):
        """Zigzag resistor, 40 px long, starting at (x,y)."""
        col = col or s.C["line"]
        if horiz:
            pts = [(x, y), (x + 5, y), (x + 8, y - 6), (x + 14, y + 6), (x + 20, y - 6), (x + 26, y + 6), (x + 32, y - 6), (x + 35, y), (x + 40, y)]
            lx, ly = x + 20, y - 16
        else:
            pts = [(x, y), (x, y + 5), (x - 6, y + 8), (x + 6, y + 14), (x - 6, y + 20), (x + 6, y + 26), (x - 6, y + 32), (x, y + 35), (x, y + 40)]
            lx, ly = x + 12, y + 20
        s.wire(pts, col, 1.4)
        if label:
            s.text(lx, ly, label, 12, "middle" if horiz else "start", s.C["text"])

    def cap_to_gnd(s, x, y, label=""):
        """Capacitor from (x,y) down to ground."""
        c = s.C["line"]
        s.wire([(x, y), (x, y + 14)], c, 1.4)
        s.wire([(x - 10, y + 14), (x + 10, y + 14)], c, 2)
        s.wire([(x - 10, y + 20), (x + 10, y + 20)], c, 2)
        s.wire([(x, y + 20), (x, y + 32)], c, 1.4)
        s.gnd(x, y + 32)
        if label:
            s.text(x + 14, y + 17, label, 12, "start", s.C["text"])

    def gnd(s, x, y):
        c = s.C["line"]
        s.wire([(x - 10, y), (x + 10, y)], c, 1.6)
        s.wire([(x - 6, y + 4), (x + 6, y + 4)], c, 1.4)
        s.wire([(x - 2, y + 8), (x + 2, y + 8)], c, 1.2)

    def pin(s, x, y, name, side="r"):
        """Pin label on a chip edge; side r = pin on right edge."""
        c = s.C["text"]
        if side == "r":
            s.text(x - 8, y, name, 12, "end", c)
        else:
            s.text(x + 8, y, name, 12, "start", c)
        s.dot(x, y, s.C["line"])

    def save(s, path):
        s.o.append("</svg>")
        open(path, "w", encoding="utf-8").write("\n".join(s.o) + "\n")


# ---------------------------------------------------------------- 1. system
def system(C):
    s = S(980, 600, "ESP32 tabanlı kablolu modem: iki düğüm arasında BFSK / QPSK / 16-QAM",
          "Her ESP32 butonlardan veya rastgele üreteçten gelen bitleri sembole çevirir, DAC ile analog dalga üretir; dalga RC filtre ve gürültü toplayıcıdan geçip karşı kartın ADC girişine ulaşır; alıcı korelasyonla bitleri çözer ve LED, seri port veya MATLAB'a verir.", C)
    # Node A
    s.frame(20, 30, 330, 330, "ESP32 A  (verici)")
    s.box(40, 70, 130, 56, "Butonlar", "4 bit + gönder", "y")
    s.box(190, 70, 140, 56, "PRBS üreteci", "BER testi için", "y")
    s.arrow([(105, 126), (105, 150), (185, 150), (185, 162)])
    s.arrow([(260, 126), (260, 150), (185, 150)])
    s.box(60, 164, 250, 56, "Sembol eşleme", "BFSK: ton · QPSK: faz · 16-QAM: I/Q", "p")
    s.arrow([(185, 220), (185, 242)])
    s.box(60, 244, 250, 56, "Örnek üretimi (fs = 8 kHz)", "sin/cos tablosu, fc = 1 kHz", "p")
    s.arrow([(185, 300), (185, 318)])
    s.box(110, 320, 150, 30, "DAC1 (GPIO25)", None, "t")
    # Channel
    s.frame(370, 30, 240, 330, "Kanal  (breadboard)")
    s.arrow([(260, 335), (380, 335), (380, 190), (398, 190)])
    s.box(400, 150, 190, 80, "MCP6002 toplayıcı", "sinyal + gürültü, kazanç −1", "g", "fc ≈ 4.8 kHz, çıkış 1.65 V ± …")
    s.box(400, 280, 190, 56, "Gürültü kaynağı", "DAC2 (GPIO26), Eb/N0 ayarı", "c")
    s.arrow([(495, 280), (495, 232)])
    # Node B
    s.frame(630, 30, 330, 330, "ESP32 B  (alıcı)")
    s.arrow([(590, 190), (650, 190), (650, 82), (668, 82)])
    s.box(670, 66, 150, 30, "ADC1_CH6 (GPIO34)", None, "t")
    s.arrow([(795, 96), (795, 118)])
    s.box(670, 120, 250, 56, "Örnekleme (fs = 8 kHz, DMA)", "12 bit, DC ofset çıkarılır", "p")
    s.arrow([(795, 176), (795, 198)])
    s.box(670, 200, 250, 56, "Korelatör bankası", "sin/cos ile çarp, sembol boyunca topla", "p")
    s.arrow([(795, 256), (795, 278)])
    s.box(670, 280, 250, 56, "Karar + bit hatası sayacı", "BFSK: |z1|≷|z0| · QPSK/QAM: kesici", "p")
    # sync line
    s.wire([(330, 98), (350, 98)], C["wire_clk"], 1.4, True)
    s.wire([(350, 98), (350, 20), (940, 20), (940, 150), (920, 150)], C["wire_clk"], 1.4, True)
    s.text(645, 12, "isteğe bağlı sembol saati kablosu (GPIO18 → GPIO19)", 12, "middle", C["t_st"])
    # outputs
    s.frame(20, 390, 940, 190, "Çıktılar ve ölçüm")
    s.arrow([(795, 336), (795, 420)])
    s.box(640, 422, 300, 56, "4 LED + seri port", "çözülen bitler, anlık BER", "y")
    s.box(330, 422, 280, 56, "USB seri → MATLAB", "ham ADC örnekleri, takımyıldız", "t")
    s.arrow([(640, 450), (612, 450)])
    s.box(40, 422, 260, 56, "Ölçülen BER – Eb/N0", "src/ simülasyonu + teori ile kıyas", "g")
    s.arrow([(330, 450), (302, 450)])
    s.text(490, 520, "Ters yön (B → A) aynı yapının ayna kopyası: B'nin GPIO25'i → A'nın GPIO34'ü.", 13, "middle", C["text"])
    s.text(490, 546, "Tüm kartlarda GND ortak bağlanır.", 13, "middle", C["text"])
    return s


# ---------------------------------------------------------------- 2. wiring
def wiring(C):
    s = S(1000, 700, "ESP32 modem breadboard bağlantı şeması",
          "Verici kartın GPIO25 DAC çıkışı 1 kΩ ve 47 nF RC filtreden, ardından 10 kΩ ile toplama düğümüne gider; GPIO26 gürültü DAC'ı ayrı bir 10 kΩ ile aynı düğüme bağlanır; düğüm 100 nF ile kuplajlanıp 2×100 kΩ bölücüyle 1.65 V'a oturtulur ve alıcı kartın GPIO34 ADC girişine gider. Butonlar ve LED'ler alt kısımda.", C)
    sig, nz, clk = C["wire_sig"], C["wire_noise"], C["wire_clk"]
    # ESP32 A chip
    s.o.append(f'<rect x="40" y="60" width="180" height="300" rx="10" fill="{C["g_fill"]}" stroke="{C["g_st"]}" stroke-width="1"/>')
    s.text(130, 80, "ESP32 A", 15, "middle", C["text"], 600)
    s.text(130, 100, "DevKit (WROOM-32)", 12, "middle")
    for y, n in [(140, "GPIO25 · DAC1"), (200, "GPIO26 · DAC2"), (260, "GPIO18 · sembol saati"), (330, "GND")]:
        s.pin(220, y, n, "r")
    # ESP32 B chip
    s.o.append(f'<rect x="780" y="60" width="180" height="300" rx="10" fill="{C["g_fill"]}" stroke="{C["g_st"]}" stroke-width="1"/>')
    s.text(870, 80, "ESP32 B", 15, "middle", C["text"], 600)
    s.text(870, 100, "DevKit (WROOM-32)", 12, "middle")
    for y, n in [(170, "GPIO34 · ADC1_CH6"), (260, "GPIO19 · sembol saati"), (330, "GND")]:
        s.pin(780, y, n, "l")
    c = C["line"]
    # op-amp block
    s.box(380, 115, 240, 110, "U1: MCP6002 toplayıcı", "eviren toplayıcı + alçak geçiren", "p", "ayrıntı: esp32_opamp.svg")
    s.wire([(220, 140), (380, 140)], sig)
    s.text(300, 130, "sinyal", 12, "middle", C["p_st"])
    s.wire([(220, 200), (380, 200)], nz)
    s.text(300, 190, "gürültü", 12, "middle", C["c_st"])
    s.wire([(620, 170), (680, 170)], sig)
    s.resistor(680, 170, True, "R8 100 Ω", sig)
    s.wire([(720, 170), (780, 170)], sig)
    s.text(500, 100, "3V3 ve GND: ESP32 A'dan", 12, "middle")
    s.text(700, 290, "çıkış 1.65 V etrafında, doğrudan ADC'ye", 12, "middle")
    # clock
    s.wire([(220, 260), (780, 260)], clk, 1.4, True)
    s.text(500, 250, "isteğe bağlı: sembol saati (QPSK / 16-QAM senkronu)", 12, "middle", C["t_st"])
    # gnd
    s.wire([(220, 330), (780, 330)], C["wire_gnd"], 2)
    s.text(500, 320, "ortak GND (zorunlu)", 12, "middle", C["text"], 500)
    # notes on levels
    s.frame(260, 380, 480, 60, "")
    s.text(500, 398, "DAC orta noktası 128 kod ≈ 1.65 V; sinyal + gürültü tepesi ±1.2 V'u geçmesin", 12, "middle", C["text"])
    s.text(500, 420, "U1 için 100 nF dekuplaj kondansatörü VDD–GND arasına, entegreye yakın", 12, "middle", C["text"])
    # buttons
    s.frame(40, 470, 440, 200, "Kullanıcı arayüzü (her iki kartta aynı)")
    xs = [80, 160, 240, 320, 400]
    names = ["GPIO32", "GPIO33", "GPIO27", "GPIO14", "GPIO13"]
    roles = ["bit 0", "bit 1", "bit 2", "bit 3", "gönder / mod"]
    for x, n, r in zip(xs, names, roles):
        s.text(x, 510, n, 12, "middle", C["text"], 500)
        s.wire([(x, 520), (x, 560)], c, 1.4)
        s.wire([(x - 12, 560), (x + 12, 556)], c, 1.6)
        s.dot(x - 12, 568, c); s.dot(x + 12, 568, c)
        s.wire([(x, 568 + 0), (x, 568)], c, 1)
        s.wire([(x - 12, 568), (x - 12, 590)], c, 1.4)
        s.gnd(x - 12, 590)
        s.text(x, 620, r, 12, "middle")
    s.text(260, 650, "INPUT_PULLUP: basınca pin GND'ye çekilir, harici direnç yok", 12, "middle")
    # LEDs
    s.frame(520, 470, 440, 200, "Çözülen bit LED'leri")
    lx = [560, 640, 720, 800, 880]
    ln = ["GPIO4", "GPIO16", "GPIO17", "GPIO5", "GPIO2"]
    lr = ["bit 0", "bit 1", "bit 2", "bit 3", "hata (dahili)"]
    for x, n, r in zip(lx, ln, lr):
        s.text(x, 510, n, 12, "middle", C["text"], 500)
        s.wire([(x, 520), (x, 528)], c, 1.4)
        s.resistor(x, 528, False, "", c)
        s.wire([(x, 568), (x, 572)], c, 1.4)
        s.o.append(f'<path d="M{x-8} 572 L{x+8} 572 L{x} 586 Z" fill="{C["y_fill"]}" stroke="{C["y_st"]}" stroke-width="1"/>')
        s.wire([(x - 8, 586), (x + 8, 586)], c, 1.6)
        s.wire([(x, 586), (x, 596)], c, 1.4)
        s.gnd(x, 596)
        s.text(x, 620, r, 12, "middle")
    s.text(740, 650, "her LED'e seri 330 Ω", 12, "middle")
    return s


# ---------------------------------------------------------------- 3. op-amp
def opamp_tri(s, x, y, label):
    """Op-amp triangle; (x,y) = left edge centre, 100 wide, 100 tall. - input top."""
    C = s.C
    s.o.append(f'<path d="M{x} {y-50} L{x} {y+50} L{x+100} {y} Z" fill="{C["p_fill"]}" stroke="{C["p_st"]}" stroke-width="1.2"/>')
    s.text(x + 10, y - 25, "−", 16, "start", C["p_tx"], 600)
    s.text(x + 10, y + 25, "+", 16, "start", C["p_tx"], 600)
    s.text(x + 40, y, label, 12, "middle", C["p_tx"], 500)


def opamp(C):
    s = S(1000, 720, "MCP6002 ile eviren toplayıcı ve 1.65 V referans",
          "U1A eviren toplayıcıdır: GPIO25 sinyal DAC'ı ve GPIO26 gürültü DAC'ı 10 kΩ dirençlerle eviren girişe bağlanır, geri besleme 10 kΩ paralel 3.3 nF'tır; artı giriş U1B tamponundan gelen 1.65 V referanstır. Çıkış 100 Ω üzerinden alıcı ESP32'nin GPIO34 girişine gider.", C)
    sig, nz, c = C["wire_sig"], C["wire_noise"], C["line"]
    # inputs
    s.text(40, 170, "ESP32 A · GPIO25 (DAC1)", 13, "start", C["text"], 500)
    s.text(40, 250, "ESP32 A · GPIO26 (DAC2)", 13, "start", C["text"], 500)
    s.wire([(60, 185), (60, 200), (260, 200)], sig)
    s.resistor(260, 200, True, "R2 10 kΩ", sig)
    s.wire([(60, 265), (60, 280), (260, 280)], nz)
    s.resistor(260, 280, True, "R3 10 kΩ", nz)
    s.wire([(300, 200), (380, 200)], sig)
    s.wire([(300, 280), (340, 280), (340, 200)], nz)
    s.dot(340, 200, C["text"]); s.dot(380, 200, C["text"])
    s.text(300, 160, "Σ düğümü (sanal toprak = 1.65 V)", 11, "middle")
    # feedback
    s.wire([(380, 200), (380, 120)], c, 1.4)
    s.wire([(380, 120), (460, 120)], c, 1.4)
    s.resistor(460, 120, True, "Rf 10 kΩ", c)
    s.wire([(500, 120), (580, 120)], c, 1.4)
    s.wire([(380, 120), (380, 70), (500, 70)], c, 1.4)
    s.wire([(500, 58), (500, 82)], c, 2); s.wire([(508, 58), (508, 82)], c, 2)
    s.text(504, 45, "Cf 3.3 nF", 12, "middle", C["text"])
    s.wire([(508, 70), (580, 70), (580, 120)], c, 1.4)
    s.dot(380, 120, c); s.dot(580, 120, c)
    s.wire([(580, 120), (580, 225)], c, 1.4)
    # U1A
    s.wire([(380, 200), (420, 200)], sig)
    opamp_tri(s, 420, 225, "U1A")
    s.wire([(420, 250), (400, 250), (400, 330)], c, 1.4)
    s.text(392, 340, "+ giriş ← VREF", 11, "end")
    s.dot(520, 225, c)
    s.wire([(520, 225), (580, 225)], sig)
    s.dot(580, 225, sig)
    s.wire([(580, 225), (660, 225)], sig)
    s.resistor(660, 225, True, "R8 100 Ω", sig)
    s.wire([(700, 225), (780, 225)], sig)
    s.text(790, 218, "→ ESP32 B · GPIO34", 13, "start", C["text"], 500)
    s.text(790, 238, "(ADC1_CH6)", 12, "start")
    s.text(640, 255, "VOUT", 12, "middle", C["p_st"], 500)
    # VREF: divider + U1B follower
    s.text(130, 380, "3V3", 12, "middle", C["text"], 500)
    s.wire([(120, 390), (140, 390)], c, 1.6)
    s.wire([(130, 390), (130, 400)], c, 1.2)
    s.resistor(130, 400, False, "R6 10 kΩ", c)
    s.wire([(130, 440), (130, 450)], c, 1.2)
    s.dot(130, 450, c)
    s.resistor(130, 455, False, "R7 10 kΩ", c)
    s.wire([(130, 450), (130, 455)], c, 1.2)
    s.wire([(130, 495), (130, 505)], c, 1.2); s.gnd(130, 505)
    s.wire([(130, 450), (230, 450)], c, 1.2)
    s.dot(230, 450, c)
    s.cap_to_gnd(230, 450, "C3 1 µF")
    s.wire([(230, 450), (300, 450), (300, 480), (340, 480)], c, 1.2)
    opamp_tri(s, 340, 455, "U1B")
    s.wire([(440, 455), (470, 455)], c, 1.4)
    s.dot(470, 455, c)
    s.wire([(470, 455), (470, 390), (320, 390), (320, 430), (340, 430)], c, 1.4)
    s.text(395, 380, "gerilim izleyici (kazanç 1)", 11, "middle")
    s.wire([(470, 455), (520, 455), (520, 330), (400, 330)], c, 1.4)
    s.text(530, 455, "VREF = 1.65 V", 12, "start", C["text"], 500)
    # supply / decoupling
    s.frame(640, 300, 330, 210, "Besleme ve pinler (MCP6002, DIP-8)")
    pins = [("1 OUTA", "8 VDD (3V3)"), ("2 INA−", "7 OUTB"), ("3 INA+", "6 INB−"), ("4 VSS (GND)", "5 INB+")]
    s.o.append(f'<rect x="740" y="335" width="130" height="110" rx="6" fill="{C["g_fill"]}" stroke="{C["g_st"]}" stroke-width="1"/>')
    s.text(805, 350, "MCP6002", 12, "middle", C["text"], 600)
    for i, (l, r) in enumerate(pins):
        y = 370 + i * 20
        s.text(735, y, l, 11, "end", C["text"]); s.text(875, y, r, 11, "start", C["text"])
    s.text(805, 470, "VDD–VSS arasına 100 nF, pinlere yakın", 12, "middle")
    s.text(805, 490, "3V3 ve GND: ESP32 A'dan", 12, "middle")
    # equations
    s.frame(30, 540, 940, 160, "Denklemler")
    s.text(50, 585, "VOUT = VREF − (Rf/R2)·(V_DAC1 − VREF) − (Rf/R3)·(V_DAC2 − VREF)     →  Rf = R2 = R3 olduğundan: VOUT − 1.65 = −(s(t) + n(t))", 13, "start", C["text"])
    s.text(50, 613, "fc = 1 / (2π·Rf·Cf) = 1 / (2π · 10 kΩ · 3.3 nF) ≈ 4.8 kHz   →   1 kHz ve 2 kHz tonları geçer, 8 kHz DAC basamakları yumuşar", 13, "start", C["text"])
    s.text(50, 641, "Eviren yapı sinyali 180° çevirir: BFSK'da önemsiz, QPSK / 16-QAM'de preamble ile ölçülen faza zaten dahil olur", 13, "start", C["text"])
    s.text(50, 669, "DAC'lar 128 kodda (≈1.65 V) dururken VOUT = 1.65 V: kuplaj kondansatörü ve ofset bölücüsü gerekmez", 13, "start", C["text"])
    return s


os.makedirs(OUT, exist_ok=True)
for name, fn in [("esp32_sistem", system), ("esp32_baglanti", wiring), ("esp32_opamp", opamp)]:
    fn(LIGHT).save(os.path.join(OUT, f"{name}.svg"))
    fn(DARK).save(os.path.join(OUT, f"{name}_dark.svg"))
print("ok")
