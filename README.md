# Scan-Removable-Media
![Demo](https://i.imgur.com/kSmbk4S.gif)
Scan-RMMedia.ps1 works in conjunction with an external virus scanner to automatically scan removable media when it is inserted into the running system. Once the scan is completed, a .txt log file is outputted to a specified directory and can be opened automatically for ease of printing. From my testing, I have found that Emsisoft Emergency Kit's (EEK) command-line scanning utility fits this script best. 

# Prerequisities
- PowerShell Version 5
- .NET Framework 4.5 for PowerShell 5.1
- Emsisoft Emergency Kit (EEK) command-line scanning utility
- Install to default directory C:\EEK (change $ScannerPath variable on line 107 otherwise)
- User account must be a local admin

