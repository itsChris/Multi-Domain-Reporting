# Configure a Windows host
# ------------------------
#
# This PowerShell Script is being used to create a HTML report about  VM/Workloads running on an ESXi server
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

Add-Type -AssemblyName PresentationFramework

[xml]$XAML = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Please provide your connection details" MaxHeight="200"  MinHeight="200" MinWidth="450" MaxWidth="450">
    <Window.Resources>
        <Style TargetType="{x:Type Label}">
            <Setter Property="Margin" Value="2"/>
        </Style>
        <Style TargetType="{x:Type TextBox}">
            <Setter Property="Margin" Value="2"/>
            <Setter Property="Height" Value="22"/>
            <Setter Property="Width" Value="200"/>
        </Style>
        <Style TargetType="{x:Type PasswordBox}">
            <Setter Property="Margin" Value="2"/>
        </Style>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Margin" Value="2"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="10"></ColumnDefinition>
            <ColumnDefinition></ColumnDefinition>
            <ColumnDefinition></ColumnDefinition>
            <ColumnDefinition Width="10"></ColumnDefinition>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="10"></RowDefinition>
            <RowDefinition></RowDefinition>
            <RowDefinition></RowDefinition>
            <RowDefinition></RowDefinition>
            <RowDefinition></RowDefinition>
            <RowDefinition></RowDefinition>
            <RowDefinition Height="10"></RowDefinition>
        </Grid.RowDefinitions>
        <Label Content="Server:" 
               Grid.Row="1" Grid.Column="1"/>
        <TextBox Name="ServerTextBox"
                 Grid.Row="1" Grid.Column="2" Text="host10"/>
        <Label Content="Username:" 
               Grid.Row="2" Grid.Column="1"/>
        <TextBox Name="UsernameTextBox"
                 Grid.Row="2" Grid.Column="2" Text="powercli"/>
        <Label Content="Password:" 
               Grid.Row="3" Grid.Column="1"/>
        <PasswordBox Name="PasswordTextBox" Width="200" Height="22"
                     Grid.Row="3" Grid.Column="2"/>
        <Label Content="VM-Name filter (contains)" 
               Grid.Row="4" Grid.Column="1"/>
        <TextBox Name="VmNameFilterTextBox" 
                 Grid.Row="4" Grid.Column="2"/>
        <Button Name="SubmitButton" Content="Submit" Width="100"  Height="22"
                Grid.Row="5" Grid.Column="2"/>
    </Grid>
</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader $XAML)
$Window=[Windows.Markup.XamlReader]::Load( $reader )

$ServerTextBox=$Window.FindName('ServerTextBox')
$UsernameTextBox=$Window.FindName('UsernameTextBox')
$VmNameFilterTextBox=$Window.FindName('VmNameFilterTextBox')
$PasswordTextBox=$Window.FindName('PasswordTextBox')
$SubmitButton=$Window.FindName('SubmitButton')

$SubmitButton.Add_Click({
    $Window.Close()
})

$null = $Window.ShowDialog()

$Server = $ServerTextBox.Text
$Username = $UsernameTextBox.Text
$Password = ConvertTo-SecureString -String $PasswordTextBox.Password -AsPlainText -Force
$filter = $VmNameFilterTextBox.Text

$cred = New-Object System.Management.Automation.PSCredential($Username, $Password)

# Ignore SSL Certificate warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create a new VMware PowerCLI session
Connect-VIServer -Server $Server -Credential $cred

# Get VMs details
$VMs = Get-VM | Where-Object { $_.Name -like "*$($filter)*" } | Sort-Object Name

