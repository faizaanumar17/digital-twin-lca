function cfg = config_base()
%CONFIG_BASE Base-case configuration for the pavement digital twin (1 lane-km, 20 years).
%
% This config is the SINGLE SOURCE OF TRUTH for assumptions ("model knobs").
% All other functions should read from cfg.* so that:
%   - sensitivity analysis is easy,
%   - MATLAB → Vensim coupling is clean (exported summaries/lookup tables),
%   - your dissertation is auditable/traceable.

cfg = struct();

%% Horizon / timestep
cfg.T_years = 20;
cfg.dt_year = 1;                 % yearly step (simple + defensible)

%% Functional unit (geometry)
cfg.length_m     = 1000;         % 1 km
cfg.lanes        = 1;            % 1 lane-km functional unit
cfg.lane_width_m = 3.65;         % Nigerian standard lane width
cfg.area_m2      = cfg.length_m * cfg.lanes * cfg.lane_width_m;

%% Base year + currency
cfg.base_year = 2023;
cfg.ngn_per_gbp = 1024.4;
cfg.gbp_per_ngn = 1 / cfg.ngn_per_gbp;

%% Discount rate (real, for NPV)
cfg.discount_rate = 0.12;        % base (sensitivity: 0.08–0.15)

%% Traffic + loading
cfg.traffic = struct();

% Base corridor: Lokoja–Abuja federal trunk road (Oyekanmi et al. 2020 WIM survey)
% Two-way AADT ~13,667 veh/day, HGV 15.9% (conservative; Lokoja-Abuja WIM=30.5%)
cfg.traffic.AADT_total = 13667;       % veh/day (two-way)
cfg.traffic.pct_HGV    = 0.159;       % fraction by vehicle count
cfg.traffic.growth     = 0.04;        % annual growth in AADT

cfg.traffic.lane_split_factor = 0.5;  % single design lane of two-way road

cfg.traffic.ESAs_no_overload = 1.6;
cfg.traffic.ESAs_overload    = 10.0;
cfg.traffic.loading_mode     = "overload";

cfg.traffic.factor_alpha = 0.30;

% Reference annual ESAs (no-overload basis so traffic_factor > 1 represents
% overload amplification relative to a normally-loaded baseline)
refOut = traffic_annual_esas(cfg, cfg.traffic.AADT_total, cfg.traffic.pct_HGV, ...
                             cfg.traffic.ESAs_no_overload, cfg.traffic.lane_split_factor);
cfg.traffic.ref_annual_ESAs = refOut.annual_ESAs;

% ── USE-PHASE CO2: Rolling Resistance Coefficients ───────────────────────────
% RRC values (dimensionless) from Trupia (2017) and Chatti & Zaabar (2012).
% RRC of the reference surface used to compute absolute use-phase CO2.
% Material-specific RRC values are set in the material struct (mat.rrc).
cfg.traffic.rrc_reference = 0.0120;   % conventional asphalt, good condition

% Fuel factors from NCHRP Report 720 (Chatti & Zaabar 2012):
%   Light vehicles: 0.040 L/vehicle/km per unit RRC
%   HGV:            0.150 L/vehicle/km per unit RRC
% Diesel emission factor: 2.64 kg CO2/L (IPCC 2006 Tier 1)
% These are stored in cfg for traceability and sensitivity analysis.
cfg.traffic.rrc_FF_LV       = 0.040;    % L/veh/km per unit RRC, light vehicles
cfg.traffic.rrc_FF_HGV      = 0.150;    % L/veh/km per unit RRC, HGV
cfg.traffic.EF_diesel_kg_L  = 2.64;     % kg CO2 per litre diesel

%% Climate proxy (tropical)
cfg.climate = struct();
cfg.climate.factor = 1.15;

%% Condition index and failure
cfg.CI = struct();
cfg.CI.CI0     = 100;
cfg.CI.failure = 40;
cfg.CI.cap     = 100;

%% Deterioration model (piecewise)
cfg.det = struct();
cfg.det.good_band  = [70 100];
cfg.det.mid_band   = [55 70];
cfg.det.poor_band  = [40 55];
cfg.det.vpoor_band = [0  40];

cfg.det.rate_good  = 2.2;
cfg.det.rate_mid   = 3.0;
cfg.det.rate_poor  = 4.2;
cfg.det.rate_vpoor = 6.0;

%% Maintenance policy
cfg.maint = struct();
cfg.maint.th_minor   = 65;
cfg.maint.th_overlay = 55;
cfg.maint.th_recon   = 40;

