function summary = summarize_outputs(cfg, mat, t_years, CI, cost_ngn, co2_kg, events)
%SUMMARIZE_OUTPUTS Produce Vensim-ready summary parameters.

dCI = -diff(CI);
CI_mid = CI(1:end-1);
years_mid = t_years(2:end);

is_event_year = false(size(years_mid));
if ~isempty(events)
    for i = 1:height(events)
        is_event_year = is_event_year | (years_mid == events.Year(i));
    end
end

dCI_clean = dCI;
dCI_clean(is_event_year) = NaN;

good_mask = (CI_mid > 70) & ~is_event_year;
poor_mask = (CI_mid >= 40 & CI_mid < 55) & ~is_event_year;

avg_det_good = mean(dCI_clean(good_mask), 'omitnan');
avg_det_poor = mean(dCI_clean(poor_mask), 'omitnan');

ev = events;
if ~isempty(ev)
    ev = ev(ev.Type ~= "construct", :);
end

mean_interval_all = NaN;
if ~isempty(ev) && height(ev) >= 2
    mean_interval_all = mean(diff(ev.Year), 'omitnan');
end

mean_interval_minor  = NaN;
mean_interval_overlay = NaN;
mean_interval_recon   = NaN;

if ~isempty(ev)
    y_minor  = ev.Year(ev.Type=="minor");
    y_overlay= ev.Year(ev.Type=="overlay");
    y_recon  = ev.Year(ev.Type=="recon");

    if numel(y_minor) >= 2,  mean_interval_minor  = mean(diff(y_minor), 'omitnan'); end
    if numel(y_overlay)>= 2, mean_interval_overlay = mean(diff(y_overlay), 'omitnan'); end
    if numel(y_recon)  >= 2, mean_interval_recon   = mean(diff(y_recon), 'omitnan'); end
end

first_minor  = NaN;
first_overlay = NaN;
first_recon   = NaN;

if ~isempty(events)
    if any(events.Type == "minor"),  first_minor  = events.Year(find(events.Type=="minor",1,'first')); end
    if any(events.Type == "overlay"),first_overlay= events.Year(find(events.Type=="overlay",1,'first')); end
    if any(events.Type == "recon"),  first_recon  = events.Year(find(events.Type=="recon",1,'first')); end
end

failure_year = NaN;
idx_fail = find(CI < cfg.CI.failure, 1, 'first');
if ~isempty(idx_fail)
    failure_year = t_years(idx_fail);
end

total_cost_ngn = sum(cost_ngn);
total_co2_kg   = sum(co2_kg);

npv_cost_ngn = npv_series(cost_ngn, cfg.discount_rate, t_years);
npv_cost_gbp = npv_cost_ngn * cfg.gbp_per_ngn;

summary = struct();

summary.material_key  = mat.key;
summary.material_name = mat.name;

summary.avg_det_good_CI_per_year = avg_det_good;
summary.avg_det_poor_CI_per_year = avg_det_poor;

summary.mean_maint_interval_year   = mean_interval_all;
summary.mean_minor_interval_year   = mean_interval_minor;
summary.mean_overlay_interval_year = mean_interval_overlay;
summary.mean_recon_interval_year   = mean_interval_recon;

summary.first_minor_year   = first_minor;
summary.first_overlay_year = first_overlay;
summary.first_recon_year   = first_recon;

summary.cost_per_km_year_ngn = total_cost_ngn / cfg.T_years;
summary.cost_per_km_year_gbp = (total_cost_ngn * cfg.gbp_per_ngn) / cfg.T_years;

summary.co2_per_km_year_t = (total_co2_kg/1000) / cfg.T_years;

summary.total_cost_ngn = total_cost_ngn;
summary.total_cost_gbp = total_cost_ngn * cfg.gbp_per_ngn;

summary.npv_cost_ngn = npv_cost_ngn;
summary.npv_cost_gbp = npv_cost_gbp;

summary.total_co2_t = total_co2_kg / 1000;

summary.failure_year = failure_year;
if isnan(failure_year)
    summary.service_life_years = cfg.T_years;
else
    summary.service_life_years = failure_year;
end

if isempty(events)
    summary.n_events_total = 0;
    summary.n_minor = 0;
    summary.n_overlay = 0;
    summary.n_recon = 0;
else
    summary.n_events_total = height(events) - sum(events.Type=="construct");
    summary.n_minor  = sum(events.Type=="minor");
    summary.n_overlay= sum(events.Type=="overlay");
    summary.n_recon  = sum(events.Type=="recon");
end

end
