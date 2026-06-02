%% time_to_crisis_budget_threshold.m
% Replicates the Vensim SD model equations and runs all 7 scenarios (S0-S6).
% Computes time-to-crisis table, policy-threshold analysis, a budget-
% threshold sweep showing when budget becomes binding, and an initial
% backlog sensitivity sweep for structural robustness.
% Outputs are written to /outputs alongside the other MATLAB exports.

clear; clc;

outdir = fullfile(pwd, "outputs");
if ~exist(outdir, 'dir'); mkdir(outdir); end

%% ── BASELINE PARAMETERS (from Vensim model + MATLAB twin) ──────────────────

p.T  = 20;
p.dt = 1;

p.total_network_km               = 100;
p.initial_backlog_km             = 15;
p.initial_acceptable_km_asphalt  = 59.5;
p.initial_acceptable_km_laterite = 17.0;
p.initial_acceptable_km_plastic  = 8.5;

p.TTL_asphalt  = 5.0;
p.TTL_laterite = 3.33333;
p.TTL_plastic  = 7.0;

p.rehab_share_asphalt  = 0.70;
p.rehab_share_laterite = 0.20;
p.rehab_share_plastic  = 0.10;

p.unit_cost_asphalt  = 21256.9;
p.unit_cost_laterite = 11820.8;
p.unit_cost_plastic  = 26067.1;

p.unit_co2_asphalt  = 23.5078;
p.unit_co2_laterite = 3.82907;
p.unit_co2_plastic  = 24.771;

% ── USE-PHASE CO2 PARAMETERS (rolling resistance, Trupia 2017 / NCHRP 720) ──
% Annual use-phase CO2 per km of road at baseline AADT (t/km/yr).
% Derived from: RRC × FF_mix × VKT_yr × EF_diesel / 1000
% where RRC values: asphalt=0.0120, plastic=0.0105, laterite=0.0165
% FF_LV=0.04 L/veh/km/unit-RRC, FF_HGV=0.15 L/veh/km/unit-RRC (NCHRP 720)
% EF_diesel = 2.64 kg CO2/L; AADT=13667, lane_split=0.5, pHGV=0.159
% These scale with traffic growth each year (factor (1+g)^t).
%
% NOTE: construction-phase CO2 (unit_co2_*) is per km REHABILITATED.
%       Use-phase CO2 (unit_up_co2_*) is per km of ACCEPTABLE road, every year.
p.unit_up_co2_asphalt  = 4.5427;   % t/km/yr at baseline AADT (RRC=0.012)
p.unit_up_co2_laterite = 6.2462;   % t/km/yr at baseline AADT (RRC=0.0165)
p.unit_up_co2_plastic  = 3.9749;   % t/km/yr at baseline AADT (RRC=0.0105)
p.traffic_growth        = 0.04;    % annual traffic growth rate (for use-phase scaling)

p.baseline_annual_budget_gbp = 844794;
p.budget_factor              = 1.0;
p.overload_damage_multiplier = 1.0;
p.rehab_response_time        = 1.0;   % years; dimensional-consistency fix

CRISIS_THRESHOLD = 0.20;   % 20% backlog fraction = crisis point


%% ── SCENARIO DEFINITIONS ────────────────────────────────────────────────────

S(1).name  = "S0_Baseline";
S(1).label = "S0 – Baseline";
S(1).budget_factor              = 1.0;
S(1).rehab_share_asphalt        = 0.70;
S(1).rehab_share_laterite       = 0.20;
S(1).rehab_share_plastic        = 0.10;
S(1).overload_damage_multiplier = 1.0;

S(2).name  = "S1_LowBudget";
S(2).label = "S1 – Low-budget stress";
S(2).budget_factor              = 0.7;
S(2).rehab_share_asphalt        = 0.70;
S(2).rehab_share_laterite       = 0.20;
S(2).rehab_share_plastic        = 0.10;
S(2).overload_damage_multiplier = 1.0;

S(3).name  = "S2_HighBudget";
S(3).label = "S2 – High-budget";
S(3).budget_factor              = 1.3;
S(3).rehab_share_asphalt        = 0.70;
S(3).rehab_share_laterite       = 0.20;
S(3).rehab_share_plastic        = 0.10;
S(3).overload_damage_multiplier = 1.0;

S(4).name  = "S3_PlasticPush";
S(4).label = "S3 – Plastic-push";
S(4).budget_factor              = 1.0;
S(4).rehab_share_asphalt        = 0.25;
S(4).rehab_share_laterite       = 0.15;
S(4).rehab_share_plastic        = 0.60;
S(4).overload_damage_multiplier = 1.0;

