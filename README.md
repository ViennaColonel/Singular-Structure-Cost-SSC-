# GeneralStereoSGM

A compact MATLAB implementation of seven stereo matching configurations:

- SAD
- Census
- SAD-Census (AD-Census)
- SGSC (Spectral-Gap Structural Cost)
- SAD + SGSC
- Census + SGSC
- SAD-Census + SGSC

All methods use the same eight-direction Semi-Global Matching (SGM) stage.
Traditional-only methods use the base SGM penalties. SGSC and every SGSC fusion
use a configurable penalty multiplier (default: 3).

SGSC represents each local patch with the selected SVD modes. For mode `k`,
the descriptor uses `sqrt(sigma_k) * [u_k; v_k]`; all selected modes are
concatenated and jointly normalized before matching. Absolute U/V correlations
remove the arbitrary sign ambiguity of the singular vectors. The SGSC cost is
one minus this concatenated-descriptor similarity.

## Requirements

- MATLAB R2021a or newer
- Image Processing Toolbox

## Quick start

Open `main.m` and edit the user configuration section:

```matlab
config.left_image = 'data/left.png';
config.right_image = 'data/right.png';
config.method = 'SAD_CENSUS_SGSC';
config.disparity_range = [0 64];
```

Then run:

```matlab
result = main;
```

Available method names are:

```text
SAD
CENSUS
SAD_CENSUS
SGSC
SAD_SGSC
CENSUS_SGSC
SAD_CENSUS_SGSC
```

## Ground-truth evaluation

Ground truth is optional. When a ground-truth path is supplied, evaluation and
plotting are enabled automatically:

```matlab
config.ground_truth = 'data/disp_gt.png';
config.gt_scale = 8;          % disparity = stored value / 8
config.gt_offset = 0;
config.gt_invalid_value = 0;
config.disparity_range = [];  % infer maximum disparity from valid GT
```

Without ground truth, the program still saves the exact disparity and its
visualization, but does not calculate error metrics.

## Function API

The editable `main.m` file is only a convenient entry point. The algorithm can
also be called from another project:

```matlab
addpath('GeneralStereoSGM/src');
config = stereo_default_config();
config.left_image = 'left.png';
config.right_image = 'right.png';
config.method = 'CENSUS_SGSC';
config.disparity_range = [0 96];
result = run_stereo(config);
```

## Saved outputs

Every run creates a timestamped folder under `outputs/` containing:

- `disparity.mat`: exact MATLAB disparity array
- `disparity_x256.png`: 16-bit disparity (`value = disparity * 256`)
- `disparity_visualization.png`: color visualization
- `run_info.mat`: complete configuration, method and runtime metadata

When ground truth is supplied, it additionally saves:

- `metrics.csv`: MAE, RMSE and bad-pixel rates at 0.5, 1 and 2 pixels
- `evaluation_panel.png`: inputs, estimate, ground truth and error maps

## Important parameters

```matlab
config.block_size = 5;
config.base_P1 = [];  % auto: (1/16)*8*block_size^2
config.base_P2 = [];  % auto: (1/16)*32*block_size^2
config.sgsc_penalty_multiplier = 3;
config.fusion_lambda = 0.15;
config.sgsc_window = 5;
config.sgsc_modes = [1 2 3];
```

For reproducible evaluation, always record the disparity range, ground-truth
scale, invalid-pixel convention, and all parameters above.
