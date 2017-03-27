#
# No idea whether this will work or not - can't find any documentaiton
# on using PS with a queue output
#

$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$name = $requestBody.name

Write-Output "Testing Write Output Works"

if ($name) 
{
    Write-Output "In conditional"

    $guid = [guid]::NewGuid()

    $outItem = $guid.Guid, $name

    $outItem | % {Write-Output $_}

    Out-File -Encoding Ascii -FilePath $outputQueueItem -inputObject $outItem    
    Out-File -Encoding Ascii -FilePath $res -inputObject $outItem
}

