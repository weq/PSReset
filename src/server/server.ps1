#Import-Module ActiveDirectory
Import-Module UniversalDashboard.Community

$process = New-UDEndpoint -Url "/process" -Method "GET" -Endpoint {
        Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; ID=$_.ID} } | ConvertTo-Json
    }

$service = New-UDEndpoint -Url "/service" -Method "GET" -Endpoint {
        Get-Service | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Status=$_.Status} } | ConvertTo-Json
    }
    
$endpoint = @($process, $service)

Get-UDRestApi | Stop-UDRestApi
Start-UDRestApi -Endpoint $endpoint -Port 8001

#Invoke-RestMethod -Uri http://localhost:8001/api/process
