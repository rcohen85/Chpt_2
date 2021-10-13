function Deseason_data(myData,savePath,outputFileName)
% deseason longterm data
% https://www.mathworks.com/help/econ/parametric-trend-estimation.html
% JAH 12/30/2016

% myData = [matlabDates,meanMeasurement,standard deviation (optional)]% a column matrix
% example: myData = [734139, 1.0, 0.6;
%                    734140, 0.7, 0.4] 
% meanMeasurement = mean density of animals, or percent of time present,
% etc., that goes with your dates 

% savePath = where you want to save figs, string, example: 'D:\myFigs'
% outputFileName = string to use for naming figs, example: 'MC_Rissos_'

% kef 9/25/2018

% clearvars
monthlyBins = 1; % set to 1 if you want to convert to monthly bins. 
% If not, we assume you are providing weekly bins.
savePlots = 1;% Set to 1 if you want to save plots


%% Begin calculations

if size(myData,2)<2
    disp('ERROR: Expecting text file with at least 2 columns. Check data and delimiter.')
    return
else
    dateVec = myData(:,1);
    meanVec = myData(:,2);
    if size(myData,2)>2
        cvVec = myData(:,3); 
    else
        cvVec = nan(size(dateVec));
    end
end

% Test to make sure that the user has supplied weekly bins if they want to
% use weekly bins for estimating seasonality. If the test fails, use monthly
% bins, because that option will re-bin the data anyway.
if mean(diff(dateVec))~= 7 && monthlyBins == 0
    fprintf(['WARNING: your data does not appear to be in weekly bins\n',...
        'Forcing use of monthly bins to handle unknown interval.\n'])
    monthlyBins = 1;
end
    
%% Identify placeholders (NaN or -1), and replace with NaN
missingDataRows = union(find(meanVec<0),find(isnan(meanVec)));
goodRows = setdiff(1:length(meanVec),missingDataRows);

% dateVec(missingDataRows) = NaN;
meanVec(missingDataRows) = NaN;
cvVec(missingDataRows) = NaN;

%% Plot initial data
figure(91);clf
plot(dateVec, meanVec,'.'); 
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[1 2 10 5])
yMax91 = get(gca,'yLim');
repY91 = repmat(yMax91(2),size(dateVec,1),1);
bar(dateVec(isnan(meanVec)),repY91(isnan(meanVec)),1,'FaceColor',[0.8,0.8,0.8],...
    'EdgeColor',[0.8,0.8,0.8])
hold on
plot(dateVec, meanVec,'.');
xlim([min(dateVec),max(dateVec)])
datetick('x','mmm ''yy','keepLimits')
xlabel('Date (month, year)','FontSize',12)
ylabel('Mean','FontSize',12)
simpleFName = strrep(strrep(outputFileName,'_','\_'),'.txt','');
title(simpleFName,'FontSize',10)
ylim([0,max(repY91)])

%% Call Theil-Sen to estimate slope of entire dataset
dataMat = [dateVec,meanVec];
[estSlope,estOffSet] = TheilSen(dataMat);
trend = estSlope * dateVec + estOffSet;
meanMinusTrend = meanVec - trend;

%% Add trend line to original plot
figure(91); hold on
plot(dateVec,trend,'-r')
hold off
set(gca,'layer','top')
legend({'Recording Gaps','Original Data', 'Trend 1: incl. season'})
if savePlots
    disp('Saving plots')
    figName91 = fullfile(savePath,[outputFileName,'_orig_timeseries']);
    saveas(91,figName91,'fig')
    print(91,'-dpng','-r600',[figName91,'.png'])
else
    disp('No plots saved.')
end
%% Make second plot with detrended timeseries
figure(92);clf
plot(dateVec,meanMinusTrend,'.')
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[2 2 10 5])
datetick('x','mmm ''yy','keepLimits')
xlabel('Date (month, year)','FontSize',12)
ylabel('Mean','FontSize',12)
title(['Detrended Timeseries: ', simpleFName],'FontSize',10)
xlim([min(dateVec),max(dateVec)])

