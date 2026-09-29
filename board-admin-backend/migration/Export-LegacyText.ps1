param(
    [string]$OldBackend = 'C:\Users\Administrator\Desktop\Boardpac\wcf\bin',
    [string]$SqlServer = 'localhost',
    [string]$Database = 'BoardPAC',
    [string]$Output = 'target/legacy-decrypted-text.tsv'
)

$ErrorActionPreference = 'Stop'
$daoPath = Join-Path $OldBackend 'BoardPACDAO.dll'
$utilPath = Join-Path $OldBackend 'BoardAppUtil.dll'
if (!(Test-Path -LiteralPath $daoPath) -or !(Test-Path -LiteralPath $utilPath)) {
    throw 'Old backend DLLs were not found.'
}
$dao = [Reflection.Assembly]::LoadFrom($daoPath)
$util = [Reflection.Assembly]::LoadFrom($utilPath)
$baseType = $dao.GetType('BoardPACDAO.Base.BaseDAO')
$base = [Activator]::CreateInstance($baseType)
$flags = [Reflection.BindingFlags]'Public,NonPublic,Instance'
$key = $baseType.GetField('details', $flags).GetValue($base)
$iv = $baseType.GetField('iVector', $flags).GetValue($base)
if ($key.Length -notin @(16,24,32) -or $iv.Length -ne 16) { throw 'Unexpected legacy crypto configuration.' }
$decrypt = $util.GetType('BoardAppUtil.Security.CryptoServices').GetMethod('DecryptString')

$outputPath = [IO.Path]::GetFullPath($Output)
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
if (Test-Path -LiteralPath $outputPath) { throw 'Output already exists. Remove it explicitly before repeating the export.' }
$connection = New-Object System.Data.SqlClient.SqlConnection("Server=$SqlServer;Database=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True")
$writer = New-Object IO.StreamWriter($outputPath, $false, (New-Object Text.UTF8Encoding($false)))
try {
    $connection.Open()
    foreach ($spec in @(@('heading','Headings','HeadingId','Description'), @('paper','Papers','PaperId','Name'))) {
        $count = 0
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT [$($spec[2])],[$($spec[3])] FROM dbo.[$($spec[1])] ORDER BY [$($spec[2])]"
        $reader = $cmd.ExecuteReader()
        try {
            while ($reader.Read()) {
                $id = $reader.GetInt32(0)
                if ($reader.IsDBNull(1)) { throw "Missing encrypted text for $($spec[0]) $id" }
                $plain = $decrypt.Invoke($null, @($reader.GetString(1), $key, $iv, $false, $false))
                if ([string]::IsNullOrWhiteSpace($plain)) { throw "Empty decrypted text for $($spec[0]) $id" }
                $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($plain))
                $writer.WriteLine("$($spec[0])`t$id`t$encoded")
                $count++
            }
        } finally { $reader.Close() }
        Write-Output "$($spec[0]): $count decrypted records"
    }
} catch {
    $writer.Close()
    if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath }
    throw
} finally {
    $writer.Close()
    $connection.Close()
}
Write-Output "Export complete: $outputPath"
