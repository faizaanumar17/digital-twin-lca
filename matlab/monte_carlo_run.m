%% monte_carlo_run.m
% Monte Carlo uncertainty analysis across all uncertain parameters simultaneously.
% Run this file independently — it takes a few minutes at N=2000.
% Outputs probability distributions of NPV cost, total CO2, and first overlay
% year for each material, plus summary statistics and box plots.
%
% Place in your MATLAB project folder alongside main_run.m.
% Outputs are written to /outputs alongside your other exports.

clear; clc;

addpath(genpath(fullfile(pwd,"functions")));

outdir = fullfile(pwd, "outputs");
if ~exist(outdir, 'dir'); mkdir(outdir); end

%% ── SETTINGS ────────────────────────────────────────────────────────────────

N   = 2000;     % number of Monte Carlo samples (use 500 to test, 2000 for final)
rng(42);       % fix random seed for reproducibility

mats = materials();

% RGB colour triplets (replaces hex codes for compatibility)
colors = {[0.13 0.40 0.67], [0.84 0.19 0.15], [0.10 0.60 0.31]};

%% ── STORAGE ─────────────────────────────────────────────────────────────────

n_mats = numel(mats);

npv_cost_gbp  = zeros(N, n_mats);
total_co2_t   = zeros(N, n_mats);
first_overlay = zeros(N, n_mats);

%% ── MONTE CARLO LOOP ────────────────────────────────────────────────────────

fprintf('Running Monte Carlo (N=%d)...\n', N);

for n = 1:N

    if mod(n, 100) == 0
        fprintf('  Sample %d / %d\n', n, N);
    end

    cfg = config_base();

    % ── Sample uncertain parameters uniformly within defined ranges ──────────

    % Climate damage multiplier: 1.00 – 1.30
    cfg.climate.factor = 1.00 + rand() * 0.30;

    % Traffic annual growth rate: 2% – 6%
    cfg.traffic.growth = 0.02 + rand() * 0.04;

    % Discount rate: 8% – 15%
    cfg.discount_rate = 0.08 + rand() * 0.07;

    % Loading exponent alpha: 0.20 – 0.60
    cfg.traffic.factor_alpha = 0.20 + rand() * 0.40;

    % Recalculate ESA reference after changing traffic growth
    refOut = traffic_annual_esas(cfg, cfg.traffic.AADT_total, cfg.traffic.pct_HGV, ...
                                 cfg.traffic.ESAs_no_overload, cfg.traffic.lane_split_factor);
    cfg.traffic.ref_annual_ESAs = refOut.annual_ESAs;

    % Cost multiplier: ±30% on asphalt overlay base (propagates to all materials)
    cost_mult = 0.70 + rand() * 0.60;
    cfg.cost.asphalt_overlay_base = config_base().cost.asphalt_overlay_base * cost_mult;
    cfg = rebuild_costs_mc(cfg);

    % ── Run each material with sampled durability factor (±15%) ─────────────

    for i = 1:n_mats
        mat = mats(i);
        mat.det_factor = mats(i).det_factor * (0.85 + rand() * 0.30);

        res = simulate_section(cfg, mat);

        npv_cost_gbp(n, i)  = res.summary.npv_cost_gbp;
        total_co2_t(n, i)   = res.summary.total_co2_t;
        first_overlay(n, i) = res.summary.first_overlay_year;
    end

end

fprintf('Monte Carlo complete.\n\n');


%% ── EXPORT CSVs ─────────────────────────────────────────────────────────────

for i = 1:n_mats
    T = table(npv_cost_gbp(:,i), total_co2_t(:,i), first_overlay(:,i), ...
        'VariableNames', {'npv_cost_gbp', 'total_co2_t', 'first_overlay_year'});
    writetable(T, fullfile(outdir, "mc_" + mats(i).key + ".csv"));
end


%% ── PRINT SUMMARY STATISTICS ────────────────────────────────────────────────

fprintf('%s\n', repmat('=',1,80));
fprintf('  MONTE CARLO SUMMARY (N=%d)\n', N);
fprintf('%s\n', repmat('=',1,80));

metrics = {"NPV Cost (GBP)", "Total CO2 (t)", "1st Overlay (yr)"};
data    = {npv_cost_gbp, total_co2_t, first_overlay};

for d = 1:3
    fprintf('\n  %s:\n', metrics{d});
    fprintf('  %-30s %10s %10s %10s %10s %10s\n', ...
        'Material','Mean','Median','5th pct','95th pct','Std Dev');
    fprintf('  %s\n', repmat('-',1,72));
    for i = 1:n_mats
        vals = data{d}(:,i);
        vals_clean = vals(~isnan(vals));
        fprintf('  %-30s %10.1f %10.1f %10.1f %10.1f %10.1f\n', ...
            mats(i).name, ...
            mean(vals_clean), ...
            median(vals_clean), ...
            prctile(vals_clean, 5), ...
            prctile(vals_clean, 95), ...
            std(vals_clean));
    end
