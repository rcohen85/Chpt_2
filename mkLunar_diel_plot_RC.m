% Use hourly presence data to generate diel plots with night shaded and
% lunar illumination represented.
% Expects all inputs in UTC; times will be adjusted to local for plotting
% Adapted from MAZ on 9/15/2021

clearvars
UTCOffset = 0;
presDir = 'I:\HourlyCT_Totals\minClicks50'; % directory containing hourly presence files
matchStr = '_HourlyTotals_Prob0_RL120_numClicks50.mat';
lumDir = 'I:\IlluminationFiles'; % directory containing lunar illumination and night files
outDir = 'I:\Diel Plots'; % directory to save plots

%%

if ~isdir(outDir)
    mkdir(outDir)
end

presFileList = dir(fullfile(presDir,'*.mat'));

for ia = 1:size(presFileList,1)
    
    load(fullfile(presDir,presFileList(ia).name))
    load(fullfile(lumDir,strrep(presFileList(ia).name,matchStr,'_Illum.mat')));
    EffortSpan = [min(hourlyTots(:,1)),max(hourlyTots(:,1))];
    
    for ib = 1:size(spNameList,1)
        CT = spNameList{ib,1};
        siteName = strrep(presFileList(ia).name,matchStr,'');
        siteName = strrep(siteName,'_','\_');
        
        CTdir = fullfile(outDir,['\' CT '\minClicks50\SolidBars']);
        if ~isdir(CTdir)
            mkdir(CTdir)
        end
        
        % Get start/end times of hourly bins with presence
%                 CTind = hourlyTots(:,ib+1)>0;
%                 thisCT = hourlyTots(CTind,1);
%                 thisCT(:,2) = thisCT(:,1) + datenum([0 0 0 0 59 59]) - (.001 / (24*3600));  % 1 ms in days;
        
        % Use number of 5-min bins in each hour to indicate confidence in
        % encounter; scale confidences to [0.5 1] so they can be used as
        % patch transparency, and will be visible even when confidence is low
        %         nBins = hourlyTots(CTind,ib+1)/12;
        %         nBins_scaled = (((nBins-0.0833)/(1-0.0833))*(1-0.2))+0.2;
        %         thisCT(:,3) = nBins_scaled;
        
        
        % Get start/end times of 5-min bins with presence
        thisCT = labeledBins{1,ib};
        thisCT = sortrows(thisCT);
        thisCT(:,2) = thisCT(:,2)-(.001 / (24*3600));
        
        if ~isempty(thisCT)
            figure(99), clf
            % add shading during nighttime hours
            [nightH,~,~] = visPresence(night, 'Color', 'black', ...
                'LineStyle', 'none', 'Transparency', .15, 'UTCOffset',UTCOffset,...
                'Resolution_m', 1, 'DateRange', EffortSpan, 'DateTickInterval',30);
            
            % add lunar illumination data
            lunarH = visLunarIllumination(illum,'UTCOffset',UTCOffset);
            
            % add species presence data with bar transparency
            %             [BarH, ~, ~] = visPresence(thisCT(:,1:2), 'Color','blue',...
            %                 'UTCOffset',UTCOffset,'Resolution_m',60, 'DateRange',EffortSpan,...
            %                 'Transparency',thisCT(:,3),'DateTickInterval',30,'Title',...
            %                 ['Presence of ',CT,' at ',siteName]);
            
            % add species presence data with solid bars
            [BarH, ~, ~] = visPresence(thisCT(:,1:2), 'Color','blue',...
                'UTCOffset',UTCOffset,'Resolution_m',6, 'DateRange',EffortSpan,...
                'DateTickInterval',30,'Title',['Presence of ',CT,' at ',siteName]);
            
            %save plot
            saveName = strrep(presFileList(ia).name,matchStr,['_' CT]);
            saveas(figure(99),fullfile(CTdir,saveName),'tiff');
            %         print('-painters','-depsc',fullfile(mapDir,savename));
        end
    end
end
