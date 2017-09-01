function WriteKey($File, $Key)
{
    ECHO $Key >> $File;
    ECHO '"Acceleration.Level"=dword:00000000' >> $File;
    ECHO "" >> $File;
}

function Generate($File, $ControlSet)
{
    $Item = Get-Item -Path "HKLM:\HARDWARE\DEVICEMAP\VIDEO";
    $ValueNames = $Item.GetValueNames();
    foreach($ValueName in $ValueNames)
    {
        if($ValueName.StartsWith("\Device\Video"))
        {
            $Value = $Item.GetValue($ValueName);
            if($Value.Length -gt 43)
            {
                $Guid = $Value.SubString($Value.Length - 43, 38);
                $ObjectNumber = $Value.SubString($Value.Length - 4);
                try
                {
                    [System.Guid]::Parse($Guid);
                    [System.Int32]::Parse($ObjectNumber);
                }
                catch
                {
                    continue;
                }
                $Path = "HKLM:\SYSTEM\" + $ControlSet + "\Control\Video\" + $Guid + "\Video";
                $Service = (Get-Item -Path $Path).GetValue("Service");
                $Path = "HKLM:\SYSTEM\" + $ControlSet + "\Services\" + $Service;
                $ChildItems = Get-ChildItem -Path $Path;
                foreach($ChildItem in $ChildItems)
                {
                    if($ChildItem.PSChildName.StartsWith("Device"))
                    {
                        $Key = "[" + $ChildItem.Name + "]";
                        WriteKey $File $Key;
                    }
                }
                $Key = "[HKEY_LOCAL_MACHINE\SYSTEM\" + $ControlSet + "\Control\Video\" + $Guid + "\" + $ObjectNumber + "]";
                WriteKey $File $Key;
                $Key = "[HKEY_LOCAL_MACHINE\SYSTEM\" + $ControlSet + "\Control\Video\" + $Guid + "\" + $ObjectNumber + "\Settings]";
                WriteKey $File $Key;
            }
        }
    }
    $VideoControllers = Get-WmiObject -Class Win32_VideoController;
    foreach($VideoController in $VideoControllers)
    {
        $PnPEntities = Get-WmiObject -Class Win32_PnPEntity;
        foreach($PnPEntity in $PnPEntities)
        {
            if($PnPEntity.PNPDeviceID -eq $VideoController.PNPDeviceID)
            {
                $Path = "HKLM:\SYSTEM\" + $ControlSet + "\Control\Class\" + $PnPEntity.ClassGuid;
                $ChildItems = Get-ChildItem -Path $Path;
                foreach($ChildItem in $ChildItems)
                {
                    try
                    {
                        [System.Int32]::Parse($ChildItem.PSChildName);
                    }
                    catch
                    {
                        continue;
                    }
                    $Key = "[" + $ChildItem.Name + "]";
                    WriteKey $File $Key;
                    $Key = "[" + $ChildItem.Name + "\Settings]";
                    WriteKey $File $Key;
                }
            }
        }
    }
}

$File = "Acceleration.Level.reg";
New-Item $File -Type File -Force;
ECHO "Windows Registry Editor Version 5.00" > $File;
ECHO "" >> $File;
Generate $File "ControlSet001";
Generate $File "ControlSet002";
Generate $File "CurrentControlSet";
TYPE $File;
regedit.exe /s $File;