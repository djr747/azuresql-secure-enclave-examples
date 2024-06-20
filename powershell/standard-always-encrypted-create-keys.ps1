# Create a column master key in Azure Key Vault and column encryption key.  Then encrypt one column.
$subscriptionId = "<subscriptionId>"
$akvResourceGroup = "<resourceGroup>"
$akvName = "<keyVaultName>"
$akvKeyName = "<keyName>"
$serverName = "<serverName>"
$databaseName = "<databaseName>"

Import-Module "SqlServer" -MinimumVersion 22.0.50
Import-Module Az.Accounts -MinimumVersion 2.2.0
Connect-AzAccount

$azureCtx = Set-AzConteXt -SubscriptionId $subscriptionId # Sets the context for the below cmdlets to the specified subscription.
Set-AzKeyVaultAccessPolicy -VaultName $akvName -ResourceGroupName $akvResourceGroup -PermissionsToKeys get, create, delete, list, wrapKey,unwrapKey, sign, verify -UserPrincipalName $azureCtx.Account
$akvKey = Add-AzKeyVaultKey -VaultName $akvName -Name $akvKeyName -Destination "Software" -Size 2048 -KeyType RSA

# Connect to your database.
$akvKey = Get-AzKeyVaultKey -VaultName $akvName -Name $akvKeyName

# Change the authentication method in the connection string, if needed.
$connStr = "Server = " + $serverName + "; Database = " + $databaseName + "; Authentication=Active Directory Default"
$database = Get-SqlDatabase -ConnectionString $connStr

# Obtain an access token for key vaults.
$keyVaultAccessToken = (Get-AzAccessToken -ResourceUrl https://vault.azure.net).Token 

# Create a SqlColumnMasterKeySettings object for your column master key. 
$cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $akvKey.ID -KeyVaultAccessToken $keyVaultAccessToken

# Create column master key metadata in the database.
$cmkName = "CMK1"
New-SqlColumnMasterKey -Name $cmkName -InputObject $database -ColumnMasterKeySettings $cmkSettings

# Generate a column encryption key, encrypt it with the column master key and create column encryption key metadata in the database. 
$cekName = "CEK1"
New-SqlColumnEncryptionKey -Name $cekName -InputObject $database -ColumnMasterKey $cmkName -KeyVaultAccessToken $keyVaultAccessToken

# Encrypt the selected columns (or re-encrypt, if they are already encrypted using keys/encrypt types, different than the specified keys/types.
$ces = New-SqlColumnEncryptionSettings -ColumnName "dbo.Customers.ContactName" -EncryptionType "Deterministic" -EncryptionKey "CEK1" 
Set-SqlColumnEncryption -InputObject $database -ColumnEncryptionSettings $ces -LogFileDirectory . -KeyVaultAccessToken $keyVaultAccessToken