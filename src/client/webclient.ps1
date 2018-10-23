Import-Module UniversalDashboard.Community
$Colors = @{
    BackgroundColor = "#252525"
    FontColor = "#FFFFFF"
}

$AlternateColors = @{
    BackgroundColor = "#4081C9"
    FontColor = "#FFFFFF"
}

$ScriptColors = @{
    BackgroundColor = "#5A5A5A"
    FontColor = "#FFFFFF"
}



$dashboard = New-UDDashboard -Title "Trouble logging in?" -Content {
    New-UDLayout -Columns 3 -Content {
        New-UDRow -Columns {}
        New-UDRow -Columns {
            New-UDInput -Title "We need some information about you first" -Content {
                New-UDInputField -Type "textbox" -Name "username" -Placeholder "Enter your username"
                New-UDInputField -Type "textbox" -Name "phonematch" -Placeholder "Last for digits in your phone number"
        } -Endpoint {
            param($username,$phonematch)

            New-UDInputAction -Content @(
                New-UDCard -Title "yeye" -Text $username
            ) 
        }
        
        }
    }
}
#Get-UDDashboard | Stop-UDDashboard
Start-UDDashboard -Dashboard $dashboard -Port 8000 -AutoReload