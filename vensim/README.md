# vensim/

Network-scale System Dynamics model built in Vensim.

## File

| File | Description |
|---|---|
| `VENSIM MODEL.mdl` | Network model — 100 km road network, 20-year horizon, budget-constrained rehabilitation |

## Model Structure

Three stock categories per material (asphalt, laterite, PMA):

```
Acceptable km  ──→  Marginal km  ──→  Backlog km
                                          │
                                          ↓
                              Budget-constrained rehab flow
                                          │
                                          ↓
                              Acceptable km (refreshed)
```

Flows are driven by:
- **Deterioration rate**: derived from asset-layer TTL outputs (MATLAB → Vensim coupling)
- **Rehabilitation rate**: budget-constrained, overlay preferred over reconstruction
- **Overload damage multiplier (ODM)**: scenario-dependent

## Coupling Interface

The model receives these inputs from the MATLAB asset layer (via `../matlab/export_vensim_params.m`):

| Variable | Description |
|---|---|
| `TTL_asphalt` | Mean time-to-live, years |
| `TTL_laterite` | Mean time-to-live, years |
| `TTL_PMA` | Mean time-to-live, years |
| `cost_per_km_*` | Unit rehabilitation cost £/km, per material |
| `co2_per_km_*` | Unit CO₂ tonnes/km, per material |

## Scenarios

The seven policy scenarios are configured by adjusting parameters directly in the model:

| Scenario | Lever | Setting |
|---|---|---|
| S0 | Baseline | 100% asphalt mix, ODM = 1.0, calibrated budget |
| S1 | Low budget | Budget × 0.7 |
| S2 | High budget | Budget × 1.3 |
| S3 | Plastic-push | 40% PMA / 40% asphalt / 20% laterite |
| S4 | Laterite-heavy | 50% laterite / 30% asphalt / 20% PMA |
| S5 | Strong enforcement | ODM reduced 1.0 → 0.6 |
| S6 | Combined policy ★ | S5 enforcement + S3 mix |

## Running

1. Open `VENSIM MODEL.mdl` in Vensim PLE (free, [vensim.com/vensim-ple/](https://vensim.com/vensim-ple/)) or Vensim Professional
2. Set scenario parameters as listed in the table above
3. Run the simulation (default: 20-year horizon)
4. Export results — recorded values land in `../results/vensim/`

## Notes

- Vensim PLE is free and sufficient to open and run this model
- Vensim Professional adds Monte Carlo, but the MC analysis in this project is done in MATLAB at asset scale and propagated via the unit outputs
