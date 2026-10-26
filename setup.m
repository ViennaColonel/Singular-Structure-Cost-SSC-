function setup()
%SETUP Add this project's source and examples, independent of working folder.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'),fullfile(root,'examples'),fullfile(root,'tests'));
end