S(5).name  = "S4_LateriteHeavy";
S(5).label = "S4 – Laterite-heavy";
S(5).budget_factor              = 1.0;
S(5).rehab_share_asphalt        = 0.30;
S(5).rehab_share_laterite       = 0.60;
S(5).rehab_share_plastic        = 0.10;
S(5).overload_damage_multiplier = 1.0;

S(6).name  = "S5_StrongEnforcement";
S(6).label = "S5 – Strong enforcement";
S(6).budget_factor              = 1.0;
S(6).rehab_share_asphalt        = 0.70;
S(6).rehab_share_laterite       = 0.20;
S(6).rehab_share_plastic        = 0.10;
S(6).overload_damage_multiplier = 0.7;

S(7).name  = "S6_CombinedPolicy";
S(7).label = "S6 – Combined policy";
S(7).budget_factor              = 1.0;
S(7).rehab_share_asphalt        = 0.25;
S(7).rehab_share_laterite       = 0.15;
S(7).rehab_share_plastic        = 0.60;
S(7).overload_damage_multiplier = 0.7;


%% ── RUN ALL SCENARIOS ───────────────────────────────────────────────────────

allResults = struct([]);

for s = 1:numel(S)
    scen = S(s);
    cfg  = p;

    % Apply scenario overrides
    cfg.budget_factor              = scen.budget_factor;
    cfg.rehab_share_asphalt        = scen.rehab_share_asphalt;
    cfg.rehab_share_laterite       = scen.rehab_share_laterite;
    cfg.rehab_share_plastic        = scen.rehab_share_plastic;
    cfg.overload_damage_multiplier = scen.overload_damage_multiplier;

    res = run_sd_scenario(cfg);
    allResults(s).name  = scen.name;
    allResults(s).label = scen.label;
    allResults(s).scen  = scen;
    allResults(s).res   = res;

    % Export trajectory CSV
    T_out = table(res.t, res.backlog_km, res.backlog_frac, ...
                  res.acceptable_km, res.acceptable_frac, ...
                  res.cum_cost_gbp, res.cum_co2_t, ...
                  res.cum_co2_con_t, res.cum_co2_use_t, ...
        'VariableNames', {'Year','Backlog_km','Backlog_fraction', ...
                          'Acceptable_km','Acceptable_fraction', ...
                          'Cumulative_cost_GBP','Cumulative_CO2_whole_life_t', ...
                          'Cumulative_CO2_construction_t','Cumulative_CO2_use_phase_t'});
    writetable(T_out, fullfile(outdir, "sd_" + scen.name + ".csv"));
end


%% ── TIME-TO-CRISIS TABLE ────────────────────────────────────────────────────

crisis_scenario    = strings(numel(S),1);
crisis_year_str    = strings(numel(S),1);
backlog_yr20       = zeros(numel(S),1);
backlog_frac_yr20  = zeros(numel(S),1);
acc_frac_yr20      = zeros(numel(S),1);
cum_cost_yr20      = zeros(numel(S),1);
cum_co2_yr20       = zeros(numel(S),1);

for s = 1:numel(S)
    res = allResults(s).res;
    crisis_scenario(s) = allResults(s).label;

    idx_crisis = find(res.backlog_frac >= CRISIS_THRESHOLD, 1, 'first');
    if ~isempty(idx_crisis)
        crisis_year_str(s) = sprintf("Year %d", res.t(idx_crisis));
    else
        crisis_year_str(s) = "Not reached";
    end

    final = numel(res.t);
    backlog_yr20(s)      = res.backlog_km(final);
    backlog_frac_yr20(s) = res.backlog_frac(final);
    acc_frac_yr20(s)     = res.acceptable_frac(final);
    cum_cost_yr20(s)     = res.cum_cost_gbp(final) / 1e6;
    cum_co2_yr20(s)      = res.cum_co2_t(final);
end

crisis_table = table(crisis_scenario, crisis_year_str, backlog_yr20, ...
                     backlog_frac_yr20, acc_frac_yr20, cum_cost_yr20, cum_co2_yr20, ...
    'VariableNames', {'Scenario', 'Crisis_year', 'Backlog_km_yr20', ...
                      'Backlog_fraction_yr20', 'Acceptable_fraction_yr20', ...
                      'Cumulative_cost_GBP_M', 'Cumulative_CO2_whole_life_t'});

writetable(crisis_table, fullfile(outdir, "time_to_crisis.csv"));


%% ── PRINT TIME-TO-CRISIS TABLE ──────────────────────────────────────────────

fprintf('\n%s\n', repmat('=',1,88));
fprintf('  TIME-TO-CRISIS  (threshold: backlog fraction >= %.0f%%)\n', CRISIS_THRESHOLD*100);
fprintf('%s\n', repmat('=',1,88));
fprintf('%-30s %-18s %12s %14s %12s\n', ...
    'Scenario','Crisis year','Backlog yr20','Acc.frac yr20','Cum.Cost £M');
