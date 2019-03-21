# Create a scheduled job to run Monitor-RMMedia.ps1 silently
# Reference script: https://old.reddit.com/r/PowerShell/comments/4y7ig4/running_a_scheduled_job_at_logon/

$JobOption = New-ScheduledJobOption -MultipleInstancePolicy IgnoreNew
$JobTrigger = New-JobTrigger -AtLogOn
$NewJob = Register-ScheduledJob `
    -Name Scan-RMMedia `
    -Trigger $JobTrigger `
    -ScheduledJobOption $JobOption `
    -FilePath '\\Path\to\Scan-RMMedia.ps1'

# Create scheduled task from Scheduled-Job
$TaskPrincipal = New-ScheduledTaskPrincipal -LogonType Interactive -UserId 'Domain\User'
Set-ScheduledTask `
    -TaskPath '\Microsoft\Windows\PowerShell\ScheduledJobs\' `
    -TaskName $($NewJob.Name) `
    -Principal $TaskPrincipal


$Task = Get-ScheduledTask -TaskName 'Scan-RMMedia'

# Turn off setting 'Stop the task if it runs longer than'
$Task.Settings.ExecutionTimeLimit = 'PT0H'

# Turn on 'Run task as soon as possible after a scheduled start is missed'
$Task.Settings.StartWhenAvailable = $true

Set-ScheduledTask $Task
