function config = stereo_default_config()
%STEREO_DEFAULT_CONFIG Return all supported configuration fields.

    package_root = fileparts(fileparts(mfilename('fullpath')));

    config.left_image = '';
    config.right_image = '';
    config.ground_truth = '';
    config.output_root = fullfile(package_root, 'outputs');
    config.run_name = '';

    config.method = 'SAD_CENSUS_SGSC';
    config.disparity_range = [0 64];
    config.block_size = 5;
    config.directions = 8;

    % Base SGM penalties. Traditional-only methods use multiplier 1.
    % SGSC and every SGSC fusion use sgsc_penalty_multiplier.
    config.base_P1 = [];
    config.base_P2 = [];
    config.sgsc_penalty_multiplier = 3;

    config.fusion_lambda = 0.15;
    config.ad_lambda = 10.0;
    config.census_lambda = 30.0;
    config.census_window = [5 5];

    config.sgsc_window = 5;
    config.sgsc_modes = [1 2 3];
    config.sgsc_use_weighting = true;
    % Keep 1 for compatibility with the original structural-cost experiment.
    config.sgsc_only_cost_scale = 1.0;

    config.gt_scale = 1.0;
    config.gt_offset = 0.0;
    config.gt_invalid_value = 0;
    config.allow_size_crop = false;

    config.png_disparity_scale = 256;
    config.figure_resolution = 300;
    config.verbose = true;
end
