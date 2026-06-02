%% willingness_to_pay.m
% Willingness-to-pay (WTP) framing for overload enforcement.
%
% Computes the monetary equivalent of strong enforcement by answering:
% "How much additional annual budget would a road agency need to achieve
%  the same backlog reduction as stronger enforcement alone?"
%
% Uses SD scenario trajectories already produced by time_to_crisis.m.
% Run time_to_crisis.m first, then run this script.
%
% Place in your MATLAB project folder. Outputs written to /outputs.

clear; clc;

outdir = fullfile(pwd, "outputs");
if ~exist(outdir, 'dir'); mkdir(outdir); end

%% ── LOAD SD SCENARIO TRAJECTORIES ──────────────────────────────────────────

fprintf('Loading SD scenario trajectories from /outputs...\n\n');

% Check files exist
required = {"sd_S0_Baseline.csv", "sd_S1_LowBudget.csv", "sd_S2_HighBudget.csv", ...
            "sd_S5_StrongEnforcement.csv", "sd_S6_CombinedPolicy.csv"};

for f = 1:numel(required)
    fpath = fullfile(outdir, required{f});
    if ~exist(fpath, 'file')
        error("Required file not found: %s\n" + ...
              "Please run time_to_crisis.m first.", fpath);
    end
end

S0 = readtable(fullfile(outdir, "sd_S0_Baseline.csv"));
S1 = readtable(fullfile(outdir, "sd_S1_LowBudget.csv"));
S2 = readtable(fullfile(outdir, "sd_S2_HighBudget.csv"));
S5 = readtable(fullfile(outdir, "sd_S5_StrongEnforcement.csv"));
S6 = readtable(fullfile(outdir, "sd_S6_CombinedPolicy.csv"));

% SD model parameters (must match time_to_crisis.m)
baseline_budget_gbp = 844794;
total_network_km    = 100;
T                   = 20;


%% ── CORE WTP CALCULATION ────────────────────────────────────────────────────
%
% Logic:
%   S5 achieves a backlog reduction relative to S0 through enforcement alone.
%   We find the budget multiplier (S_budget) that produces the same yr-20
%   backlog as S5 by interpolating between S1 (0.7x) and S2 (1.3x).
%   WTP = (S_budget - 1.0) * baseline_budget_gbp
%
% This is the monetary value of enforcement: what an agency would need to
% spend on additional maintenance budget to replicate what enforcement gives
% for free (or at much lower administrative cost).

backlog_S0_yr20 = S0.Backlog_km(end);
backlog_S1_yr20 = S1.Backlog_km(end);
backlog_S2_yr20 = S2.Backlog_km(end);
backlog_S5_yr20 = S5.Backlog_km(end);
backlog_S6_yr20 = S6.Backlog_km(end);

backlog_frac_S0 = S0.Backlog_fraction(end);
backlog_frac_S5 = S5.Backlog_fraction(end);
backlog_frac_S6 = S6.Backlog_fraction(end);

% Backlog improvement from enforcement (S5 vs S0)
backlog_reduction_S5 = backlog_S0_yr20 - backlog_S5_yr20;   % km
backlog_reduction_S6 = backlog_S0_yr20 - backlog_S6_yr20;   % km

% Interpolate: what budget factor achieves the same backlog as S5?
% Linear interpolation between S1 (0.7x, backlog_S1) and S2 (1.3x, backlog_S2)
% Note: higher budget → lower backlog, so interpolation is decreasing
% Check whether budget variation produces different backlog outcomes
budget_factors      = [0.7, 1.0, 1.3];
backlogs_at_factors = [backlog_S1_yr20, backlog_S0_yr20, backlog_S2_yr20];
backlog_range       = max(backlogs_at_factors) - min(backlogs_at_factors);

% Threshold: if budget produces <0.5 km variation, system is backlog-limited
BUDGET_LIMITED_THRESHOLD = 0.5;

if backlog_range < BUDGET_LIMITED_THRESHOLD
    % System is BACKLOG-LIMITED — budget changes have negligible effect.
    % WTP cannot be computed by interpolation.
    % Instead: compute how much extra budget would be needed based on
    % the unit cost of rehabilitating the backlog difference directly.
    
    % Unit cost of rehabilitating 1 km (baseline mix weighted cost)
    unit_cost_baseline = 0.70*21256.9 + 0.20*11820.8 + 0.10*26067.1;  % GBP/km
    
    % Annual cost to rehabilitate the enforcement-driven backlog reduction
    wtp_annual_S5 = backlog_reduction_S5 * unit_cost_baseline;
    wtp_annual_S6 = backlog_reduction_S6 * unit_cost_baseline;
    
    equiv_budget_factor_S5 = 1.0 + (wtp_annual_S5 / baseline_budget_gbp);
    equiv_budget_factor_S6 = 1.0 + (wtp_annual_S6 / baseline_budget_gbp);
    
    budget_limited = true;
