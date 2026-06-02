function res = simulate_section(cfg, mat)
%SIMULATE_SECTION Discrete-time road-section simulation (1 lane-km).
%
% Processes:
%   1) annual deterioration (piecewise, CI points/year)
%   2) threshold-based maintenance triggering (recon > overlay > minor)
%   3) maintenance delay queue (optional)
%   4) cost + CO2 accounting per event
%   5) use-phase CO2 from rolling resistance (Trupia 2017 / NCHRP 720)
%
% Required additional field in mat struct:
%   mat.rrc  - Rolling Resistance Coefficient (dimensionless)
%              asphalt: 0.0120, plastic: 0.0105, laterite: 0.0165
%
% Outputs include separate construction-phase and use-phase CO2 streams
% so the two contributions can be reported and compared independently.

T  = cfg.T_years;
dt = cfg.dt_year;

t_years = (0:dt:T)';
n = numel(t_years);

CI = zeros(n,1);
CI(1) = cfg.CI.CI0;

cost_ngn     = zeros(n,1);
co2_con_kg   = zeros(n,1);   % construction-phase (maintenance events)
co2_use_kg   = zeros(n,1);   % use-phase (rolling resistance)

event_year = [];
event_type = strings(0,1);

% Initial construction at year 0
[c0, e0] = event_cost_emissions(cfg, mat, "construct");
cost_ngn(1)   = cost_ngn(1)   + c0;
co2_con_kg(1) = co2_con_kg(1) + e0;

queued_type = strings(n,1);
queued_type(:) = "";

last_minor_year = -Inf;

% Select ESAs/HGV based on scenario
if cfg.traffic.loading_mode == "overload"
    ESAs_per_HV_used = cfg.traffic.ESAs_overload;
else
    ESAs_per_HV_used = cfg.traffic.ESAs_no_overload;
end

% RRC for this material (default to asphalt reference if not set)
if isfield(mat, 'rrc')
    rrc_material = mat.rrc;
else
    rrc_material = 0.0120;
    warning('simulate_section: mat.rrc not set, using asphalt default 0.012');
end

for k = 2:n
    year = t_years(k);

    % AADT grows
    AADT_y = cfg.traffic.AADT_total * (1 + cfg.traffic.growth)^(year);

    % Annual ESAs on modelled lane
    annOut = traffic_annual_esas(cfg, AADT_y, cfg.traffic.pct_HGV, ...
                                 ESAs_per_HV_used, cfg.traffic.lane_split_factor);

    % CRITICAL FIX:
    % make traffic_factor respond to OVERLOADING by normalising to NO-OVERLOAD reference
    traffic_factor = (annOut.annual_ESAs / cfg.traffic.ref_annual_ESAs) ^ cfg.traffic.factor_alpha;

    % ── USE-PHASE CO2 (rolling resistance, Trupia 2017 / NCHRP 720) ──────────
    [ann_use_co2_t, ~] = rrc_annual_co2(rrc_material, AADT_y);
    co2_use_kg(k) = ann_use_co2_t * 1000 * dt;

    % Deterioration
    dCI = deterioration_step(cfg, CI(k-1), traffic_factor, cfg.climate.factor, mat.det_factor);
    CI_k = max(CI(k-1) - dCI*dt, 0);

    % Execute queued event
    if queued_type(k) ~= ""
        [CI_k, c, e, evType] = apply_intervention(cfg, CI_k, mat, queued_type(k));
        cost_ngn(k)   = cost_ngn(k)   + c;
        co2_con_kg(k) = co2_con_kg(k) + e;

        event_year(end+1,1) = year; %#ok<AGROW>
        event_type(end+1,1) = evType; %#ok<AGROW>

        if evType == "minor"
            last_minor_year = year;
        end

        queued_type(k) = "";
    else
        trig = maintenance_trigger(cfg, CI_k);

        % Minimum interval for minor maintenance
        if trig == "minor"
            if (year - last_minor_year) < cfg.maint.min_interval_minor
                trig = "";
            end
        end

        if trig ~= ""
            exec_index = min(k + cfg.maint.delay_years, n);
            queued_type(exec_index) = trig;

            if cfg.maint.delay_years == 0
                [CI_k, c, e, evType] = apply_intervention(cfg, CI_k, mat, trig);
                cost_ngn(k)   = cost_ngn(k)   + c;
                co2_con_kg(k) = co2_con_kg(k) + e;

                event_year(end+1,1) = year; %#ok<AGROW>
                event_type(end+1,1) = evType; %#ok<AGROW>

                if evType == "minor"
                    last_minor_year = year;
                end

                queued_type(exec_index) = "";
            end
        end
    end

    CI(k) = min(CI_k, cfg.CI.cap);
end

% ── TOTAL CO2 = CONSTRUCTION-PHASE + USE-PHASE ───────────────────────────────
co2_kg = co2_con_kg + co2_use_kg;

cost_gbp        = cost_ngn       * cfg.gbp_per_ngn;
co2_t           = co2_kg         / 1000;
co2_con_t       = co2_con_kg     / 1000;
co2_use_t       = co2_use_kg     / 1000;

events = table(event_year, event_type, 'VariableNames', {'Year','Type'});

% Pass construction-phase co2 to summarize_outputs so calibration/NPV
% comparisons remain construction-only (existing behaviour preserved).
% Whole-life total is reported separately.
summary = summarize_outputs(cfg, mat, t_years, CI, cost_ngn, co2_con_kg, events);
summary.loading_mode         = string(cfg.traffic.loading_mode);
summary.ESAs_per_HV_used     = ESAs_per_HV_used;
summary.lane_split_factor    = cfg.traffic.lane_split_factor;
summary.AADT_total_two_way   = cfg.traffic.AADT_total;
summary.pct_HGV              = cfg.traffic.pct_HGV;
summary.rrc_material         = rrc_material;
summary.total_co2_construction_t = sum(co2_con_t);
summary.total_co2_use_phase_t    = sum(co2_use_t);
summary.total_co2_whole_life_t   = sum(co2_con_t) + sum(co2_use_t);

res = struct( ...
    "t_years",    t_years, ...
    "CI",         CI, ...
    "cost_ngn",   cost_ngn, ...
    "cost_gbp",   cost_gbp, ...
    "co2_kg",     co2_kg, ...          % whole-life total
    "co2_t",      co2_t, ...           % whole-life total (tonnes)
    "co2_con_kg", co2_con_kg, ...      % construction-phase only
    "co2_con_t",  co2_con_t, ...
    "co2_use_kg", co2_use_kg, ...      % use-phase only
    "co2_use_t",  co2_use_t, ...
    "events",     events, ...
    "summary",    summary);

end