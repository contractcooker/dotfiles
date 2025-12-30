#This script exists because the auto-lock/disconnect time period is way too short.

#*** Make sure to lock before you go AFK! ***

#==============================================================================

#https://stackoverflow.com/a/56636565/1599699
#https://gist.github.com/MatthewSteeples/ce7114b4d3488fc49b6a?permalink_comment_id=4590234#gistcomment-4590234
#https://ss64.com/vb/sendkeys.html
#https://devguru.com/content/technologies/wsh/wshshell-sendkeys.html

#==============================================================================

$host.UI.RawUI.WindowTitle = "OS Keep-Alive"
[Console]::SetWindowSize(50, 10)

$format = "dddd MM/dd/yy hh:mm:ss tt"
$start = $(Get-Date -Format $format)
$previous = "N/A"

$WShell = New-Object -com "Wscript.Shell"
while ($true)
{
  Clear-Host
  Echo "Keep-alive with Scroll Lock toggle..."
  Write-Host
  Write-Host "     Start:" $start
  Write-Host "  Previous:" $previous
  $previous = $(Get-Date -Format $format)
  Write-Host "    Latest:" $previous
  Write-Host
  Echo "*** Make sure to lock before you go AFK! ***"

  #==============================================================================
  
  #If you're getting a "null-valued" expression error, try "SCROLLLOCK" instead.
  $WShell.sendkeys("{SCROLLLOCK}")
  Start-Sleep -Milliseconds 100 #100 milliseconds == 1/10th seconds

  $WShell.sendkeys("{SCROLLLOCK}")
  Start-Sleep -Seconds 240 #240 seconds == 4 minutes * 60 seconds
}