else
    % Normal interpolation path
    equiv_budget_factor_S5 = interp1(backlogs_at_factors, budget_factors, ...
                                      backlog_S5_yr20, 'linear', 'extrap');
    equiv_budget_factor_S6 = interp1(backlogs_at_factors, budget_factors, ...
                                      backlog_S6_yr20, 'linear', 'extrap');
    budget_limited = false;
end

wtp_total_S5 = wtp_annual_S5 * T;
wtp_total_S6 = wtp_annual_S6 * T;

% WTP = additional annual budget needed above baseline
wtp_annual_S5 = (equiv_budget_factor_S5 - 1.0) * baseline_budget_gbp;
wtp_annual_S6 = (equiv_budget_factor_S6 - 1.0) * baseline_budget_gbp;

% WTP over full 20-year horizon
wtp_total_S5 = wtp_annual_S5 * T;
wtp_total_S6 = wtp_annual_S6 * T;

% CO2 and cost savings from enforcement
co2_saving_S5  = S0.Cumulative_CO2_t(end)  - S5.Cumulative_CO2_t(end);
co2_saving_S6  = S0.Cumulative_CO2_t(end)  - S6.Cumulative_CO2_t(end);
cost_saving_S5 = S0.Cumulative_cost_GBP(end) - S5.Cumulative_cost_GBP(end);
cost_saving_S6 = S0.Cumulative_cost_GBP(end) - S6.Cumulative_cost_GBP(end);

% Enforcement "leverage ratio" — backlog reduction per £ of WTP
if wtp_annual_S5 > 0
    leverage_S5 = backlog_reduction_S5 / (wtp_annual_S5);   % km per £/yr
else
    leverage_S5 = Inf;
end
if wtp_annual_S6 > 0
    leverage_S6 = backlog_reduction_S6 / (wtp_annual_S6);
else
    leverage_S6 = Inf;
end


%% ── PRINT RESULTS ───────────────────────────────────────────────────────────

fprintf('%s\n', repmat('=',1,72));
fprintf('  WILLINGNESS-TO-PAY ANALYSIS: Monetary Value of Enforcement\n');
fprintf('%s\n', repmat('=',1,72));

fprintf('\n  Baseline budget (S0):    GBP %.0f/year\n', baseline_budget_gbp);
fprintf('  Analysis horizon:        %d years\n\n', T);

fprintf('  %-38s %12s %12s\n', 'Metric', 'S5 Enforce', 'S6 Combined');
fprintf('  %s\n', repmat('-',1,64));
fprintf('  %-38s %12.1f %12.1f\n', 'Backlog at year 20 (km)', ...
    backlog_S5_yr20, backlog_S6_yr20);
fprintf('  %-38s %12.1f %12.1f\n', 'Backlog reduction vs S0 (km)', ...
    backlog_reduction_S5, backlog_reduction_S6);
fprintf('  %-38s %12.3f %12.3f\n', 'Backlog fraction at year 20', ...
    backlog_frac_S5, backlog_frac_S6);
fprintf('  %s\n', repmat('-',1,64));
fprintf('  %-38s %12.2f %12.2f\n', 'Equivalent budget factor', ...
    equiv_budget_factor_S5, equiv_budget_factor_S6);
fprintf('  %-38s %12.0f %12.0f\n', 'WTP — annual equivalent (GBP/yr)', ...
    wtp_annual_S5, wtp_annual_S6);
fprintf('  %-38s %12.0f %12.0f\n', 'WTP — 20-year total (GBP)', ...
    wtp_total_S5, wtp_total_S6);
fprintf('  %s\n', repmat('-',1,64));
fprintf('  %-38s %12.0f %12.0f\n', 'CO2 saving vs S0 (t over 20 yr)', ...
    co2_saving_S5, co2_saving_S6);
fprintf('  %-38s %12.0f %12.0f\n', 'Agency cost saving vs S0 (GBP)', ...
    cost_saving_S5, cost_saving_S6);
fprintf('%s\n\n', repmat('=',1,72));

% Interpretation sentence
fprintf('  INTERPRETATION:\n');
fprintf('  Strong enforcement (S5) achieves a %.1f km backlog reduction\n', backlog_reduction_S5);
fprintf('  equivalent to increasing the annual maintenance budget by\n');
if wtp_annual_S5 > 0
    fprintf('  approximately GBP %.0f/year (%.2fx baseline).\n\n', ...
        wtp_annual_S5, equiv_budget_factor_S5);
else
    fprintf('  less than baseline (enforcement outperforms any budget increase\n');
    fprintf('  within the tested range).\n\n');
end

