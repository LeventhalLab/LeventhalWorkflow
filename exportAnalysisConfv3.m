function analysisConf = exportAnalysisConfv2(subjects,nasPath)

analysisConf = struct;
analysisConf.subjects = subjects;
analysisConf.nasPath = nasPath;
analysisConf.sessionConfs = {};

allNeurons = {};
allSessionNames = {};
allSessionConfs = {};
neuronCount = 1;
    
for iSubjects = 1:numel(subjects)
    subjects__name = subjects{iSubjects};
    % get all data folders that exist
    % use dir2 to remove {'.','..','.DS_Store','._.DS_Store'}
    dataDirs = dir2(fullfile(nasPath,subjects__name,[subjects__name,'-processed']));
    for iDataDir=1:length(dataDirs)
        if ~dataDirs(iDataDir).isdir
            continue;
        end
        % requires network
        sessionConf = exportSessionConfv2(dataDirs(iDataDir).name,'nasPath',nasPath);
        if isempty(sessionConf.leventhalPaths.nex) % nex files uncompilled
            continue;
        end
        leventhalPaths = buildLeventhalPathsv2(sessionConf);
        [nvar, names, types] = nex_info(leventhalPaths.nex);
        neuronNames = cellstr(deblank(names(types==0,:)));
        allNeurons = {allNeurons{:} neuronNames{:}};
        for ii=1:length(neuronNames)
            allSessionNames = [allSessionNames;sessionConf.sessions__name];
            allSessionConfs{neuronCount,1} = sessionConf;
            neuronCount = neuronCount + 1;
        end
    end
    allNeurons = allNeurons';
end

 neuronIds = listdlg('PromptString','Select neurons:',...
                'SelectionMode','multiple','ListSize',[500 700],...
                'ListString',allNeurons);

analysisConf.neurons = allNeurons(neuronIds);
analysisConf.sessionNames = allSessionNames(neuronIds);
analysisConf.sessionConfs = allSessionConfs(neuronIds);