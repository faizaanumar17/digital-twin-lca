%% sensitivity_run.m
% One-factor-at-a-time sensitivity runs.
% Produces outputs/sensitivity_summary.csv (scenario x material).
%
% FIX applied: ESA reference is recalculated whenever traffic.growth changes
% so that the traffic_factor normalisation remains consistent across scenarios.

clear; clc;

addpath(genpath(fullfile(pwd,"functions")));

cfg0 = config_base();
mats = materials();

S = struct([]);
k = 0;

%% ── SCENARIO DEFINITIONS ────────────────────────────────────────────────────

% Base
k = k + 1;
S(k).name = "Base";
S(k).cfg  = cfg0;

% No overloading (strong enforcement proxy)
k = k + 1;
S(k).name = "NoOverload";
S(k).cfg  = cfg0;
S(k).cfg.traffic.loading_mode = "no_overload";

% Traffic growth — LOW (2%)
k = k + 1;
S(k).name = "LowGrowth_2pct";
S(k).cfg  = cfg0;
S(k).cfg.traffic.growth = 0.02;
% Recalculate ESA reference for this growth rate
refOut = traffic_annual_esas(S(k).cfg, S(k).cfg.traffic.AADT_total, ...
    S(k).cfg.traffic.pct_HGV, S(k).cfg.traffic.ESAs_no_overload, ...
    S(k).cfg.traffic.lane_split_factor);
S(k).cfg.traffic.ref_annual_ESAs = refOut.annual_ESAs;

% Traffic growth — HIGH (6%)
k = k + 1;
S(k).name = "HighGrowth_6pct";
S(k).cfg  = cfg0;
S(k).cfg.traffic.growth = 0.06;
% Recalculate ESA reference for this growth rate
refOut = traffic_annual_esas(S(k).cfg, S(k).cfg.traffic.AADT_total, ...
    S(k).cfg.traffic.pct_HGV, S(k).cfg.traffic.ESAs_no_overload, ...
    S(k).cfg.traffic.lane_split_factor);
S(k).cfg.traffic.ref_annual_ESAs = refOut.annual_ESAs;

% Discount rate — LOW (8%)
k = k + 1;
S(k).name = "LowDiscount_8pct";
S(k).cfg  = cfg0;
S(k).cfg.discount_rate = 0.08;

% Discount rate — HIGH (15%)
k = k + 1;
S(k).name = "HighDiscount_15pct";
S(k).cfg  = cfg0;
S(k).cfg.discount_rate = 0.15;

% Climate multiplier — LOW (1.0, no tropical penalty)
k = k + 1;
S(k).name = "ClimateMin_1p0";
S(k).cfg  = cfg0;
S(k).cfg.climate.factor = 1.00;

% Climate multiplier — HIGH (1.30, severe tropical)
k = k + 1;
S(k).name = "ClimateMax_1p3";
S(k).cfg  = cfg0;
S(k).cfg.climate.factor = 1.30;

% Maintenance minor boost — LOW (2 pts)
k = k + 1;
S(k).name = "MinorBoost_2";
S(k).cfg  = cfg0;
S(k).cfg.maint.boost_minor = 2;

% Maintenance trigger threshold — TIGHTER (60)
k = k + 1;
S(k).name = "MinorTrigger_60";
S(k).cfg  = cfg0;
S(k).cfg.maint.th_minor = 60;

% Cost multiplier — LOW (0.8x)
k = k + 1;
S(k).name = "CostLow_0p8x";
S(k).cfg  = cfg0;
S(k).cfg.cost.asphalt_overlay_base = cfg0.cost.asphalt_overlay_base * 0.8;
S(k).cfg = rebuild_costs(S(k).cfg);

% Cost multiplier — HIGH (1.5x)
k = k + 1;
S(k).name = "CostHigh_1p5x";
S(k).cfg  = cfg0;
S(k).cfg.cost.asphalt_overlay_base = cfg0.cost.asphalt_overlay_base * 1.5;
S(k).cfg = rebuild_costs(S(k).cfg);