fprintf('%s\n', repmat('-',1,88));

for s = 1:numel(S)
    fprintf('%-30s %-18s %12.1f %14.3f %12.2f\n', ...
        crisis_scenario(s), crisis_year_str(s), ...
        backlog_yr20(s), acc_frac_yr20(s), cum_cost_yr20(s));
end
fprintf('%s\n\n', repmat('=',1,88));


%% ── POLICY THRESHOLD ANALYSIS ───────────────────────────────────────────────

fprintf('%s\n', repmat('=',1,70));
fprintf('  POLICY THRESHOLD: minimum budget to stabilise backlog\n');
fprintf('%s\n', repmat('=',1,70));

mixes(1).name    = "Baseline mix (70/20/10)";
mixes(1).share_a = 0.70; mixes(1).share_l = 0.20; mixes(1).share_p = 0.10;

mixes(2).name    = "Plastic-push (25/15/60)";
mixes(2).share_a = 0.25; mixes(2).share_l = 0.15; mixes(2).share_p = 0.60;

mixes(3).name    = "Laterite-heavy (30/60/10)";
mixes(3).share_a = 0.30; mixes(3).share_l = 0.60; mixes(3).share_p = 0.10;

for m = 1:numel(mixes)
    mx = mixes(m);
    acc_total = 85.0;

    det_total = (acc_total * mx.share_a / p.TTL_asphalt) + ...
                (acc_total * mx.share_l / p.TTL_laterite) + ...
                (acc_total * mx.share_p / p.TTL_plastic);

    w_cost = mx.share_a * p.unit_cost_asphalt + ...
             mx.share_l * p.unit_cost_laterite + ...
             mx.share_p * p.unit_cost_plastic;

    min_budget = det_total * w_cost;

    fprintf('\n  %s\n', mx.name);
    fprintf('    Steady-state deterioration:  %.2f km/year\n', det_total);
    fprintf('    Weighted unit rehab cost:    GBP %.0f/km\n', w_cost);
    fprintf('    Minimum stabilising budget:  GBP %.0f/year\n', min_budget);
    fprintf('    As fraction of baseline:     %.2fx\n', min_budget / p.baseline_annual_budget_gbp);
end

fprintf('\n%s\n\n', repmat('=',1,70));


%% ── BUDGET THRESHOLD SWEEP (BASELINE MIX) ──────────────────────────────────

fprintf('%s\n', repmat('=',1,78));
fprintf('  BUDGET THRESHOLD SWEEP – BASELINE MIX (70/20/10)\n');
fprintf('%s\n', repmat('=',1,78));

budget_factors = [0.2 0.3 0.4 0.5 0.7 1.0 1.3]';

share_a = p.rehab_share_asphalt;
share_l = p.rehab_share_laterite;
share_p = p.rehab_share_plastic;

weighted_cost = share_a * p.unit_cost_asphalt + ...
                share_l * p.unit_cost_laterite + ...
                share_p * p.unit_cost_plastic;

fprintf('Baseline weighted rehab cost = GBP %.2f/km\n', weighted_cost);

nB = numel(budget_factors);
annual_budget_gbp    = zeros(nB,1);
rehab_capacity_km_yr = zeros(nB,1);
year20_backlog_km    = zeros(nB,1);
budget_binding       = strings(nB,1);

baseline_res = struct();
tol = 0.01;   % km tolerance for “materially different”

for i = 1:nB
    cfg = p;
    cfg.budget_factor = budget_factors(i);
    cfg.rehab_share_asphalt  = 0.70;
    cfg.rehab_share_laterite = 0.20;
    cfg.rehab_share_plastic  = 0.10;
    cfg.overload_damage_multiplier = 1.0;

    annual_budget_gbp(i)    = cfg.baseline_annual_budget_gbp * cfg.budget_factor;
    rehab_capacity_km_yr(i) = annual_budget_gbp(i) / weighted_cost;

    res = run_sd_scenario(cfg);
    year20_backlog_km(i) = res.backlog_km(end);

    if abs(budget_factors(i) - 1.0) < 1e-12
        baseline_res = res;
    end
end

baseline_backlog = baseline_res.backlog_km(end);

for i = 1:nB
    if abs(year20_backlog_km(i) - baseline_backlog) > tol
        budget_binding(i) = "Yes";
    else
        budget_binding(i) = "No";
    end
end

budget_threshold_table = table( ...
    budget_factors, ...
    annual_budget_gbp, ...
    rehab_capacity_km_yr, ...
    year20_backlog_km, ...
    budget_binding, ...
    'VariableNames', { ...
        'Budget_factor', ...
        'Annual_budget_GBP', ...
        'Rehab_capacity_km_per_yr', ...
        'Year20_backlog_km', ...
        'Budget_binding'});

