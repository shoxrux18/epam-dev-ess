param (
    # Set the regular expression for the ip addresses
    [ValidatePattern("^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$")]
    # We choose String type for the correct validation, otherwise in case with IpAddress type we could input "10" and it will be supplemented with zeros "10.0.0.0"
    [string]$ip_address_1,

    [ValidatePattern("^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$")]
    [string]$ip_address_2,

    # Here we could input either octets or the number of bits
    [ValidatePattern("(^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$)|((^[12]?\d$)|(^3[0-2]$))")]
    [string]$network_mask
)

# If the mask is defined as the number of bits, we bring it to the form of octets
if ($network_mask -match "(^[12]?\d$)|(^3[0-2]$)") {
    $mask = ([Math]::Pow(2, $network_mask) - 1) * [Math]::Pow(2, (32 - $network_mask))
    $bytes = [BitConverter]::GetBytes([UInt32]$mask)
    $network_mask = $((($bytes.Count - 1)..0 | ForEach-Object { [String]$bytes[$_] }) -join ".")
}

# Check if all the required arguments are provided
if (-not $PSBoundParameters.ContainsKey('ip_address_1') -or -not $PSBoundParameters.ContainsKey('ip_address_2') -or -not $PSBoundParameters.ContainsKey('network_mask')) {
    Write-Host "Error: Missing required arguments. Please provide values for 'ip_address_1', 'ip_address_2', and 'network_mask'."
    exit 1
}

# Change the type of variables and validate input parameters
try {
    [IPAddress]$network_mask = $network_mask
    [IPAddress]$ip_address_1 = $ip_address_1
    [IPAddress]$ip_address_2 = $ip_address_2
} catch {
    Write-Host "Error: Invalid input parameters. Please check the provided IP addresses and network mask."
    exit 1
}

# Identify the networks of each address
$network_1 = [IPAddress]($ip_address_1.Address -band $network_mask.Address)
$network_2 = [IPAddress]($ip_address_2.Address -band $network_mask.Address)

# Show the result
if ($network_1 -eq $network_2) {
    Write-Host "yes"
} else {
    Write-Host "no"
}
