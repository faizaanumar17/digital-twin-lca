function trig = maintenance_trigger(cfg, CI)
%MAINTENANCE_TRIGGER Choose intervention based on CI thresholds.
% Priority: recon > overlay > minor

if CI < cfg.maint.th_recon
    trig = "recon";
elseif CI < cfg.maint.th_overlay
    trig = "overlay";
elseif CI < cfg.maint.th_minor
    trig = "minor";
else
    trig = "";
end

end
