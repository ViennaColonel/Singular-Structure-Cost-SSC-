function build_native(outputDirectory)
%BUILD_NATIVE Compile the SGM source for the current MATLAB platform.
root=fileparts(mfilename('fullpath'));
if nargin<1,outputDirectory=fullfile(root,'src','+ssc');end
if ~isfolder(outputDirectory),mkdir(outputDirectory);end
mex('-R2018a',fullfile(root,'native','sgm_native.cpp'), ...
    '-outdir',outputDirectory,'-output','sgm_native');
end
