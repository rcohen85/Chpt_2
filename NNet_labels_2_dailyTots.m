% Use cluster_bins output and corresponding NNet labels to calculate daily
% click type presence at each site in hours (5-min resolution).

clearvars
TPWSDir = 'J:\WAT_HZ_02\WAT_HZ_02_TPWS'; % directory containing TPWS files
clusDir = 'J:\WAT_HZ_02\NEW_ClusterBins_120dB'; % directory containing cluster_bins output
saveName = 'WAT_HZ_02_DailyTotals'; % filename to save 
NNetDir = []; % directory containing NNet training folders
saveDir = 'I:\DailyCT_Totals\minClicks50'; % directory to save output
labFlagStr = 'labFlag_0';
spNameList = {'Blainville','Boats','UD36','UD26','UD28','UD19',...
    'UD47','UD38','Cuvier','Gervais','GoM_Gervais','HFA','Kogia','MFA',...
    'MultiFreqSonar','Risso','SnapShrimp','Sowerby','Sperm Whale','True'}';
RLThresh = 120;
numClicksThresh = 50;
probThresh = 0;

%%
TPWSfList = dir(fullfile(TPWSDir,'*TPWS1.mat'));
clusfList = dir(fullfile(clusDir,'*.mat'));
labelDir = fullfile(clusDir,'ToClassify\labels');
labelfList = dir(fullfile(labelDir,'*predLab.mat'));

if isempty(spNameList) && ~isempty(NNetDir)
    typeList = dir(NNetDir);
    typeList = typeList(3:end);
    typeList = typeList(vertcat(typeList.isdir));
    spNameList = {typeList(:).name}'; % species names corresponding to NNet labels
elseif isempty(spNameList) && isempty(NNetDir)
    sprintf('NO SPECIES NAME INFO\n');
    return
end

% Compile labeled bins across the deployment; columns correspond to spNameList;
% each cell contains the start/end times of  all bins given that label 
% (meeting the user thresholds) across the deployment

labeledBins = cell(1,size(spNameList,1));
binFeatures = cell(3,size(spNameList,1));
for iF = 1:size(clusfList,1) % for each file
    load(fullfile(TPWSfList(iF).folder,TPWSfList(iF).name),'MTT','MPP')
    load(fullfile(clusfList(iF).folder,clusfList(iF).name),'binData')
    load(fullfile(clusfList(iF).folder,'/ToClassify',strrep(clusfList(iF).name,'.mat','_toClassify.mat')));
    load(fullfile(labelfList(iF).folder,labelfList(iF).name));
    if ~isempty(labFlagStr)
    load(fullfile(labelfList(iF).folder,strrep(labelfList(iF).name,'predLab',labFlagStr)));
    end
    
    % calculate mean PPRL for each bin spec in toClassify
    meanPPRL = [];
    binTimes = vertcat(binData.tInt);
    binTimes(:,2) = [];
    for iB = 1:size(sumTimeMat,1) % for each bin spec
        % find times of clicks contributing to this spec
        binInd = find(binTimes==sumTimeMat(iB,1));
        clickTimes = binData(binInd).clickTimes{1,whichCell(iB)}; 
        
%         if iF == 7 || iF == 11 % for remade WAT_BC_03 TPWS
%          if iF == 37 % for remade WAT_WC_03 TPWS
%             [~,timesInTPWS] = ismembertol(clickTimes,MTT,1e-9,'DataScale',1);
%         else
            [~,timesInTPWS] = ismember(clickTimes,MTT); % find indices of clicks in TPWS vars
%          end
         timesInTPWS(timesInTPWS==0) = [];
%          if ~isempty(timesInTPWS)
             clickRLs = MPP(timesInTPWS); % get RLs of clicks
             clickRLs_lin = 10.^(clickRLs./20); % return to linear space
             meanRL = 20*log10(mean(clickRLs_lin)); % average and revert to log space
             meanPPRL = [meanPPRL;meanRL];
%          else
%              meanPPRL = [meanPPRL;NaN];
%          end
    end
    
    % get rid of labels which don't meet thresholds
    probs = double(probs);
    predLabels = double(predLabels)+1;
    probIdx = sub2ind(size(probs),1:size(probs,1),double(predLabels));
    myProbs = probs(probIdx)';
    predLabels(labFlag(:,2)==0) = NaN;
    predLabels(myProbs<probThresh) = NaN;
    predLabels(meanPPRL<RLThresh) = NaN;
    predLabels(nSpecMat<numClicksThresh)=NaN;
    

    for iS = 1:size(spNameList,1) % collect bins and bin features by label
        labeledBins{1,iS} = [labeledBins{1,iS};sumTimeMat(predLabels==iS,:)];
        binFeatures{1,iS} = [binFeatures{1,iS};myProbs(predLabels==iS)];
        binFeatures{2,iS} = [binFeatures{2,iS};meanPPRL(predLabels==iS)];
        binFeatures{3,iS} = [binFeatures{3,iS};nSpecMat(predLabels==iS)];
        
        [labeledBins{1,iS}, binInd] = sortrows(labeledBins{1,iS});
        binFeatures{1,iS} = binFeatures{1,iS}(binInd);
        binFeatures{2,iS} = binFeatures{2,iS}(binInd);
        binFeatures{3,iS} = binFeatures{3,iS}(binInd);
    end
    
end

% Sum daily hourly presence of each CT; resolution is cluster_bins dur; column 1
% is the date, remaining columns correspond to spNameList
depSt = floor(min(min(vertcat(labeledBins{1,:}))));
depEnd = floor(max(max(vertcat(labeledBins{1,:}))));
dvec = depSt:1:depEnd;
dailyTots = zeros(length(dvec),size(spNameList,1),1);
dailyTots(:,1) = datenum(dvec);
for iCT = 1:size(spNameList,1) % for each CT
    thisCTbins = labeledBins{1,iCT}(:,1);
    thisCTbins = unique(thisCTbins); % don't double-count bins with multiple spectra given this label
    binDays = sort(floor(thisCTbins)); % find day each labeled bin falls on
    [N,~,bin] = histcounts(binDays,[dvec,dvec(end)+1]); % sort bins into days of the deployment
    if max(N)>288
        fprintf('WARNING: TOO MANY BINS PER DAY!\n');
        tooMany = 1;
    end
    dailyTots(:,iCT+1) = N*0.0833;
end

% Combine Atl Gervais & GoM Gervais detections
spNameList{21,1} = 'AtlGervais+GomGervais';
binFeatures{1,21} = [binFeatures{1,10};binFeatures{1,11}];
binFeatures{2,21} = [binFeatures{2,10};binFeatures{2,11}];
binFeatures{3,21} = [binFeatures{3,10};binFeatures{3,11}];
dailyTots(:,22) = dailyTots(:,11)+dailyTots(:,12);
labeledBins{1,21} = [labeledBins{1,10};labeledBins{1,11}];

[labeledBins{1,21}, binInd] = sortrows(labeledBins{1,21});
binFeatures{1,21} = binFeatures{1,21}(binInd);
binFeatures{2,21} = binFeatures{2,21}(binInd);
binFeatures{3,21} = binFeatures{3,21}(binInd);
dailyTots = sortrows(dailyTots);

save(fullfile(saveDir,[saveName '_Prob' num2str(probThresh) '_RL' num2str(RLThresh) '_numClicks' num2str(numClicksThresh)]),...
    'spNameList','RLThresh','numClicksThresh','probThresh','labeledBins','binFeatures','dailyTots');
