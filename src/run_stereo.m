function result = run_stereo(user_config)
%RUN_STEREO Run a selected matching method and save all results.
%
% result = run_stereo(config)
%
% Ground truth is optional. If config.ground_truth points to a file,
% evaluation metrics and comparison figures are created automatically.

    if nargin < 1, user_config = struct(); end
    config = merge_config(stereo_default_config(), user_config);
    validate_config(config);
    method = resolve_method(config.method);

    left_image = read_gray_image(config.left_image);
    right_image = read_gray_image(config.right_image);
    if ~isequal(size(left_image), size(right_image))
        error('Left and right images must have identical dimensions.');
    end

    has_ground_truth = ~isempty(config.ground_truth);
    ground_truth = [];
    valid_mask = [];
    if has_ground_truth
        if ~isfile(config.ground_truth)
            error('Ground-truth file does not exist: %s', config.ground_truth);
        end
        [ground_truth, valid_mask] = read_ground_truth(config);
        [left_image, right_image, ground_truth, valid_mask] = ...
            align_sizes(left_image, right_image, ground_truth, ...
            valid_mask, config.allow_size_crop);
    end

    if isempty(config.disparity_range)
        if ~has_ground_truth
            error('Set disparity_range when ground truth is not provided.');
        end
        config.disparity_range = [0 ceil(max(ground_truth(valid_mask)))];
    end
    config.disparity_range = round(config.disparity_range(:)');

    if isempty(config.base_P1)
        config.base_P1 = (1/16) * 8 * config.block_size.^2;
    end
    if isempty(config.base_P2)
        config.base_P2 = (1/16) * 32 * config.block_size.^2;
    end

    if method.uses_sgsc
        penalty_multiplier = config.sgsc_penalty_multiplier;
    else
        penalty_multiplier = 1;
    end
    sgm.P1 = penalty_multiplier * config.base_P1;
    sgm.P2 = penalty_multiplier * config.base_P2;
    sgm.directions = config.directions;
    sgm.disparity_range = config.disparity_range;

    if config.verbose
        fprintf('Method: %s\n', method.display_name);
        fprintf('Disparity range: [%d, %d]\n', config.disparity_range);
        fprintf('P1=%.4g, P2=%.4g (multiplier=%g)\n', ...
            sgm.P1, sgm.P2, penalty_multiplier);
    end

    total_timer = tic;
    cost_timer = tic;
    [cost_volume, cost_info] = compute_matching_cost( ...
        left_image, right_image, config, method);
    cost_seconds = toc(cost_timer);

    sgm_timer = tic;
    disparity = sgm_optimize(cost_volume, sgm);
    sgm_seconds = toc(sgm_timer);
    total_seconds = toc(total_timer);

    metrics = struct();
    evaluation = struct();
    if has_ground_truth
        [metrics, evaluation] = evaluate_disparity( ...
            disparity, ground_truth, valid_mask);
    end

    output_dir = create_output_directory(config, method);
    run_info.method = method;
    run_info.P1 = sgm.P1;
    run_info.P2 = sgm.P2;
    run_info.penalty_multiplier = penalty_multiplier;
    run_info.cost_seconds = cost_seconds;
    run_info.sgm_seconds = sgm_seconds;
    run_info.total_seconds = total_seconds;
    run_info.cost_info = cost_info;

    save_stereo_results(output_dir, disparity, left_image, right_image, ...
        ground_truth, valid_mask, metrics, evaluation, config, run_info);

    result.disparity = disparity;
    result.metrics = metrics;
    result.output_dir = output_dir;
    result.run_info = run_info;

    if config.verbose
        fprintf('Saved results: %s\n', output_dir);
        fprintf('Runtime: cost %.3fs, SGM %.3fs, total %.3fs\n', ...
            cost_seconds, sgm_seconds, total_seconds);
        if has_ground_truth
            fprintf('MAE %.4f px | RMSE %.4f px | BPR>1 %.2f%%\n', ...
                metrics.MAE_px, metrics.RMSE_px, metrics.BPR_1_0_pct);
        end
    end
end

function config = merge_config(config, user_config)
    names = fieldnames(user_config);
    for k = 1:numel(names)
        if ~isfield(config, names{k})
            error('Unknown configuration field: %s', names{k});
        end
        config.(names{k}) = user_config.(names{k});
    end
end

function validate_config(config)
    if isempty(config.left_image) || ~isfile(config.left_image)
        error('Set config.left_image to an existing image file.');
    end
    if isempty(config.right_image) || ~isfile(config.right_image)
        error('Set config.right_image to an existing image file.');
    end
    if config.block_size < 3 || mod(config.block_size,2) == 0
        error('block_size must be an odd integer >= 3.');
    end
    if config.directions ~= 8
        error('This SGM implementation currently supports 8 directions.');
    end
    if ~isempty(config.disparity_range) && ...
            (numel(config.disparity_range) ~= 2 || ...
             config.disparity_range(2) <= config.disparity_range(1))
        error('disparity_range must be [minimum maximum].');
    end
    if config.gt_scale <= 0
        error('gt_scale must be positive.');
    end
end

function image = read_gray_image(path)
    image = imread(path);
    if ndims(image) == 3, image = rgb2gray(image); end
end

function [gt, mask] = read_ground_truth(config)
    raw = imread(config.ground_truth);
    if ndims(raw) == 3, raw = raw(:,:,1); end
    raw_double = double(raw);
    gt = raw_double / config.gt_scale + config.gt_offset;
    mask = raw_double ~= config.gt_invalid_value & isfinite(gt);
end

function [left,right,gt,mask] = align_sizes(left,right,gt,mask,allow_crop)
    image_size = size(left);
    if isequal(image_size, size(gt)), return; end
    if ~allow_crop
        error(['Image and ground-truth dimensions differ. Set ', ...
            'allow_size_crop=true only if top-left cropping is intended.']);
    end
    common_h = min(image_size(1),size(gt,1));
    common_w = min(image_size(2),size(gt,2));
    warning('Cropping images and ground truth to %dx%d.',common_w,common_h);
    left=left(1:common_h,1:common_w);
    right=right(1:common_h,1:common_w);
    gt=gt(1:common_h,1:common_w);
    mask=mask(1:common_h,1:common_w);
end

function output_dir = create_output_directory(config,method)
    if isempty(config.run_name)
        timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
        run_name = [timestamp,'_',method.id];
    else
        run_name = regexprep(char(config.run_name),'[^a-zA-Z0-9_-]','_');
    end
    output_dir = fullfile(config.output_root,run_name);
    if ~isfolder(output_dir), mkdir(output_dir); end
end