disp(budget_threshold_table);
writetable(budget_threshold_table, fullfile(outdir, "budget_threshold_sweep.csv"));

idx_bind = find(abs(year20_backlog_km - baseline_backlog) > tol, 1, 'first');
if ~isempty(idx_bind)
    fprintf('\nBinding behaviour first appears at budget factor %.2f\n', budget_factors(idx_bind));
    fprintf('Corresponding annual budget = GBP %.0f/year\n', annual_budget_gbp(idx_bind));
else
    fprintf('\nNo binding behaviour detected in the tested budget-factor range.\n');
end
fprintf('%s\n\n', repmat('=',1,78));


%% ── INITIAL BACKLOG SENSITIVITY SWEEP ──────────────────────────────────────

fprintf('%s\n', repmat('=',1,86));
fprintf('  INITIAL BACKLOG SENSITIVITY SWEEP\n');
fprintf('%s\n', repmat('=',1,86));

initial_backlog_fracs = [0.05 0.15 0.25 0.35]';   % 5%%, 15%%, 25%%, 35%%
tol_backlog = 0.01;   % km tolerance for deciding whether budget matters

% Keep the original initial acceptable-stock composition proportions
base_initial_acceptable_total = p.initial_acceptable_km_asphalt + ...
                                p.initial_acceptable_km_laterite + ...
                                p.initial_acceptable_km_plastic;

base_share_acc_a = p.initial_acceptable_km_asphalt  / base_initial_acceptable_total;
base_share_acc_l = p.initial_acceptable_km_laterite / base_initial_acceptable_total;
base_share_acc_p = p.initial_acceptable_km_plastic  / base_initial_acceptable_total;

nIB = numel(initial_backlog_fracs);

S0_y20 = zeros(nIB,1);
S1_y20 = zeros(nIB,1);
S2_y20 = zeros(nIB,1);
S4_y20 = zeros(nIB,1);
S5_y20 = zeros(nIB,1);
S6_y20 = zeros(nIB,1);

budget_matters   = strings(nIB,1);
s6_beats_s5      = strings(nIB,1);
s4_worse_than_s0 = strings(nIB,1);

for i = 1:nIB

    ib_frac = initial_backlog_fracs(i);
    ib_km   = ib_frac * p.total_network_km;
    acc_km_total = p.total_network_km - ib_km;

    % Apply the same initial acceptable-stock proportions as the baseline
    init_acc_a = acc_km_total * base_share_acc_a;
    init_acc_l = acc_km_total * base_share_acc_l;
    init_acc_p = acc_km_total * base_share_acc_p;

    % Run S0, S1, S2, S4, S5, S6
    scenario_indices = [1 2 3 5 6 7];
    sweep_results = struct();

    for jj = 1:numel(scenario_indices)
        s_idx = scenario_indices(jj);
        scen  = S(s_idx);

        cfg = p;

        % Apply scenario overrides
        cfg.budget_factor              = scen.budget_factor;
        cfg.rehab_share_asphalt        = scen.rehab_share_asphalt;
        cfg.rehab_share_laterite       = scen.rehab_share_laterite;
        cfg.rehab_share_plastic        = scen.rehab_share_plastic;
        cfg.overload_damage_multiplier = scen.overload_damage_multiplier;

        % Apply initial backlog override
        cfg.initial_backlog_km             = ib_km;
        cfg.initial_acceptable_km_asphalt  = init_acc_a;
        cfg.initial_acceptable_km_laterite = init_acc_l;
        cfg.initial_acceptable_km_plastic  = init_acc_p;

        res = run_sd_scenario(cfg);
        sweep_results(jj).name = scen.name;
        sweep_results(jj).res  = res;
    end

    % scenario_indices = [1 2 3 5 6 7] = [S0 S1 S2 S4 S5 S6]
    S0_y20(i) = sweep_results(1).res.backlog_km(end);
    S1_y20(i) = sweep_results(2).res.backlog_km(end);
    S2_y20(i) = sweep_results(3).res.backlog_km(end);
    S4_y20(i) = sweep_results(4).res.backlog_km(end);
    S5_y20(i) = sweep_results(5).res.backlog_km(end);
    S6_y20(i) = sweep_results(6).res.backlog_km(end);

    % Does budget matter? (do S0/S1/S2 diverge materially?)
    spread_012 = max([S0_y20(i), S1_y20(i), S2_y20(i)]) - ...
                 min([S0_y20(i), S1_y20(i), S2_y20(i)]);

    if spread_012 > tol_backlog
        budget_matters(i) = "Yes";
    else
        budget_matters(i) = "No";
    end

    % Does S6 still outperform S5?
    if S6_y20(i) < S5_y20(i)
        s6_beats_s5(i) = "Yes";
    else
        s6_beats_s5(i) = "No";
    end

    % Does S4 still perform worse than S0?
    if S4_y20(i) > S0_y20(i)
        s4_worse_than_s0(i) = "Yes";
    else
        s4_worse_than_s0(i) = "No";
    end
