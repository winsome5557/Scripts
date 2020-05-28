param (
    [Parameter(Mandatory=$true)][Alias('p')][string]$PolicyFile,
    [Parameter(Mandatory=$true)][Alias('n')][string]$WebAppName = "",
    [Parameter(Mandatory=$false)][Alias('r')][string]$redirect_uri = "https://jwt.ms",
    [Parameter(Mandatory=$false)][Alias('s')][string]$scopes = ""
    )

if (!(Test-Path $PolicyFile -PathType leaf)) {
    write-error "File does not exists: $PolicyFile"
    exit 1
}
[xml]$xml = Get-Content $PolicyFile
$PolicyId = $xml.TrustFrameworkPolicy.PolicyId
$tenantName = $xml.TrustFrameworkPolicy.TenantId

write-host "Getting test app $WebAppName"
$app = Get-AzureADApplication -SearchString $WebAppName -ErrorAction SilentlyContinue
if ( $null -eq $app ) {
    write-error "App isn't registered: $WebAppName"
    exit 1
}
if ( $app.Count -gt 1 ) {
    $app = ($app | where {$_.DisplayName -eq $WebAppName})
}
if ( $app.Count -gt 1 ) {
    write-error "App name isn't unique: $WebAppName"
    exit 1
}


$scope = "openid"
$response_type = "id_token"

# if extra scopes passed on cmdline, then we will also ask for an access_token
if ( "" -ne $scopes ) {
    $scope = "openid offline_access $scopes"
    $response_type = "id_token token"
}

$params = "client_id={0}&nonce={1}&redirect_uri={2}&scope={3}&response_type={4}&prompt=login&disable_cache=true" `
        -f $app.AppId.ToString(), (New-Guid).Guid, $redirect_uri, $scope, $response_type
# Q&D urlencode
$params = $params.Replace(":","%3A").Replace("/","%2F").Replace(" ", "%20")

$url = "https://{0}.b2clogin.com/{1}/{2}/oauth2/v2.0/authorize?{3}" -f $tenantName.Split(".")[0], $tenantName, $PolicyId, $params

write-host "Starting Browser`n$url"

[System.Diagnostics.Process]::Start("chrome.exe","--incognito --new-window $url")
