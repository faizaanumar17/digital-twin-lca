%% main_run.m
% Master script. Runs all three materials, produces dissertation figures,
% exports CSVs, prints intervention frequency table, and computes
% break-even analysis.
%
% OUTPUTS (all written to ./outputs/):
%   timeseries_<material>.csv       annual CI, cost, CO2
%   events_<material>.csv           intervention log
%   vensim_params.csv               Vensim coupling parameters
%   config_used.json                frozen config snapshot
%   intervention_frequency.csv      intervention count and timing
%   breakeven_analysis.csv          cumulative cost and CO2 comparison
%   fig4_1_ci_trajectories.png      Figure 4.1
%   fig4_2_cumulative_cost_co2.png  Figure 4.2
%   fig4_3_breakeven.png            Figure 4.3

clear; clc; close all;

addpath(genpath(fullfile(pwd, 'functions')));

cfg  = config_base();
mats = materials();

outAll = struct([]);
outdir = fullfile(pwd, 'outputs');
if ~exist(outdir, 'dir'), mkdir(outdir); end

%% -- 1. RUN SIMULATIONS AND EXPORT RESULTS ----------------------------------

for i = 1:numel(mats)
    res                = simulate_section(cfg, mats(i));
    outAll(i).material = mats(i).name;
    outAll(i).key      = mats(i).key;
    outAll(i).summary  = res.summary;
    outAll(i).res      = res;
    export_results(cfg, mats(i), res);
end

export_vensim_params(cfg, mats, outAll);


%% -- 2. INTERVENTION FREQUENCY SUMMARY TABLE --------------------------------

fprintf('\n=======================================================\n');
fprintf('          INTERVENTION FREQUENCY SUMMARY\n');
fprintf('=======================================================\n');
fprintf('%-32s %6s %7s %6s %11s %10s\n', ...
    'Material','Minor','Overlay','Recon','1st Overlay','1st Recon');
fprintf('-------------------------------------------------------\n');

for i = 1:numel(mats)
    s = outAll(i).summary;
    fo_str = '   N/A'; fr_str = '   N/A';
    if ~isnan(s.first_overlay_year), fo_str = sprintf('Yr %5.1f', s.first_overlay_year); end
    if ~isnan(s.first_recon_year),   fr_str = sprintf('Yr %5.1f', s.first_recon_year);   end
    fprintf('%-32s %6d %7d %6d %11s %10s\n', ...
        outAll(i).material, s.n_minor, s.n_overlay, s.n_recon, fo_str, fr_str);
end
fprintf('=======================================================\n\n');

mat_names     = string({outAll.material})';
n_minor_vec   = arrayfun(@(x) x.summary.n_minor,            outAll)';
n_overlay_vec = arrayfun(@(x) x.summary.n_overlay,          outAll)';
n_recon_vec   = arrayfun(@(x) x.summary.n_recon,            outAll)';
fo_vec        = arrayfun(@(x) x.summary.first_overlay_year, outAll)';
fr_vec        = arrayfun(@(x) x.summary.first_recon_year,   outAll)';
npv_vec       = arrayfun(@(x) x.summary.npv_cost_gbp,       outAll)';
co2_vec       = arrayfun(@(x) x.summary.total_co2_t,        outAll)';

freq_table = table(mat_names, n_minor_vec, n_overlay_vec, n_recon_vec, ...
                   fo_vec, fr_vec, npv_vec, co2_vec, ...
    'VariableNames', {'Material','N_Minor','N_Overlay','N_Recon', ...
                      'First_Overlay_Year','First_Recon_Year', ...
                      'NPV_Cost_GBP','Total_CO2_t'});
writetable(freq_table, fullfile(outdir, 'intervention_frequency.csv'));


%% -- 3. BREAK-EVEN DATA PREP ------------------------------------------------

% Robust key lookup: handles both MATLAB string ("") and char ('') types
keys_cell = arrayfun(@(x) char(x.key), outAll, 'UniformOutput', false);
idx_a = find(strcmp(keys_cell, 'asphalt'), 1);
idx_p = find(strcmp(keys_cell, 'plastic'), 1);

if isempty(idx_a) || isempty(idx_p)
    error('Could not find asphalt or plastic in outAll. Keys found: %s', ...
          strjoin(keys_cell, ', '));
end

res_a = outAll(idx_a).res;
res_p = outAll(idx_p).res;

cum_cost_A = cumsum(res_a.cost_gbp);
cum_cost_P = cumsum(res_p.cost_gbp);
cost_diff  = cum_cost_P - cum_cost_A;