fprintf('  Combined policy (S6) achieves a %.1f km backlog reduction\n', backlog_reduction_S6);
if wtp_annual_S6 > 0
    fprintf('  equivalent to GBP %.0f/year additional budget (%.2fx baseline).\n\n', ...
        wtp_annual_S6, equiv_budget_factor_S6);
else
    fprintf('  beyond the budget range tested — enforcement + material shift\n');
    fprintf('  outperforms any isolated budget increase in this model.\n\n');
end


%% ── EXPORT TABLE ────────────────────────────────────────────────────────────

wtp_table = table( ...
    ["S5 – Strong enforcement"; "S6 – Combined policy"], ...
    [backlog_S5_yr20; backlog_S6_yr20], ...
    [backlog_reduction_S5; backlog_reduction_S6], ...
    [equiv_budget_factor_S5; equiv_budget_factor_S6], ...
    [wtp_annual_S5; wtp_annual_S6], ...
    [wtp_total_S5; wtp_total_S6], ...
    [co2_saving_S5; co2_saving_S6], ...
    [cost_saving_S5; cost_saving_S6], ...
    'VariableNames', { ...
        'Scenario', ...
        'Backlog_km_yr20', ...
        'Backlog_reduction_km', ...
        'Equivalent_budget_factor', ...
        'WTP_annual_GBP', ...
        'WTP_total_20yr_GBP', ...
        'CO2_saving_t', ...
        'Agency_cost_saving_GBP'});

writetable(wtp_table, fullfile(outdir, "willingness_to_pay.csv"));


%% ── PLOTS ───────────────────────────────────────────────────────────────────

% Plot 1: Backlog trajectories S0, S1, S2, S5, S6
figure('Name','WTP: Backlog Trajectories');
hold on;
plot(S0.Year, S0.Backlog_km, '-o', 'LineWidth',2, 'Color','#2166ac', 'DisplayName','S0 Baseline (1.0x budget)');
plot(S1.Year, S1.Backlog_km, '--s', 'LineWidth',1.5, 'Color','#92c5de', 'DisplayName','S1 Low-budget (0.7x)');
plot(S2.Year, S2.Backlog_km, '--^', 'LineWidth',1.5, 'Color','#4dac26', 'DisplayName','S2 High-budget (1.3x)');
plot(S5.Year, S5.Backlog_km, '-d', 'LineWidth',2.5, 'Color','#d73027', 'DisplayName','S5 Strong enforcement');
plot(S6.Year, S6.Backlog_km, '-v', 'LineWidth',2.5, 'Color','#b35806', 'DisplayName','S6 Combined policy');
hold off;
grid on;
legend('Location','best','FontSize',9);
xlabel('Year');
ylabel('Backlog (km)');
title('Backlog Trajectories: Enforcement vs Budget Increases');

% Plot 2: Bar chart — WTP annual equivalent
figure('Name','WTP: Annual Monetary Equivalent of Enforcement');
bar_data = [wtp_annual_S5, wtp_annual_S6];
bar_labels = {"S5 – Strong enforcement", "S6 – Combined policy"};
b = bar(bar_data, 0.5, 'FaceColor','flat');
b.CData(1,:) = [0.84 0.19 0.15];
b.CData(2,:) = [0.70 0.35 0.02];
set(gca, 'XTickLabel', bar_labels, 'XTick', 1:2);
xtickangle(10);
grid on;
ylabel('Annual WTP equivalent (GBP/year)');
title('Willingness-to-Pay: Annual Monetary Value of Enforcement');

% Add value labels on bars
for i = 1:2
    text(i, bar_data(i) + max(bar_data)*0.02, ...
         sprintf('£%.0f', bar_data(i)), ...
         'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
end

% Plot 3: Cumulative cost saving from enforcement
figure('Name','WTP: Cumulative Cost Saving from Enforcement');
hold on;
cost_diff_S5 = S0.Cumulative_cost_GBP - S5.Cumulative_cost_GBP;
cost_diff_S6 = S0.Cumulative_cost_GBP - S6.Cumulative_cost_GBP;
plot(S0.Year, cost_diff_S5, '-d', 'LineWidth',2, 'Color','#d73027', ...
     'DisplayName','S5 – cost saving vs S0');
plot(S0.Year, cost_diff_S6, '-v', 'LineWidth',2, 'Color','#b35806', ...
     'DisplayName','S6 – cost saving vs S0');
yline(0,'--k','LineWidth',1);
hold off;
grid on;
legend('Location','best');
xlabel('Year');
ylabel('Cumulative cost saving (GBP)');
title('Cumulative Agency Cost Saving from Enforcement vs Baseline');


%% ── DONE ────────────────────────────────────────────────────────────────────

fprintf('Output written to /outputs:\n');
fprintf('  willingness_to_pay.csv    WTP summary table\n');