end

initial_backlog_table = table( ...
    initial_backlog_fracs, ...
    initial_backlog_fracs * 100, ...
    S0_y20, S1_y20, S2_y20, ...
    S4_y20, S5_y20, S6_y20, ...
    budget_matters, ...
    s6_beats_s5, ...
    s4_worse_than_s0, ...
    'VariableNames', { ...
        'Initial_backlog_fraction', ...
        'Initial_backlog_percent', ...
        'S0_year20_backlog_km', ...
        'S1_year20_backlog_km', ...
        'S2_year20_backlog_km', ...
        'S4_year20_backlog_km', ...
        'S5_year20_backlog_km', ...
        'S6_year20_backlog_km', ...
        'Budget_matters', ...
        'S6_beats_S5', ...
        'S4_worse_than_S0'});

disp(initial_backlog_table);
writetable(initial_backlog_table, fullfile(outdir, "initial_backlog_sensitivity.csv"));

idx_budget_starts = find(initial_backlog_table.Budget_matters == "Yes", 1, 'first');
if ~isempty(idx_budget_starts)
    fprintf('\nBudget sensitivity first appears at initial backlog = %.0f%%%%\n', ...
        initial_backlog_table.Initial_backlog_percent(idx_budget_starts));
else
    fprintf('\nNo budget sensitivity detected across the tested initial backlog range.\n');
end

fprintf('%s\n\n', repmat('=',1,86));


%% ── INITIAL BACKLOG SENSITIVITY PLOT ───────────────────────────────────────

figure('Name','Initial Backlog Sensitivity – Year-20 Backlog');
hold on;
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S0_year20_backlog_km, '-o', 'LineWidth', 1.8, 'DisplayName', 'S0');
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S1_year20_backlog_km, '-s', 'LineWidth', 1.8, 'DisplayName', 'S1');
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S2_year20_backlog_km, '-^', 'LineWidth', 1.8, 'DisplayName', 'S2');
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S4_year20_backlog_km, '-d', 'LineWidth', 1.8, 'DisplayName', 'S4');
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S5_year20_backlog_km, '-v', 'LineWidth', 1.8, 'DisplayName', 'S5');
plot(initial_backlog_table.Initial_backlog_percent, initial_backlog_table.S6_year20_backlog_km, '-p', 'LineWidth', 1.8, 'DisplayName', 'S6');
hold off;
grid on;
xlabel('Initial backlog (%%)');
ylabel('Year-20 backlog (km)');
title('Initial Backlog Sensitivity of Year-20 Network Backlog');
legend('Location', 'best');


%% ── BACKLOG TRAJECTORY PLOT ─────────────────────────────────────────────────

colors = {'#2166ac','#d73027','#4dac26','#7b3294','#e66101','#1a9850','#b35806'};
figure('Name','Backlog Trajectories – All Scenarios');
hold on;
for s = 1:numel(S)
    res = allResults(s).res;
    plot(res.t, res.backlog_frac * 100, '-o', ...
         'LineWidth', 1.8, 'Color', colors{s}, ...
         'DisplayName', allResults(s).label);
end
yline(CRISIS_THRESHOLD * 100, '--k', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('Crisis threshold (%d%%)', round(CRISIS_THRESHOLD*100)));
hold off;
grid on;
legend('Location', 'best', 'FontSize', 9);
xlabel('Year');
ylabel('Backlog fraction (%)');
title('Network Backlog Fraction by Scenario (SD Model)');

% Acceptable fraction plot
figure('Name','Acceptable Fraction – All Scenarios');
hold on;
for s = 1:numel(S)
    res = allResults(s).res;
    plot(res.t, res.acceptable_frac * 100, '-s', ...
         'LineWidth', 1.8, 'Color', colors{s}, ...
         'DisplayName', allResults(s).label);
end
hold off;
grid on;
legend('Location', 'best', 'FontSize', 9);
xlabel('Year');
ylabel('Acceptable fraction (%)');
title('Network Acceptable Fraction by Scenario (SD Model)');

% Cumulative cost plot
figure('Name','Cumulative Cost GBP – All Scenarios');
hold on;
for s = 1:numel(S)
    res = allResults(s).res;
    plot(res.t, res.cum_cost_gbp / 1e6, '-^', ...
         'LineWidth', 1.8, 'Color', colors{s}, ...
         'DisplayName', allResults(s).label);
end
hold off;
grid on;
legend('Location', 'best', 'FontSize', 9);
xlabel('Year');
ylabel('Cumulative agency cost (£M)');
title('Cumulative Agency Cost by Scenario (SD Model)');

