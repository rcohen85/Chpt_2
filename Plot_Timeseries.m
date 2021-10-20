% Plot seasonal presence per species across multiple deployments as bar
% charts of weekly hours presence with classifier error shown by error bars
clearvars
inDir = 'I:\DailyCT_Totals\minClicks50'; % directory containing dailyTots files
TSdir = 'I:\TimeSeries';
plotDir = 'I:\Timeseries_Plots';
errDir = 'I:\ErrorEval';
dataDates = 'F:\Data\AtlDataDates.csv';
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
Dates = table2cell(readtable(dataDates));
Dates(:,4) = cellfun(@(x) datenum(x),Dates(:,4),'UniformOutput',0);
Dates(:,7) = cellfun(@(x) datenum(x),Dates(:,7),'UniformOutput',0);

dailyPresTS = cell(size(siteAbbrevs,1),21);
dailyErrTS = cell(size(siteAbbrevs,1),21);
dailyEffortTS = cell(size(siteAbbrevs,1),1);

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
    fullDates = [];
    effortFrac = [];
    
    if contains(thisSite,'HAT_B_01') || contains(thisSite,'HAT_B_04')
        dep1 = thisSite(1:8);
        dep2 = strrep(dep1,dep1(end),thisSite(end));
        t = find(contains(Dates(:,1),dep1)|contains(Dates(:,1),dep2));
        for ib = 1:size(t,1)
            depDates = (floor(Dates{t(ib),4}):1:floor(Dates{t(ib),7}))';
            depEffortFrac = ones(size(depDates,1),1);
            depEffortFrac(1) = 1-(Dates{t(ib),4}-floor(Dates{t(ib),4}));
            depEffortFrac(end) = Dates{t(ib),7}-floor(Dates{t(ib),7});
            fullDates = [fullDates;depDates];
            effortFrac = [effortFrac;depEffortFrac];
        end
        dailyEffortTS{q,1} = [dailyEffortTS{q,1};[fullDates,effortFrac]];
    else
        t = find(strcmp(thisSite,Dates(:,1)));
        fullDates = (floor(Dates{t,4}):1:floor(Dates{t,7}))';
        effortFrac = ones(size(fullDates,1),1);
        effortFrac(1) = 1-(Dates{t,4}-floor(Dates{t,4}));
        effortFrac(end) = Dates{t,7}-floor(Dates{t,7});
        dailyEffortTS{q,1} = [dailyEffortTS{q,1};[fullDates,effortFrac]];
    end
    
    % find days outside date range of interest
    badDates = find(dailyTots(:,1)<dateStart | dailyTots(:,1)>dateEnd); 
    
    for iCT = 1:size(spNameList,1)
        
        thisCT = dailyTots(:,[1,iCT+1]); % get time series for this CT
        thisCT(badDates,:) = []; % remove days outside date range of interest
        [Lia Locb] = ismember(thisCT(:,1),fullDates); % find where these days fit into continuous TS
        if any(Locb==0) % occasionally getting day bins outside of supposed deployment dates
            Locb(Locb==0) = []; % don't count those bins
        end
        thisCTpres = fullDates;
        thisCTpres(:,2) = NaN;
        thisCTpres(Locb,2) = thisCT(Lia,2);
        
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
 % find repeated dates, for when a new deployment began before the previous 
 % one stopped recording; sum presence and effort and average error on repeated dates
for io = 1:size(dailyEffortTS,1)
    
    overlap = find(diff(dailyEffortTS{io,1}(:,1))==0); 
    if ~isempty(overlap)
        for ic = 1:size(overlap,1)
            dailyPresTS{io,1}(overlap(ic),2) = dailyPresTS{io,1}(overlap(ic),2) + dailyPresTS{io,1}(overlap(ic)+1,2);
            dailyEffortTS{io,1}(overlap(ic),2) = dailyEffortTS{io,1}(overlap(ic),2) + dailyEffortTS{io,1}(overlap(ic)+1,2);
            if ~isnan(dailyErrTS{io,1}(overlap(ic),1))|~isnan(dailyErrTS{io,1}(overlap(ic)+1,1))
                dailyErrTS{io,1}(overlap(ic),2) = mean((dailyErrTS{io,1}(overlap(ic),1)*dailyEffortTS{io,1}(overlap(ic),2)),(dailyErrTS{io,1}(overlap(ic)+1,1)*dailyEffortTS{io,1}(overlap(ic)+1,2)),'omitnan');
            end
        end
        % remove repeated dates
        dailyEffortTS{io,1}(overlap(ic)+1,:) = [];
        for iCT = 1:size(dailyPresTS,2)
            dailyPresTS{io,iCT}(overlap(ic)+1,:) = [];
            dailyErrTS{io,iCT}(overlap(ic)+1,:) = [];
        end
    end
    
