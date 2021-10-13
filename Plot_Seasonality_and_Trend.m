
clearvars

inFile = 'I:\TimeSeries\DailyPresence.mat';
saveDir = 'I:\Seasonal_Plots';
load(inFile);

for iS = 1:size(siteAbbrevs,1)
    
    for iCT = 1:size(spNameList,1)
        
        myData = dailyPresTS{iS,iCT};
        myData(:,2) = myData(:,2)./24;
        outputFileName = [spNameList{iCT,1} '_at_' siteAbbrevs{iS,1}];
        
        Deseason_data(myData,saveDir,outputFileName);
        
        
        
    end
    
end