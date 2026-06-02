function [co2_t, fuel_L] = rrc_annual_co2(rrc, AADT_yr)
%RRC_ANNUAL_CO2  Annual use-phase CO2 from rolling resistance.
%  rrc_annual_co2(rrc)        - uses baseline AADT 13667
%  rrc_annual_co2(rrc, AADT)  - uses given AADT
%  rrc values: asphalt=0.0120  plastic=0.0105  laterite=0.0165
if nargin < 1, rrc = 0.0120; end
if nargin < 2, AADT_yr = 13667; end
FF_mix = (1-0.159)*0.040 + 0.159*0.150;
VKT    = AADT_yr * 0.5 * 1.0 * 365;
fuel_L = rrc * FF_mix * VKT;
co2_t  = fuel_L * 2.64 / 1000;
end
