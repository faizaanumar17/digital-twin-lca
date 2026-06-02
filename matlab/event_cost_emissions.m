function [cost_ngn, co2_kg] = event_cost_emissions(cfg, mat, evType)
%EVENT_COST_EMISSIONS Computes event cost + embodied CO2 for the lane-km.

%% COST
c = cfg.cost.(mat.key);

switch evType
    case "construct"
        unit = c.construct_ngn_m2; area = cfg.area_m2;
    case "minor"
        unit = c.minor_ngn_m2;     area = cfg.area_m2 * cfg.maint.minor_area_frac;
    case "overlay"
        unit = c.overlay_ngn_m2;   area = cfg.area_m2;
    case "recon"
        unit = c.recon_ngn_m2;     area = cfg.area_m2;
    otherwise
        unit = 0; area = 0;
end

cost_ngn = unit * area;

%% CARBON
EF_asphalt = cfg.carbon.EF_asphalt_mix;
EF_agg     = cfg.carbon.EF_aggregate;
EF_bit     = cfg.carbon.EF_bitumen;

rho_asph = cfg.carbon.density_asphalt;
rho_agg  = cfg.carbon.density_agg;

uplift  = cfg.carbon.process_uplift;

co2_kg = 0;

switch mat.key
    case {"asphalt","plastic"}
        switch evType
            case "construct"
                m_asph = cfg.carbon.th_recon_asphalt * rho_asph;
                m_unb  = cfg.carbon.th_recon_unbound * rho_agg;
                kg_m2  = (m_asph*EF_asphalt + m_unb*EF_agg) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
            case "overlay"
                m_asph = cfg.carbon.th_overlay_asphalt * rho_asph;
                kg_m2  = (m_asph*EF_asphalt) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
            case "minor"
                m_asph = cfg.carbon.th_patch_asphalt * rho_asph;
                kg_m2  = (m_asph*EF_asphalt) * uplift;
                co2_kg = kg_m2 * (cfg.area_m2 * cfg.maint.minor_area_frac);
            case "recon"
                m_asph = cfg.carbon.th_recon_asphalt * rho_asph;
                m_unb  = cfg.carbon.th_recon_unbound * rho_agg;
                kg_m2  = (m_asph*EF_asphalt + m_unb*EF_agg) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
        end

        if mat.key == "plastic"
            plastic_co2_multiplier = 0.80;
            co2_kg = co2_kg * plastic_co2_multiplier;
        end

    case "laterite"
        switch evType
            case "construct"
                m_unb  = cfg.carbon.th_recon_unbound * rho_agg;
                m_bit  = cfg.carbon.seal_binder_kg_m2;
                m_chip = cfg.carbon.seal_chips_kg_m2;
                kg_m2  = (m_unb*EF_agg + m_bit*EF_bit + m_chip*EF_agg) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
            case "overlay"
                m_bit  = cfg.carbon.seal_binder_kg_m2;
                m_chip = cfg.carbon.seal_chips_kg_m2;
                kg_m2  = (m_bit*EF_bit + m_chip*EF_agg) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
            case "minor"
                frac   = cfg.maint.minor_area_frac;
                m_bit  = cfg.carbon.seal_binder_kg_m2 * 0.50;
                m_chip = cfg.carbon.seal_chips_kg_m2 * 0.50;
                kg_m2  = (m_bit*EF_bit + m_chip*EF_agg) * uplift;
                co2_kg = kg_m2 * (cfg.area_m2 * frac);
            case "recon"
                m_unb  = cfg.carbon.th_recon_unbound * rho_agg;
                m_bit  = cfg.carbon.seal_binder_kg_m2;
                m_chip = cfg.carbon.seal_chips_kg_m2;
                kg_m2  = (m_unb*EF_agg + m_bit*EF_bit + m_chip*EF_agg) * uplift;
                co2_kg = kg_m2 * cfg.area_m2;
        end
end

end