cum_co2_A  = cumsum(res_a.co2_t);
cum_co2_P  = cumsum(res_p.co2_t);
co2_diff   = cum_co2_P - cum_co2_A;

be_table = table(res_a.t_years, cum_cost_A, cum_cost_P, cost_diff, ...
                 cum_co2_A, cum_co2_P, co2_diff, ...
    'VariableNames', {'Year', ...
                      'CumCost_Asphalt_GBP','CumCost_Plastic_GBP','Cost_Diff_GBP', ...
                      'CumCO2_Asphalt_t','CumCO2_Plastic_t','CO2_Diff_t'});
writetable(be_table, fullfile(outdir, 'breakeven_analysis.csv'));
fprintf('Break-even data written.\n');


%% -- 4. FIGURE 4.1: CI TRAJECTORIES -----------------------------------------
% Line plot: Year vs Condition Index for all three materials.
% Filled markers = overlay/reseal events. Open markers = minor repairs.

col_A = [0.12, 0.47, 0.71];  % blue
col_L = [0.84, 0.15, 0.16];  % red
col_P = [0.17, 0.63, 0.17];  % green

minor_co2_thresh = 5;  % t CO2 cutoff: below = minor repair, above = overlay/reseal

fig41 = figure('Visible','off','Units','centimeters','Position',[2 2 18 11]);
hold on;

yline(40, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.1, ...
      'Label', 'Reconstruction threshold (CI = 40)', ...
      'LabelHorizontalAlignment', 'left', 'FontSize', 8, ...
      'HandleVisibility', 'off');

keys_order   = {'asphalt', 'laterite', 'plastic'};
labels_ci    = {'Conventional asphalt', 'Sealed laterite', 'Plastic-modified asphalt'};
cols_ci      = {col_A, col_L, col_P};
mark_filled  = {'o', 's', '^'};

for i = 1:3
    idx = find(strcmp(keys_cell, keys_order{i}), 1);
    r   = outAll(idx).res;
    col = cols_ci{i};

    plot(r.t_years, r.CI, '-', 'Color', col, 'LineWidth', 2.0, ...
         'DisplayName', labels_ci{i});

    % Overlay / reseal: filled markers
    mask_ovl = r.cost_gbp > 0 & r.t_years > 0 & r.co2_t >= minor_co2_thresh;
    if any(mask_ovl)
        plot(r.t_years(mask_ovl), r.CI(mask_ovl), mark_filled{i}, ...
             'Color', col, 'MarkerFaceColor', col, 'MarkerSize', 7, ...
             'HandleVisibility', 'off');
    end

    % Minor repair: open markers
    mask_min = r.cost_gbp > 0 & r.t_years > 0 & r.co2_t < minor_co2_thresh;
    if any(mask_min)
        plot(r.t_years(mask_min), r.CI(mask_min), mark_filled{i}, ...
             'Color', col, 'MarkerFaceColor', 'white', 'MarkerSize', 5, ...
             'HandleVisibility', 'off');
    end
end

hold off;
xlabel('Year', 'FontSize', 10);
ylabel('Condition Index (CI)', 'FontSize', 10);
xlim([0 20]); ylim([35 105]);
xticks(0:2:20); yticks(40:10:100);
legend('Location', 'southeast', 'FontSize', 9, 'Box', 'on');
grid on;
ax = gca; ax.FontSize = 9; ax.GridAlpha = 0.3; ax.GridLineStyle = ':';
box on;

annotation(fig41, 'textbox', [0.13 0.15 0.34 0.10], ...
    'String', {'Filled marker = overlay / reseal', 'Open marker = minor repair'}, ...
    'FontSize', 7.5, 'EdgeColor', [0.8 0.8 0.8], ...
    'BackgroundColor', 'white', 'FitBoxToText', 'on');

out41 = fullfile(outdir, 'fig4_1_ci_trajectories.png');
print(fig41, out41, '-dpng', '-r300');
fprintf('Saved: %s\n', out41);
close(fig41);


%% -- 5. FIGURE 4.2: CUMULATIVE COST AND CO2 ---------------------------------
% Two side-by-side panels: (a) cumulative undiscounted cost, (b) cumulative CO2.

keys_order = {'asphalt', 'laterite', 'plastic'};
labels_42  = {'Conventional asphalt', 'Sealed laterite', 'Plastic-modified asphalt'};
cols42     = {col_A, col_L, col_P};
yrs42      = outAll(find(strcmp(keys_cell,'asphalt'),1)).res.t_years;

