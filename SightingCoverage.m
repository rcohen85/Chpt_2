% Plot geographic & temporal coverage of sighting data & sighting effort

clearvars

sp = 'Dd';
comName = {'Short-beaked Common Dolphin'};
sightDir = 'J:\OBIS_Vis_data';
effortDir = 'J:\OBIS_Vis_data\DataSets\Effort';
mapSaveDir = 'J:\OBIS_Vis_data\Seasonal_Maps';

% Date range
startDate = datenum('01-05-2016 00:00:00','dd-mm-yyyy HH:MM:SS');
endDate = datenum('30-04-2019 23:59:59','dd-mm-yyyy HH:MM:SS');

% Set lat/long limits to plot only your region of interest
lat_lims = [30 42];

% HARP latitudes
HARPs = [41.06165;  % WAT_HZ
    40.22999;       % WAT_OC
    39.83295;       % WAT_NC
    39.19192;       % WAT_BC
    38.37337;       % WAT_WC
    37.16452;       % NFC
    35.30183;       % HAT
    33.66992;        % WAT_GS
    32.10527;       % WAT_BP
    30.58295;       % WAT_BS
    30.27818];      % JAX_D

%% Load sighting data, find data points missing datetime info

a = readtable(fullfile(sightDir,sp,'Datapoints.csv'));
a = sortrows(a,20);
if iscell(a.date_time)
    miss_ind = find(cellfun(@isempty,a.date_time));
else
    miss_ind = find(isempty(a.date_time));
end
tot = 1:length(a.date_time);
keep_ind = setdiff(tot,miss_ind);


% Pull observation datetimes, locations, group sizes, species, and obs
% platform info
if iscell(a.date_time)
    dat.obs_dnum = datenum(cell2mat(a.date_time(keep_ind)));
else
    dat.obs_dnum = datenum(a.date_time(keep_ind));
end
dat.latlon = [a.latitude(keep_ind), a.longitude(keep_ind)];
dat.comName = a.common(keep_ind);

inDateRange = find(dat.obs_dnum>=startDate & dat.obs_dnum<endDate);
inLatRange = find(dat.latlon>=lat_lims(1) & dat.latlon<lat_lims(2));
rightSpecInd = find(strcmp(comName,dat.comName));
dateLatInd = intersect(inDateRange,inLatRange);
goodSights = intersect(dateLatInd,rightSpecInd);

dat.obs_dnum = dat.obs_dnum(goodSights);
dat.latlon = dat.latlon(goodSights,:);
dat.comName = dat.comName(goodSights);


load(fullfile(effortDir,'All_Survey_Tracks.mat'));


%% Plot sightings by latitude and date, with tracklines shown by start lat+date and end lat+date
[sightLatCounts LatBins] = histcounts(dat.latlon(:,1),[lat_lims(1):1:lat_lims(2),lat_lims(2)+0.99]);

[effortLatCounts LatBins] = histcounts(lines(:,2),[lat_lims(1):1:lat_lims(2),lat_lims(2)+0.99]);

figure(9999), clf
histogram(dat.latlon(:,1),[lat_lims(1):1:lat_lims(2),lat_lims(2)+0.99]);
xlabel('Latitude');
ylabel('Counts');

figure(8888)
plot(dat.obs_dnum,dat.latlon(:,1),'.','MarkerSize',16)
datetick('x',12);
ylim([lat_lims(1) lat_lims(2)]);
xlabel('Date');
ylabel('Latitude');
title([comName, ' Sightings']);

