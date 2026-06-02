# Digital-Twin-Enabled Life-Cycle Assessment of Sustainable Pavement Materials for Nigerian Roads

**Faizaan Umar** · fu1e22@soton.ac.uk  
FEEG3003 Individual Project · University of Southampton · June 2026  
Supervised by Dr Paul Kemp, Faculty of Engineering & Physical Sciences

---

## Overview

This repository contains all research outputs, models, and code for an individual project that couples asset-scale Life-Cycle Assessment (LCA) with network-scale System Dynamics (SD) to evaluate sustainable pavement materials for Nigerian roads.

The central finding is **The Laterite Inversion**: laterite — the lowest-cost, lowest-CO₂ material at single-asset scale — becomes the *worst* network performer when adopted at scale, due to its short time-to-live overwhelming rehabilitation queue capacity. This trade-off is invisible to conventional single-scale LCA and only emerges through digital-twin coupling.

---

## Key Results

| Metric | Best material (asset scale) | Worst network scenario |
|---|---|---|
| 20-yr NPV | Laterite £79,688 | S4 laterite-heavy: 19.24 km backlog |
| Whole-life CO₂ | Laterite 236.7 t | S4 +13% vs baseline |
| Service life | PMA (Yr 12 first overlay) | S0=S1=S2 identically (budget non-binding) |

**Recommended policy:** S6 Combined — WIM axle-load enforcement + 40% PMA / 40% asphalt / 20% laterite mix. Achieves −37% Yr-20 backlog, payback 1.4–3.8 yr, ranks 1st in 100% of 10,000 MCDA weight draws.

---

## Repository Structure

```
digital-twin-lca/
│
├── dissertation/          # Full dissertation PDF
│   └── README.md
│
├── matlab/                # Asset-scale LCA and Monte Carlo scripts
│   └── README.md
│
├── vensim/                # Network-scale System Dynamics model
│   └── README.md
│
├── figures/               # All dissertation figures (PNG, high-res)
│   └── README.md
│
├── results/               # Raw Monte Carlo, Sobol and MCDA outputs
│   └── README.md
│
├── poster/                # A1 poster PPTX and PDF
│   └── README.md
│
├── .gitignore
├── LICENSE
└── README.md              ← you are here
```

---

## Methodology

The study uses a **two-layer digital twin**:

**Layer 1 — MATLAB (Asset Scale)**
- 1 km road section · 20-year horizon
- Condition Index deterioration with climate and overload multipliers
- N = 2,000 Monte Carlo runs per material
- Outputs: TTL, unit cost (£/km), unit CO₂ (t/km)

**Layer 2 — Vensim (Network Scale)**
- 100 km network · 20-year horizon · 7 policy scenarios
- System Dynamics with budget-constrained rehabilitation queue
- Stocks: Acceptable km (×3 materials) + Backlog km
- Sobol variance decomposition: N = 9,216 (Saltelli method)
- MCDA robustness: N = 10,000 Dirichlet weight draws

**One-way coupling:** asset-layer unit outputs (TTL, £/km, t CO₂/km) feed into the network model. No congestion-condition feedback (acknowledged limitation; future work).

---

## Three Knowledge Contributions

1. **The Laterite Inversion** — best asset-scale material produces worst network outcome. TTL = 3.33 yr at network scale overwhelms rehabilitation capacity. Inaccessible from single-scale LCA.

2. **Budget Non-Binding** — S0 = S1 = S2 identically on all four metrics. Deterioration rate, not expenditure, is the binding constraint. Policy should redirect resources to enforcement, not additional rehabilitation contracts.

3. **Multiplicative CO₂ Uncertainty** — k_climate × α interaction accounts for 91% of asphalt CO₂ variance. OAT sensitivity methods systematically understate uncertainty in tropical overloading contexts. Sobol decomposition is necessary.

---

## Materials Compared

| Material | Description |
|---|---|
| Conventional asphalt | Standard hot-mix bituminous pavement |
| Sealed laterite | Locally available iron-rich gravel with bituminous chip-seal surface |
| Plastic-modified asphalt (PMA) | Hot-mix asphalt with recycled HDPE polymer modifier |

---

## How to Reproduce

### MATLAB (Asset-scale LCA)
```matlab
% Set poster-scale figure defaults (for regenerating figures)
set(groot,'defaultAxesFontSize', 22)
set(groot,'defaultTextFontSize', 22)
set(groot,'defaultLegendFontSize', 18)
set(groot,'defaultAxesLineWidth', 1.5)
set(groot,'defaultLineLineWidth', 2.5)

% Run main analysis
run('matlab/main_run.m')
```

### Vensim (Network-scale SD)
Open `vensim/network_model.mdl` in Vensim PLE or Professional.  
Run baseline simulation, then load scenario files from `vensim/scenarios/`.

---

## Dependencies

- MATLAB R2022a or later
- Vensim PLE (free) or Professional — [vensim.com](https://vensim.com)
- Python 3.10+ (for figure post-processing, optional)

---

## Citation

If you use this work, please cite:

```
Umar, F. (2026). Digital-Twin-Enabled Life-Cycle Assessment of Sustainable
Pavement Materials for Nigerian Roads. Individual Project, FEEG3003,
University of Southampton.
https://github.com/faizaanumar17/digital-twin-lca
```

---

## Licence

This work is licensed under the [MIT Licence](LICENSE). You are free to use, adapt, and build on this work with attribution.

---

## Contact

Faizaan Umar · fu1e22@soton.ac.uk  
University of Southampton, UK
