function export_results(cfg, mat, res)
%EXPORT_RESULTS Write clean CSV outputs for Vensim + appendices.

outdir = fullfile(pwd, "outputs");
if ~exist(outdir, 'dir'); mkdir(outdir); end

T = table(res.t_years, res.CI, res.cost_ngn, res.cost_gbp, res.co2_kg, res.co2_t, ...
    'VariableNames', {'Year','CI','Cost_NGN','Cost_GBP','CO2_kg','CO2_t'});

writetable(T, fullfile(outdir, "timeseries_" + mat.key + ".csv"));

writetable(res.events, fullfile(outdir, "events_" + mat.key + ".csv"));

end