cfg.maint.boost_minor   = 4;
cfg.maint.boost_overlay = 28;
cfg.maint.reset_recon   = 100;

cfg.maint.min_interval_minor = 3;
cfg.maint.minor_area_frac    = 0.08;
cfg.maint.delay_years        = 0;

%% Unit costs (NGN/m2)
cfg.cost = struct();
cfg.cost.asphalt_overlay_base         = 9000;
cfg.cost.asphalt_overlay_rng          = [6000 12000];
cfg.cost.recon_overlay_ratio_base     = 2.5;
cfg.cost.recon_overlay_ratio_rng      = [1.8 3.0];
cfg.cost.laterite_reseal_ratio_base   = 0.60;
cfg.cost.laterite_reseal_ratio_rng    = [0.50 0.70];
cfg.cost.laterite_construct_ratio     = 0.75;
cfg.cost.minor_frac_of_overlay_base   = 0.10;
cfg.cost.minor_frac_of_overlay_rng    = [0.05 0.15];
cfg.cost.plastic_premium_base         = 0.20;
cfg.cost.plastic_premium_rng          = [0.10 0.30];

overlayA = cfg.cost.asphalt_overlay_base;
reconA   = overlayA * cfg.cost.recon_overlay_ratio_base;
minorA   = overlayA * cfg.cost.minor_frac_of_overlay_base;

cfg.cost.asphalt = struct( ...
    "construct_ngn_m2", reconA, ...
    "minor_ngn_m2",     minorA, ...
    "overlay_ngn_m2",   overlayA, ...
    "recon_ngn_m2",     reconA);

overlayL = overlayA * cfg.cost.laterite_reseal_ratio_base;
reconL   = reconA   * cfg.cost.laterite_construct_ratio;
minorL   = minorA   * 0.80;

cfg.cost.laterite = struct( ...
    "construct_ngn_m2", reconL, ...
    "minor_ngn_m2",     minorL, ...
    "overlay_ngn_m2",   overlayL, ...
    "recon_ngn_m2",     reconL);

premP = 1 + cfg.cost.plastic_premium_base;

cfg.cost.plastic = struct( ...
    "construct_ngn_m2", reconA * premP, ...
    "minor_ngn_m2",     minorA * premP, ...
    "overlay_ngn_m2",   overlayA * premP, ...
    "recon_ngn_m2",     reconA * premP);

%% Carbon factors and layer assumptions
cfg.carbon = struct();
cfg.carbon.EF_asphalt_mix  = 0.055;
cfg.carbon.EF_aggregate    = 0.010;
cfg.carbon.EF_bitumen      = 0.40;
cfg.carbon.density_asphalt = 2400;
cfg.carbon.density_agg     = 2000;
cfg.carbon.th_overlay_asphalt = 0.05;
cfg.carbon.th_patch_asphalt   = 0.04;
cfg.carbon.th_recon_asphalt   = 0.1262;
cfg.carbon.th_recon_unbound   = 0.35;
cfg.carbon.process_uplift     = 1.20;
cfg.carbon.patch_area_frac    = cfg.maint.minor_area_frac;
cfg.carbon.seal_binder_kg_m2  = 1.2;
cfg.carbon.seal_chips_kg_m2   = 14.0;

%% Calibration targets
cfg.calib = struct();
cfg.calib.asphalt_first_overlay_years  = [8 12];
cfg.calib.asphalt_first_recon_years    = [15 25];
cfg.calib.laterite_first_overlay_years = [5 9];
cfg.calib.plastic_first_overlay_years  = [10 15];

%% Material definitions (RRC + deterioration factor)
% These are convenience structs used as the `mat` argument to simulate_section.
% RRC values from Trupia (2017) and Chatti & Zaabar (2012) NCHRP 720:
%   asphalt:  0.0120 (good condition conventional surface, reference)
%   plastic:  0.0105 (stiffer polymer-modified mix; lower rolling resistance)
%   laterite: 0.0165 (rougher sealed surface; higher rolling resistance)
%
% det_factor is the material-specific deterioration multiplier.

cfg.mat_asphalt  = struct('det_factor', 1.00, 'rrc', 0.0120, 'name', "asphalt");
cfg.mat_laterite = struct('det_factor', 1.35, 'rrc', 0.0165, 'name', "laterite");
cfg.mat_plastic  = struct('det_factor', 0.75, 'rrc', 0.0105, 'name', "plastic");

end