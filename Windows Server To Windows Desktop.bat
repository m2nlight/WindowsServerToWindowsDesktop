@echo off
pushd %~dp0
set gpfile=temp_gpfile
set currentuser=%username%
if "%currentuser%" == "" set currentuser=Administrator
echo Windows Server To Windows Desktop
echo =================================
PowerShell /Command "&{Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption}"
echo Current Domain: %USERDOMAIN%
echo Current User: %currentuser%
echo.
set /p tmpInput=Maybe will restart computer. Are you ready? (Y/N):
if "%tmpInput%"=="y" goto :START
if "%tmpInput%"=="Y" goto :START
echo Canelled.
echo Press any key to exit...
pause>nul
goto :END
:START
echo (1/3) Config Service
echo - Automatic Audio Server
PowerShell /Command "&{Import-Module ServerManager}"
PowerShell /Command "&{Set-Service "Audiosrv" -StartupType Automatic}"
echo (2/3) Config Registry and GroupPolicy
echo - Shutdown without logon
REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ShutdownWithoutLogon /t REG_DWORD /d 1 /f>nul
echo - Disable Ctrl+Alt+Del
REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v DisableCAD /t REG_DWORD /d 1 /f>nul
echo - Disable Shutdown reason On
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f>nul
echo - CPU Priority for Program
REG ADD HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl /v Win32PrioritySeparation /t REG_DWORD /d 38 /f>nul
echo - IE Security Policy
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f>nul
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f>nul
Rundll32 iesetup.dll, IEHardenLMSettings
Rundll32 iesetup.dll, IEHardenUser
Rundll32 iesetup.dll, IEHardenAdmin
echo - No autorun Server Manager
REG ADD HKLM\Software\Microsoft\ServerManager /v DoNotOpenServerManagerAtLogon /t REG_DWORD /d 1 /f>nul
echo - Disable Password complexity and Minimum password length
echo [version]>%gpfile%.inf
echo signature="$CHICAGO$">>%gpfile%.inf
echo [System Access]>>%gpfile%.inf
echo MinimumPasswordLength = 0 >>%gpfile%.inf
echo PasswordComplexity = 0 >>%gpfile%.inf
secedit /configure /db %gpfile%.sdb /cfg %gpfile%.inf /log %gpfile%.log>nul 2>nul
del %gpfile%.inf %gpfile%.sdb %gpfile%.log %gpfile%.jfm /f /q
echo - %currentuser%'s Password nerver expires
wmic Path Win32_UserAccount Where Name="%currentuser%" Set PasswordExpires="FALSE">nul
echo   PasswordExpires List:
wmic useraccount get Name,PasswordExpires
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
popd
