function summary=run_tsukuba(datasetFolder,outputFolder)
%RUN_TSUKUBA A transparent clean-pair example, not a dataset-average table.
% datasetFolder contains scene1.row3.col3.ppm, scene1.row3.col4.ppm and
% truedisp.row3.col3.pgm. Output goes only to the caller-specified folder.
arguments
    datasetFolder (1,1) string
    outputFolder (1,1) string
end
left=im2double(rgb2gray(imread(fullfile(datasetFolder,'scene1.row3.col3.ppm'))));
right=im2double(rgb2gray(imread(fullfile(datasetFolder,'scene1.row3.col4.ppm'))));
raw=imread(fullfile(datasetFolder,'truedisp.row3.col3.pgm'));gt=double(raw)/16;
config=ssc.paperConfig(0:ceil(max(gt(raw>0))));
if ~isfolder(outputFolder),mkdir(outputFolder);end
rows={};
for method=["SAD","Census","SADCensus"]
    for fused=[false true]
        config.baseline=char(method);config.useSSC=fused;
        result=ssc.match(left,right,config);m=ssc.metrics(result.disparity,gt,raw>0);
        m.Method=method;m.WithSSC=fused;rows{end+1}=m; %#ok<AGROW>
        save(fullfile(outputFolder,sprintf('%s_SSC%d.mat',method,fused)),'result','m','-v7.3');
    end
end
summary=struct2table([rows{:}]);writetable(summary,fullfile(outputFolder,'metrics.csv'));
end
