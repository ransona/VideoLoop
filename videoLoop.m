function videoLoop()
global listenerStatus;
global eTrackGlobal;

listOfTimers = timerfindall;
if ~isempty(listOfTimers)
delete(listOfTimers(:));
end
clear all

global listenerStatus;
global eTrackGlobal;

% initial setup
eTrackGlobal.tic = tic;
eTrackGlobal.camsTriggered  = false;

allcams = webcamlist;
disp('Starting cameras...')
% setup eye track camera 1
eTrackGlobal.cam1 = webcam(1);
% setup eye track camera2
eTrackGlobal.cam2 = webcam(2);
% setup behavioural camera
eTrackGlobal.cam3 = webcam(3);

% setup arduino
disp('Starting arduino...')
eTrackGlobal.arduino = arduino('COM4');
eTrackGlobal.arduino.writeDigitalPin('D8',0);

% setup UDP listener
disp('Starting UDP listener...')
listenerStatus.udpSI = UDPqML('10.40.6.198',1814,1813);
listenerStatus.status = 'idle';
listenerStatus.udpCheckTimer = timer('StartDelay',0,'Period',1,'BusyMode','drop','TimerFcn',@UDP_handler1,'ExecutionMode','fixedRate');
start(listenerStatus.udpCheckTimer);

% figure window for display
fig = figure('Units','normalized','Position',[0.33 0.05 0.33 0.9],'Name','Video acquisition','NumberTitle','off');
set(fig, 'MenuBar', 'none');
set(fig, 'ToolBar', 'none');
listenerStatus.status = 'idle';

% testing:
% t1 = timer('StartDelay',2,'Period',1,'BusyMode','drop','TimerFcn',@testVideo,'ExecutionMode','singleShot');
% t2 = timer('StartDelay',12,'Period',1,'BusyMode','drop','TimerFcn',@testVideo,'ExecutionMode','singleShot');
% start(t1);
% start(t2);

%setup images for video preview

a = tight_subplot(3,1,0.01);
%axis equal;
axis(a(1));
eTrackGlobal.hImage1 = image(a(1),zeros(size(snapshot(eTrackGlobal.cam1))));
axis(a(2));
%axis equal;
eTrackGlobal.hImage2 = image(a(2),zeros(size(snapshot(eTrackGlobal.cam2))));
axis(a(3));
%axis equal;
eTrackGlobal.hImage3 = image(a(3),zeros(size(snapshot(eTrackGlobal.cam3))));

eTrackGlobal.cam1.preview(eTrackGlobal.hImage1);
eTrackGlobal.cam2.preview(eTrackGlobal.hImage2);
eTrackGlobal.cam3.preview(eTrackGlobal.hImage3);
 
set(groot,'CurrentFigure',fig);
axes(a(1));
statusText = text(20,20,'IDLE','Color','green','FontSize',20);
axes(a(1));
statusText2 = text(20,80,'','Color','yellow','FontSize',20);

while true
    
    % grab latest camera data
    data1 = snapshot(eTrackGlobal.cam1);
    data2 = snapshot(eTrackGlobal.cam2);
    data3 = snapshot(eTrackGlobal.cam3);
    data1 = squeeze(data1(:,:,1));
    data2 = squeeze(data2(:,:,1));
    data3 = squeeze(data3(:,:,1));
    % concatinate
    xMax = max([size(data1,2),size(data2,2),size(data3,2)]);
    yMax = max([size(data1,1),size(data2,1),size(data3,1)]);
    % pad each
    data1 = cat(2,data1,zeros([size(data1,1),xMax-size(data1,2)]));
    data1 = cat(1,data1,zeros([yMax-size(data1,1),size(data1,2),]));
    data2 = cat(2,data2,zeros([size(data2,1),xMax-size(data2,2)]));
    data2 = cat(1,data2,zeros([yMax-size(data2,1),size(data2,2),]));
    data3 = cat(2,data3,zeros([size(data3,1),xMax-size(data3,2)]));
    data3 = cat(1,data3,zeros([yMax-size(data3,1),size(data3,2),]));
    % data 0 contains the final thing to be output
    data0 = cat(2,data1,data2,data3);
    % update display
    try
    set(groot,'CurrentFigure',fig);
    catch
        break
    end

    if strcmp(listenerStatus.status,'idle')
        drawnow;
    end
    
    %% do stuff relate3d to writing video to disk
    % check if new acquistion has been requested
    % check if a new recording session has been requested
    if  strcmp(listenerStatus.status,'start')
        
        % clear current eyetracking data
        disp('Starting new eyetracking acquisition');
