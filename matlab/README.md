# matlab/

Asset-scale LCA and Monte Carlo simulation scripts.

## Files

| File | Description |
|---|---|
| `main_run.m` | Master script — runs full asset-scale analysis for all three materials |
| `deterioration_model.m` | CI deterioration function with climate and overload multipliers |
| `lca_cost.m` | NPV cost calculation with intervention logic |
| `lca_carbon.m` | Whole-life CO₂ calculation (construction + use-phase) |
| `monte_carlo_run.m` | N=2,000 Monte Carlo loop with parameter sampling |
| `sobol_analysis.m` | Sobol variance decomposition (N=9,216, Saltelli method) |
| `plot_figures.m` | Figure generation for dissertation and poster |

## Running

```matlab
% From MATLAB command window, with this folder on the path:
run('main_run.m')
```

Outputs are written to `../results/matlab/`.

## Notes

- MATLAB R2022a or later required
- No additional toolboxes required beyond base MATLAB
- Monte Carlo runs take approximately 2–5 minutes depending on hardware
- Sobol analysis (N=9,216) takes approximately 10–20 minutes
