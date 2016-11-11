# WindowsServerToWindowsDesktop

A bat script to auto config Windows Server 2016 to "Windows Desktop"

<img src="demo.png" width="979" />

## BAT Will Do:
* Config Service
	- Automatic Audio Server

* Config Registry and GroupPolicy
	- Shutdown without logon
	- Disable Ctrl+Alt+Del
	- Disable Shutdown reason On
	- CPU Priority for Program
	- IE Security Policy
	- No autorun Server Manager
	- Disable Password complexity and Minimum password length
	- Administrator's Password nerver expires

* Config Windows Feature
	- BitLocker
	- Direct-Play
	- Wireless-Networking
	- qWave

## Manual configuration
1. Press `Win+Break` to open System Window, click `Advanced System Config` to show System Properties Dialog, and select `Advance` Tab. Click first `Setting` button to change Visual Effect.
2. You can close Windows Defender in Windows Settings -> Update and Security - Windows Defender
3. Install Flash player use [install_flash_player_23_active_x.exe](http://download.macromedia.com/get/flashplayer/current/licensing/win/install_flash_player_23_active_x.exe) with Windows 7 compatibility mode on file property dialog.
4. Setup Graphics drivers and DirectX etc.
5. Have fun!

## About Docker in Windows Server 2016
Please read [this blog](https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/).
