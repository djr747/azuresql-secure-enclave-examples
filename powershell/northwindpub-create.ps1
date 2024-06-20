# Create a column master key in Azure Key Vault.
$serverName = "<serverName>"
$databaseName = "<databaseName>"

Import-Module "SqlServer" -MinimumVersion 22.0.50
Import-Module "Az.Accounts" -MinimumVersion 2.2.0
Connect-AzAccount


if (Test-Path "northwindpub-create.sql") {
    Remove-Item "northwindpub-create.sql" 
}

Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/databases/northwind-pubs/instnwnd%20(Azure%20SQL%20Database).sql" -OutFile "northwindpub-create.sql"

$token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

Invoke-SqlCmd -ServerInstance "$serverName" `
              -Database "$databaseName" `
              -AccessToken "$token" `
              -InputFile ./northwindpub-create.sql `
              | Out-File -FilePath ./northwindpub-create.log
