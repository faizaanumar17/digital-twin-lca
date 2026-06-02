# figures/

High-resolution figures from the dissertation and poster.

## Files

| File | Description | Used in |
|---|---|---|
| `fig4_1.png` | CI trajectories over 20 yr (all 3 materials) | Dissertation §4, Poster Fig.2 |
| `fig4_4.png` | Monte Carlo boxplots — NPV, CO₂, first overlay | Dissertation §4, Poster Fig.4 |
| `fig4_6.png` | Network backlog trajectories (7 scenarios) | Dissertation §4, Poster Fig.5 |
| `fig4_7.png` | MCDA rank probabilities (Dirichlet weights) | Dissertation §4, Poster Fig.6 |
| `fig4_sobol.png` | Sobol S₁ and S_T indices | Dissertation §4, Poster Fig.3 |
| `fig5_1.png` | Research positioning matrix | Dissertation §5 |
| `fig3_2.png` | Vensim stock-flow diagram | Dissertation §3 |

## Regenerating with poster-scale fonts

To regenerate figures with larger fonts suitable for A1 poster printing:

```matlab
% Add to top of plot_figures.m before any plotting
set(groot,'defaultAxesFontSize', 22)
set(groot,'defaultTextFontSize', 22)
set(groot,'defaultLegendFontSize', 18)
set(groot,'defaultAxesLineWidth', 1.5)
set(groot,'defaultLineLineWidth', 2.5)
```

```python
# Python/matplotlib equivalent
import matplotlib.pyplot as plt
plt.rcParams.update({
    'font.size': 22,
    'axes.labelsize': 26,
    'xtick.labelsize': 20,
    'ytick.labelsize': 20,
    'legend.fontsize': 18,
    'axes.titlesize': 24,
    'lines.linewidth': 2.5,
    'figure.dpi': 200
})
```
