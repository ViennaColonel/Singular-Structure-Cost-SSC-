# Examples and case manifests

For the bundled two-image demo, open [run_ssc_demo.m](../run_ssc_demo.m) and click Run. Its settings are at the top of the file.

The following functions support additional experiments:

| File | Purpose |
|---|---|
| `examples/run_tsukuba.m` | Run the three baselines and their SSC fusions with supplied Tsukuba images and ground truth |
| `examples/run_experiment.m` | Read a CSV case manifest and save disparities, configurations, and metrics |

From the package root, run `setup()` before calling these functions.

```matlab
run_tsukuba(datasetFolder, outputFolder);
run_experiment(manifestFile, dataRoot, outputRoot);
```

`run_tsukuba` expects `scene1.row3.col3.ppm`, `scene1.row3.col4.ppm`, and `truedisp.row3.col3.pgm` in `datasetFolder`. The two-image quick-start demo does not require these files.

## CSV fields

Paths in the CSV are relative to `dataRoot`.

| Field | Meaning |
|---|---|
| `ID` | Unique case identifier |
| `Left`, `Right`, `GroundTruth` | Input image and ground-truth paths |
| `GTScale` | Divisor that converts ground truth to pixel disparity |
| `GrayOrder` | `float_first` or `integer_first` |
| `MinDisparity`, `MaxDisparity` | Inclusive disparity endpoints |
| `Method` | Cost identifier: e.g. `SAD`, `Census`, `SADCensus`, or `SSC` |
| `UseSSC` | SSC fusion switch |
| `P1`, `P2` | SGM penalties |
| `NumericalThreads` | Optional MATLAB numerical thread count |
| `ExpectedMAE`, `ExpectedBPR1` | Optional reference metrics, supplied together |
| `InputMAT` | Optional MAT file containing `left`, `right`, and `gt` arrays |

Each result MAT contains inputs, ground truth, configuration, disparity, and metrics.
