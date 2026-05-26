%BUILD_STANDALONE  Compile Convert3DLApp and package a branded web installer.
%
%   Run this script from the Convert3DL folder. It:
%     1. Generates ArCH3D-branded icon/splash images from assets\ArCH3D_logo.png.
%     2. Compiles Convert3DLApp into a standalone executable (.\build_Convert3DL),
%        with the ArCH3D icon and a startup splash.
%     3. Wraps it in a self-installing WEB installer (.\installer_Convert3DL)
%        branded with the ArCH3D logo, that automatically downloads and installs
%        the correctly-versioned MATLAB Runtime on the end user's machine.
%
%   Build vs run -- the important split:
%     * BUILDING (this script) needs MATLAB + MATLAB Compiler. Only the
%       developer needs this, once per release. No other toolbox is required
%       because every file here uses only base MATLAB.
%     * RUNNING the produced web installer needs only Windows + an internet
%       connection. The installer fetches the matching MATLAB Runtime (free,
%       no license) itself, so end users need no MATLAB and no toolboxes.

thisDir = fileparts(mfilename("fullpath"));
addpath(thisDir);

assetsDir    = fullfile(thisDir, "assets");
buildDir     = fullfile(thisDir, "build_Convert3DL");
installerDir = fullfile(thisDir, "installer_Convert3DL");

logoPath = fullfile(assetsDir, "ArCH3D_logo.png");

% --- 0. Generate branded icon + splash from the logo (dark backing) ---
darkBG   = [31 41 51];   % 0-255 dark slate so white "ArCH" text reads
iconPath   = fullfile(assetsDir, "ArCH3D_icon.png");    % square, for exe + installer
splashPath = fullfile(assetsDir, "ArCH3D_splash.png");  % logo banner on dark bg
makeBranding(logoPath, iconPath, splashPath, darkBG);

supportFiles = [ ...
    fullfile(thisDir, "writePLY.m"); ...
    fullfile(thisDir, "convert3dl.m"); ...
    fullfile(thisDir, "convert3dlFolder.m"); ...
    logoPath];   % bundled so the in-app banner shows when deployed

% --- 1. Compile the standalone executable (with icon + splash) ---
% ExecutableIcon / ExecutableSplashScreen require a recent release; if your
% MATLAB rejects them, the catch block rebuilds without the branding options.
commonArgs = { ...
    fullfile(thisDir, "Convert3DLApp.m"), ...
    "ExecutableName", "Convert3DL", ...
    "OutputDir", buildDir, ...
    "AdditionalFiles", supportFiles};
try
    results = compiler.build.standaloneApplication(commonArgs{:}, ...
        "ExecutableIcon", iconPath, ...
        "ExecutableSplashScreen", splashPath);
catch ME
    warning("build_standalone:noExeBranding", ...
        "Exe icon/splash not applied (%s). Rebuilding without them.", ME.message);
    results = compiler.build.standaloneApplication(commonArgs{:});
end

disp("Build complete. Executable in:");
disp(buildDir);

% --- 2. Package a branded WEB installer (auto-downloads the MATLAB Runtime) ---
compiler.package.installer(results, ...
    "ApplicationName", "Convert3DL", ...
    "AuthorName",      "Gadi Herzlinger", ...
    "AuthorCompany",   "ArCH3D — School of Archaeology and Maritime Cultures, University of Haifa", ...
    "Summary",         "Convert AGMT3-D .3dl files to PLY meshes and landmark exports.", ...
    "Description",     "ArCH3D lab tool. Converts .3dl (oriented AGMT3-D) files to coloured PLY meshes plus landmark PLY/CSV exports.", ...
    "Version",         "1.0", ...
    "InstallerIcon",   iconPath, ...
    "InstallerLogo",   splashPath, ...
    "InstallerSplash", splashPath, ...
    "RuntimeDelivery", "web", ...   % small installer; fetches Runtime at install time
    "OutputDir",       installerDir);

disp("Installer complete. Web installer in:");
disp(installerDir);

% --- Alternative: OFFLINE installer that bundles the full Runtime (~GBs) ---
% compiler.package.installer(results, ...
%     "ApplicationName", "Convert3DL", "RuntimeDelivery", "installer", ...
%     "InstallerIcon", iconPath, "InstallerLogo", splashPath, ...
%     "OutputDir", fullfile(thisDir, "installer_Convert3DL_offline"));


% ===================== helpers =====================
function makeBranding(logoPath, iconPath, splashPath, darkBG255)
%MAKEBRANDING  Composite the (transparent) logo over a dark background and
%   write a square icon and a wide splash, so the white logo text is visible.
    if ~isfile(logoPath)
        warning("build_standalone:noLogo", ...
            "Logo not found at '%s'; skipping branded image generation.", logoPath);
        return;
    end
    [rgb, ~, alpha] = imread(logoPath);
    rgb = im2double(rgb);
    if isempty(alpha)
        a = ones(size(rgb,1), size(rgb,2));
    else
        a = im2double(alpha);
    end
    bg = reshape(darkBG255/255, 1, 1, 3);
    comp = rgb .* a + bg .* (1 - a);   % over-composite onto dark slate

    % Splash: the full banner on dark bg, capped to a sensible width.
    splash = comp;
    maxW = 500;
    if size(splash,2) > maxW
        splash = imresize(splash, maxW / size(splash,2));
    end
    imwrite(splash, splashPath);

    % Icon: square canvas (dark bg) with the logo fit inside.
    side = 256;
    icon = repmat(bg, side, side, 1);
    scale = min(side / size(comp,1), side / size(comp,2)) * 0.9;
    logoR = imresize(comp, scale);
    [h, w, ~] = size(logoR);
    r0 = floor((side - h)/2) + 1;
    c0 = floor((side - w)/2) + 1;
    icon(r0:r0+h-1, c0:c0+w-1, :) = logoR;
    imwrite(icon, iconPath);
end
