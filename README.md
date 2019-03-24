# Scan-Removable-Media
![Demo](https://i.imgur.com/kSmbk4S.gif)
Scan-RMMedia.ps1 works in conjunction with an external virus scanner to automatically scan removable media when it is inserted into the running system. Once the scan is completed, a .txt log file is outputted to a specified directory and can be opened automatically for ease of printing. From my testing, I have found that [Emsisoft Emergency Kit's (EEK) command-line scanning utility](https://www.emsisoft.com/en/home/emergencykit/) fits this script best. 

## Prerequisities
- PowerShell Version 5
- .NET Framework 4.5 for PowerShell 5.1
- Emsisoft Emergency Kit (EEK) command-line scanning utility
- Install to default directory C:\EEK (change $ScannerPath variable on line 107 otherwise)
- User account must be a local admin
- PowerShell execution policy as Unrestricted `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`

## How to use
1. Clone the repository to a local or shared network location.
2. Create a local administrator account to run the script.
3. Create a scheduled task to run the script under the scope of the administrator account, or create a scheduled job with Register-RMMediaJob.ps1.
    - Program/script: powershell.exe
    - Add arguments (optional): -NoLogo -NonInteractive -WindowStyle Hidden "\\Path\to\Scan-RMMedia.ps1"
4. If created with Register-RMMediaJob.ps1, verify the scheduled task has been created by navigating to: `Task Scheduler Library\Microsoft\Windows\PowerShell\ScheduledJobs`
5. Trigger the scheduled task or run it manually to test.

## Automatic detection signature updates for EEK
1. Create a new scheduled task to run whether the administrator account is logged on or not.
2. Add a scheduled trigger for when you want to run the updates.
3. Add actions
    - Program/script: cmd.exe
    - Add arguments (optional): /c "\\\path\to\a2cmd.exe" /u
