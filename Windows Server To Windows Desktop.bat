@echo off
PATH="%SYSTEMROOT%\system32";%PATH%
pushd %~dp0
set gpfile=temp_gpfile
set currentuser=%username%
set videopsfile=Acceleration.Level.ps1
rem UAC code begin
set getadminfile=getadmin.vbs
echo Windows Server To Windows Desktop
echo =================================
echo Starting
"%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\SYSTEM" >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    goto :Admin
) else (
    if %ERRORLEVEL% EQU 2 (
        goto :PathErr
    ) else (
        goto :UAC
    )
)
:PathErr
echo.
echo Please open "%~n0%~x0" by explorer.exe
echo.
echo Press any key to explore the folder...
pause>nul
start "" "%SYSTEMROOT%\system32\explorer.exe" /select,"%~f0"
goto :END
:UAC
echo Set sh = CreateObject^("Shell.Application"^) > %getadminfile%
echo sh.ShellExecute "%~f0", "", "", "runas", 1 >> %getadminfile%
ping 127.1 -n 1 >nul
"%SYSTEMROOT%\system32\cscript.exe" %getadminfile%
goto :END
:Admin
if exist %getadminfile% ( del %getadminfile% )
cls
rem UAC code end
if "%currentuser%" == "" set currentuser=Administrator
echo Windows Server To Windows Desktop
echo =================================
::PowerShell /Command "&{Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption}"
set caption=
for /f "skip=1 delims=" %%t in ('wmic os get caption') do (
if not defined caption set caption=%%t
)
echo %caption%
echo %caption%|find /i "Windows Server">nul 2>nul
if ERRORLEVEL 1 goto :OSERR
echo Current Domain: %USERDOMAIN%
echo Current User: %currentuser%
echo.
set /p tmpInput=Maybe will restart computer. Are you ready? (Y/N):
if /i "%tmpInput%"=="y" goto :START
echo Canelled.
echo Press any key to exit...
pause>nul
goto :END
:OSERR
echo.
echo ERROR: Unsupported operating system!
echo Press any key to exit...
pause>nul
goto :END
:START
echo (1/3) Config Service
PowerShell /Command "&{Import-Module ServerManager}"
echo - [Automatic] Windows Audio
PowerShell /Command "&{Set-Service "Audiosrv" -StartupType Automatic}"
echo - [Automatic] Windows Audio Endpoint Builder
PowerShell /Command "&{Set-Service "AudioEndpointBuilder" -StartupType Automatic}"
echo - [Manual] Windows Remote Management (WS-Management)
PowerShell /Command "&{Set-Service "WinRM" -StartupType Manual}"
echo (2/3) Config Registry and GroupPolicy
echo - Enable Shutdown without logon
REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ShutdownWithoutLogon /t REG_DWORD /d 1 /f>nul
echo - Disable Shutdown reason On
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f>nul
:: echo - No Lock Screen
:: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreen" /t REG_DWORD /d 0x1 /f>nul
echo - Disable Ctrl+Alt+Del login
REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v DisableCAD /t REG_DWORD /d 1 /f>nul
echo - Disable UAC
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 0x0 /f>nul
echo - Disable DEP (Turn on DEP for essential Windows programs and services only)
bcdedit /set {current} nx OptIn>nul
::bcdedit /set {current} nx AlwaysOff>nul
echo - Disable SEHOP
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d 0x1 /f>nul
echo - Enable disk performance counters
diskperf -Y>nul
if exist %videopsfile%. (
echo - Enable Video Hardware Acceleration
PowerShell -ExecutionPolicy Unrestricted -File %videopsfile%>nul
del Acceleration.Level.reg /f /q
)
echo - Enable Audio Hardware Acceleration
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0x14 /f>nul
echo - CPU Priority for Program
REG ADD HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl /v Win32PrioritySeparation /t REG_DWORD /d 38 /f>nul
echo - Adjust Visual Effects (Manual)
SystemPropertiesPerformance.exe
::reg add HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects /v VisualFXSetting /t REG_DWORD /d 1 /f>nul
::reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects /v VisualFXSetting /t REG_DWORD /d 1 /f>nul
::reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f>nul
::reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f>nul
::reg add "HKCU\Control Panel\Desktop" /v MinAnimate /t REG_SZ /d 1 /f>nul
::reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f>nul
echo - Adjust IE Max Connection
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "MaxConnectionsPer1_0Server" /t REG_DWORD /d 10 /f>nul
echo - IE Security Policy
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f>nul
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f>nul
Rundll32 iesetup.dll, IEHardenLMSettings
Rundll32 iesetup.dll, IEHardenUser
Rundll32 iesetup.dll, IEHardenAdmin
echo - Disable TCP Auto-Tuning
netsh interface tcp set heuristics disabled>nul
echo - Change Power Scheme To High Performance
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c>nul
echo - No Autorun Server Manager
REG ADD HKLM\Software\Microsoft\ServerManager /v DoNotOpenServerManagerAtLogon /t REG_DWORD /d 1 /f>nul
echo - Disable Password complexity and Minimum password length
echo [version]>%gpfile%.inf
echo signature="$CHICAGO$">>%gpfile%.inf
echo [System Access]>>%gpfile%.inf
echo MinimumPasswordLength = 0 >>%gpfile%.inf
echo PasswordComplexity = 0 >>%gpfile%.inf
secedit /configure /db %gpfile%.sdb /cfg %gpfile%.inf /log %gpfile%.log>nul 2>nul
del %gpfile%.inf %gpfile%.sdb %gpfile%.log %gpfile%.jfm /f /q
echo - %currentuser%'s Password never expires
wmic Path Win32_UserAccount Where Name="%currentuser%" Set PasswordExpires="FALSE">nul
echo   PasswordExpires List:
wmic useraccount get Name,PasswordExpires
echo - Disable Application Experience task schedulers
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable>nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable>nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\StartupAppTask" /disable>nul 2>nul
echo - Disable Customer Experience Improvement Program task schedulers
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable>nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable>nul 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable>nul 2>nul
echo (3/3) Config Windows Feature
echo - BitLocker
echo - Direct-Play
echo - Wireless-Networking
echo - qWave
echo please wait...
PowerShell /Command "&{Install-WindowsFeature "BitLocker","Direct-Play","Wireless-Networking","qWave" -Restart}"
echo Completed!
echo Press any key to exit...
pause>nul
:END
if exist %getadminfile% ( del %getadminfile% )
popd
