function results=run_experiment(manifestFile,dataRoot,outputRoot)
%RUN_EXPERIMENT Run explicit CSV cases, saving exact floating-point inputs.
% Required columns: ID, Left, Right, GroundTruth, GTScale, GrayOrder,
% MinDisparity, MaxDisparity, Method, UseSSC, P1, P2.
% Optional InputMAT contains left/right doubles and gt (bypasses image loading).
% Optional ExpectedMAE/ExpectedBPR1 are checked AFTER prediction, never used
% for parameter selection. Optional NumericalThreads sets BLAS thread count.
% See docs/EXPERIMENTS.md for units, preprocessing, and output formats.
arguments
    manifestFile (1,1) string
    dataRoot (1,1) string
    outputRoot (1,1) string
end
cases=readtable(manifestFile,'TextType','string');
assert(numel(unique(cases.ID))==height(cases),'Case IDs must be unique.');
if ~isfolder(outputRoot),mkdir(outputRoot);end
oldThreads=maxNumCompThreads;cleanup=onCleanup(@()maxNumCompThreads(oldThreads)); %#ok<NASGU>
rows={};
for i=1:height(cases)
    q=cases(i,:);id=char(q.ID);
    assert(~isempty(regexp(id,'^[A-Za-z0-9_-]+$','once')),'Use portable case IDs.');
    if ismember('NumericalThreads',cases.Properties.VariableNames) && isfinite(q.NumericalThreads)
        maxNumCompThreads(q.NumericalThreads);
    end
    if ismember('InputMAT',cases.Properties.VariableNames) && ~ismissing(q.InputMAT) && strlength(q.InputMAT)>0
        a=load(fullfile(dataRoot,q.InputMAT),'left','right','gt');
        left=a.left;right=a.right;gt=a.gt;
    else
        left=read_gray(fullfile(dataRoot,q.Left),q.GrayOrder);
        right=read_gray(fullfile(dataRoot,q.Right),q.GrayOrder);
        gt=double(imread(fullfile(dataRoot,q.GroundTruth)))/q.GTScale;
    end
    config=ssc.paperConfig(q.MinDisparity:q.MaxDisparity);
    config.baseline=char(q.Method);config.useSSC=logical(q.UseSSC);
    config.P1=q.P1;config.P2=q.P2;config.alpha=q.P1/12.5;
    result=ssc.match(left,right,config);metric=ssc.metrics(result.disparity,gt,gt>0);
    metric.ID=string(id);metric.Method=q.Method;metric.WithSSC=logical(q.UseSSC);
    metric.CostSeconds=result.costSeconds;metric.SGMSeconds=result.sgmSeconds;
    if ismember('ExpectedMAE',cases.Properties.VariableNames) && isfinite(q.ExpectedMAE)
        metric.DeltaMAE=metric.MAE_px-q.ExpectedMAE;
        metric.DeltaBPR1=metric.BPR_1_0_pct-q.ExpectedBPR1;
    else
        metric.DeltaMAE=NaN;metric.DeltaBPR1=NaN;
    end
    % Exact inputs are saved before checking discrepancies, for diagnosis.
    disparity=result.disparity;
    save(fullfile(outputRoot,[id '.mat']),'left','right','gt','config','disparity','metric','-v7.3');
    rows{end+1}=metric;results=struct2table([rows{:}]); %#ok<AGROW>
    writetable(results,fullfile(outputRoot,'metrics.csv'));
    assert(isnan(metric.DeltaMAE) || max(abs([metric.DeltaMAE metric.DeltaBPR1]))<1e-9, ...
        'ssc:ReplayMismatch','Case %s differs from archived expectations; outputs retained.',id);
    fprintf('CASE %s: MAE %.12g, BPR1 %.12g%%\n',id,metric.MAE_px,metric.BPR_1_0_pct);
end
end
function image=read_gray(file,order)
image=imread(file);
switch order
    case "float_first"
        image=im2double(image);if ndims(image)==3,image=rgb2gray(image);end
    case "integer_first"
        if ndims(image)==3,image=rgb2gray(image);end;image=im2double(image);
    otherwise
        error('GrayOrder must be float_first or integer_first.');
end
end
