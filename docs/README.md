# docs

Project proposal, progress notes, final report and presentation, plus one folder per modulation scheme.

## Folders

| Folder | Contents |
|---|---|
| [`genel/`](genel/) | Diagrams common to all schemes: end-to-end BER simulation chain, Gray-coded QPSK / 16-QAM constellations |
| [`bfsk/`](bfsk/) | BFSK full-system, transmitter and correlator receiver diagrams, step-by-step MATLAB script, math (signal model → correlator → decision → BER) |
| [`qpsk/`](qpsk/) | QPSK full-system, transmitter (I/Q mapping) and receiver (two correlators, sign decisions) diagrams, step-by-step MATLAB script, math |
| [`qam16/`](qam16/) | 16-QAM full-system, transmitter (Gray 4-PAM per axis) and receiver (4-level slicers) diagrams, step-by-step MATLAB script, math |

Each scheme folder has a `README.md` that walks through the scheme step by step: transmitter → channel → receiver → decision → BER, with the matching `src/` functions. Every figure is an `.svg` with a `_dark.svg` twin; the READMEs use `<picture>` so GitHub shows the one that matches your light/dark theme.

## Overview

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="genel/end_to_end_ber_system_dark.svg">
  <img alt="End-to-end BER system" src="genel/end_to_end_ber_system.svg">
</picture>
