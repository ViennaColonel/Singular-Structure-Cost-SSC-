function m=metrics(disparity,groundTruth,valid)
%METRICS Paper evaluation: finite valid GT pixels and strict error thresholds.
% Caller must decode dataset-specific GT scale (Tsukuba /16, MB2006 /3, etc.).
assert(isequal(size(disparity),size(groundTruth),size(valid)));
assert(any(valid(:)) && all(isfinite(disparity(valid))) && all(isfinite(groundTruth(valid))));
e=abs(double(disparity(valid))-double(groundTruth(valid)));
m=struct('ValidPixels',nnz(valid),'MAE_px',mean(e),'RMSE_px',sqrt(mean(e.^2)), ...
    'BPR_0_5_pct',100*mean(e>0.5),'BPR_1_0_pct',100*mean(e>1),'BPR_2_0_pct',100*mean(e>2));
end
