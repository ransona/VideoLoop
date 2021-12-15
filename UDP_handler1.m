function UDP_handler1(varargin)
% parse UDP message
% take action depending upon first 4 letters of UDP
% Handler for acquiring eyetracking data

global listenerStatus;
global eTrackGlobal;
localPath = 'c:\local_repository';
remotePath = '\\ar-lab-nas1\dataserver\Remote_Repository';
% check the udp queue
udpSI =listenerStatus.udpSI;

%try
    udpData = udpSI.pull;
    
    if ~isempty(udpData)
        if strcmp(udpData.messageType,'COM')
            % if it's a command
            switch udpData.messageData
                case 'GOGO'
                    disp('=======');
                    disp('Received GOGO signal');
                    % ensure we are ready to acquire
                    if ~strcmp(listenerStatus.status,'idle')
                        % if currently acquiring then request abort
                        listenerStatus.status = 'aborting';
                        startTime = tic;
                        while ~strcmp(listenerStatus.status,'idle')
                            if toc(startTime)>10
                                msgbox('Could not abort ongoing acquisition.');return;
                            else
                              drawnow
                            end
                        end
                            
                    end
                                        
                    % parse experiment reference
                    listenerStatus.expID = udpData.meta{1};
                    
                    % update GUI
                    % set(eTrackGlobal.handles.textExpID,'String',listenerStatus.expID);
                    
                    % set save path and filename appropriately
                    
                    % ensure directory exists locally
                    animalID = listenerStatus.expID(15:end);
                    localDataDirectory = fullfile(localPath,animalID,listenerStatus.expID);
                    if ~exist(localDataDirectory,'dir')
                        mkdir(localDataDirectory);
                    end
                    
                    % ensure directory exists remotely
                    remoteDataDirectroy = fullfile(remotePath,animalID,listenerStatus.expID);
                    if ~exist(remoteDataDirectroy,'dir')
                        mkdir(remoteDataDirectroy);
                    end
                    
                    % eye tracking data 1
                    listenerStatus.filename1 = fullfile(localDataDirectory,[listenerStatus.expID,'_eye1']);
                    listenerStatus.filenameMeta1 = fullfile(localDataDirectory,[listenerStatus.expID,'_eyeMeta1.mat']);
                    
                    % load the view roi config for eyetracking cam
                    eyeDirectory = fullfile(localPath,animalID,'eyeCalib','eyeCalib.mat');
                    % check if a config exists
                    if exist(eyeDirectory,'file')
                        % load roi setting for animal
                        load(eyeDirectory);
                        eTrackGlobal.roi = roi;
                    else
                        % use default config
                        disp('Warning: no eyetracking configuration exists for this animal.');
                    end
                    
                    % start the acquisition and wait for confirmation
                    listenerStatus.status = 'start';
%                     statWait = tic;
%                         while ~strcmp(listenerStatus.status,'acquiring')&&(toc(statWait)<120)
%                             drawnow;
%                         end
%                     udpSI.send('READY','COM');
                    disp('Grabbing confirmed');

                case 'STOP'
 
                    listenerStatus.status = 'aborting';
                    % force a TICKs until idle
                        statWait = tic;
                        listenerStatus.status = 'aborting';
%                     startTime = tic;
%                         while ~strcmp(listenerStatus.status,'idle')
%                             if toc(startTime)>10
%                                 msgbox('Could not abort ongoing acquisition.');return;
%                             else
%                               drawnow
%                             end
%                         end
%                     disp('Stopped');

            end
        end
        
    end
    
% catch
%     disp('Error processing UDP data');
% end