% Cumulative CO2 plot
figure('Name','Cumulative CO2 – All Scenarios');
hold on;
for s = 1:numel(S)
    res = allResults(s).res;
    plot(res.t, res.cum_co2_t, '-v', ...
         'LineWidth', 1.8, 'Color', colors{s}, ...
         'DisplayName', allResults(s).label);
end
hold off;
grid on;
legend('Location', 'best', 'FontSize', 9);
xlabel('Year');
ylabel('Cumulative embodied CO2 (t)');
title('Cumulative Embodied CO2 by Scenario (SD Model)');

fprintf('\nOutputs written to /outputs\n');
fprintf('  time_to_crisis.csv           summary table\n');
fprintf('  budget_threshold_sweep.csv   budget sweep table\n');
fprintf('  sd_<scenario>.csv            full trajectories\n');


%% ── LOCAL FUNCTION: RUN ONE SD SCENARIO ─────────────────────────────────────

function res = run_sd_scenario(cfg)

t   = (0:cfg.dt:cfg.T)';
n   = numel(t);

acc_a    = cfg.initial_acceptable_km_asphalt;
acc_l    = cfg.initial_acceptable_km_laterite;
acc_p    = cfg.initial_acceptable_km_plastic;
backlog  = cfg.initial_backlog_km;
cum_cost = 0;
cum_co2_con = 0;
cum_co2_use = 0;

share_a = cfg.rehab_share_asphalt;
share_l = cfg.rehab_share_laterite;
share_p = cfg.rehab_share_plastic;

uc_a = cfg.unit_cost_asphalt;
uc_l = cfg.unit_cost_laterite;
uc_p = cfg.unit_cost_plastic;

uco2_a = cfg.unit_co2_asphalt;
uco2_l = cfg.unit_co2_laterite;
uco2_p = cfg.unit_co2_plastic;

% Use-phase CO2 parameters (t/km/yr at baseline AADT)
up_co2_a = cfg.unit_up_co2_asphalt;
up_co2_l = cfg.unit_up_co2_laterite;
up_co2_p = cfg.unit_up_co2_plastic;
g_traffic = cfg.traffic_growth;

budget = cfg.baseline_annual_budget_gbp * cfg.budget_factor;
ODM    = cfg.overload_damage_multiplier;

TTL_a = cfg.TTL_asphalt  / ODM;
TTL_l = cfg.TTL_laterite / ODM;
TTL_p = cfg.TTL_plastic  / ODM;

total_km = cfg.total_network_km;

backlog_km      = zeros(n,1);
backlog_frac    = zeros(n,1);
acc_km          = zeros(n,1);
acc_frac        = zeros(n,1);
cum_cost_out    = zeros(n,1);
cum_co2_out     = zeros(n,1);   % whole-life (construction + use-phase)
cum_co2_con_out = zeros(n,1);   % construction-phase only
cum_co2_use_out = zeros(n,1);   % use-phase only

cum_co2_con = 0;
cum_co2_use = 0;

for k = 1:n
    w_cost    = share_a*uc_a + share_l*uc_l + share_p*uc_p;
    rehab_cap = budget / max(w_cost, 0.001);

    det_a = acc_a / max(TTL_a, 0.001);
    det_l = acc_l / max(TTL_l, 0.001);
    det_p = acc_p / max(TTL_p, 0.001);

    desired_reh_a = (backlog * share_a) / cfg.rehab_response_time;
    desired_reh_l = (backlog * share_l) / cfg.rehab_response_time;
    desired_reh_p = (backlog * share_p) / cfg.rehab_response_time;

    reh_a = min(desired_reh_a, rehab_cap * share_a);
    reh_l = min(desired_reh_l, rehab_cap * share_l);
    reh_p = min(desired_reh_p, rehab_cap * share_p);

    total_det   = det_a + det_l + det_p;
    total_rehab = reh_a + reh_l + reh_p;

    ann_cost = reh_a*uc_a + reh_l*uc_l + reh_p*uc_p;
    ann_co2_con  = reh_a*uco2_a + reh_l*uco2_l + reh_p*uco2_p;

    % ── USE-PHASE CO2: scales with traffic growth and acceptable km ───────
    traffic_growth_factor = (1 + g_traffic)^(t(k) - 1);
    ann_co2_use = (acc_a * up_co2_a + acc_l * up_co2_l + acc_p * up_co2_p) ...
                  * traffic_growth_factor;
    % up_co2_* are t/km/yr at baseline AADT; scaled by growth factor each year.
    % Backlog km excluded — roads in backlog carry no traffic.

    ann_co2 = ann_co2_con + ann_co2_use;   % whole-life annual total

    backlog_km(k)      = backlog;
    backlog_frac(k)    = backlog / total_km;
    acc_km(k)          = acc_a + acc_l + acc_p;
    acc_frac(k)        = acc_km(k) / total_km;
    cum_cost_out(k)    = cum_cost;
    cum_co2_out(k)     = cum_co2_con + cum_co2_use;
    cum_co2_con_out(k) = cum_co2_con;
    cum_co2_use_out(k) = cum_co2_use;

    if k < n
        acc_a    = max(acc_a    + (reh_a - det_a) * cfg.dt, 0);
        acc_l    = max(acc_l    + (reh_l - det_l) * cfg.dt, 0);
        acc_p    = max(acc_p    + (reh_p - det_p) * cfg.dt, 0);
        backlog  = max(backlog  + (total_det - total_rehab) * cfg.dt, 0);
        cum_cost    = cum_cost    + ann_cost     * cfg.dt;
        cum_co2_con = cum_co2_con + ann_co2_con  * cfg.dt;
        cum_co2_use = cum_co2_use + ann_co2_use  * cfg.dt;
    end
