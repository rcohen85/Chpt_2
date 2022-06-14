% Use hourly presence data to generate diel plots with night shaded and
% lunar illumination represented.
% Expects all inputs in UTC; times will be adjusted to local for plotting
% Adapted from MAZ on 9/15/2021

% clearvars
% UTCOffset = 0;
% presDir = 'I:\HourlyCT_Totals\minClicks50'; % directory containing hourly presence files
% matchStr = '_HourlyTotals_Prob0_RL120_numClicks50.mat';
% lumDir = 'I:\IlluminationFiles'; % directory containing lunar illumination and night files
% outDir = 'I:\Diel Plots'; % directory to save plots
% 
% %% From un-corrected hourlyTots files
% 
% if ~isdir(outDir)
%     mkdir(outDir)
% end
% 
% presFileList = dir(fullfile(presDir,'*.mat'));
% 
% for ia = 1:size(presFileList,1)
%     
%     load(fullfile(presDir,presFileList(ia).name))
%     load(fullfile(lumDir,strrep(presFileList(ia).name,matchStr,'_Illum.mat')));
%     EffortSpan = [min(hourlyTots(:,1)),max(hourlyTots(:,1))];
%     
%     for ib = 1:size(spNameList,1)
%         CT = spNameList{ib,1};
%         siteName = strrep(presFileList(ia).name,matchStr,'');
%         siteName = strrep(siteName,'_','\_');
%         
%         CTdir = fullfile(outDir,['\' CT '\minClicks50\SolidBars']);
%         if ~isdir(CTdir)
%             mkdir(CTdir)
%         end
%         
%         % Get start/end times of hourly bins with presence
% %                 CTind = hourlyTots(:,ib+1)>0;
% %                 thisCT = hourlyTots(CTind,1);
% %                 thisCT(:,2) = thisCT(:,1) + datenum([0 0 0 0 59 59]) - (.001 / (24*3600));  % 1 ms in days;
%         
%         % Use number of 5-min bins in each hour to indicate confidence in
%         % encounter; scale confidences to [0.5 1] so they can be used as
%         % patch transparency, and will be visible even when confidence is low
%         %         nBins = hourlyTots(CTind,ib+1)/12;
%         %         nBins_scaled = (((nBins-0.0833)/(1-0.0833))*(1-0.2))+0.2;
%         %         thisCT(:,3) = nBins_scaled;
%         
%         
%         % Get start/end times of 5-min bins with presence
%         thisCT = labeledBins{1,ib};
%         thisCT = sortrows(thisCT);
%         thisCT(:,2) = thisCT(:,2)-(.001 / (24*3600));
%         
%         if ~isempty(thisCT)
%             figure(99), clf
%             % add shading during nighttime hours
%             [nightH,~,~] = visPresence(night, 'Color', 'black', ...
%                 'LineStyle', 'none', 'Transparency', .15, 'UTCOffset',UTCOffset,...
%                 'Resolution_m', 1, 'DateRange', EffortSpan, 'DateTickInterval',30);
%             
%             % add lunar illumination data
%             lunarH = visLunarIllumination(illum,'UTCOffset',UTCOffset);
%             
%             % add species presence data with bar transparency
%             %             [BarH, ~, ~] = visPresence(thisCT(:,1:2), 'Color','blue',...
%             %                 'UTCOffset',UTCOffset,'Resolution_m',60, 'DateRange',EffortSpan,...
%             %                 'Transparency',thisCT(:,3),'DateTickInterval',30,'Title',...
%             %                 ['Presence of ',CT,' at ',siteName]);
%             
%             % add species presence data with solid bars
%             [BarH, ~, ~] = visPresence(thisCT(:,1:2), 'Color','blue',...
%                 'UTCOffset',UTCOffset,'Resolution_m',6, 'DateRange',EffortSpan,...
%                 'DateTickInterval',30,'Title',['Presence of ',CT,' at ',siteName]);
%             
%             %save plot
%             saveName = strrep(presFileList(ia).name,matchStr,['_' CT]);
%             saveas(figure(99),fullfile(CTdir,saveName),'tiff');
%             %         print('-painters','-depsc',fullfile(mapDir,savename));
%         end
%     end
% end

%% From corrected 5minBin Timeseries

TSdir = 'J:\Chpt_2\TimeSeries_ScaledByEffortError';
lumDir = 'J:\Chpt_2\IlluminationFiles'; % directory containing lunar illumination and night files
outDir = 'J:\Chpt_2\Diel Plots'; % directory to save plots
goodIdx = [1,2,4,8,11,13:19];
stDate = datenum('2016-05-01');
endDate = datenum('2019-04-30 23:59:59');
sites = {'WAT_HZ','WAT_OC','WAT_NC','WAT_BC','WAT_WC','NFC','HAT',...
    'WAT_GS','WAT_BP','WAT_BS','JAX'};
HARPs = {[41.0618333 66.35158]; % WAT_HZ  
    [40.2633167 67.98623]; % WAT_OC       
    [39.8323833 69.9821]; % WAT_NC
    [39.19105 72.2287]; % WAT_BC      
    [38.37415 73.37068]; % WAT_WC      
    [37.1665167 74.4666]; % NFC       
    [35.3018333 74.87895]; % HAT       
    [33.6656333 76.00138]; % WAT_GS       
    [32.1060333 77.09432]; % WAT_BP      
    [30.5837833 77.39072]; % WAT_BS       
    [30.1518333 79.77022]}; % JAX_D
UTCOffset = -18;


TSfiles = dir(fullfile(TSdir,'*_5minBin.csv'));
effFiles = dir(fullfile(TSdir,'*_5minBin_Effort.csv'));
lumFiles = dir(fullfile(lumDir,'*_Illum.mat'));
fullDateVec = stDate:datenum([0 0 0 0 5 0]):endDate;
% 
% % Tethys expects longitudes in [0 360], not [-180 180] or 180W to 180E
% for i = 1:size(HARPs,1)
%     HARPs{i,1}(:,2) = 360 - HARPs{i,1}(:,2);
% end

for i = goodIdx
    
    thisCT = readtable(fullfile(TSdir,TSfiles(i).name));
    CTname = erase(TSfiles(i).name,'_5minBin.csv');
    if strfind(CTname,'Atl')
        CTname = 'Gervais';
    end
    
    if any(i==[11 16:19])
        clickThresh = 50;
    else
        clickThresh = 20;
    end
    
    for j = 1:size(sites,2)
        
        presInd = table2array(thisCT(:,j+1))>=clickThresh;
        
        if any(presInd) % if there is any presence exceeding min clicks thresh
            
            % load lunar illumination & night data
            lumMatch = reshape(strfind({lumFiles.name},sites{j}),size(lumFiles));
            whichLum = cellfun(@(x) ~isempty(x),lumMatch);
            load(fullfile(lumDir,lumFiles(whichLum).name));
            
            % load effort data
            effmatch = reshape(strfind({effFiles.name},sites(j)),size(effFiles));
            whichEff = cellfun(@(x) ~isempty(x),effmatch);
            effort = readtable(fullfile(TSdir,effFiles(whichEff).name));
            
            % fit effort into continuous time series (no gaps between
            % deployments)
            effBins = datenum(table2array(effort(:,1)));
            effProp = table2array(effort(:,2));
            [Lia Lib] = ismembertol(effBins,fullDateVec,1e-9,'DataScale',1);
            effProp(Lia==0) = [];
            Lia(Lia==0)=[]; Lib(Lib==0)=[];
            fullEffVec = fullDateVec';
            fullEffVec(:,2) = 0;
            fullEffVec(Lib,2) = effProp(Lia);
            
            % identify gaps in effort
            offEff = find(fullEffVec(:,2)==0);
            jumps = find(diff(offEff)~=1);
            EffortGaps = datenum(fullEffVec(offEff(1),1));
            for e = 1:size(jumps,1)
                EffortGaps(e,2) = fullEffVec(offEff(jumps(e),1));
                EffortGaps(e+1,1) = fullEffVec(offEff(jumps(e)+1,1));
            end
            EffortGaps(end,2) = fullEffVec(offEff(end));

            
            % get presence which exceeds min clicks threshold
            thisSite = datenum(thisCT.Bin(presInd));
            thisSite(:,2) = thisSite(:,1)+datenum([0 0 0 0 4 59]);
            
            siteName = strrep(sites{j},'_','\_');
            
%             queries = dbInit('Server','breach.ucsd.edu','Port',9779);          
%             % get lunar illumination data
%             dep.illum = dbGetLunarIllumination(queries, HARPs{j,1},HARPs{j,1},EffortSpan(1,1),EffortSpan(end,2), interval, 'getDaylight', false);
%             
%             % get night duration data
%             dep.night = dbDiel(queries,HARPs(j,1),HARPs(j,2),EffortSpan(1,1),EffortSpan(end,2));
%             
%             illum = [illum;dep.illum];night = [night;dep.night];
            
            figure(99), clf
            % add shading during nighttime hours
            [nightH,~,~] = visPresence(night, 'Color', 'black', ...
                'LineStyle', 'none', 'Transparency', .15, 'UTCOffset',UTCOffset,...
                'Resolution_m', 1, 'DateRange', [stDate endDate], 'DateTickInterval',90);
            
            % add lunar illumination data
            lunarH = visLunarIllumination(illum,'UTCOffset',UTCOffset);
            
            % add shading during off-effort periods
            [effH,~,~] = visPresence(EffortGaps, 'Color', 'purple', ...
                'LineStyle', 'none', 'Transparency', .15, 'UTCOffset',UTCOffset,...
                'Resolution_m', 1, 'DateRange', [stDate endDate], 'DateTickInterval',90);
            
            % add species presence data with solid bars
            [BarH, ~, ~] = visPresence(thisSite(:,1:2), 'Color','blue',...
                'UTCOffset',UTCOffset,'Resolution_m',5, 'DateRange',[stDate endDate],...
                'DateTickInterval',90,'Title',['Presence of ',CTname,' at ',siteName]);
            
            %save plot
            saveName = [CTname,'/minClicks50/',CTname,'_at_',sites{j},'_combined'];
            saveas(figure(99),fullfile(outDir,saveName),'png');
        end
    end
    
end


