# Configure a Windows host
# ------------------------
#
# This script is used to finalize the setup of a Windows computer
# _______  _______  _                _________ _______ 
#(  ____ \(  ___  )( \      |\     /|\__   __/(  ___  )
#| (    \/| (   ) || (      | )   ( |   ) (   | (   ) |
#| (_____ | |   | || |      | |   | |   | |   | (___) |
#(_____  )| |   | || |      ( (   ) )   | |   |  ___  |
#      ) || |   | || |       \ \_/ /    | |   | (   ) |
#/\____) || (___) || (____/\  \   /  ___) (___| )   ( |
#\_______)(_______)(_______/   \_/   \_______/|/     \|
#
#Solution by Solvia
#https://www.solvia.ch
#info@solvia.ch
#---------------------------

Function Print-Welcome {
    Write-Host "
     _______  _______  _                _________ _______ 
    (  ____ \(  ___  )( \      |\     /|\__   __/(  ___  )
    | (    \/| (   ) || (      | )   ( |   ) (   | (   ) |
    | (_____ | |   | || |      | |   | |   | |   | (___) |
    (_____  )| |   | || |      ( (   ) )   | |   |  ___  |
          ) || |   | || |       \ \_/ /    | |   | (   ) |
    /\____) || (___) || (____/\  \   /  ___) (___| )   ( |
    \_______)(_______)(_______/   \_/   \_______/|/     \|

    Solution by Solvia
    https://www.solvia.ch
    info@solvia.ch" -ForegroundColor Cyan

}
# Setup error handling.
Trap {
    $_
    Exit 1
}
$ErrorActionPreference = "Stop"
# Print Welcome
Print-Welcome

Get-VBRBackup | 
Select-Object @{N = "Job Name"; E = { $_.Name } }, 
@{N = "BackupSize (GB)"; E = {
        [math]::Round(
                          ($_.GetAllStorages().Stats.BackupSize | 
            Measure-Object -Sum).Sum / 1GB, 1)
    }
},
@{N = "DataSize (GB)"; E = {
        [math]::Round(
                            ($_.GetAllStorages().Stats.DataSize | 
            Measure-Object -Sum).Sum / 1GB, 1)
    }
}| Out-GridView
