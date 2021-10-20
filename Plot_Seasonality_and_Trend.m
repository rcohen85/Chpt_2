
clearvars

inFile = 'I:\TimeSeries\DailyPresence.mat';
saveDir = 'I:\Seasonal_Plots';
load(inFile);


for iCT = 1:size(spNameList,1)
    for iS = 1:size(siteAbbrevs,1)
        
        outputFileName = [spNameList{iCT,1} '_at_' siteAbbrevs{iS,1}];
        thisCTsaveDir = fullfile(saveDir,spNameList{iCT,1});
        if ~isdir(thisCTsaveDir)
            mkdir(thisCTsaveDir)
        end
        
        thisCT = dailyPresTS{iS,iCT};
        thisCT(:,2) = thisCT(:,2)./24; % proportion of day with presence
        thisCTerr = dailyErrTS{iS,iCT};  
        thisCTerr(isnan(thisCTerr)) = 0; % if error values are missing, assume no error
        adjustedPres = thisCT(:,2).*(1-thisCTerr); % adjust presence by error
        effort = dailyEffortTS{iS,1};
        noEffDays = find(effort(:,2)==0);
        adjustedPres(noEffDays) = NaN; % remove spurious presence on no-effort days
        adjustedPres = adjustedPres.*(1./effort(:,2)); % adjust presence by daily effort
        
        fullTS = (thisCT(1,1):1:thisCT(end,1))';
        [Lia Locb] = ismember(thisCT(:,1),fullTS);
        fullTS(:,2) = NaN;
        fullTS(Locb,2) = adjustedPres;
        
        Deseason_data(fullTS,thisCTsaveDir,outputFileName);
        
    end
end