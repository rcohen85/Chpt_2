% run_deaseason_per_dir
inputPathName = 'E:\Data\Presentations\GOMRI 2017\MP_TS';
flag2match = '*Click_All*.txt';
fList = dir(fullfile(inputPathName,flag2match));
for iF = 1:length(fList)
    Deseason(inputPathName,fList(iF).name)
end