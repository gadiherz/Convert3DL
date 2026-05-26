function Convert3DLApp()
%CONVERT3DLAPP  GUI front-end for converting AGMT3-D .3dl files to PLY.
%   Convert3DLApp opens a simple window to convert a single .3dl file or an
%   entire folder of them. Outputs (mesh PLY, landmark PLY, landmark CSV)
%   are written via convert3dl / convert3dlFolder.
%
%   Written as a programmatic uifigure app (plain .m, no binary .mlapp) and
%   using only base MATLAB, so it compiles cleanly with MATLAB Compiler into
%   a standalone application. End users then need only the free MATLAB
%   Runtime.

    % --- State shared via the figure's UserData ---
    state.inputPath = "";   % selected file or folder
    state.isFolder  = false;

    fig = uifigure("Name", "Convert .3dl to PLY", ...
        "Position", [100 100 640 460]);
    fig.UserData = state;

    gl = uigridlayout(fig, [6 3]);
    gl.RowHeight   = {30, 30, 30, 30, '1x', 25};
    gl.ColumnWidth = {130, '1x', 130};

    % Row 1: pick a single file
    btnFile = uibutton(gl, "Text", "Select File…", ...
        "ButtonPushedFcn", @(~,~) onSelectFile());
    btnFile.Layout.Row = 1; btnFile.Layout.Column = 1;

    inField = uieditfield(gl, "text", "Editable", "off", ...
        "Placeholder", "No input selected");
    inField.Layout.Row = 1; inField.Layout.Column = [2 3];

    % Row 2: pick a folder (batch)
    btnFolder = uibutton(gl, "Text", "Select Folder…", ...
        "ButtonPushedFcn", @(~,~) onSelectFolder());
    btnFolder.Layout.Row = 2; btnFolder.Layout.Column = 1;

    modeLabel = uilabel(gl, "Text", "(choose a file OR a folder)");
    modeLabel.Layout.Row = 2; modeLabel.Layout.Column = [2 3];

    % Row 3: output folder
    btnOut = uibutton(gl, "Text", "Output Folder…", ...
        "ButtonPushedFcn", @(~,~) onSelectOut());
    btnOut.Layout.Row = 3; btnOut.Layout.Column = 1;

    outField = uieditfield(gl, "text", ...
        "Placeholder", "Defaults to source folder");
    outField.Layout.Row = 3; outField.Layout.Column = [2 3];

    % Row 4: convert
    btnConvert = uibutton(gl, "Text", "Convert", ...
        "FontWeight", "bold", ...
        "ButtonPushedFcn", @(~,~) onConvert());
    btnConvert.Layout.Row = 4; btnConvert.Layout.Column = [1 3];

    % Row 5: log
    logArea = uitextarea(gl, "Editable", "off", "Value", {'Ready.'});
    logArea.Layout.Row = 5; logArea.Layout.Column = [1 3];

    % Row 6: status line
    statusLabel = uilabel(gl, "Text", "");
    statusLabel.Layout.Row = 6; statusLabel.Layout.Column = [1 3];

    % ----------------- callbacks -----------------
    function onSelectFile()
        [name, path] = uigetfile({'*.3dl','AGMT3-D files (*.3dl)'}, ...
            "Select a .3dl file");
        if isequal(name, 0); return; end
        fig.UserData.inputPath = string(fullfile(path, name));
        fig.UserData.isFolder  = false;
        inField.Value = char(fig.UserData.inputPath);
        modeLabel.Text = "Mode: single file";
    end

    function onSelectFolder()
        path = uigetdir("", "Select a folder of .3dl files");
        if isequal(path, 0); return; end
        fig.UserData.inputPath = string(path);
        fig.UserData.isFolder  = true;
        inField.Value = char(fig.UserData.inputPath);
        modeLabel.Text = "Mode: batch folder";
    end

    function onSelectOut()
        path = uigetdir("", "Select output folder");
        if isequal(path, 0); return; end
        outField.Value = path;
    end

    function onConvert()
        inPath = fig.UserData.inputPath;
        if inPath == ""
            log("No input selected.");
            return;
        end
        outDir = string(outField.Value);
        btnConvert.Enable = "off";
        cleanup = onCleanup(@() set(btnConvert, "Enable", "on")); %#ok<NASGU>
        try
            if fig.UserData.isFolder
                log("Converting folder: " + inPath);
                drawnow;
                res = convert3dlFolder(inPath, outDir);
                for i = 1:height(res)
                    if res.ok(i)
                        log(sprintf("  OK   %s  (%d files)", ...
                            res.file(i), res.nFilesWritten(i)));
                    else
                        log(sprintf("  FAIL %s  -- %s", ...
                            res.file(i), res.message(i)));
                    end
                end
                statusLabel.Text = sprintf("Done: %d/%d converted.", ...
                    sum(res.ok), height(res));
            else
                log("Converting file: " + inPath);
                drawnow;
                st = convert3dl(inPath, outDir);
                for i = 1:numel(st.files)
                    log("  wrote " + st.files(i));
                end
                statusLabel.Text = "Done.";
            end
        catch ME
            log("ERROR: " + string(ME.message));
            statusLabel.Text = "Failed.";
        end
    end

    function log(msg)
        v = logArea.Value;
        if ischar(v); v = {v}; end
        lines = cellstr(string(msg));
        logArea.Value = [v(:); lines(:)];
        drawnow;
    end
end
