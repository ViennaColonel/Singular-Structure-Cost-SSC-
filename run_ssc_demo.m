function result = run_ssc_demo(overrides)
%RUN_SSC_DEMO Match the two bundled stereo images. Open this file and click Run.
% Edit method and useSSC below to switch between baseline and fused methods.
% Example: r = run_ssc_demo(struct('method','Census','useSSC',false));

%% User settings
settings.method = 'SAD-Census'; % 'SAD', 'Census', 'SAD-Census', or standalone 'SSC'
settings.useSSC = true;         % true: fuse SSC; false: use the baseline alone
settings.alpha = 7;             % SGM penalties: P1=12.5*alpha, P2=50*alpha
settings.disparities = 0:14;   % Integer disparity candidates for this demo
settings.datasetFolder = '';   % Empty: bundled demo/; otherwise a folder with left.png and right.png
settings.outputFolder = '';    % Empty: create output/<timestamp>_<method>/

%% Run the selected method
settings=advanced_settings(settings);
if nargin>0
    assert(isstruct(overrides)&&isscalar(overrides),'Settings must be a scalar struct.');
    names=fieldnames(overrides);
    for k=1:numel(names)
        assert(isfield(settings,names{k}),'Unknown setting: %s',names{k});
        settings.(names{k})=overrides.(names{k});
    end
end
settings.method=validatestring(settings.method,{'SAD','Census','SAD-Census','SADCensus','SSC'});
validateattributes(settings.useSSC,{'logical','numeric'},{'scalar','real','finite'});
assert(ismember(settings.useSSC,[0 1]),'useSSC must be true or false.');
validateattributes(settings.alpha,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(settings.fusionMax,{'numeric'},{'scalar','real','finite','>=',0,'<=',1});
settings.useSSC=logical(settings.useSSC);
if strcmp(settings.method,'SSC'),settings.useSSC=false;end

root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'),'-begin');
required={'left.png','right.png'};
if strlength(string(settings.datasetFolder))==0
    settings.datasetFolder=fullfile(root,'demo');
end
for k=1:numel(required)
    assert(isfile(fullfile(settings.datasetFolder,required{k})), ...
        'Missing input: %s',fullfile(settings.datasetFolder,required{k}));
end

% Convert integer RGB to grayscale, then to double in [0,1].
left=read_gray(fullfile(settings.datasetFolder,required{1}));
right=read_gray(fullfile(settings.datasetFolder,required{2}));
assert(isequal(size(left),size(right)),'The two images must have the same size.');
config=ssc.paperConfig(settings.disparities);
assert(all(abs(config.disparities)<size(left,2)),'Disparities must be smaller than the image width.');
config.baseline=strrep(settings.method,'-','');
config.useSSC=settings.useSSC;
config.alpha=settings.alpha;
config.P1=12.5*settings.alpha;config.P2=50*settings.alpha;
config.fusionMax=settings.fusionMax;

fprintf('Input: %s\n',settings.datasetFolder);
fprintf('Method: %s | Use SSC: %d | P1: %g | P2: %g\n', ...
    settings.method,config.useSSC,config.P1,config.P2);
matched=ssc.match(left,right,config);
disparity=matched.disparity;
summary=table(string(settings.method),config.useSSC,size(left,1),size(left,2), ...
    config.disparities(1),config.disparities(end),config.P1,config.P2,config.fusionMax, ...
    matched.costSeconds,matched.sgmSeconds,matched.costSeconds+matched.sgmSeconds, ...
    'VariableNames',{'Method','WithSSC','ImageHeight','ImageWidth','MinDisparity', ...
    'MaxDisparity','P1','P2','FusionMax','CostSeconds','SGMSeconds','MatchingSeconds'});

if strlength(string(settings.outputFolder))==0
    tag=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
    settings.outputFolder=fullfile(root,'output', ...
        sprintf('%s_%s_SSC%d',tag,config.baseline,config.useSSC));
end
if ~isfolder(settings.outputFolder),mkdir(settings.outputFolder);end
writetable(summary,fullfile(settings.outputFolder,'run_summary.csv'));
save(fullfile(settings.outputFolder,'result.mat'),'disparity','config','settings','summary','-v7');
result=struct('disparity',disparity,'summary',summary,'config',config,'settings',settings);
disp(summary(:,{'Method','WithSSC','CostSeconds','SGMSeconds','MatchingSeconds'}));
fprintf('Saved: %s\n',settings.outputFolder);
end

function image=read_gray(file)
image=imread(file);
if ndims(image)==3,image=rgb2gray(image);end
image=im2double(image);
end

function settings=advanced_settings(settings)
%ADVANCED_SETTINGS Optional tuning parameters for SSC fusion.
settings.fusionMax = 0.15; % Maximum SSC fusion weight
end
