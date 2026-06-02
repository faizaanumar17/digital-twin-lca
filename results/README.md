# results/

Raw numerical outputs from the MATLAB and Vensim analyses.

## Structure

```
results/
├── matlab/
│   ├── asset_baseline.csv        # Asset-scale baseline results (3 materials)
│   ├── monte_carlo_npv.csv       # N=2,000 NPV draws per material
│   ├── monte_carlo_co2.csv       # N=2,000 CO₂ draws per material
│   ├── monte_carlo_ttl.csv       # N=2,000 TTL draws per material
│   ├── sobol_indices.csv         # S₁ and S_T for all parameters
│   └── mcda_rankings.csv         # 10,000 Dirichlet weight MCDA results
│
└── vensim/
    ├── S0_baseline.csv           # Yr-20 backlog, cum. cost, cum. CO₂
    ├── S1_low_budget.csv
    ├── S2_high_budget.csv
    ├── S3_plastic_push.csv
    ├── S4_laterite_heavy.csv
    ├── S5_enforcement.csv
    └── S6_combined.csv
```

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
