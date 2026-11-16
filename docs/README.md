# docs

Project proposal, progress notes, final report and presentation.

## Theory notes

Signal model, receiver equations, decision rule and BER formula for each scheme, linked to the functions in `src/`:

- [theory/bfsk.md](theory/bfsk.md)
- [theory/qpsk.md](theory/qpsk.md)
- [theory/qam16.md](theory/qam16.md)

## Figures

Every figure is in `figures/` as `.svg` (for GitHub) and `.png` at 2× (for the report).

| File | Shows |
|---|---|
| `end_to_end_ber_system` | Whole simulation chain: bits → mapping → modulator → AWGN → demodulator → decision → bits → BER, repeated per Eb/N0 |
| `constellations_gray` | Gray-coded QPSK and 16-QAM constellations |
| `bfsk_correlation_receiver` | BFSK correlator receiver, decision on the sign of z₁ − z₂ |
| `qpsk_system` | QPSK transmitter (I/Q mapping, cos / −sin carriers) and receiver (two correlators, sign decisions) |
| `qam16_system` | 16-QAM transmitter (Gray 4-PAM per axis) and receiver (two correlators, 4-level slicers) |

![End-to-end BER system](figures/end_to_end_ber_system.svg)
