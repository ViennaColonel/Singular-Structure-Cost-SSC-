function result = main()
%MAIN Edit this file to run one stereo pair. SGSC(Spectral-Gap Structural Cost)
% Run from MATLAB with:
%   result = main;

    root_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(root_dir, 'src'));

    config = stereo_default_config();

    %% ===================== USER CONFIGURATION =====================
    config.left_image  = 'path/to/left_image.png';
    config.right_image = 'path/to/right_image.png';

    % Available methods:
    % SAD, CENSUS, SAD_CENSUS, SGSC
    % SAD_SGSC, CENSUS_SGSC, SAD_CENSUS_SGSC
    config.method = 'SAD_CENSUS_SGSC';

    % Use [] to infer the maximum disparity from ground truth. If no
    % ground truth is supplied, set an explicit range such as [0 64].
    config.disparity_range = [0 64];

    % Optional ground truth. Leave empty to disable evaluation figures.
    config.ground_truth = '';
    config.gt_scale = 1.0;       % stored_value / gt_scale + gt_offset
    config.gt_offset = 0.0;
    config.gt_invalid_value = 0;

    % Results are always saved. A timestamped run folder is created here.
    config.output_root = fullfile(root_dir, 'outputs');
    %% ==============================================================

    result = run_stereo(config);
end
