function status = convert3dl(inPath, outDir)
%CONVERT3DL  Convert one AGMT3-D .3dl file to PLY (+ landmark exports).
%   status = convert3dl(inPath, outDir) reads a single .3dl file and writes:
%     <base>.ply            - coloured triangle mesh (v, f, c).
%     <base>_landmarks.ply  - landmark point cloud (Landmarks), if present.
%     <base>_landmarks.csv  - landmark coordinates as CSV, if present.
%
%   A .3dl file is a MAT file (loaded with '-mat') containing the variables
%   v (Nx3 vertices), f (Mx3 1-based faces), c (Nx3 per-vertex RGB),
%   matsize1 (1x2 grid config), and Landmarks (lx3 projected landmarks).
%   The mesh is written even when c or Landmarks are absent.
%
%   If outDir is omitted, the source folder is used. Uses only base MATLAB
%   so it can be deployed as a standalone application.
%
%   status is a struct with fields: input, files (string array written),
%   ok (logical), message (error text if any).

    arguments
        inPath (1,1) string
        outDir (1,1) string = ""
    end

    [srcDir, base] = fileparts(inPath);
    if outDir == ""
        outDir = srcDir;
    end
    if outDir ~= "" && ~isfolder(outDir)
        mkdir(outDir);
    end

    status = struct("input", inPath, "files", strings(0,1), "ok", false, "message", "");

    S = load(inPath, '-mat');

    if ~isfield(S, "v") || ~isfield(S, "f")
        error("convert3dl:missingMesh", ...
            "'%s' does not contain both 'v' and 'f'.", inPath);
    end

    % --- Mesh PLY (colour optional) ---
    if isfield(S, "c") && ~isempty(S.c)
        col = S.c;
    else
        col = [];
        warning("convert3dl:noColour", ...
            "No 'c' in '%s'; writing geometry-only mesh.", base);
    end
    meshPath = fullfile(outDir, base + ".ply");
    writePLY(meshPath, S.v, S.f, col);
    status.files(end+1,1) = meshPath;

    % --- Landmarks: PLY point cloud + CSV ---
    if isfield(S, "Landmarks") && ~isempty(S.Landmarks)
        lmPly = fullfile(outDir, base + "_landmarks.ply");
        writePLY(lmPly, S.Landmarks, [], []);
        status.files(end+1,1) = lmPly;

        lmCsv = fullfile(outDir, base + "_landmarks.csv");
        writematrix(S.Landmarks, lmCsv);
        status.files(end+1,1) = lmCsv;
    end

    status.ok = true;
end
