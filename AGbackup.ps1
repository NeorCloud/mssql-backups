$ServerInstance = "MSSQLSERVER1"
$BackupPath = "C:\SQLBackups\" 
$AvailabilityGroupName = "HamyarPayeshAG01"
$S3BucketName = "fiscal-backup"
$S3BackupFolder = "dotnet-mssql"

Import-Module SqlServer -ErrorAction Stop

function Backup-Database {
    param (
        [string]$ServerInstance,
        [string]$DatabaseName,
        [string]$BackupPath
    )
    
    try {
        $server = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance

        $backup = New-Object Microsoft.SqlServer.Management.Smo.Backup
        $backup.Action = "Database"
        $backup.Database = $DatabaseName

        $backupFile = "$BackupPath\$DatabaseName.bak"
        $backup.Devices.AddDevice($backupFile, "File")
        $backup.Initialize = $true

        Write-Host "Starting backup for database: $DatabaseName"
        $backup.SqlBackup($server)
        Write-Host "Backup completed for database: $DatabaseName"
        return $backupFile
    } catch {
        Write-Error "Failed to backup database $DatabaseName. Error: $_"
        return $null
    }
}

try {
    # Connect to the SQL Server instance
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance

    # Get the availability group
    $availabilityGroup = $server.AvailabilityGroups[$AvailabilityGroupName]
    if (-not $availabilityGroup) {
        throw "Availability group '$AvailabilityGroupName' not found on server '$ServerInstance'."
    }

    # Enumerate databases in the availability group
    $databases = $availabilityGroup.AvailabilityDatabases
    foreach ($database in $databases) {
        $databaseName = $database.Name
        $backupFile = Backup-Database -ServerInstance $ServerInstance -DatabaseName $databaseName -BackupPath $BackupPath
    }
} catch {
    Write-Error "An error occurred: $_"
}
