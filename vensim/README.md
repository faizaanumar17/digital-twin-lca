# vensim/

Network-scale System Dynamics model built in Vensim.

## Files

| File | Description |
|---|---|
| `network_model.mdl` | Main Vensim model — 100 km network, budget-constrained rehabilitation |
| `scenarios/S0_baseline.cin` | Scenario control file: S0 Baseline |
| `scenarios/S1_low_budget.cin` | S1: Budget × 0.7 |
| `scenarios/S2_high_budget.cin` | S2: Budget × 1.3 |
| `scenarios/S3_plastic_push.cin` | S3: 40% PMA / 40% asphalt / 20% laterite mix |
| `scenarios/S4_laterite_heavy.cin` | S4: 50% laterite / 30% asphalt / 20% PMA |
| `scenarios/S5_enforcement.cin` | S5: WIM enforcement, ODM 1.0 → 0.6 |
| `scenarios/S6_combined.cin` | S6: S5 + S3 combined (recommended policy) |

## Model Structure

The model uses three stock categories per material:

```
Acceptable km (Asphalt)  ──→  Marginal km (Asphalt)  ──→  Backlog km
Acceptable km (Laterite) ──→  Marginal km (Laterite)
Acceptable km (PMA)      ──→  Marginal km (PMA)
```

Flows are driven by:
- **Deterioration rate**: TTL-derived from asset-layer outputs
- **Rehabilitation rate**: budget-constrained, overlay preferred over reconstruction

## Running

1. Open `network_model.mdl` in Vensim PLE (free) or Professional
2. Run baseline simulation
3. Load scenario `.cin` files via Simulation → Load
4. Export results to `../results/vensim/`

## Coupling Interface

The model receives these inputs from the MATLAB asset layer:

| Variable | Source | Description |
|---|---|---|
| `TTL_asphalt` | matlab output | Mean time-to-live, years |
| `TTL_laterite` | matlab output | Mean time-to-live, years |
| `TTL_PMA` | matlab output | Mean time-to-live, years |
| `cost_per_km_*` | matlab output | Unit rehabilitation cost £/km |
| `co2_per_km_*` | matlab output | Unit CO₂ t/km |

Download Vensim PLE free at: https://vensim.com/vensim-ple/
