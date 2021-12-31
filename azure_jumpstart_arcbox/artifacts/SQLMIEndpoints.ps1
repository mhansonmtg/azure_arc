$ArcBoxLogsDir = "C:\ArcBox\Logs"

Start-Transcript -Path $ArcBoxLogsDir\SQLMIEndpoints.log

# Creating SQLMI Endpoints file 
New-Item -Path "C:\ArcBox\" -Name "SQLMIEndpoints.txt" -ItemType "file" 
$Endpoints = "C:\ArcBox\SQLMIEndpoints.txt"

# Retrieving SQL MI connection endpoints
Add-Content $Endpoints "Primary SQL Managed Instance external endpoint:"
$primaryEndpoint = kubectl get sqlmanagedinstances jumpstart-sql -n arc -o=jsonpath='{.status.primaryEndpoint}'
$primaryEndpoint = $primaryEndpoint.Substring(0, $primaryEndpoint.IndexOf(',')) + ",11433" | Add-Content $Endpoints
Add-Content $Endpoints ""

Add-Content $Endpoints "Secondary SQL Managed Instance external endpoint:"
$secondaryEndpoint = kubectl get sqlmanagedinstances jumpstart-sql -n arc -o=jsonpath='{.status.secondaryEndpoint}'
$secondaryEndpoint = $secondaryEndpoint.Substring(0, $secondaryEndpoint.IndexOf(',')) + ",11433" | Add-Content $Endpoints

# Retrieving SQL MI connection username and password
Add-Content $Endpoints ""
Add-Content $Endpoints "SQL Managed Instance username:"
$env:AZDATA_USERNAME | Add-Content $Endpoints

Add-Content $Endpoints ""
Add-Content $Endpoints "SQL Managed Instance password:"
$env:AZDATA_PASSWORD | Add-Content $Endpoints

Write-Host "`n"
Write-Host "Creating SQLMI Endpoints file Desktop shortcut"
Write-Host "`n"
$TargetFile = $Endpoints
$ShortcutFile = "C:\Users\$env:adminUsername\Desktop\SQLMI Endpoints.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()