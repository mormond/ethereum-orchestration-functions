#
# Take a JSON payload in the following format to kick off a new member deployment
# {
#    "id"                   : "An ID for the request to allow it to be tracked for it's lifetime",
#    "location"             : "An azure location for the deployment",
#    "rgName"               : "Resource group name",
#    "dashboardIp"          : "IP Address of the registrar node",
#    "subName"              : "Azure Subscription Name",
#    "templateParamsUri"    : "A link to the ARM template parameters file for the deployment"
# }
#

# Add collection of new members / value pairs to object
function ExtendJsonObject($originalObject, [hashtable]$members) {
    ForEach ($key in $members.keys) {
        Add-Member -InputObject $originalObject $key $members[$key]             
    }
    return $originalObject
}

# Encrypt a SecureString
function AESEncryptString([SecureString]$secureString, $key) {
    $encryptedString = ConvertFrom-SecureString $secureString -Key $key
    return $encryptedString
}

# Decrypt an encrypted string to a SecureString
function AESDecryptString([string]$encryptedString, $key) {
    $secureString = ConvertTo-SecureString $encryptedString -Key $key
    return $secureString
}

# Render a SecureString as plaintext
function SecureStringToPlainText($secureString) {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# Get the payload containing the deployment metadata
$payload = Get-Content $req -Raw | ConvertFrom-Json

# TODO (This will do for now)
$key = (3, 4, 2, 3, 56, 34, 254, 212, 1, 1, 2, 23, 42, 54, 33, 213, 1, 34, 2, 7, 6, 5, 35, 44)
#$key = $env:key

#TODO (Get the bearer token)
$plainToken = "A bearer token from somewhere"
$secureToken = $plainToken | ConvertTo-SecureString -AsPlainText -Force

$timestamp = (Get-Date).ToString();
$guid = New-Guid;
$token = AESEncryptString $secureToken $key

# Add the extra metadata to the payload
$newMembers = @{ `
    Timestamp = $timestamp; `
    Id = $guid; `
    SecureToken = $token `

}

$queueMessageObject = ExtendJsonObject $payload $newMembers


$queueMessageJson = $queueMessageObject | ConvertTo-Json

#Write-Output "Testing Write Output Works"

#$queueMessage | % {Write-Output $_}

Out-File -Encoding Ascii -FilePath $outputQueueItem -inputObject $queueMessageJson    
Out-File -Encoding Ascii -FilePath $res -inputObject $queueMessageJson

