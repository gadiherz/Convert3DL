# Convert3DL

Convert AGMT3-D `.3dl` files to **PLY**, from a MATLAB script or a standalone app.

A `.3dl` file is a MAT file (loaded with `-mat`) holding:

| variable    | size  | meaning |
|-------------|-------|---------|
| `v`         | N×3   | vertex XYZ (oriented in AGMT3-D) |
| `f`         | M×3   | triangle faces, **1-based** |
| `c`         | N×3   | per-vertex RGB colour |
| `matsize1`  | 1×2   | grid config: #latitudes, #landmarks per latitude |
| `Landmarks` | l×3   | projected landmarks, `l = matsize1(1)·matsize1(2)·2` |

For each input the tool writes:

- `<base>.ply` — coloured triangle mesh (`v`, `f`, `c`).
- `<base>_landmarks.ply` — landmark point cloud.
- `<base>_landmarks.csv` — landmark coordinates.

PLY is used (not OBJ) because PLY stores per-vertex RGB natively; standard OBJ does not.

## Install without MATLAB (end users)

Download **[`installer/Convert3DL_WebInstaller.exe`](installer/Convert3DL_WebInstaller.exe)**
and run it. It automatically downloads and installs the matching (free) MATLAB Runtime,
then installs the app — **no MATLAB license or toolboxes required**. You only need 64-bit
Windows and an internet connection during installation.

## Use as a script

```matlab
% Single file (output defaults to the source folder)
convert3dl("C:\data\piece001.3dl");
convert3dl("C:\data\piece001.3dl", "C:\out");

% Whole folder
results = convert3dlFolder("C:\data", "C:\out");   % returns a status table
```

## Use the GUI

```matlab
Convert3DLApp
```

Pick a single `.3dl` file **or** a folder, optionally set an output folder, then
**Convert**. The log lists every file written and reports per-file errors.

## Build a standalone installable app

```matlab
build_standalone
```

This produces two things:

- `build_Convert3DL\Convert3DL.exe` — the bare standalone (needs a matching MATLAB
  Runtime already installed).
- `installer_Convert3DL\` — a small **web installer** (e.g. `MyAppInstaller_web.exe`).
  This is the one to distribute: on the end user's machine it **automatically downloads
  and installs the correctly-versioned MATLAB Runtime**, then installs the app.

### Who needs what — the build-vs-run split

- **Building** (running `build_standalone`) needs **MATLAB + MATLAB Compiler**. Only you,
  the developer, need this, and only once per release. No other toolbox is required because
  every file here uses **only base MATLAB** (`fopen`/`fprintf`, `load`, `writematrix`,
  `uifigure`) — deliberately **no Lidar Toolbox** (`writeSurfaceMesh`) or **Computer Vision
  Toolbox** (`pcwrite`).
- **Running the web installer** needs only **Windows + an internet connection**. It fetches
  the free MATLAB Runtime itself, so end users need **no MATLAB and no toolbox licenses**.

For air-gapped machines, an **offline installer** (bundles the full ~GB Runtime, no
internet needed) is available as a commented alternative in `build_standalone.m`.

Using `writeSurfaceMesh` would have forced a Lidar Toolbox dependency into the build for
what a few lines of `fprintf` do, so it was avoided on purpose.

## Distributing on GitHub

- **Commit source only** — the `.m` files, `README.md`, and `.gitignore`. Build outputs
  (`build_Convert3DL/`, `installer_Convert3DL/`) are git-ignored to keep the repo small.
- **Ship the installer as a Release asset**, not in the repo tree. GitHub rejects files
  over 100 MB in the tree, but **Release assets allow up to 2 GB each**. Zip the web
  installer and attach it to a tagged Release. (The web installer is small; only the
  optional offline installer is large.)

## Files

- `writePLY.m` — dependency-free ASCII PLY writer (mesh or point cloud, optional colour).
- `convert3dl.m` — convert one `.3dl`.
- `convert3dlFolder.m` — batch convert a folder.
- `Convert3DLApp.m` — GUI front-end.
- `build_standalone.m` — compile to a standalone app.
