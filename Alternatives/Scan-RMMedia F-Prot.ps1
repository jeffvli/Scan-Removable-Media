function Monitor-RMMedia {
<#  
    .SYNOPSIS
        Monitor for removable media being inserted into the system.

    .DESCRIPTION
        The script runs a continuous process to monitor for removable media, and running an Emsisoft Emergy Kit 
        (EEK; https://www.emsisoft.com/en/software/eek/) command-line scan on the specified media. Only one 
        removable device can be scanned at a time. Please wait until the first scan completes to insert another
        device. To use a different program for scanning, change commands in the function Scan-RMMedia.

        When a removable device is inserted into the system, scanned, or removed from the system, a balloon tooltip will
        display. The removable drive will be scanned with the designated scanner in function Scan-RMMedia, and will
        automatically open the log file saved in the directory specified by $logPath and $directoryPath.

    .PARAMETER
        -DirectoryPath <StringParameter>
        Specify the mandatory -DirectoryPath parameter to designate the location of the scan log output.

        -Log <SwitchParameter
        Add the -Log parameter to automatically open the newly created log file upon scan completion.

        -Tip <SwitchParameter>
        Run with the -Tip parameter to display tooltips when inserting/scanning/removing removable media.

    .LINK
        Setup instructions located at https://wiki.jeff-server.com/books/scripts/page/monitor-rmmedia

    .NOTES
        Source code by monotone (removable drive check): https://answers.microsoft.com/en-us/windows/forum/windows_vista-windows_programs/task-scheduler-how-to-automatically-synchronize-my/45a49d83-b1d8-4d37-8896-3d2696cf9795
        Source code by Boe Prox (balloon tooltip): https://mcpmag.com/articles/2017/09/07/creating-a-balloon-tip-notification-using-powershell.aspx

    .AUTHOR
        Jeff Li
        jli@teamfortech.com

    .VERSION
        1.0.0 (1/2/19) - Deployed
        1.0.1 (1/4/19) - Added check to confirm that virus scanner is installed under function Display-TipScanned; Fixed extra spaces in tooltip display
        1.0.2 (1/11/19) - Adjusted function ordering to ensure that scanner path check is working; changed default directory path to C:\Scans
        1.0.3 (1/15/19) - Fixed scanner path check under function Display-TipScanned; Set default tooltip off
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$DirectoryPath,
        [switch]$Log,
        [switch]$Tip
    )

    # Add WinForms
    Add-Type -AssemblyName System.Windows.Forms 

    # Unregister duplicate events before starting
    Unregister-Event -SourceIdentifier VolumeChange 2> $null
    Unregister-Event -SourceIdentifier IconClicked 2> $null
    $NewEvent = $null
    $EventType = $null

    # Register volumeChange event
    Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier VolumeChange

    # Add balloon object
    $global:Balloon = New-Object System.Windows.Forms.NotifyIcon 
    $BalloonPath = (Get-Process -id $pid).Path
    $Balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($BalloonPath) 
    [System.Windows.Forms.ToolTipIcon] | Get-Member -Static -Type Property 
    $Balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info

    $Balloon.Visible = $false

    if ($Tip) {
        $Balloon.Visible = $true
    }

    # Close balloon tooltip when double clicked
    [void](Register-ObjectEvent -InputObject $balloon -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action {
        #Perform cleanup actions on balloon tooltip
        $global:Balloon.dispose()
        Unregister-Event -SourceIdentifier IconClicked
        Remove-Job -Name IconClicked
        Remove-Variable -Name Balloon -Scope Global
    })

    # Run scan on removable media; change as you see fit
    function Scan-RMMedia {
        $ScannerPath = 'C:\Program Files (x86)\FRISK Software\F-PROT Antivirus for Windows\fpscan.exe'
        cmd.exe /c "`"$ScannerPath`" $DriveLetter /output=$LogPath"
        if ($Log) {
            Invoke-Item -Path $LogPath
        }
    }

    # Tooltip when media is inserted into the system
    function Display-TipConnected {
        $Balloon.BalloonTipTitle = "Removable media connected" 
        $Balloon.BalloonTipText = "Drive letter: $DriveLetter `nDrive Label: $DriveLabel `nStarting virus scan, please wait..."
        $Balloon.ShowBalloonTip(1000)
    }

    # Tooltip when media is removed from the system
    function Display-TipDisconnected {
        $Balloon.BalloonTipTitle = "Removable media disconnected" 
        $Balloon.BalloonTipText = "Drive letter: $DriveLetter"
        $Balloon.ShowBalloonTip(1000)
    }

    # Tooltip when media scan is completed
    function Display-TipScanned {
        $Balloon.BalloonTipTitle = "Scan completed" 
        $Balloon.BalloonTipText = "Log file saved to $LogPath"
        $Balloon.ShowBalloonTip(1000)
    }

    # Create default directory for logs if does not exist
    if (!(Test-Path -Path $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath
    }

    do {
        $NewEvent = Wait-Event -SourceIdentifier VolumeChange
        $EventType = $NewEvent.SourceEventArgs.NewEvent.EventType

        $EventTypeName = switch($EventType) {
            1 { "Configuration changed" }
            2 { "Device arrival" }
            3 { "Device removal" }
            4 { "Docking" }
        }

        # If removable media is connected
        if ($EventType -eq 2) {
            $LogDate = Get-Date -Format s | foreach { $_ -replace ":", "." }
            $LogPath = "$DirectoryPath\$LogDate" + "Scan.txt"
            $DriveLetter = $NewEvent.SourceEventArgs.NewEvent.DriveName + "\"
            $DriveLabel = ([wmi]"Win32_LogicalDisk='$DriveLetter'").VolumeName

            # Display media detected tooltip
            Display-TipConnected

            # Run virus scan on removable media
            Scan-RMMedia

            # Display completed scan tooltip
            Display-TipScanned
        }

        # If removable media is disconnected
        if ($EventType -eq 3) {
            # Display media removed tooltip
            Display-TipDisconnected
        }

        Remove-Event -SourceIdentifier VolumeChange
    } 

    # Loop until next event
    while (1 -eq 1) {
        Unregister-Event -SourceIdentifier VolumeChange
    }
}

Monitor-RMMedia -DirectoryPath 'C:\Scans' -Log -Tip
