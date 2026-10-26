# Demo stereo pair

| File | View | Size |
|---|---|---|
| `left.png` | Reference view, `scene1.row3.col3` | 384 x 288 pixels |
| `right.png` | Target view, `scene1.row3.col4` | 384 x 288 pixels |

These images show the Tsukuba scene, distributed with the [Middlebury stereo datasets](https://vision.middlebury.edu/stereo/data/scenes2001/) courtesy of the University of Tsukuba.

Run `run_ssc_demo.m` from the package root. It reads these two images and uses disparity candidates `0:14`. Ground truth is not needed for this matching example.

Keep this folder together with `run_ssc_demo.m` and `src/` when sharing the demo.