%         eTrackGlobal.data.frames{1} = zeros([size(data1),50000],'uint8');
%         eTrackGlobal.data.frames{2} = zeros([size(data2),50000],'uint8');
%         eTrackGlobal.data.frames{3} = zeros([size(data3),50000],'uint8');

%         eTrackGlobal.cam1.closePreview;
%         eTrackGlobal.cam2.closePreview;
%         eTrackGlobal.cam3.closePreview;
        
        eTrackGlobal.writerObj{1} = VideoWriter(listenerStatus.filename1,'MPEG-4');
        %eTrackGlobal.writerObj{2} = VideoWriter(listenerStatus.filename2,'MPEG-4');
        %eTrackGlobal.writerObj{3} = VideoWriter(listenerStatus.filename3,'MPEG-4');
        
        eTrackGlobal.data.frameTimes=[];
        eTrackGlobal.data.frameCount = 0;
        eTrackGlobal.data.posPulseTimes = [];
        eTrackGlobal.data.negPulseTimes = [];
        eTrackGlobal.data.startTime = toc(eTrackGlobal.tic);
        eTrackGlobal.data.lastTrig = 1;
        %eTrackGlobal.arduino.digitalWrite(8,1);
        eTrackGlobal.arduino.writeDigitalPin('D8',1);
        
        open(eTrackGlobal.writerObj{1});
        %open(eTrackGlobal.writerObj{2});
        %open(eTrackGlobal.writerObj{3});
        
        listenerStatus.status = 'acquiring';
        statusText2.String = strrep(listenerStatus.expID, '_', '\_');
    end
    
    %% check if abort acquisition has been requested
    if  strcmp(listenerStatus.status,'aborting')
        statusText.String = 'ABORTING';
        statusText.Color = 'red';
        disp('Stopping acquisition');
        eTrackGlobal.data.lastTrig = 0;
        eTrackGlobal.arduino.writeDigitalPin('D8',0);
        % then close frames output writer
        %eTrackGlobal.writerObj{1}.  
        drawnow

        eTrackGlobal.writerObj{1}.close;
        % save the rest of the meta data
        eTrackGlobal.data.frames = [];
        statusText.String = 'SAVING META DATA';
        drawnow;
        eTrackData = eTrackGlobal.data;
        save(listenerStatus.filenameMeta1,'eTrackData');

        % sync to server
        %remotePath = '\\ar-lab-nas1\dataserver\Remote_Repository';
        %localPath = 'c:\local_repository\*.*';
        %statusText.String = 'SYNCING TO SERVER';
        %drawnow;
        %tic
        %copyfile(localPath,remotePath);
        %disp(['Time to sync = ',num2str(toc)]);
        listenerStatus.status = 'idle';
        statusText.String = 'IDLE';
        statusText.Color = 'green';
        
        disp('Data saved.');
        % figure;
        % plot(diff(eTrackGlobal.data.frameTimes));
        disp(['Median frame rate = ',num2str(1/median(diff(eTrackGlobal.data.frameTimes)))]);
        %stop(eTrackGlobal.timer);
    end
    
    %% check if acquiring
    if  strcmp(listenerStatus.status,'acquiring')
        statusText.String = 'ACQUIRING';
        statusText.Color = 'red';
        eTrackGlobal.data.frameCount = eTrackGlobal.data.frameCount + 1;
        eTrackGlobal.data.frameTimes(eTrackGlobal.data.frameCount) = toc(eTrackGlobal.tic) - eTrackGlobal.data.startTime;
        
        if length(eTrackGlobal.data.frameTimes)>1
        if eTrackGlobal.data.frameTimes(end)-eTrackGlobal.data.frameTimes(end-1)<0
            disp('Err');
        end
        end
        
        % if frame count is a multiple of 100 then output a timing pulse
        if rem(eTrackGlobal.data.frameCount,100)==0
            
            if eTrackGlobal.data.lastTrig == 1
                eTrackGlobal.data.lastTrig = 0;
                eTrackGlobal.arduino.writeDigitalPin('D8',0);
                eTrackGlobal.data.negPulseTimes = [eTrackGlobal.data.negPulseTimes,eTrackGlobal.data.frameTimes(end)];
            else
                eTrackGlobal.data.lastTrig = 1;
                eTrackGlobal.arduino.writeDigitalPin('D8',1);
                eTrackGlobal.data.posPulseTimes = [eTrackGlobal.data.posPulseTimes,eTrackGlobal.data.frameTimes(end)];
            end

        end
        
        % write frame to disk
        writeVideo(eTrackGlobal.writerObj{1},data0);
    end
end

end

