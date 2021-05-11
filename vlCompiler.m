mFileName = 'videoLoop.m'; % or whatever it's called.  Change to match your m-file's name.
outputFolder = 'C:\Code\VideoLoop\compiled'; % Or wherever you want the compiled "my_webcam_app.exe" to go.
fprintf('Beginning compile of %s application at %s ...\n', mFileName, datestr(now));
tic;
% Now we're ready to compile.
% But first, make sure you change R2020a in the line below to whatever release year you're using.
mcc('-m', mFileName, '-d', outputFolder, '-a', 'C:\ProgramData\MATLAB\SupportPackages\R2021a\toolbox\matlab\webcam\supportpackages' ...
                                       , '-a', 'C:\ProgramData\MATLAB\SupportPackages\R2021a\toolbox\matlab\hardware\supportpackages\arduinoio' ...
                                       , '-a', 'C:\ProgramData\MATLAB\SupportPackages\R2021a\toolbox\matlab\hardware\supportpackages\sharedarduino');
% Done compiling.  Tell developer that we're done, and how long it took to compile.
elapsedSeconds = toc;
minutes = int32(floor(elapsedSeconds / 60));
seconds = elapsedSeconds - 60 * double(minutes);
message = sprintf('It is done compiling %s at %s.  It took %d minutes and %.1f seconds.\n', mFileName, datestr(now), minutes, seconds);
fprintf('%s\n', message);
msgbox(message);