end

fprintf('\n%s\n\n', repmat('=',1,80));


%% ── PLOTS ───────────────────────────────────────────────────────────────────

mat_labels = cellstr(string({mats.name}));

% Box plot — NPV Cost
figure('Name','Monte Carlo: NPV Cost Distribution');
boxplot(npv_cost_gbp, 'Labels', mat_labels, 'Colors', 'k', 'Symbol', '.');
hold on;
for i = 1:n_mats
    scatter(ones(N,1)*i + (rand(N,1)-0.5)*0.15, npv_cost_gbp(:,i), ...
            3, colors{i}, 'filled');
end
hold off;
grid on;
ylabel('20-year NPV Agency Cost (GBP)');
title(sprintf('Monte Carlo: NPV Cost Distribution (N=%d)', N));

% Box plot — Total CO2
figure('Name','Monte Carlo: Total CO2 Distribution');
boxplot(total_co2_t, 'Labels', mat_labels, 'Colors', 'k', 'Symbol', '.');
hold on;
for i = 1:n_mats
    scatter(ones(N,1)*i + (rand(N,1)-0.5)*0.15, total_co2_t(:,i), ...
            3, colors{i}, 'filled');
end
hold off;
grid on;
ylabel('20-year Total Embodied CO2 (t)');
title(sprintf('Monte Carlo: CO2 Distribution (N=%d)', N));

% Box plot — First overlay year
figure('Name','Monte Carlo: First Overlay Year Distribution');
fo_clean = first_overlay;
fo_clean(isnan(fo_clean)) = 21;
boxplot(fo_clean, 'Labels', mat_labels, 'Colors', 'k', 'Symbol', '.');
hold on;
for i = 1:n_mats
    scatter(ones(N,1)*i + (rand(N,1)-0.5)*0.15, fo_clean(:,i), ...
            3, colors{i}, 'filled');
end
hold off;
grid on;
ylabel('Year of first overlay / reseal');
title(sprintf('Monte Carlo: First Overlay Year Distribution (N=%d)', N));

% Histogram comparison — NPV Cost
figure('Name','Monte Carlo: NPV Cost Histograms');
for i = 1:n_mats
    subplot(1, n_mats, i);
    histogram(npv_cost_gbp(:,i), 40, 'FaceColor', colors{i}, 'FaceAlpha', 0.7);
    xlabel('NPV Cost (GBP)'); ylabel('Count');
    title(mats(i).name, 'FontSize', 9);
    grid on;
end
sgtitle(sprintf('Monte Carlo: NPV Cost Distributions (N=%d)', N));

% Histogram comparison — Total CO2
figure('Name','Monte Carlo: CO2 Histograms');
for i = 1:n_mats
    subplot(1, n_mats, i);
    histogram(total_co2_t(:,i), 40, 'FaceColor', colors{i}, 'FaceAlpha', 0.7);
    xlabel('Total CO2 (t)'); ylabel('Count');
    title(mats(i).name, 'FontSize', 9);
    grid on;
end
sgtitle(sprintf('Monte Carlo: Total CO2 Distributions (N=%d)', N));


%% ── DONE ────────────────────────────────────────────────────────────────────

fprintf('Outputs written to /outputs:\n');
fprintf('  mc_asphalt.csv    — NPV cost, CO2, first overlay distributions\n');
fprintf('  mc_laterite.csv\n');
fprintf('  mc_plastic.csv\n');


%% ── LOCAL FUNCTION: REBUILD COSTS AFTER SAMPLING ───────────────────────────

function cfg = rebuild_costs_mc(cfg)
overlayA = cfg.cost.asphalt_overlay_base;
reconA   = overlayA * cfg.cost.recon_overlay_ratio_base;
minorA   = overlayA * cfg.cost.minor_frac_of_overlay_base;

cfg.cost.asphalt.construct_ngn_m2 = reconA;
cfg.cost.asphalt.overlay_ngn_m2   = overlayA;
cfg.cost.asphalt.recon_ngn_m2     = reconA;
cfg.cost.asphalt.minor_ngn_m2     = minorA;

overlayL = overlayA * cfg.cost.laterite_reseal_ratio_base;
reconL   = reconA   * cfg.cost.laterite_construct_ratio;
minorL   = minorA   * 0.80;

cfg.cost.laterite.construct_ngn_m2 = reconL;
cfg.cost.laterite.overlay_ngn_m2   = overlayL;
cfg.cost.laterite.recon_ngn_m2     = reconL;
cfg.cost.laterite.minor_ngn_m2     = minorL;

premP = 1 + cfg.cost.plastic_premium_base;
cfg.cost.plastic.construct_ngn_m2 = reconA * premP;
cfg.cost.plastic.overlay_ngn_m2   = overlayA * premP;
cfg.cost.plastic.recon_ngn_m2     = reconA * premP;
cfg.cost.plastic.minor_ngn_m2     = minorA * premP;
end