cum_costs = cell(3,1);
cum_co2s  = cell(3,1);
for i = 1:3
    idx = find(strcmp(keys_cell, keys_order{i}), 1);
    cum_costs{i} = cumsum(outAll(idx).res.cost_gbp);
    cum_co2s{i}  = cumsum(outAll(idx).res.co2_t);
end

fig42 = figure('Visible','off','Units','centimeters','Position',[2 2 22 10]);

subplot(1, 2, 1); hold on;
for i = 1:3
    plot(yrs42, cum_costs{i}/1000, '-', 'Color', cols42{i}, ...
         'LineWidth', 2.0, 'DisplayName', labels_42{i});
end
% Endpoint labels with vertical offset to avoid overlap
cost_ends = cellfun(@(c) c(end)/1000, cum_costs);
% Sort to detect close values and offset
offsets = [0, 0, 0];  % default no offset
% If asphalt and plastic are within 8k, offset them apart
if abs(cost_ends(1) - cost_ends(3)) < 8
    offsets(1) = 3;   % asphalt up
    offsets(3) = -3;  % plastic down
end
for i = 1:3
    text(20.3, cost_ends(i) + offsets(i), ...
         sprintf([char(163) '%.0fk'], cost_ends(i)), ...
         'FontSize', 8, 'Color', cols42{i}, 'VerticalAlignment', 'middle');
end
hold off;
xlabel('Year', 'FontSize', 10);
ylabel(['Cumulative cost (' char(163) ' thousands)'], 'FontSize', 9);
title('(a) Agency cost', 'FontSize', 10, 'FontWeight', 'normal');
xlim([0 21]); xticks(0:4:20);
ylim([0, max(cellfun(@(c) c(end), cum_costs))/1000 * 1.18]);
legend('Location', 'northwest', 'FontSize', 8, 'Box', 'on');
grid on; ax = gca; ax.FontSize = 9; ax.GridAlpha = 0.3; ax.GridLineStyle = ':'; box on;

subplot(1, 2, 2); hold on;
for i = 1:3
    plot(yrs42, cum_co2s{i}, '-', 'Color', cols42{i}, ...
         'LineWidth', 2.0, 'DisplayName', labels_42{i});
end
for i = 1:3
    text(20.2, cum_co2s{i}(end), sprintf('%.1f t', cum_co2s{i}(end)), ...
         'FontSize', 8, 'Color', cols42{i}, 'VerticalAlignment', 'middle');
end
hold off;
xlabel('Year', 'FontSize', 10);
ylabel('Cumulative embodied CO_2 (tonnes)', 'FontSize', 9);
title('(b) Embodied CO_2', 'FontSize', 10, 'FontWeight', 'normal');
xlim([0 21]); xticks(0:4:20);
ylim([0, max(cellfun(@(c) c(end), cum_co2s)) * 1.18]);
legend('Location', 'northwest', 'FontSize', 8, 'Box', 'on');
grid on; ax = gca; ax.FontSize = 9; ax.GridAlpha = 0.3; ax.GridLineStyle = ':'; box on;

out42 = fullfile(outdir, 'fig4_2_cumulative_cost_co2.png');
print(fig42, out42, '-dpng', '-r300');
fprintf('Saved: %s\n', out42);
close(fig42);


%% -- 6. FIGURE 4.3: BREAK-EVEN ANALYSIS -------------------------------------
% Two stacked panels: (a) cost difference, (b) CO2 difference (plastic - asphalt).
% Green shading = plastic better; red shading = plastic worse.

col_cost = [0.49, 0.18, 0.56];
col_co2b = [0.17, 0.63, 0.17];
col_zero = [0.50, 0.50, 0.50];

fig43 = figure('Visible','off','Units','centimeters','Position',[2 2 18 13]);

% Convert cost difference to thousands for cleaner axis
cost_diff_k = cost_diff / 1000;
yrs43 = res_a.t_years;

subplot(2, 1, 1); hold on;

