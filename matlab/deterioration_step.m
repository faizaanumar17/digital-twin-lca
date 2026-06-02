function dCI = deterioration_step(cfg, CI, traffic_factor, climate_factor, material_factor)
%DETERIORATION_STEP Piecewise deterioration rate (CI points/year).

if CI >= cfg.det.good_band(1)
    base = cfg.det.rate_good;
elseif CI >= cfg.det.mid_band(1)
    base = cfg.det.rate_mid;
elseif CI >= cfg.det.poor_band(1)
    base = cfg.det.rate_poor;
else
    base = cfg.det.rate_vpoor;
end

dCI = base * traffic_factor * climate_factor * material_factor;

end
