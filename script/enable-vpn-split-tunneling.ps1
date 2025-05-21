param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the VPN connection name")]
    [ValidateNotNullOrEmpty()]
    [string]$vpnName,
    
    [Parameter(Mandatory=$true, HelpMessage="Enter the subnet in CIDR notation (e.g., 172.168.4.0/24)")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}/\d{1,2}$', ErrorMessage="Subnet must be in CIDR notation (e.g., 172.168.4.0/24)")]
    [string]$subnet
)

# Script thiết lập Split Tunneling cho subnet được chỉ định
# Chạy script này với quyền Administrator

try {
    # Check if VPN connection exists
    $vpnExists = Get-VpnConnection -Name $vpnName -ErrorAction SilentlyContinue
    if (-not $vpnExists) {
        throw "VPN connection '$vpnName' does not exist"
    }

    Write-Host "Enable split tunneling for $vpnName"
    Set-VpnConnection -Name $vpnName -SplitTunneling $True

    Write-Host "Add route for $subnet"
    Add-VpnConnectionRoute -ConnectionName $vpnName -DestinationPrefix $subnet

    Write-Host "Done"
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}