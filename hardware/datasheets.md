# Datasheets and op-amp comparison

The summer runs from the ESP32's **3.3 V** rail with no negative supply, and its output sits at 1.65 V ± about 1.2 V. So the op-amp must:

1. work from a single 3.3 V supply,
2. accept inputs at 1.65 V (mid-supply) and swing its output from about 0.45 V to 2.85 V, which means **rail-to-rail input and output** in practice,
3. be fast enough: a 2 kHz tone with 1.2 V peak needs a slew rate of 2π · 2000 · 1.2 ≈ 0.015 V/µs. At gain −1 the closed-loop bandwidth is about GBW / 2, so even 1 MHz GBW gives ~500 kHz, far above our 4.8 kHz corner.

Point 3 is easy for every candidate. Points 1 and 2 decide the choice.

## Comparison

| | **MCP6002** | TLV9002 | OPA2340 | LM358 | TL072 |
|---|---|---|---|---|---|
| Maker | Microchip | TI | TI | TI / ST / others | TI / ST |
| Single supply | 1.8–6 V | 1.8–5.5 V | 2.7–5.5 V | 3–30 V | 6–36 V (ST) / 7 V min (TI) |
| Rail-to-rail | In + out | In + out | In + out (out within 1 mV, 100 kΩ load) | No: in and out only up to VCC − 1.5 V | No |
| GBW (typ) | 1 MHz | 1 MHz | 5.5 MHz | 0.7 MHz | 3 MHz |
| Slew rate (typ) | 0.6 V/µs | — | 6 V/µs | — | 13 V/µs |
| Offset voltage | 4.5 mV max | ±0.4 mV typ | 0.5 mV max | 2 mV typ | 6 mV max |
| Quiescent current | ~100 µA | 60 µA/ch | 750 µA/ch | 0.7 mA | 1.4 mA |
| DIP-8 for breadboard | Yes (MCP6002-I/P) | No (SOIC/SOT, needs an adapter) | Yes (OPA2340PA) | Yes | Yes |
| Works at 3.3 V here? | ✅ | ✅ | ✅ | ❌ | ❌ |

### Why not LM358 or TL072

- **LM358:** at 3.3 V both the input common-mode range and the output top out at about 3.3 − 1.5 = 1.8 V. Our signal is centred at 1.65 V and swings up to 2.85 V, so the top half would clip.
- **TL072:** needs at least 6–7 V total supply and its output does not get near the rails. It cannot run from the ESP32's 3.3 V at all.

Both are fine op-amps, just not at 3.3 V single supply.

### Choice: MCP6002

It meets the requirements, comes in DIP-8 so it plugs straight into the breadboard, is common and cheap, and one package holds both the summer (U1A) and the reference buffer (U1B). The 4.5 mV max offset is irrelevant here: the receiver removes the DC level in software anyway.

**Alternatives:** OPA2340PA if MCP6002 is not in stock (also DIP-8, RRIO, more expensive). TLV9002 only with a SOIC-to-DIP adapter.

## Datasheet links

| Part | Link |
|---|---|
| MCP6002 | [Microchip product page + datasheet (DS21733)](https://www.microchip.com/en-us/product/MCP6002) |
| TLV9002 | [TI datasheet (SBOS833)](https://www.ti.com/lit/gpn/tlv9002) |
| OPA2340 | [TI product page + datasheet (SBOS073)](https://www.ti.com/product/OPA2340) |
| LM358 | [TI datasheet](https://www.ti.com/lit/gpn/lm358) · [ST datasheet (DocID2163)](https://www.farnell.com/datasheets/1862552.pdf) |
| TL072 | [TI product page + datasheet (SLOS080)](https://www.ti.com/product/TL072) |
| ESP32 | [Espressif ESP32 datasheet](https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf) · [DAC API (ESP-IDF)](https://docs.espressif.com/projects/esp-idf/en/stable/api-reference/peripherals/dac.html) |

Values above are from the datasheets and distributor summaries (Nov 2026). Blank cells were not checked; look them up in the datasheet before relying on them.