%% Estimate seasonal component
% How many weeks of data?
if ~monthlyBins
    fprintf('Calculating seasonal trend using input bins (assumes weekly)\n')
    dateList = weeknum(dateVec);
    
else
    fprintf('Calculating seasonal trend using MONTHLY bins\n')
    % this date math is ugly because we are trying to find all of the first
    % of the months between the start and end of the data, including the
    % month that starts before the first point. Since months have
    % different numbers of days, it gets messy. Using financial toolbox
    % functions.
    startDate = datenum(datevec(eomdate(min(dateVec)))-[0,1,0,0,0,0])-1;
    endDate = eomdate(max(dateVec));
    monthStarts = unique(eomdate(startDate:15:endDate)+1)';
    % datestr(monthStarts) % <-sanity check: now we have datenums for
    % firsts of the months, including start month.
    dateList = month(monthStarts); % function for figuring out month

    % bin the input data using the monthly starts
    [binCounts, binIdx] = histc(dateVec,monthStarts);
    % compute mean for each month
    monthlyMeanVec = nan(size(monthStarts));
    for iB = 1:length(binCounts)
        monthlyMeanVec(iB) = nanmean(meanVec(binIdx==iB));
    end
     
    % calculate montly version of trend
    monthTrend = estSlope * monthStarts + estOffSet;
    meanMinusTrend = monthlyMeanVec - monthTrend;
    goodRows = find(~isnan(monthlyMeanVec));
    missingDataRows = find(isnan(monthlyMeanVec));

end
onesAndZeros = dummyvar(dateList);
% remove NaN rows. Could probably do this implicitly.
onesAndZeros(missingDataRows,:) = [];
seasonalAdjust = onesAndZeros\meanMinusTrend(goodRows);
seasonalComponent = onesAndZeros*seasonalAdjust;

%% Plot seasonal adjustment
figure(93);clf
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[3 2 5 5])
bar(seasonalAdjust)
if monthlyBins
    xlabel('Months','FontSize',12)
    xlim([0.5,12.5])
else
    xlabel('Weeks','FontSize',12)
    xlim([0.5,52.5])
end
ylabel('Seasonal adjustment','FontSize',12)
title(['Estimated seasonal trend: ', simpleFName],'FontSize',10)
if savePlots
    figName93 = fullfile(savePath,[outputFileName,'_seasonality']);
    saveas(93,figName93,'fig')
    print(93,'-dpng','-r600',[figName93,'.png'])
end

figure(930);clf
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[3 2 5 5])
bar(seasonalAdjust./mean(meanMinusTrend(goodRows)))
if monthlyBins
    xlabel('Months','FontSize',12)
    xlim([0.5,12.5])
else
    xlabel('Weeks','FontSize',12)
    xlim([0.5,52.5])
end
ylabel('Seasonal adjustment / deseasoned mean','FontSize',12)
title(['Estimated seasonal trend: ', simpleFName],'FontSize',10)
if savePlots
    figName930 = fullfile(savePath,[outputFileName,'_seasonality_norm']);
    saveas(930,figName930,'fig')
    print(930,'-dpng','-r600',[figName93,'.png'])
end
%% Plot seasonal component of timeseries
figure(94);clf
if monthlyBins
    plot(monthStarts(goodRows),seasonalComponent,'.')
else
    plot(dateVec(goodRows),seasonalComponent,'.')
end
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[4 2 10 5])
datetick('x','mmm ''yy','keepLimits')
xlabel('Date (month, year)','FontSize',12)
ylabel('Mean','FontSize',12)
title(['Seasonal component estimate: ',simpleFName], 'FontSize',10)
xlim([min(dateVec),max(dateVec)])

