function mats = materials()
%MATERIALS Defines the three material strategies as multipliers and labels.
%
% mat.det_factor multiplies deterioration (relative durability)
% mat.ci_recovery_factor multiplies treatment effectiveness (CI jump effect)

mats = struct([]);

% 1) Conventional Asphalt (baseline)
mats(1).name = "Asphalt (conventional)";
mats(1).key  = "asphalt";
mats(1).det_factor = 1.00;
mats(1).ci_recovery_factor = 1.00;

% 2) Laterite (SEALED laterite base + surface dressing/Otta-type reseal)
mats(2).name = "Laterite (sealed base + reseal)";
mats(2).key  = "laterite";
mats(2).det_factor = 1.35;          % assumption; calibrate if needed
mats(2).ci_recovery_factor = 0.95;

% 3) Plastic-modified asphalt
mats(3).name = "Plastic-modified asphalt";
mats(3).key  = "plastic";
mats(3).det_factor = 0.80;          % assumption (more durable)
mats(3).ci_recovery_factor = 1.05;

end
