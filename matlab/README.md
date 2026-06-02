# matlab/

Asset-scale Life-Cycle Assessment and Monte Carlo simulation scripts.

## Script Organisation

### Entry point

| Script | Purpose |
|---|---|
| `main_run.m` | Master script — runs full asset-scale analysis for all three materials, calls all other modules in order |

### Configuration & inputs

| Script | Purpose |
|---|---|
| `config_base.m` | Baseline parameter set (discount rate, climate factor, time horizon, etc.) |
| `materials.m` | Material-specific properties for asphalt, laterite and PMA |
| `traffic_annual_esas.m` | Annual ESAL (Equivalent Single Axle Load) traffic model |

### Core simulation engine

| Script | Purpose |
|---|---|
| `simulate_section.m` | Simulates a single 1 km road section over 20 years |
| `deterioration_step.m` | Computes CI deterioration per year given traffic, climate, overload |
| `maintenance_trigger.m` | Decision logic — when CI drops below thresholds, schedules overlay or reconstruction |
| `apply_intervention.m` | Applies a scheduled intervention, restores CI, logs the event |
| `time_to_crisis.m` | Computes Time-To-Live (TTL) — years until CI hits intervention threshold |

### LCA cost and carbon

| Script | Purpose |
|---|---|
| `npv_series.m` | Net Present Value calculation across the cost time series |
| `event_cost_emissions.m` | Cost and CO₂ contribution from a single intervention event |
| `rrc_annual_co2.m` | Routine Road Carbon — annual use-phase CO₂ emissions |

### Uncertainty quantification

| Script | Purpose |
|---|---|
| `monte_carlo_run.m` | N = 2,000 Monte Carlo loop with parameter sampling |
| `sensitivity_run.m` | Sobol variance decomposition (N = 9,216, Saltelli method) |
| `willingness_to_pay.m` | Expected Value of Perfect Information (EVPI) calculation |

### Output & integration

| Script | Purpose |
|---|---|
| `summarize_outputs.m` | Aggregates Monte Carlo results into percentiles and summary statistics |
| `export_results.m` | Writes CSV files of all numerical outputs to `../results/matlab/` |
| `export_vensim_params.m` | Exports asset-layer unit outputs (TTL, £/km, t CO₂/km) for the Vensim network model |

---

## Running the analysis

```matlab
% From MATLAB command window, with this folder on the path:
run('main_run.m')
```

`main_run.m` calls everything else in the correct order. Outputs land in `../results/matlab/`.

The handoff to the network-scale Vensim model is via `export_vensim_params.m`, which writes the unit cost / unit CO₂ / mean TTL values that the SD model reads as inputs.

---

## Computational cost

- Single section simulation (20 years): seconds
- Full Monte Carlo (N = 2,000, three materials): 2–5 minutes
- Sobol sensitivity (N = 9,216, three materials): 10–20 minutes

Times vary with CPU.

---

## Regenerating figures for poster scale

If you need to regenerate any figures with poster-scale fonts (for A1 printing), add this at the top of whichever script does the plotting:

```matlab
set(groot,'defaultAxesFontSize', 22)
set(groot,'defaultTextFontSize', 22)
set(groot,'defaultLegendFontSize', 18)
set(groot,'defaultAxesLineWidth', 1.5)
set(groot,'defaultLineLineWidth', 2.5)
```

This brings axis labels from ~3 mm to ~5 mm at A1 print size.

---

## Dependencies

- MATLAB R2022a or later
- No additional toolboxes required (base MATLAB only)
