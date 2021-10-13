%created by MAZ on 9/7/2021 to get this dang lunar plot into the correct
%format (i.e. similar to E:\dbDemo_lunarExample.jpg)
clear all
close all
clc

%read in our count data to use
site = 'Kona';
infiles = ['E:\ch2\countdata\',site];
allfiles = dir(fullfile(infiles,'*.mat'));
outfolder = ['E:\ch2\figures\prelim\',site,'_lunardiel'];
specs = {'Blainvilles','Kogia','Cuviers','FKW','RT','SFPW','Sten','Bott/MHW'};

if ~isdir(outfolder)
    mkdir(outfolder)
end

%switch lat lons depending on site
if strcmp(site,'Kona')
    load('E:\ch2\konaIllum.mat')
    %     lat = 19.5824;
    %     lon = -156.0154;
elseif strcmp(site,'Kauai')
    load('E:\ch2\kauaiIllum.mat')
    %     lat = 21.9519;
    %     lon = -159.8883;
elseif strcmp(site,'PHR')
    load('E:\ch2\phrIllum.mat')
    %     lat = 27.7310;
    %     lon = -175.5972;
end

for ia = 1:size(allfiles,1)
    figure
    load(fullfile(allfiles(ia).folder,allfiles(ia).name))
    spec = specs{ia};

    %if we're dealing with Kona, exclude deps 01-03,13-15,25
    if strcmp(site,'Kona')
        excludenums = {'01','02','03','13','14','15','25'};
              %remove bad rows if we don't want them in timeseries
        disp('Removing rows corresponding to bad deployments')
        for ie = 1:size(excludenums,2)
            rmvrows = find(contains(countdata.depsave,excludenums{ie}));
            countdata(rmvrows,:) = [];
        end
    end
    
    %split into shorter versions because otherwise too hard to see anything
    startd = min(countdata.hours);
    stopd = max(countdata.hours);
    increms = startd:datenum(2,0,0,0,0,0):stopd;
    increms = [increms,stopd]; %make sure to get real end time in there
    labinc = 0;
    
    for inc = 1:size(increms,2)-1
        curyrs = [increms(inc),increms(inc+1)];
        userows = find(countdata.hours >= curyrs(1) & countdata.hours <= curyrs(2));
        
        %if there is something recorded during those years, continue
        if ~isempty(userows)
            labinc = labinc + 1;
        uselum = find(illum(:,1) >= curyrs(1) & illum(:,1) <= curyrs(2));
        illumuse = illum(uselum,:);
        countdatause = countdata(userows,:);
        
        
        %initialize correct plot/axis
        %get hours of night using sunrise/sunset times for each detection
        %get values by day
        [uniqueday,userows] = unique(floor(countdatause.hours));
        
        sunrisevals = countdatause.sunrise(userows)+ 693960;
        sunsetvals = countdatause.sunset(userows)+ 693960;
        %because we have sunrise and sunset, not moonrise and moonset, need to wrok
        %a little differently than original. So we'll have entries for 0 to
        %sunrise, and sunset to 24 for each day
        sunrisedays = floor(sunrisevals);
        sunriseadj = [sunrisedays,sunrisevals];
        sunsetdays = floor(sunsetvals) + datenum(0,0,0,23,59,59); %take day the sunset is for, jack it up to last second of that day
        sunsetadj = [sunsetvals,sunsetdays];
        %then night will just be all of these combined and sorted
        nightog = [sunriseadj;sunsetadj];
        night = sortrows(nightog);
        %get effort span from 1st val to last val
        EffortSpan = [min(countdatause.hours),max(countdatause.hours)];
        
        %taken right from dbDemo
        [nightH,presence_d,presence_dayfrac] = visPresence(night, 'Color', 'black', ...
            'LineStyle', 'none', 'Transparency', .15, ...
            'Resolution_m', 1/60, 'DateRange', EffortSpan,'DateTickInterval'...
            ,30,'Title',['Presence of ',spec,' at ',site,'-pt',num2str(labinc)]);
        
        %add lunar illumination- moonfrac into percentages to get colors right
        % %remove illumination from hours during daylight
        % nighthrs = presence_d + presence_dayfrac;
        % userows = [];
        % for in = 1:size(nighthrs,1)
        %     currow = nighthrs(in,:);
        %     %modify last value down an hour if it's morning hours
        %     dvst = datevec(currow(1));
        %     if dvst(4) == 0
        %     currow(2) = currow(2) - datenum(0,0,0,1,0,0);
        %     end
        %
        %     %go through countdata and only use rows from those hours
        %     userowstemp = find(currow(1)<= countdata.hours & currow(2)>= countdata.hours);
        %     userows = [userows;userowstemp];
        % end
        %
        % usehours = countdata.hours(userows);
        % uselum = countdata.moonfrac(userows).*100;
        % illum = [usehours,uselum];
        
        %%%%%%%%%%%%%%%%%%%%%loading this from previous files, so dont need to redo here
        %%lunarillum- tethys method. Idk why but I can't get the above to work, so
        %%we can just query tethys for moon illumination. Don't need to change in
        %%csv files because values are the same as found in r (which is good!)
        %     queries = dbInit('Server','breach.ucsd.edu','Port',9779);
        %     interval = 30;
        %     illum = dbGetLunarIllumination(queries, ...
        %         lat,lon, ...
        %         EffortSpan(1), EffortSpan(2), interval, 'getDaylight', false,'UTCOffset',-10);
        
        lunarH = visLunarIllumination(illumuse,'resolution_m',30);
        
        %add presence data
        countdatatrunc = countdatause(find(countdatause.counts > 0),:); %just plot for a short version, faster
        dvx = datevec(countdatatrunc.hours);
        xvals = dvx(:,4)./24; %have to set as values from 0-1
        yvals = floor(countdatatrunc.hours);
        
        %run through for each hour of detection
        for it = 1:size(xvals,1)
            line([xvals(it) xvals(it)+1/24],[yvals(it) yvals(it)],'Color','b','LineWidth',1.5) %plot a line!
        end
        
        xlabel('Hours (HST)')
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.05, 0.6, 0.9]);
        
        %save plot
        saven = strrep(allfiles(ia).name,'binsperhr',['lunar_diel_pt',num2str(labinc)]);
        saven2 = strrep(saven,'.mat','');
        outname = fullfile(outfolder,saven2);
        print(outname,'-dpng')
       
        end
                disp(['Done with increment ',num2str(inc)])
    end
end

disp(['Done with diel/lunar plots for ',site])
