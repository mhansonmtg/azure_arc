$ArcBoxLogsDir = "C:\ArcBox\Logs"

Start-Transcript -Path $ArcBoxLogsDir\DeploymentStatus.log

$Env:AZURE_STORAGE_CONNECTION_STRING ='BlobEndpoint=https://sgarcktfxuoca4g2qa.blob.core.windows.net/;QueueEndpoint=https://sgarcktfxuoca4g2qa.queue.core.windows.net/;FileEndpoint=https://sgarcktfxuoca4g2qa.file.core.windows.net/;TableEndpoint=https://sgarcktfxuoca4g2qa.table.core.windows.net/;SharedAccessSignature=sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-08-23T22:44:43Z&st=2024-08-23T14:44:43Z&spr=https&sig=Tef3Qo28Ifj%2B6EKEj7bQj0%2FanMGTN0ROrRXN1JY1SOQ%3D'

# Adding Resource Graph Azure CLI extension
Write-Host "`n"
Write-Host "Adding Resource Graph Azure CLI extension"
Write-Host "`n"
az extension add --name "resource-graph" -y

# Sending deployement status message to Azure storage account queue
$arcNumResources = az graph query -q "Resources | where type =~ 'Microsoft.HybridCompute/machines' or type=~'Microsoft.Kubernetes/connectedClusters' or type=~'Microsoft.AzureArcData/SqlServerInstances' or type=~'Microsoft.AzureArcData/dataControllers' or type=~'Microsoft.AzureArcData/sqlManagedInstances' or type=~'Microsoft.AzureArcData/postgresInstances' | where resourceGroup=~'$Env:resourceGroup' | project name, location, resourceGroup, tags | summarize count()" | Select-String "count_"
$arcNumResources = $arcNumResources -replace "[^0-9]" , ''
Write-Host "You now have $arcNumResources Azure Arc resources in '$Env:resourceGroup' resource group"
Write-Host "`n"

# ArcBox Full edition report if applicabale
if ($Env:flavor -eq "DevOps") {
    if ( $arcNumResources -eq 11 )
    {
        Write-Host "Great success!"
        az storage message put --content "Successful Jumpstart ArcBox ($Env:flavor) deployment" --account-name "sgarcktfxuoca4g2qa" --queue-name "arcboxusage" --time-to-live -1
    }
}

# ArcBox IT Pro edition report if applicabale
if ($Env:flavor -eq "ITPro") {
    if ( $arcNumResources -eq 6 )
    {
        Write-Host "Great success!"
        az storage message put --content "Successful Jumpstart ArcBox ($Env:flavor) deployment" --account-name "sgarcktfxuoca4g2qa" --queue-name "arcboxusage" --time-to-live -1
    }
}

if ( $arcNumResources -ne 11 -and $arcNumResources -ne 6) {
    Write-Host "Too bad, not all Azure Arc resources onboarded"
    az storage message put --content "Failed Jumpstart ArcBox ($Env:flavor) deployment" --account-name "sgarcktfxuoca4g2qa" --queue-name "arcboxusage" --time-to-live -1
}
