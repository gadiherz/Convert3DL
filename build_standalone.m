%BUILD_STANDALONE  Compile Convert3DLApp and package a web installer.
%
%   Run this script from the Convert3DL folder. It does two things:
%     1. Compiles Convert3DLApp into a standalone executable
%        (.\build_Convert3DL).
%     2. Wraps it in a self-installing WEB installer
%        (.\installer_Convert3DL) that automatically downloads and installs
%        the correctly-versioned MATLAB Runtime on the end user's machine.
%
%   Build vs run -- the important split:
%     * BUILDING (this script) needs MATLAB + MATLAB Compiler. Only the
%       developer needs this, once per release. No other toolbox is required
%       because every file here (writePLY, convert3dl, convert3dlFolder,
%       Convert3DLApp) uses only base MATLAB.
%     * RUNNING the produced web installer needs only Windows + an internet
%       connection. The installer fetches the matching MATLAB Runtime (free,
%       no license) itself, so end users need no MATLAB and no toolboxes.
%
%   If compiler.build is unavailable on your release, use the mcc command
%   shown at the bottom instead.

thisDir = fileparts(mfilename("fullpath"));
addpath(thisDir);

buildDir     = fullfile(thisDir, "build_Convert3DL");
installerDir = fullfile(thisDir, "installer_Convert3DL");

supportFiles = [ ...
    fullfile(thisDir, "writePLY.m"); ...
    fullfile(thisDir, "convert3dl.m"); ...
    fullfile(thisDir, "convert3dlFolder.m")];

% --- 1. Compile the standalone executable ---
results = compiler.build.standaloneApplication( ...
    fullfile(thisDir, "Convert3DLApp.m"), ...
    "ExecutableName", "Convert3DL", ...
    "OutputDir", buildDir, ...
    "AdditionalFiles", supportFiles);

disp("Build complete. Executable in:");
disp(buildDir);

% --- 2. Package a WEB installer (auto-downloads the MATLAB Runtime) ---
compiler.package.installer(results, ...
    "ApplicationName", "Convert3DL", ...
    "AuthorName",      "Gadi Herzlinger", ...
    "AuthorCompany",   "University of Haifa", ...
    "Version",         "1.0", ...
    "RuntimeDelivery", "web", ...   % small installer; fetches Runtime at install time
    "OutputDir",       installerDir);

disp("Installer complete. Web installer in:");
disp(installerDir);

% --- Alternative: OFFLINE installer that bundles the full Runtime (~GBs) ---
% Use this for air-gapped / no-internet target machines. Too large for a
% normal GitHub repo; attach as a Release asset or host externally.
% compiler.package.installer(results, ...
%     "ApplicationName", "Convert3DL", ...
%     "RuntimeDelivery", "installer", ...
%     "OutputDir", fullfile(thisDir, "installer_Convert3DL_offline"));

% --- Alternative one-liner using mcc (older releases) ---
% mcc -m Convert3DLApp.m -a writePLY.m -a convert3dl.m -a convert3dlFolder.m ...
%     -o Convert3DL -d build_Convert3DL