end

res.t               = t;
res.backlog_km      = backlog_km;
res.backlog_frac    = backlog_frac;
res.acceptable_km   = acc_km;
res.acceptable_frac = acc_frac;
res.cum_cost_gbp    = cum_cost_out;
res.cum_co2_t       = cum_co2_out;        % whole-life (construction + use-phase)
res.cum_co2_con_t   = cum_co2_con_out;    % construction-phase only
res.cum_co2_use_t   = cum_co2_use_out;    % use-phase only

end


%% ── NETWORK-LEVEL MONTE CARLO ────────────────────────────────────────────────
%
% Varies two network-level parameters jointly using Latin Hypercube Sampling:
%   ODM:               uniform [0.6, 1.4]  (enforcement uncertainty)
%   Initial backlog:   uniform [0.05, 0.35] fraction of 100 km network
%
% Three scenarios run at each sample point: S0 (baseline), S5 (enforcement),
% S6 (combined policy). Records year-20 backlog, cumulative cost, whole-life CO2.
% N = 1000 samples, seed = 42.
%
% Also runs proportional vs priority-based allocation comparison at S0, S5, S6
% over the same sampled space to test whether the priority finding is robust.

fprintf('%s\n', repmat('=',1,78));
fprintf('  NETWORK-LEVEL MONTE CARLO (N=1000, LHS, seed=42)\n');
fprintf('%s\n', repmat('=',1,78));

N_mc   = 1000;
rng(42, 'twister');

