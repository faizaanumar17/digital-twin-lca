function out = traffic_annual_esas(cfg, AADT_total, pct_HGV, ESAs_per_HV, lane_split_factor)
%TRAFFIC_ANNUAL_ESAS Convert AADT and %HGV into annual ESAs on the modelled lane.
%
% lane_split_factor converts two-way corridor traffic to the modelled lane.
% For a 2-lane two-way single carriageway and a 1-lane functional unit, use 0.5.

if nargin < 5
    lane_split_factor = 1.0;
end

HGV_per_day = AADT_total * pct_HGV * lane_split_factor;

ADE = HGV_per_day * ESAs_per_HV;           
annual_ESAs = ADE * 365;

out = struct();
out.HGV_per_day = HGV_per_day;
out.ADE = ADE;
out.annual_ESAs = annual_ESAs;

end