% Loading exponent — LOW (0.2)
k = k + 1;
S(k).name = "AlphaLow_0p2";
S(k).cfg  = cfg0;
S(k).cfg.traffic.factor_alpha = 0.20;

% Loading exponent — HIGH (0.6)
k = k + 1;
S(k).name = "AlphaHigh_0p6";
S(k).cfg  = cfg0;
S(k).cfg.traffic.factor_alpha = 0.60;


%% ── RUN ALL SCENARIOS ───────────────────────────────────────────────────────

outdir = fullfile(pwd, "outputs");
if ~exist(outdir,'dir'); mkdir(outdir); end

allRows = table();

for s = 1:numel(S)
    for i = 1:numel(mats)
        res = simulate_section(S(s).cfg, mats(i));
        sm  = res.summary;

        row = table( ...
            string(S(s).name), ...
            string(sm.material_key), ...
            string(sm.loading_mode), ...
            sm.AADT_total_two_way, ...
            sm.pct_HGV, ...
            sm.ESAs_per_HV_used, ...
            sm.npv_cost_ngn, ...
            sm.npv_cost_gbp, ...
            sm.total_co2_t, ...
            sm.service_life_years, ...
            sm.first_overlay_year, ...
            sm.first_recon_year, ...
            sm.n_minor, ...
            sm.n_overlay, ...
            sm.n_recon, ...
            'VariableNames', { ...
                'scenario', 'material', 'loading_mode', ...
                'AADT_two_way', 'pct_HGV', 'ESAs_per_HV_used', ...
                'npv_cost_ngn', 'npv_cost_gbp', ...
                'total_co2_t', 'service_life_years', ...
                'first_overlay_year', 'first_recon_year', ...
                'n_minor', 'n_overlay', 'n_recon'} );

        allRows = [allRows; row]; %#ok<AGROW>
    end
end

writetable(allRows, fullfile(outdir, "sensitivity_summary.csv"));


%% ── PRINT SUMMARY TO COMMAND WINDOW ────────────────────────────────────────

fprintf('\n=== Sensitivity Summary: NPV Cost GBP ===\n');
fprintf('%-22s %18s %18s %18s\n', 'Scenario', 'Asphalt', 'Laterite', 'Plastic');
fprintf('%s\n', repmat('-',1,78));

scenarios = unique(allRows.scenario, 'stable');
for s = 1:numel(scenarios)
    sc = scenarios(s);
    row_a = allRows(allRows.scenario==sc & allRows.material=="asphalt", :);
    row_l = allRows(allRows.scenario==sc & allRows.material=="laterite", :);
    row_p = allRows(allRows.scenario==sc & allRows.material=="plastic", :);
    if isempty(row_a) || isempty(row_l) || isempty(row_p); continue; end
    fprintf('%-22s %18.0f %18.0f %18.0f\n', sc, ...
        row_a.npv_cost_gbp, row_l.npv_cost_gbp, row_p.npv_cost_gbp);
end
fprintf('\n');

fprintf('=== Sensitivity Summary: Total CO2 (t) ===\n');
fprintf('%-22s %18s %18s %18s\n', 'Scenario', 'Asphalt', 'Laterite', 'Plastic');
fprintf('%s\n', repmat('-',1,78));

for s = 1:numel(scenarios)
    sc = scenarios(s);
    row_a = allRows(allRows.scenario==sc & allRows.material=="asphalt", :);
    row_l = allRows(allRows.scenario==sc & allRows.material=="laterite", :);
    row_p = allRows(allRows.scenario==sc & allRows.material=="plastic", :);
    if isempty(row_a) || isempty(row_l) || isempty(row_p); continue; end
    fprintf('%-22s %18.2f %18.2f %18.2f\n', sc, ...
        row_a.total_co2_t, row_l.total_co2_t, row_p.total_co2_t);
end
fprintf('\n');

disp("Sensitivity done. See outputs/sensitivity_summary.csv");


%% ── LOCAL FUNCTION: REBUILD DERIVED COSTS ──────────────────────────────────

function cfg = rebuild_costs(cfg)
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
