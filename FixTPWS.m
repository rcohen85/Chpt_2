% Fix datenum rounding error caused by change in Matlab built-in functions
% within mkTPWS_perDir

clearvars
newDir = 'H:\WAT_BP_03\new_TPWS'; % directory containing remade TPWS
oldDir = 'H:\WAT_BP_03\old_TPWS'; % directory containing original TPWS

newFileList = dir(fullfile(newDir,'*TPWS1.mat'));
oldFileList = dir(fullfile(oldDir,'*TPWS1.mat'));

if size(newFileList,1)~= size(oldFileList,1)
    fprintf('WARNING: New and old TPWS files differ in number, may not be compatible\n');
    return
end

for i = 1:size(oldFileList,1)
    oldTimes = load(fullfile(oldDir,oldFileList(i).name),'MTT');
    load(fullfile(newDir,newFileList(i).name));
    
    if size(oldTimes.MTT,1)~=size(MTT,1)
        fprintf('WARNING: Different number of clicks in old and new TPWS for file %d\n',i);
        return
    else
        Lia = ismembertol(MTT,oldTimes.MTT,1e-9,'DataScale',1);
        if sum(Lia)==size(Lia,1)
            MTT = oldTimes.MTT;
        else
            fprintf('WARNING: Click times in file %d differ by more than the allowed tolerance\n',i);
            return
        end
    end
    
    save(fullfile(newDir,newFileList(i).name),'MTT','MPP','MSP','MSN','f','-v7.3')
    sprintf('Done with file %d of %d\n',i,size(oldFileList,1));
    
end