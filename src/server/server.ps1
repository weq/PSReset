#Import-Module ActiveDirectory
Import-Module UniversalDashboard.Community

$apiVersion = "v1"
$PSResetTempFolder = $env:TEMP + "\PSReset"
$PSResetTempFolderUserTemporaryCode = $env:TEMP + "\PSReset\UserTemporaryCode"
New-Item -Path $PSResetTempFolder -ItemType Directory
New-Item -Path $PSResetTempFolderUserTemporaryCode -ItemType Directory

$process = New-UDEndpoint -Url "/$($apiVersion)/process" -Method "GET" -Endpoint {
    Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; ID=$_.ID} } | ConvertTo-Json
}

$service = New-UDEndpoint -Url "/$($apiVersion)/service" -Method "GET" -Endpoint {
    Get-Service | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Status=$_.Status} } | ConvertTo-Json
}
    
$verifyUser = New-UDEndpoint -Url "/$($apiVersion)/verifyUser" -Method "GET" -Endpoint {
    param($username, $fourDigit)
    $user = Get-ADUser -Filter {SamAccountName -like $username}
    
    if ($user) {
        $return = @{
            SamAccountName = $user.SamAccountName
        }
        $return | ConvertTo-Json
    } else {
        @{ SamAccountName = "Can't find user." } | ConvertTo-Json
    }
}

function New-OneTimeCode {
    return "{0:0000}" -f (Get-Random -Minimum 0 -Maximum 9999)
}

function New-UserTemporaryCode {
    param(
        [string]$username
    )
    try {
        $jsonData = @{
            username = $username
            code = New-OneTimeCode
            dateGenerated = (Get-Date)
        }
        $jsonData | ConvertTo-Json | Out-File -FilePath ($PSResetTempFolderUserTemporaryCode + "\$($username).json")    
        return $true
    }
    catch {
        return $false
    }
}

function Send-UserTemporaryCode {
    param(
        [string]$username,
        [int]$userTemporaryCode
    )
    $user = Get-ADUser -Filter {SamAccountName -like $username} -Properties telephoneNumber
    # Pull in Twilio account info, previously set as environment variables
    $sid = $env:TWILIO_ACCOUNT_SID
    $sid = ""
    $token = $env:TWILIO_AUTH_TOKEN
    $token = ""
    $number = $env:TWILIO_NUMBER
    $number = "+4759446601"
    $number = "+15005550006"

    # Twilio API endpoint and POST params
    $url = "https://api.twilio.com/2010-04-01/Accounts/$($sid)/Messages.json"
    $params = @{ To = ($user.telephoneNumber); From = $number; Body = "Temporary code: $($userTemporaryCode)" }

    # Create a credential object for HTTP basic auth
    $p = $token | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($sid, $p)

    # Make API request, selecting JSON properties from response
    Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing | ConvertFrom-Json | Select-Object sid, body
}

function Check-IfUserAlreadyHasAValidCode {
    param(
        [string]$username
    )
    $userfile = Get-ChildItem -path $PSResetTempFolderUserTemporaryCode -Filter "$($username).json"
    if ($userfile) {
        $userdata = Get-Content -Path $userfile.FullName | ConvertFrom-Json
        if ((Get-Date $userdata.dateGenerated) -lt ((Get-date).AddMinutes(-5))) { # Check if the dateGenerated is older than N minutes.
            Remove-Item -Path $userfile.FullName
            return $false
        } else {
            # CODE IS STILL VALID
            Write-Host VALID
            return $true
        }
        #File exists already
    } else {
        return $false
    }
}

$validateSubmittedInformation = New-UDEndpoint -Url "/$($apiVersion)/validateSubmittedInformation" -Method "POST" -Endpoint {
    param(
        [string]$username,
        [int]$fourDigit
    )
    $user = Get-ADUser -Filter {SamAccountName -like $username} -Properties telephoneNumber
    $telephoneNumber = $user.telephoneNumber

    if ($user -and $telephoneNumber) {
        # Verifiy that we have both a user object and a telephoneNumber
        # Check if the telephoneNumber matches
        if ($fourdigit -eq $telephoneNumber.substring($telephoneNumber.Length-4)) {
            # Yeah user is valid bro!
        }
    } else {
        # We didn't get a valid user with a telephoneNumber
    }
}

# Generate OneTimeCode
# Store OneTimeCode temporary with expiration
# Send OneTimeCode to user
$endpoint = @($process, $service, $verifyUser, $validateSubmittedInformation)

Get-UDRestApi | Stop-UDRestApi
Start-UDRestApi -Endpoint $endpoint -Port 8001

Invoke-RestMethod -Uri http://localhost:8001/api/v1/verifyUser -Method GET -Body @{ username = "administrator"; fourDigit = "9393" }
#Invoke-RestMethod -Uri http://localhost:8001/api/process
