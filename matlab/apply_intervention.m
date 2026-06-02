function [CI_new, cost_ngn, co2_kg, evType] = apply_intervention(cfg, CI, mat, trig)
%APPLY_INTERVENTION Applies CI recovery + returns cost and emissions.

overlay_cap = 90;

switch trig
    case "minor"
        CI_new = CI + (cfg.maint.boost_minor * mat.ci_recovery_factor);
        CI_new = min(cfg.CI.cap, CI_new);
        evType = "minor";

    case "overlay"
        CI_new = CI + (cfg.maint.boost_overlay * mat.ci_recovery_factor);
        CI_new = min(overlay_cap, CI_new);
        evType = "overlay";

    case "recon"
        CI_new = min(cfg.CI.cap, cfg.maint.reset_recon);
        evType = "recon";

    case "construct"
        CI_new = cfg.CI.CI0;
        evType = "construct";

    otherwise
        error("Unknown intervention type: %s", trig);
end

[cost_ngn, co2_kg] = event_cost_emissions(cfg, mat, evType);

end
