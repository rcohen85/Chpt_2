% Plot seasonal presence per species across multiple deployments as bar
% charts of weekly hours presence with classifier error shown by error bars
clearvars
inDir = 'I:\DailyCT_Totals\minClicks50'; % directory containing dailyTots files
TSdir = 'I:\TimeSeries';
plotDir = 'I:\Timeseries_Plots';
errDir = 'H:\ErrorEval';
siteAbbrevs = {'WAT_HZ','WAT_OC','WAT_NC','WAT_BC','WAT_WC','NFC','HAT',...
    'WAT_GS','WAT_BP','WAT_BS','JAX'}';
dateStart = datenum('2016-05-01','yyyy-mm-dd');
dateEnd = datenum('2019-04-30','yyyy-mm-dd');
spNameList = {'Blainville','Boats','UD36','UD26','UD28','UD19','UD47','UD38',...
    'Cuvier','Gervais','GoM_Gervais','HFA','Kogia','MFA','MultiFreqSonar',...
    'Risso','SnapShrimp','Sowerby','Sperm Whale','True','AtlGervais+GomGervais'}';
% Can't currently use these to filter the data
% RLThresh = 120;
% numClicksThresh = 50;
% probThresh = 0;

%% Compile daily presence across deployments and create error vectors

fileList = dir(fullfile(inDir,'*.mat'));
load(fullfile(errDir,'Error_Summary.mat'),'CTs','site','siteErr','minPPRL','minNumClicks');

dailyPresTS = cell(size(siteAbbrevs,1),21);
dailyErrTS = cell(size(siteAbbrevs,1),21);

for ia = 1:size(fileList,1)
    
    load(fullfile(inDir,fileList(ia).name),'binFeatures','dailyTots',...
        'labeledBins','RLThresh','numClicksThresh');
    thisSite = strrep(fileList(ia).name,'_DailyTotals_Prob0_RL120_numClicks50.mat','');
    if ~contains(thisSite,'WAT')
        thisSiteAbbrev = thisSite(1:3);
    else
        thisSiteAbbrev = thisSite(1:6);
    end
    
    q = find(strcmp(thisSiteAbbrev,siteAbbrevs));
    r = find(strcmp(thisSite,site));    
    RLmatch = find(minPPRL==RLThresh);
    NumMatch = find(minNumClicks==numClicksThresh);
    
    for iCT = 1:size(spNameList,1)
        
        thisCTpres = dailyTots(:,[1,iCT+1]); % get time series for this CT
        if ~isempty(siteErr{r,iCT}) % get classifier error rate for this CT at given thresholds
            thisCTerr = repmat(siteErr{r,iCT}(NumMatch,RLmatch),size(thisCTpres,1),1);
        else
            thisCTerr = NaN(size(thisCTpres,1),1);
        end
        
        dailyPresTS{q,iCT} = [dailyPresTS{q,iCT};thisCTpres];
        dailyPresTS{q,iCT} = sortrows(dailyPresTS{q,iCT});
        dailyErrTS{q,iCT} = [dailyErrTS{q,iCT};thisCTerr];
    end
    
end

save(fullfile(TSdir,'DailyPresence'),'dailyPresTS','dailyErrTS','siteAbbrevs','spNameList','-v7.3');

%% Calculate weekly presence, average weekly error, and identify no-effort periods
% scale bars on either side of gaps by % effort in that week
weeklyPresTS = cell(size(siteAbbrevs,1),21);
weeklyErrTS = cell(size(siteAbbrevs,1),21);
effortGaps = cell(size(siteAbbrevs,1),1);
weekvec = (dateStart:datenum([0 0 7 0 0 0]):dateEnd+1-(.001/(24*3600)))';

for ib = 1:size(dailyPresTS,1)
    
    % Find gaps in effort
    gaps = diff(dailyPresTS{ib,1}(:,1));
    gapIdx = find(gaps>1);
    for iG = 1:size(gapIdx,1)
        thisGap = [dailyPresTS{ib,1}(gapIdx(iG),1)+1,dailyPresTS{ib,1}(gapIdx(iG)+1,1)-1];
       effortGaps{ib,1} = [effortGaps{ib,1};thisGap];
    end
    