end

save(fullfile(TSdir,'DailyPresence'),'dailyPresTS','dailyErrTS','dailyEffortTS','siteAbbrevs','spNameList','-v7.3');

%% Calculate weekly presence, average weekly error, and identify no-effort periods
% scale bars on either side of gaps by % effort in that week
weeklyPresTS = cell(size(siteAbbrevs,1),21);
weeklyErrTS = cell(size(siteAbbrevs,1),21);
weeklyEffortTS = cell(size(siteAbbrevs,1),1);
weekvec = (dateStart:datenum([0 0 7 0 0 0]):dateEnd)';
weekvec(end) = weekvec(end)-(.001/(24*3600));

for ib = 1:size(dailyPresTS,1)
    
    % Calculate percent effort in each week from daily effort
    siteDays = dailyEffortTS{ib,1}(:,1);
    siteEffort = dailyEffortTS{ib,1}(:,2);
    [~,~,effBin] = histcounts(siteDays,weekvec); % divy days of effort into week bins
    z = effBin==0; % Remove days falling outside date range of interest
    effBin(z) = [];
    siteDays(z) = [];
    siteEffort(z) = [];
    [effG,~] = grp2idx(effBin);
    PropEffort = splitapply(@(x) sum(x)/7, siteEffort,effG); % sum days of effort in each week and divide by 7 days (full effort)
    weeklyPropEffort = zeros(size(weekvec,1)-1,1);
    weeklyPropEffort(unique(effBin)) = PropEffort; % sort back into appropriate weeks
    weeklyEffortTS{ib,1} = weeklyPropEffort;
    
   for iCT = 1:size(dailyPresTS,2)
        thisCTTS = dailyPresTS{ib,iCT};
        thisCTerr = dailyErrTS{ib,iCT};
        [N,~,bin] = histcounts(thisCTTS(:,1),weekvec); % sort days into weeks of the deployment
        
        q = bin==0; % Remove days falling outside date range of interest
        bin(q) = [];
        thisCTTS(q,:) = [];
        thisCTerr(q,:) = [];
                
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
    'weeklyEffortTS','weekvec','siteAbbrevs','spNameList','-v7.3');

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
            
            % Adjust weekly presence by FPR
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
            
            partialEffWeeks = find(weeklyEffortTS{ic,1}~=0 & weeklyEffortTS{ic,1}~=1);
            noEffWeeks = find(weeklyEffortTS{ic,1}==0);
            
            % Adjust weekly presence by effort
            adjustedPres(noEffWeeks) = NaN;
            adjustedPres = adjustedPres.*(1./weeklyEffortTS{ic,1});
            partialEffWeeks(weeklyEffortTS{ic,1}(partialEffWeeks)>1) = [];
            
            figure(999), clf
            hold on
            for iG = 1:size(noEffWeeks,1)
                thisWeek = weekvec(noEffWeeks(iG));
                patch([thisWeek; thisWeek+7-(0.001/(60*60*24)); thisWeek+7-(0.001/(60*60*24)); thisWeek], ...
                    [0; 0; ymax; ymax], 'k', ...
                    'LineStyle', 'none', 'FaceAlpha', 0.075);
            end
            bar(weeklyPresTS{ic,iCT}(:,1)+3.5,adjustedPres,'FaceColor',[0 128 255]/255);
            er = errorbar(weeklyPresTS{ic,iCT}(:,1)+3.5,adjustedPres,errLow,errHigh,'LineStyle','none','Color','k');
            ylim([0 ymax]);
            xlim([dateStart dateEnd]);
            datetick('x',12,'keeplimits');
            ylabel('Hours of Presence');
            if missErr
                text(weeklyPresTS{ic,iCT}(5,1),ymax*0.9,'Missing error values!','FontSize',12);
            end
            yyaxis right
            plot(weeklyPresTS{ic,iCT}(partialEffWeeks,1)+3.5,weeklyEffortTS{ic,1}(partialEffWeeks),'or')
            ylim([0 1.1])
            ylabel('Effort');
            title(['Presence of ' spNameList{iCT} ' at ' siteTitle],'FontSize',14);
            hold off
            
            saveName = [siteAbbrevs{ic} '_' spNameList{iCT}];
            saveas(figure(999),fullfile(CTdir,saveName),'tiff');
            print('-painters','-depsc',fullfile(CTdir,saveName));
            %             x = input('Enter to continue');
        end
    end
end




