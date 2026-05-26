function results = convert3dlFolder(inDir, outDir)
%CONVERT3DLFOLDER  Batch-convert every .3dl file in a folder to PLY.
%   results = convert3dlFolder(inDir, outDir) converts all *.3dl files in
%   inDir, writing outputs to outDir (defaults to inDir). One bad file does
%   not abort the batch: per-file errors are caught and recorded.
%
%   results is a table with columns: file, ok, nFilesWritten, message.

    arguments
        inDir  (1,1) string
        outDir (1,1) string = ""
    end

    if outDir == ""
        outDir = inDir;
    end

    listing = dir(fullfile(inDir, "*.3dl"));
    n = numel(listing);

    file    = strings(n,1);
    ok      = false(n,1);
    nWrit   = zeros(n,1);
    message = strings(n,1);

    for k = 1:n
        inPath = fullfile(listing(k).folder, listing(k).name);
        file(k) = string(listing(k).name);
        try
            st = convert3dl(inPath, outDir);
            ok(k)      = st.ok;
            nWrit(k)   = numel(st.files);
        catch ME
            ok(k)      = false;
            message(k) = string(ME.message);
        end
    end

    results = table(file, ok, nWrit, message, ...
        'VariableNames', {'file','ok','nFilesWritten','message'});

    fprintf("Converted %d of %d .3dl files in '%s'.\n", sum(ok), n, inDir);
end
