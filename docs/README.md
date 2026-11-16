# docs

Project proposal, progress notes, final report and presentation, plus one folder per modulation scheme.

## Folders

| Folder | Contents |
|---|---|
| [`genel/`](genel/) | Diagrams common to all schemes: end-to-end BER simulation chain, Gray-coded QPSK / 16-QAM constellations |
| [`bfsk/`](bfsk/) | BFSK full-system, transmitter and correlator receiver diagrams, step-by-step MATLAB script, math (signal model → correlator → decision → BER) |
| [`qpsk/`](qpsk/) | QPSK transmitter (I/Q mapping) and receiver (two correlators, sign decisions), math, full-system figure |
| [`qam16/`](qam16/) | 16-QAM transmitter (Gray 4-PAM per axis) and receiver (4-level slicers), math, full-system figure |

Each scheme folder has a `README.md` that walks through the scheme step by step: transmitter → channel → receiver → decision → BER, with the matching `src/` functions. Every figure is stored as `.svg` (shown on GitHub) and `.png` at 2× (for the report).

## Overview

![End-to-end BER system](genel/end_to_end_ber_system.svg)
