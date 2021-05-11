function  testVideo(~,~)
global listenerStatus;
global eTrackGlobal;

% eye tracking data 1
listenerStatus.filename1 = 'C:\Users\uic\Documents\vid1';
listenerStatus.filenameMeta1 = 'C:\Users\uic\Documents\meta1.mat';

% eye tracking data 2
listenerStatus.filename2 = 'C:\Users\uic\Documents\vid2';
listenerStatus.filenameMeta2 = 'C:\Users\uic\Documents\meta2.mat';

% behaviour cam data
listenerStatus.filename3 = 'C:\Users\uic\Documents\vid3';
listenerStatus.filenameMeta3 = 'C:\Users\uic\Documents\meta3.mat';

if strcmp(listenerStatus.status ,'acquiring')
    % then stop
    disp('Requesting stop');
    listenerStatus.status = 'aborting';
elseif strcmp(listenerStatus.status ,'idle')
    % then start
    listenerStatus.status = 'start';
    disp('Requesting start');
else
    disp('Current status unknown so just leaving things as they are!');
end

end