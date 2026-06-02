# results/

Numerical outputs from the MATLAB asset-layer and Vensim network-layer analyses.

## File Inventory

### Asset-level time series (per material)

| File | Contents |
|---|---|
| `timeseries_asphalt.csv` | CI trajectory and cumulative cost/CO₂ over 20 yr (asphalt) |
| `timeseries_laterite.csv` | CI trajectory and cumulative cost/CO₂ over 20 yr (laterite) |
| `timeseries_plastic.csv` | CI trajectory and cumulative cost/CO₂ over 20 yr (PMA) |
| `events_asphalt.csv` | Intervention event log: year, type (overlay/reconstruction), cost, CO₂ |
| `events_laterite.csv` | As above for laterite |
| `events_plastic.csv` | As above for PMA |

### Asset-level Monte Carlo (per material)

| File | Contents |
|---|---|
| `mc_asphalt.csv` | N = 2,000 draws: NPV, whole-life CO₂, first-overlay year, TTL |
| `mc_laterite.csv` | As above for laterite |
| `mc_plastic.csv` | As above for PMA |

### Sensitivity & decision analysis

| File | Contents |
|---|---|
| `sensitivity_summary.csv` | Sobol S₁ and S_T indices for all parameters (N = 9,216) |
| `time_to_crisis.csv` | TTL distributions for each material |
| `intervention_frequency.csv` | Intervention counts and timing statistics |
| `breakeven_analysis.csv` | WIM payback period calculations (1.4–3.8 yr range) |
| `budget_threshold_sweep.csv` | Budget sweep showing non-binding region (S0=S1=S2 boundary at £346k/yr) |
| `initial_backlog_sensitivity.csv` | Robustness check — varying initial network condition |

### Network-level Vensim outputs (seven scenarios)

| File | Contents |
|---|---|
| `sd_S0_Baseline.csv` | Year-by-year stocks and flows: acceptable km, marginal km, backlog km, cum. cost, cum. CO₂ |
| `sd_S1_LowBudget.csv` | As above for budget × 0.7 |
| `sd_S2_HighBudget.csv` | As above for budget × 1.3 |
| `sd_S3_PlasticPush.csv` | As above for 40% PMA / 40% asphalt / 20% laterite mix |
| `sd_S4_LateriteHeavy.csv` | As above for 50% laterite / 30% asphalt / 20% PMA mix |
| `sd_S5_StrongEnforcement.csv` | As above for ODM 1.0 → 0.6 enforcement |
| `sd_S6_CombinedPolicy.csv` | As above for S5 + S3 combined (★ recommended) |

### Network-level Monte Carlo

| File | Contents |
|---|---|
| `network_mc_results.csv` | Raw network MC draws (final backlog, cum. cost, cum. CO₂ per draw, per scenario) |
| `network_mc_percentiles.csv` | Aggregated percentiles (5th, 50th, 95th) per scenario per metric |

### Configuration

| File | Contents |
|---|---|
| `config_used.json` | Parameter set used for this run — discount rate, climate factor, traffic ESALs, intervention thresholds, etc. Snapshot for reproducibility. |

---

## Key Summary Numbers

### Asset-scale (1 km, 20-year baseline)

| Material | NPV | Construction CO₂ | Whole-life CO₂ | First overlay |
|---|---|---|---|---|
| Asphalt | £99,872 | 195.9 t | 335.4 t | Year 10 |
| Laterite | £79,688 | 44.7 t | 236.7 t | Year 8 |
| PMA | £110,692 | 132.1 t | 253.9 t | Year 12 |

### Network-scale (100 km, Yr-20 backlog)

| Scenario | Yr-20 Backlog | Cum. Cost | Whole-life CO₂ |
|---|---|---|---|
| S0 Baseline | 17.05 km | £6.79M | 17,929 t |
| S1 Low-budget | 17.05 km | £6.79M | 17,929 t |
| S2 High-budget | 17.05 km | £6.79M | 17,929 t |
| S3 Plastic-push | 14.45 km | £6.94M | 17,179 t |
| S4 Laterite-heavy | 19.24 km | £6.04M | 16,507 t |
| S5 Enforcement | 12.60 km | £5.09M | 16,855 t |
| **S6 Combined** | **10.68 km** | **£5.26M** | **16,182 t** |

### Headline findings

- **Laterite Inversion** — asset-optimal material produces worst network backlog (S4 = 19.24 km vs S0 = 17.05 km)
- **Budget non-binding** — S0 = S1 = S2 identically above £346k/yr threshold (see `budget_threshold_sweep.csv`)
- **WIM payback** — 1.4–3.8 yr (see `breakeven_analysis.csv`); budget-equivalent benefit £88,481/yr per 100 km
- **EVPI for laterite TTL** — £78/km (see `time_to_crisis.csv` and asset-layer EVPI calculation)
- **MCDA robustness** — S6 ranks 1st in 100% of 10,000 Dirichlet weight draws
