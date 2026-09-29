param(
    [string]$OldBackend = 'C:\Users\Administrator\Desktop\Boardpac\wcf\bin',
    [string]$SqlServer = 'localhost',
    [string]$Database = 'BoardPAC',
    [string]$OutputRoot = 'target/migration-uploads',
    [string]$Manifest = 'target/legacy-files.tsv',
    [string]$Errors = 'target/legacy-file-errors.tsv',
    [int]$Limit = 0
)

$ErrorActionPreference = 'Stop'
$dao = [Reflection.Assembly]::LoadFrom((Join-Path $OldBackend 'BoardPACDAO.dll'))
$bo = [Reflection.Assembly]::LoadFrom((Join-Path $OldBackend 'BoardPACBO.dll'))
$util = [Reflection.Assembly]::LoadFrom((Join-Path $OldBackend 'BoardAppUtil.dll'))
$paperType = $bo.GetType('BoardPACBO.Paper.PaperModel')
$paperDaoType = $dao.GetType('BoardPACDAO.Paper.PaperDAO')
$paperDao = [Activator]::CreateInstance($paperDaoType)
$keyMethod = $paperDaoType.GetMethod('GenerateCloseOpenFile', [Reflection.BindingFlags]'Public,NonPublic,Instance')
$readMethod = $paperDaoType.GetMethod('GetPdfDocument')
$il = $readMethod.GetMethodBody().GetILAsByteArray()
$keyArgument = $null
for ($i = 5; $i -lt $il.Length - 4; $i++) {
    if ($il[$i] -ne 0x28 -or $il[$i - 5] -ne 0x72) { continue }
    try { $called = $readMethod.Module.ResolveMethod([BitConverter]::ToInt32($il, $i + 1)) } catch { continue }
    if ($called.MetadataToken -eq $keyMethod.MetadataToken) {
        $keyArgument = $readMethod.Module.ResolveString([BitConverter]::ToInt32($il, $i - 4))
        break
    }
}
if ($null -eq $keyArgument) { throw 'Could not locate legacy file key argument.' }
$cryptoType = $util.GetType('BoardAppUtil.Security.CryptoServices')
Add-Type -TypeDefinition @'
using System;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;

public static class FastLegacyFileDecryptor {
    public static byte[] Decrypt(Type cryptoType, byte[] encrypted, string key, int version) {
        if (encrypted == null || encrypted.Length <= 16) throw new ArgumentException("Invalid encrypted document");
        var iv = new byte[16];
        Buffer.BlockCopy(encrypted, 0, iv, 0, 16);
        var method = cryptoType.GetMethod("GetProvider", BindingFlags.NonPublic | BindingFlags.Static);
        if (method == null) throw new MissingMethodException("Legacy GetProvider");
        using (var provider = (AesCryptoServiceProvider)method.Invoke(null, new object[] { Encoding.Default.GetBytes(key), iv, version }))
        using (var decryptor = provider.CreateDecryptor()) {
            return decryptor.TransformFinalBlock(encrypted, 16, encrypted.Length - 16);
        }
    }
}
'@
$root = [IO.Path]::GetFullPath($OutputRoot)
$manifestPath = [IO.Path]::GetFullPath($Manifest)
$errorPath = [IO.Path]::GetFullPath($Errors)
if (Test-Path -LiteralPath $manifestPath) { throw 'Manifest already exists; use a fresh output path for a repeat run.' }
if (Test-Path -LiteralPath $errorPath) { throw 'Error manifest already exists; use a fresh output path for a repeat run.' }
[IO.Directory]::CreateDirectory($root) | Out-Null
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($manifestPath)) | Out-Null
$connection = New-Object System.Data.SqlClient.SqlConnection("Server=$SqlServer;Database=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True")
$writer = New-Object IO.StreamWriter($manifestPath, $false, (New-Object Text.UTF8Encoding($false)))
$errorWriter = New-Object IO.StreamWriter($errorPath, $false, (New-Object Text.UTF8Encoding($false)))
$writer.WriteLine("paper_id`tversion_id`trelative_path`tbytes`tsha256")
$errorWriter.WriteLine("paper_id`tversion_id`tproblem")
$count = 0
$failed = 0
$totalBytes = [long]0
try {
    $connection.Open()
    $cmd = $connection.CreateCommand()
    $cmd.CommandTimeout = 0
    $top = if ($Limit -gt 0) { "TOP ($Limit) " } else { '' }
    $cmd.CommandText = "SELECT ${top}f.RefID,p.PaperId,p.VersionInfo,p.CreatedDate,p.Info1,f.Content FROM dbo.FileStructures f LEFT JOIN dbo.Papers p ON p.VersionId=f.RefID WHERE f.RefType=0 ORDER BY f.RefID"
    $reader = $cmd.ExecuteReader([System.Data.CommandBehavior]::SequentialAccess)
    try {
        while ($reader.Read()) {
            $versionId = $reader.GetInt32(0)
            $paperId = if ($reader.IsDBNull(1)) { 0 } else { $reader.GetInt32(1) }
            if ($paperId -eq 0) { continue }
            $version = if ($reader.IsDBNull(2)) { 0 } else { [int]$reader.GetValue(2) }
            $model = [Activator]::CreateInstance($paperType)
            $model.SEVersion = $version
            $model.CreatedDate = $reader.GetDateTime(3)
            $key = $keyMethod.Invoke($paperDao, @($model, $keyArgument))
            $encrypted = $reader.GetValue(5)
            try { $plain = [FastLegacyFileDecryptor]::Decrypt($cryptoType, $encrypted, $key, $version) }
            catch {
                if ($_.Exception.GetBaseException() -isnot [Security.Cryptography.CryptographicException]) { throw }
                $errorWriter.WriteLine("$paperId`t$versionId`tdecryption_failed")
                $failed++
                continue
            }
            $pdf = $plain.Length -ge 4 -and [Text.Encoding]::ASCII.GetString($plain,0,4) -eq '%PDF'
            $zip = $plain.Length -ge 2 -and $plain[0] -eq 0x50 -and $plain[1] -eq 0x4b
            if (!$pdf -and !$zip) {
                $errorWriter.WriteLine("$paperId`t$versionId`tunknown_signature")
                $failed++
                continue
            }
            $extension = if ($pdf) { '.pdf' } else { '.pptx' }
            $relative = "legacy-papers/${paperId}_${versionId}${extension}"
            $path = Join-Path $root ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $path) { throw "Output file already exists for version $versionId" }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
            [IO.File]::WriteAllBytes($path, $plain)
            $hash = [Security.Cryptography.SHA256]::Create()
            try { $sha = [BitConverter]::ToString($hash.ComputeHash($plain)).Replace('-', '').ToLowerInvariant() }
            finally { $hash.Dispose() }
            $writer.WriteLine("$paperId`t$versionId`t$relative`t$($plain.Length)`t$sha")
            $count++
            $totalBytes += $plain.Length
            if ($count % 100 -eq 0) {
                $writer.Flush()
                Write-Output "Decrypted $count files; $totalBytes bytes"
            }
            $plain = $null
            $encrypted = $null
        }
    } finally { $reader.Close() }
    $writer.Flush()
    $errorWriter.Flush()
} finally {
    $writer.Close()
    $errorWriter.Close()
    $connection.Close()
}
Write-Output "Complete: $count files; $failed failures; $totalBytes bytes; manifest $manifestPath"