# Create HTML report with CSS styling
$Report = @"
<html>
<head>
    <title>VMware VMs Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        h1 { color: #333; margin-bottom: 13px; }
        .logo-container {
            width: 380px;
            height: 140px;
            margin-bottom: 20px;
        }
        .logo-container svg {
            width: 100%;
            height: 100%;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #358997;
            color: white;
        }
        tr:nth-child(even) { 
            background-color: rgba(145, 211, 212, 0.25); 
        }
        .signature {
            margin-top: 20px;
            font-size: 14px;
        }
        
    </style>
</head>
<body>
    <div class="logo-container">
        <svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" width="120mm" height="50mm" viewBox="0 0 340.1575 141.7323"><defs><style>.cls-1{fill:#19181c;}.cls-2{fill:#358997;}.cls-3{fill:#8ed3d4;}</style></defs><title>SolviaLogo</title><path class="cls-1" d="M131.3845,91.3489a31.884,31.884,0,0,1-16.3457-4.4639l3.1685-6.3369c4.4644,2.5928,8.4248,4.1045,13.4653,4.1045,6.1206,0,9.7925-2.9522,9.7925-7.9209,0-3.6719-2.3042-5.9766-7.4165-7.4165L128.72,67.803c-4.5361-1.2964-7.7764-3.1685-9.6484-5.9766a12.5521,12.5521,0,0,1-2.0884-7.2724c0-8.7852,6.9126-14.7618,16.9214-14.7618a27.7046,27.7046,0,0,1,15.77,4.7525L145.93,50.3772c-4.6084-2.7358-7.7769-3.8159-11.7374-3.8159-4.8964,0-8.1367,2.664-8.1367,6.7685,0,3.0962,1.7281,4.68,6.6245,6.12l5.9048,1.7285c7.2007,2.0879,12.2407,6.6963,12.2407,14.185C150.8259,83.6448,144.13,91.3489,131.3845,91.3489Z"/><path class="cls-1" d="M174.0794,91.3489c-9.8648,0-16.0577-7.416-16.0577-19.0811s6.2647-19.1543,15.9131-19.1543c10.3692,0,16.2735,7.7046,16.2735,19.2256C190.2083,84.0764,183.9446,91.3489,174.0794,91.3489ZM174.0071,59.09c-5.04,0-7.2,3.8164-7.2,12.6733,0,10.5855,2.6641,13.6812,7.417,13.6812,4.68,0,7.2715-3.8164,7.2715-12.961C181.4954,62.1863,178.6155,59.09,174.0071,59.09Z"/><path class="cls-1" d="M207.56,91.2053c-7.9931,0-7.9931-7.2012-7.9931-10.2969V49.8733a59.0491,59.0491,0,0,0-.72-10.6567l8.1368-1.8c.5761,2.2324.6474,5.2563.6474,10.0087V78.3157c0,4.8965.2158,5.6884.792,6.5527a2.229,2.229,0,0,0,2.5918.5762l1.2969,4.8965A12.4214,12.4214,0,0,1,207.56,91.2053Z"/><path class="cls-1" d="M234.56,90.5569h-6.9843L214.47,54.2659l8.1367-1.1524,6.3369,19.6582c.8643,2.6641,1.8,6.336,2.2315,8.1367h.1445a67.5283,67.5283,0,0,1,2.16-8.4248l6.0488-18.5058H247.81Z"/><path class="cls-1" d="M257.886,48.5774a5.1644,5.1644,0,0,1-5.1123-5.2568,5.22,5.22,0,1,1,5.1123,5.2568Zm-3.96,41.8359V54.554l7.9932-1.44v37.3Z"/><path class="cls-1" d="M298.3528,91.925a8.5357,8.5357,0,0,1-4.9687-4.8964,12.3824,12.3824,0,0,1-10.01,4.4648c-8.3516,0-12.0967-4.6084-12.0967-10.9453,0-8.4248,6.3369-12.6733,18.002-12.6733h2.4482V65.9309c0-4.1768-.7207-6.4087-5.041-6.4087-4.68,0-9.7207,3.312-10.8731,4.1763L272.2864,58.01c5.4727-3.456,10.0078-4.9683,15.4805-4.9683,5.6894,0,9.5058,2.0879,11.09,6.0484.6475,1.584.6475,3.5283.5762,8.9287L299.2883,78.46c-.0722,4.8965.3594,6.4805,3.168,8.4248Zm-8.209-18.7216c-7.9209,0-10.2969,2.3047-10.2969,6.9131,0,3.456,1.8711,5.6162,5.04,5.6162a8.2377,8.2377,0,0,0,6.5527-3.8164l.1436-8.6407C291.44,73.2756,290.6477,73.2034,290.1438,73.2034Z"/><path class="cls-2" d="M101.7058,57.5849C97.0248,40.8149,71.207,30.95,44.0392,35.5512,16.8745,40.1523-1.3536,57.4787,3.3262,74.2487s30.5005,26.6357,57.6647,22.0341C88.1586,91.6822,106.3868,74.3549,101.7058,57.5849ZM52.5181,81.3761c-10.9611,0-19.8466-6.9215-19.8466-15.4607,0-8.5364,8.8855-15.457,19.8466-15.457,10.9569,0,19.8424,6.9206,19.8424,15.457C72.3605,74.4546,63.475,81.3761,52.5181,81.3761Z"/><path class="cls-3" d="M57.071,43.4558c-15.9321,0-28.85,10.056-28.85,22.461s12.9175,22.4619,28.85,22.4619c15.9345,0,28.852-10.057,28.852-22.4619S73.0055,43.4558,57.071,43.4558ZM52.6271,79.02c-9.6938,0-17.5521-6.118-17.5521-13.6657,0-7.5453,7.8583-13.6629,17.5521-13.6629,9.69,0,17.5485,6.1176,17.5485,13.6629C70.1756,72.9015,62.3173,79.02,52.6271,79.02Z"/></svg>
    </div>
    <h1>VMware VMs Report</h1>
 <table>
        <tr>
            <th>Name</th>
            <th>Operating System</th>
            <th>CPU Count</th>
            <th>Cores</th>
            <th>Memory (MB)</th>
            <th>Disk Info</th>
            <th>Total Disk Space (GB)</th>
        </tr>
"@

foreach ($VM in $VMs)
{
    $diskInfo = ($VM | Get-HardDisk | ForEach-Object { "$($_.Name): $($_.CapacityGB) GB" }) -join ' | '
    $totalDiskSpace = ($VM | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum
    $Report += @"
        <tr>
            <td>$($VM.Name)</td>
            <td>$($VM.Guest.OSFullName)</td>
            <td>$($VM.NumCpu)</td>
            <td>$($VM.CoresPerSocket)</td>
            <td>$($VM.MemoryMB)</td>
            <td>$diskInfo</td>
            <td>$totalDiskSpace</td>
        </tr>
"@
}

$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$Report += @"
    </table>
    <div class="signature">
        <p>Agent: Christian Casutt, Solvia GmbH</p>
        <p>Report date: $date</p>
    </div>
</body>
</html>
"@

# Write HTML report to file
$reportPath =  "$((Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')+'_VMReport.html')"
$Report | Out-File -FilePath $reportPath

# Open the report
Invoke-Item $reportPath

# Disconnect the PowerCLI session
Disconnect-VIServer -Server $Server -Confirm:$false