% Fill positive regions (plastic costlier) and negative regions (plastic cheaper)
% Walk through data and fill segments between zero crossings
for t = 1:length(yrs43)-1
    xpatch = [yrs43(t), yrs43(t+1), yrs43(t+1), yrs43(t)];
    ypatch = [0, 0, cost_diff_k(t+1), cost_diff_k(t)];
    if cost_diff_k(t) >= 0 && cost_diff_k(t+1) >= 0
        fill(xpatch, ypatch, [1.0 0.82 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    elseif cost_diff_k(t) <= 0 && cost_diff_k(t+1) <= 0
        fill(xpatch, ypatch, [0.82 1.0 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    else
        % Segment crosses zero: split at crossing point
        xc = yrs43(t) - cost_diff_k(t) * (yrs43(t+1)-yrs43(t)) / (cost_diff_k(t+1)-cost_diff_k(t));
        if cost_diff_k(t) > 0
            fill([yrs43(t), xc, xc, yrs43(t)], [0, 0, 0, cost_diff_k(t)], ...
                 [1.0 0.82 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
            fill([xc, yrs43(t+1), yrs43(t+1), xc], [0, 0, cost_diff_k(t+1), 0], ...
                 [0.82 1.0 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
        else
            fill([yrs43(t), xc, xc, yrs43(t)], [0, 0, 0, cost_diff_k(t)], ...
                 [0.82 1.0 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
            fill([xc, yrs43(t+1), yrs43(t+1), xc], [0, 0, cost_diff_k(t+1), 0], ...
                 [1.0 0.82 0.82], 'EdgeColor', 'none', 'HandleVisibility', 'off');
        end
    end
end

% Invisible patches for legend only
fill(NaN, NaN, [1.0 0.82 0.82], 'EdgeColor', 'none', 'DisplayName', 'Plastic costlier');
fill(NaN, NaN, [0.82 1.0 0.82], 'EdgeColor', 'none', 'DisplayName', 'Plastic cheaper');

yline(0, '-', 'Color', col_zero, 'LineWidth', 0.9, 'HandleVisibility', 'off');
plot(yrs43, cost_diff_k, '-', 'Color', col_cost, 'LineWidth', 2.2, ...
     'DisplayName', 'Difference (Plastic - Asphalt)');

text(0.3, cost_diff_k(1)+0.7, sprintf('+%s%.1fk (yr 0)', char(163), cost_diff_k(1)), ...
     'FontSize', 8, 'Color', col_cost);
text(19.5, cost_diff_k(end)-1.2, sprintf('%s%.1fk (yr 20)', char(163), cost_diff_k(end)), ...
     'FontSize', 8, 'Color', col_cost, 'HorizontalAlignment', 'right');
hold off;
ylabel(['Cost difference (' char(163) ' thousands)'], 'FontSize', 9);
title('(a) Cumulative cost difference: Plastic minus Asphalt', ...
      'FontSize', 9.5, 'FontWeight', 'normal');
xlim([0 20]); xticks(0:2:20);
legend('Location', 'northeast', 'FontSize', 8, 'Box', 'on');
grid on; ax = gca; ax.FontSize = 9; ax.GridAlpha = 0.3; ax.GridLineStyle = ':'; box on;

subplot(2, 1, 2); hold on;

% Fill below zero (plastic always lower CO2)
fill([yrs43; flipud(yrs43)], [co2_diff; zeros(size(co2_diff))], ...
     [0.82 1.0 0.82], 'EdgeColor', 'none', 'DisplayName', 'Plastic lower CO_2');

yline(0, '-', 'Color', col_zero, 'LineWidth', 0.9, 'HandleVisibility', 'off');
plot(yrs43, co2_diff, '-', 'Color', col_co2b, 'LineWidth', 2.2, ...
     'DisplayName', 'Difference (Plastic - Asphalt)');
text(0.3, co2_diff(1)+2, sprintf('%.1f t (yr 0)', co2_diff(1)), ...
     'FontSize', 8, 'Color', col_co2b);
text(18.5, co2_diff(end)-3, sprintf('%.1f t (yr 20)', co2_diff(end)), ...
     'FontSize', 8, 'Color', col_co2b, 'HorizontalAlignment', 'right');
hold off;
xlabel('Year', 'FontSize', 10);
ylabel('CO_2 difference (tonnes)', 'FontSize', 9);
title('(b) Cumulative CO_2 difference: Plastic minus Asphalt', ...
      'FontSize', 9.5, 'FontWeight', 'normal');
xlim([0 20]); xticks(0:2:20);
legend('Location', 'southwest', 'FontSize', 8, 'Box', 'on');
grid on; ax = gca; ax.FontSize = 9; ax.GridAlpha = 0.3; ax.GridLineStyle = ':'; box on;

out43 = fullfile(outdir, 'fig4_3_breakeven.png');
print(fig43, out43, '-dpng', '-r300');
fprintf('Saved: %s\n', out43);
close(fig43);


%% -- 7. DONE ----------------------------------------------------------------

fprintf('\nAll outputs written to /outputs\n');
fprintf('CSVs: timeseries, events, vensim_params, config_used,\n');
fprintf('      intervention_frequency, breakeven_analysis\n');
fprintf('Figures: fig4_1_ci_trajectories.png\n');
fprintf('         fig4_2_cumulative_cost_co2.png\n');
fprintf('         fig4_3_breakeven.png\n');