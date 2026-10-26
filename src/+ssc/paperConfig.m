function c=paperConfig(disparities)
%PAPERCONFIG Explicit configuration for the archived paper implementation.
% Baseline convention preserves historical SAD coordinates and Census invalid
% candidate handling. See docs/NUMERICAL_CONTRACT.md before interpreting gains.
% The caller supplies the experiment-specific disparity candidates; no single
% range or preprocessing order applies to every experiment in the manuscript.
arguments
    disparities (1,:) double {mustBeInteger,mustBeFinite}
end
assert(numel(disparities)>=2 && all(diff(disparities)==1),'Use consecutive integer disparities.');
c=struct('disparities',disparities,'window',5,'modes',[1 2 3], ...
    'weighted',true,'fusionMax',0.15,'alpha',7,'P1',87.5,'P2',350, ...
    'baselineConvention','paper','baseline','SADCensus','useSSC',true);
end
