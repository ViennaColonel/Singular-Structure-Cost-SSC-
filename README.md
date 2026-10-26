# Singular-Structure Cost (SSC)

MATLAB stereo matching with conventional costs and optional SSC fusion.

## Quick start

**Open [run_ssc_demo.m](run_ssc_demo.m) in MATLAB and click Run.**

The demo loads the bundled `demo/left.png` and `demo/right.png`, runs **SAD-Census + SSC**, and saves the disparity and timing results. No external dataset, ground-truth file, or C++ compiler is required for this example.

You can also run it from the MATLAB command window:

```matlab
r = run_ssc_demo();
```

Requirements: MATLAB R2023b and Image Processing Toolbox.

## Files to include in a compact upload

Keep these files and folders together:

```text
run_ssc_demo.m
src/
  +ssc/
    ...                 # Core MATLAB functions
demo/
  left.png
  right.png
  README.md             # Image source and view information
README.md
LICENSE_PENDING.md
```

The `examples/`, `tests/`, `docs/`, and `native/` folders, plus `setup.m` and `build_native.m`, provide additional interfaces and utilities. The quick-start demo runs using the compact layout above.

## Change the matching method

Edit the settings at the top of `run_ssc_demo.m`:

| Method | `settings.method` | `settings.useSSC` |
|---|---|---|
| SAD | `'SAD'` | `false` |
| SAD + SSC | `'SAD'` | `true` |
| Census | `'Census'` | `false` |
| Census + SSC | `'Census'` | `true` |
| SAD-Census | `'SAD-Census'` | `false` |
| SAD-Census + SSC | `'SAD-Census'` | `true` |
| Standalone SSC | `'SSC'` | `false` |

For example:

```matlab
r = run_ssc_demo(struct('method','Census','useSSC',true));
```

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `method` | `'SAD-Census'` | Matching cost |
| `useSSC` | `true` | Enable SSC fusion |
| `alpha` | `7` | SGM multiplier: `P1=12.5*alpha`, `P2=50*alpha` |
| `disparities` | `0:14` | Consecutive integer disparity candidates |
| `datasetFolder` | `''` | Empty uses the bundled `demo/`; otherwise specify a folder containing `left.png` and `right.png` |
| `outputFolder` | `''` | Empty creates a new folder under `output/`; otherwise specify an output directory |

The images must be rectified and have equal dimensions. The demo converts integer RGB images to grayscale, then to double in `[0,1]`. For your own images, set `datasetFolder` and choose the appropriate disparity range.

## Results

Each run writes to `output/<timestamp>_<method>/`:

- `result.mat`: pixel disparity array `disparity`, parameters `config`, input/output settings `settings`, and timing table `summary`.
- `run_summary.csv`: method, image size, disparity range, penalties, fusion setting, and matching time in seconds.

The returned structure provides the same information:

```matlab
r.disparity
r.summary
r.config
```

This two-image example reports disparity and runtime. Accuracy metrics require a ground-truth disparity map; `ssc.metrics` is available for that evaluation.

## Core code

| File in `src/+ssc/` | Purpose |
|---|---|
| `paperConfig.m` | Default matching configuration |
| `match.m` | Cost construction, optional fusion, and SGM |
| `costVolume.m` | SSC cost volume |
| `baselineCost.m` | SAD, Census, and SAD-Census costs |
| `additionalCost.m` | ZNCC, Gradient, and BT costs |
| `fuse.m` | Combine a baseline cost with SSC |
| `sgm.m` | SGM aggregation and disparity selection |
| `metrics.m` | Disparity error metrics |

## Additional utilities

- `setup.m`: add source, example, and test folders to the MATLAB path.
- `examples/run_tsukuba.m`: run six baseline/fusion combinations with separately supplied Tsukuba images and ground truth.
- `examples/run_experiment.m`: run cases listed in a CSV manifest; see `docs/EXPERIMENTS.md`.
- `build_native.m`: compile the optional C++ SGM backend with a configured MEX compiler. The MATLAB backend works without compilation.

## Advanced settings

The `advanced_settings` function at the end of `run_ssc_demo.m` contains `fusionMax`, the maximum SSC fusion weight (default `0.15`). It can also be supplied through the optional settings structure.

Image attribution is provided in [demo/README.md](demo/README.md). Code licensing information is in `LICENSE_PENDING.md`.
