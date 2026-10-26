function result=match(left,right,config)
%MATCH Construct a conventional cost, optionally fuse SSC, and run SGM.
% Inputs must already follow the chosen experiment's preprocessing protocol.
assert(all(diff(config.disparities)==1));t=tic;
if strcmp(config.baseline,'SSC')
    [cost,energy]=ssc.costVolume(left,right,config.disparities,config.window,config.modes,config.weighted);
    % Historical standalone SSC is on [0,1], with the configured SGM penalties.
    result=struct('cost',cost,'energy',energy,'config',config,'costSeconds',toc(t));
    t=tic;result.disparity=ssc.sgm(cost,config.P1,config.P2,config.disparities(1));
    result.sgmSeconds=toc(t);return
end
base=ssc.baselineCost(left,right,config);
result=struct('baseCost',base,'config',config);
if config.useSSC
    [s,e]=ssc.costVolume(left,right,config.disparities,config.window,config.modes,config.weighted);
    [cost,weight]=ssc.fuse(base,s,e,config.fusionMax);
    result.structuralCost=s;result.energy=e;result.weight=weight;
else
    cost=base;
end
result.costSeconds=toc(t);t=tic;
result.disparity=ssc.sgm(cost,config.P1,config.P2,config.disparities(1));
result.sgmSeconds=toc(t);result.cost=cost;
end