%% Deseason orignal data and re-estimate slope
if monthlyBins
    deseasonMean = monthlyMeanVec(goodRows) - seasonalComponent;
    deseasDataMat = [monthStarts(goodRows),deseasonMean];
else
    deseasonMean = meanVec(goodRows) - seasonalComponent;
    deseasDataMat = [dateVec(goodRows),deseasonMean];
end
[deseasEstSlope,deseasEstOffSet,confIntSlope,~] = TheilSen(deseasDataMat);
deseasTrend = deseasEstSlope * dateVec + deseasEstOffSet;
% deseas95perc = (confIntSlope'*dateVec') + repmat(confIntOffset,1,size(dateVec,1));
annualChange = deseasEstSlope*365;

%% Plot deseasoned data and slope
figure(95);clf
if monthlyBins
    plot(monthStarts(goodRows),deseasonMean,'.')
else
    plot(dateVec(goodRows),deseasonMean,'.')
end
hold on
plot(dateVec,deseasTrend','-r')
% plot(dateVec,deseas95perc','--k')
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[5 2 10 5])
datetick('x','mmm ''yy','keepLimits')
xlabel('Date (month, year)','FontSize',12)
ylabel('Mean','FontSize',12)
title(sprintf('Deseasoned data and slope estimate: %s\n Estimated rate of change: %.3f/year',...
    simpleFName,annualChange), 'FontSize',10)
legend({'Deseasoned Data', 'Trend 2: de-seasoned'})
xlim([min(dateVec),max(dateVec)])
if savePlots
    figName95 = fullfile(savePath,[outputFileName,'_deseasoned']);
    saveas(95,figName95,'fig')
    print(95,'-dpng','-r600',[figName95,'.png'])
end
%% Plot original data and slope
figure(96);clf
cvMax = max(nanmax(cvVec),0);
bar(dateVec(isnan(meanVec)),cvMax+repY91(isnan(meanVec)),...
    1,'FaceColor',[0.8,0.8,0.8],...
    'EdgeColor',[0.8,0.8,0.8])
hold on
if ~isnan(nanmax(cvVec)) % have cvs
    hE = errorbar(dateVec, meanVec,cvVec,'ok');
    hE.CapSize = 0;
    yMax = nanmax(meanVec+cvVec)*1.1;
else
    %no cvs
    plot(dateVec,meanVec,'ok');
    yMax = nanmax(meanVec)*1.1;
end
xlim([min(dateVec),max(dateVec)])
ylim([0,yMax])
set(gca,'FontSize',12)
plot(dateVec,deseasTrend,'-r')
set(gcf,'units','inches','PaperPositionMode','auto','OuterPosition',[6 2 10 5])
datetick('x','mmm ''yy','keepLimits')
set(gca,'FontSize',12)
xlabel('Date (month, year)','FontSize',14)
ylabel('Mean','FontSize',14)
legend({'Recording Gaps','Original Data', 'Trend 2: de-seasoned'})
title(sprintf('Original data and slope estimate: %s\n Estimated rate of change: %.2f%% per year',...
    simpleFName,100*annualChange./nanmean(meanVec)),'FontSize',10)
xlim([min(dateVec),max(dateVec)])
set(gca,'layer','top')
if savePlots
    figName96 = fullfile(savePath,[outputFileName,'_longTermTrend']);
    saveas(96,figName96,'fig')
    print(96,'-dpng','-r600',[figName96,'.png'])
end
confIntSlopeAnnual = confIntSlope*365;
disp(outputFileName)
fprintf('Estimated slope is %.3f /year, [5,95] confidence interval = [%.3f %.3f] \n',annualChange,confIntSlopeAnnual(1),confIntSlopeAnnual(2))
fprintf('Estimated percent change is %.3f /year, [5,95] confidence interval = [%.3f %.3f] \n',...
    100*annualChange./nanmean(meanVec),100*confIntSlopeAnnual(1)./nanmean(meanVec),100*confIntSlopeAnnual(2)./nanmean(meanVec))

