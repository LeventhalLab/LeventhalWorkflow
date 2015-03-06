function createPLXFiles(nasPath)
    % see exportSessionConf.m for details, loads sessionConf variable
    [f,p] = uigetfile({fullfile(nasPath,'*.mat')},'Select configuration file...');
    load(fullfile(p,f));
    % get paths, create: processed
    leventhalPaths = buildLeventhalPaths(nasPath,sessionConf.sessionName,{'processed'});
    
    spikeParameterString = sprintf('WL%02d_PL%02d_DT%02d', sessionConf.waveLength,...
       sessionConf.peakLoc, sessionConf.deadTime);

    validTetrodes = find(any(sessionConf.validMasks,2).*sessionConf.chMap(:,1));
    fullSevFiles = getChFileMap(leventhalPaths.session);
    
    for ii=1:length(validTetrodes)
        tetrodeName = sessionConf.tetrodeNames{validTetrodes(ii)};
        disp(['Processing tetrode ',tetrodeName]);
        tetrodeChannels = sessionConf.chMap(validTetrodes(ii),2:end);
        tetrodeValidMask = sessionConf.validMasks(validTetrodes(ii),:);
        
        tetrodeFilenames = fullSevFiles(tetrodeChannels);
        data = prepSEVData(tetrodeFilenames,tetrodeValidMask,500);
        locs = getSpikeLocations(data,tetrodeValidMask,sessionConf.Fs,'negative');
        
        PLXfn = fullfile(leventhalPaths.processed,[sessionConf.sessionName,...
            '_',tetrodeName,'_',spikeParameterString,'.plx']);
        PLXid = makePLXInfo(PLXfn,sessionConf,tetrodeChannels,length(data));
        makePLXChannelHeader(PLXid,sessionConf,tetrodeChannels,tetrodeName);
        
        disp('Extracing waveforms...');
        waveforms = extractWaveforms(data,locs,sessionConf.peakLoc,...
            sessionConf.waveLength);
        disp('Writing waveforms to PLX file...');
        writePLXdatablock(PLXid,waveforms,locs);
    end
end

function data = prepSEVData(filenames,validMask,threshArtifacts)
    header = getSEVHeader(filenames{1});
    dataLength = (header.fileSizeBytes - header.dataStartByte) / header.sampleWidthBytes;
    data = zeros(length(validMask),dataLength);
    for ii=1:length(filenames)
        if ~validMask(ii), continue, end
        disp(['Reading ',filenames{ii}]);
        [data(ii,:),~] = read_tdt_sev(filenames{ii});
        data(ii,:) = wavefilter(data(ii,:),6);
        data(ii,:) = artifactThresh(double(data(ii,:)),threshArtifacts);
    end
end

function fullSevFiles = getChFileMap(sessionPath)
    sevFiles = dir(fullfile(sessionPath,'*.sev'));
    chFileMap = zeros(length(sevFiles),1);
    fullSevFiles = cell(length(sevFiles),1);
    for ii=1:length(sevFiles)
        chFileMap(ii) = getSEVChFromFilename(sevFiles(ii).name);
        fullSevFiles{ii} = fullfile(sessionPath,sevFiles(ii).name);
    end
    fullSevFiles(chFileMap) = fullSevFiles; %remap so they are in order
end

function ch = getSEVChFromFilename(name)
    C = strsplit(name,'_');
    C = strsplit(C{end},'.'); %C{1} = chXX
    ch = str2double(C{1}(3:end));
end