function npv = npv_series(cost, r, t_years)
%NPV_SERIES Net Present Value of a cost stream.
npv = sum(cost ./ ((1+r) .^ t_years));
end