% ── LATIN HYPERCUBE SAMPLING ─────────────────────────────────────────────────
% Manual LHS: for each parameter, permute N strata then jitter within stratum
lhs_sample = @(lo, hi, N) lo + ((randperm(N)' - 1 + rand(N,1)) / N) * (hi - lo);

ODM_samples = lhs_sample(0.6, 1.4, N_mc);
IB_samples  = lhs_sample(0.05, 0.35, N_mc);

% Scenario configs for MC: S0, S5, S6
% S0: baseline mix, no enforcement
% S5: baseline mix, ODM from sample * 0.7 (enforcement reduces ODM by 30%)
% S6: plastic-push mix, ODM from sample * 0.7

mc_scenarios = struct();
mc_scenarios(1).label   = 'S0';
mc_scenarios(1).sa      = 0.70; mc_scenarios(1).sl = 0.20; mc_scenarios(1).sp = 0.10;
mc_scenarios(1).odm_mult = 1.0;  % use sampled ODM directly

mc_scenarios(2).label   = 'S5';
mc_scenarios(2).sa      = 0.70; mc_scenarios(2).sl = 0.20; mc_scenarios(2).sp = 0.10;
mc_scenarios(2).odm_mult = 0.7;  % enforcement reduces ODM by 30%

mc_scenarios(3).label   = 'S6';
mc_scenarios(3).sa      = 0.25; mc_scenarios(3).sl = 0.15; mc_scenarios(3).sp = 0.60;
mc_scenarios(3).odm_mult = 0.7;  % combined policy

n_mc_scen = numel(mc_scenarios);
backlog_mc   = zeros(N_mc, n_mc_scen);
cost_mc      = zeros(N_mc, n_mc_scen);
co2_mc       = zeros(N_mc, n_mc_scen);

fprintf('Running %d samples x %d scenarios...\n', N_mc, n_mc_scen);

for i = 1:N_mc
    odm_raw = ODM_samples(i);
    ib_frac = IB_samples(i);

    for j = 1:n_mc_scen
        sc = mc_scenarios(j);
        cfg = p;
        cfg.overload_damage_multiplier = odm_raw * sc.odm_mult;
        cfg.budget_factor = 1.0;
        cfg.rehab_share_asphalt  = sc.sa;
        cfg.rehab_share_laterite = sc.sl;
        cfg.rehab_share_plastic  = sc.sp;

        ib_km = ib_frac * p.total_network_km;
        total_acc = p.total_network_km - ib_km;
        cfg.initial_backlog_km             = ib_km;
        cfg.initial_acceptable_km_asphalt  = total_acc * sc.sa;
        cfg.initial_acceptable_km_laterite = total_acc * sc.sl;
        cfg.initial_acceptable_km_plastic  = total_acc * sc.sp;

        res = run_sd_scenario(cfg);
        backlog_mc(i,j) = res.backlog_km(end);
        cost_mc(i,j)    = res.cum_cost_gbp(end);
        co2_mc(i,j)     = res.cum_co2_t(end);
    end
end

fprintf('Monte Carlo complete.\n\n');

% ── PERCENTILE TABLE ─────────────────────────────────────────────────────────
pcts = [5 25 50 75 95];
fprintf('%-6s  %-8s  %-8s  %-8s  %-8s  %-8s\n', 'Scen', 'p5', 'p25', 'p50', 'p75', 'p95');
fprintf('%s\n', repmat('-', 1, 55));

for j = 1:n_mc_scen
    vals = sort(backlog_mc(:,j));
    p5  = vals(round(0.05*N_mc));
    p25 = vals(round(0.25*N_mc));
    p50 = vals(round(0.50*N_mc));
    p75 = vals(round(0.75*N_mc));
    p95 = vals(round(0.95*N_mc));
    fprintf('%-6s  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f\n', ...
        mc_scenarios(j).label, p5, p25, p50, p75, p95);
end
fprintf('\n');

% ── DOMINANCE CHECK: S6 vs S5 ────────────────────────────────────────────────
s6_beats_s5   = sum(backlog_mc(:,3) < backlog_mc(:,2));
s5_beats_s0   = sum(backlog_mc(:,2) < backlog_mc(:,1));
fprintf('S5 backlog < S0 backlog: %d/%d samples (%.1f%%)\n', s5_beats_s0, N_mc, 100*s5_beats_s0/N_mc);
fprintf('S6 backlog < S5 backlog: %d/%d samples (%.1f%%)\n', s6_beats_s5, N_mc, 100*s6_beats_s5/N_mc);
fprintf('\n');

% ── EXPORT ───────────────────────────────────────────────────────────────────
mc_table = table(ODM_samples, IB_samples, ...
    backlog_mc(:,1), cost_mc(:,1), co2_mc(:,1), ...
    backlog_mc(:,2), cost_mc(:,2), co2_mc(:,2), ...
    backlog_mc(:,3), cost_mc(:,3), co2_mc(:,3), ...
    'VariableNames', { ...
        'ODM_sample', 'InitialBacklog_frac', ...
        'S0_backlog_km', 'S0_cost_GBP', 'S0_co2_wl_t', ...
        'S5_backlog_km', 'S5_cost_GBP', 'S5_co2_wl_t', ...
        'S6_backlog_km', 'S6_cost_GBP', 'S6_co2_wl_t'});

writetable(mc_table, fullfile(outdir, 'network_mc_results.csv'));
fprintf('Saved: network_mc_results.csv\n');

% Percentile summary table
pct_labels = {'p5','p25','p50','p75','p95'};
pct_vals   = [5 25 50 75 95];
pct_rows   = numel(pct_vals);

S0_pct_bk = zeros(pct_rows,1); S5_pct_bk = zeros(pct_rows,1); S6_pct_bk = zeros(pct_rows,1);
S0_pct_co = zeros(pct_rows,1); S5_pct_co = zeros(pct_rows,1); S6_pct_co = zeros(pct_rows,1);

for k = 1:pct_rows
    S0_pct_bk(k) = prctile(backlog_mc(:,1), pct_vals(k));
    S5_pct_bk(k) = prctile(backlog_mc(:,2), pct_vals(k));
    S6_pct_bk(k) = prctile(backlog_mc(:,3), pct_vals(k));
    S0_pct_co(k) = prctile(co2_mc(:,1),     pct_vals(k));
    S5_pct_co(k) = prctile(co2_mc(:,2),     pct_vals(k));
    S6_pct_co(k) = prctile(co2_mc(:,3),     pct_vals(k));
end

pct_table = table(pct_labels', ...
    S0_pct_bk, S5_pct_bk, S6_pct_bk, ...
    S0_pct_co, S5_pct_co, S6_pct_co, ...
    'VariableNames', {'Percentile', ...
        'S0_backlog_km','S5_backlog_km','S6_backlog_km', ...
        'S0_co2_wl_t',  'S5_co2_wl_t',  'S6_co2_wl_t'});

writetable(pct_table, fullfile(outdir, 'network_mc_percentiles.csv'));
fprintf('Saved: network_mc_percentiles.csv\n\n');
fprintf('%s\n\n', repmat('=',1,78));