for iCT = 1:size(dailyPresTS,2)
    thisCTTS = dailyPresTS{ib,iCT};
    thisCTerr = dailyErrTS{ib,iCT};
    [N,~,bin] = histcounts(thisCTTS(:,1),weekvec); % sort bins into weeks of the deployment
    
    q = bin==0; % Remove days falling outside date range of interest
    bin(q) = [];
    thisCTTS(q,:) = [];
    thisCTerr(q,:) = [];
    
%     weeklyPres = accumarray(bin,thisCTTS(:,2));
%     weeklyPres = weeklyPres./0.0833 % convert to # 5-min bins with presence
        
    % sum presence and average error in each week (error rate may change when a new deployment begins)
    % need to use monotonically increasing grouping variable, messes up indexing a bit
    [g ~] = grp2idx(bin);
    wpCondensed = splitapply(@sum,thisCTTS(:,2),g);
    weeklyPres = zeros(size(weekvec,1)-1,1);
    weeklyPres(unique(bin)) = wpCondensed;
    meanErr = splitapply(@mean,thisCTerr,g); 
    weekErr = zeros(size(weeklyPres,1),1);
    weekErr(unique(bin)) = meanErr;
    
    weeklyPresTS{ib,iCT} = [weekvec(1:end-1),weeklyPres];
    weeklyErrTS{ib,iCT} = weekErr;
    
end
end

save(fullfile(TSdir,'WeeklyPresence'),'weeklyPresTS','weeklyErrTS',...
    'effortGaps','weekvec','siteAbbrevs','spNameList','-v7.3');

%% Plot weekly presence across deployments

for ic = 1:size(weeklyPresTS,1)
    
    siteTitle = strrep(siteAbbrevs{ic},'_','\_');
    
    for iCT = 1:size(weeklyPresTS,2)
        
        missErr = 0;
        
        if sum(weeklyPresTS{ic,iCT}(:,2))>0
            CTdir = fullfile(plotDir,spNameList{iCT});
            if ~isdir(CTdir)
                mkdir(CTdir)
            end
            
            thisCTpres = weeklyPresTS{ic,iCT}(:,2);
            thisCTerr = weeklyErrTS{ic,iCT};
            if sum(find(isnan(thisCTerr)))>0
                thisCTerr(isnan(thisCTerr)) = 0;
                missErr = 1;
            end
            adjustedPres = thisCTpres.*(1-thisCTerr);
            ymax = max(1,max(weeklyPresTS{ic,iCT}(:,2))*1.2);
            errLow = [];
            errHigh = thisCTpres-adjustedPres;
            
            figure(999), clf
            hold on
            for iG = 1:size(effortGaps{ic,1},1)
                thisGap = effortGaps{ic,1}(iG,:);
               patch([thisGap(1); thisGap(2); thisGap(2); thisGap(1)], ...
                [0; 0; ymax; ymax], 'k', ...
                'LineStyle', 'none', 'FaceAlpha', 0.075); 
            end
            bar(weeklyPresTS{ic,iCT}(:,1),adjustedPres,'FaceColor',[0 128 255]/255);
            er = errorbar(weeklyPresTS{ic,iCT}(:,1),adjustedPres,errLow,errHigh,'LineStyle','none','Color','k');
            ylim([0 ymax]);
            xlim([dateStart dateEnd]); 
            datetick('x',12,'keeplimits');
            ylabel('Hours of Presence');
            if missErr
                text(weeklyPresTS{ic,iCT}(5,1),ymax*0.9,'Missing error values!','FontSize',12);
            end
            title(['Presence of ' spNameList{iCT} ' at ' siteTitle],'FontSize',14);
            hold off
            
            saveName = [siteAbbrevs{ic} '_' spNameList{iCT}];
            saveas(figure(999),fullfile(CTdir,saveName),'tiff');
            print('-painters','-depsc',fullfile(CTdir,saveName));
%             x = input('Enter to continue');
        end
    end
end




