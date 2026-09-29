param(
    [string]$OldBackend = 'C:\Users\Administrator\Desktop\Boardpac\wcf\bin',
    [string]$SqlServer = 'localhost',
    [string]$Database = 'BoardPAC',
    [string]$Output = 'target/legacy-activity-text.tsv',
    [string]$Errors = 'target/legacy-activity-text-errors.tsv'
)

$ErrorActionPreference = 'Stop'
$dao = [Reflection.Assembly]::LoadFrom((Join-Path $OldBackend 'BoardPACDAO.dll'))
$util = [Reflection.Assembly]::LoadFrom((Join-Path $OldBackend 'BoardAppUtil.dll'))
$baseType = $dao.GetType('BoardPACDAO.Base.BaseDAO')
$base = [Activator]::CreateInstance($baseType)
$flags = [Reflection.BindingFlags]'Public,NonPublic,Instance'
$key = $baseType.GetField('details', $flags).GetValue($base)
$iv = $baseType.GetField('iVector', $flags).GetValue($base)
$decrypt = $util.GetType('BoardAppUtil.Security.CryptoServices').GetMethod('DecryptString')
$outPath = [IO.Path]::GetFullPath($Output)
$errorPath = [IO.Path]::GetFullPath($Errors)
if ((Test-Path -LiteralPath $outPath) -or (Test-Path -LiteralPath $errorPath)) {
    throw 'Activity text output already exists. Remove it explicitly before repeating the export.'
}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outPath)) | Out-Null
$connection = New-Object System.Data.SqlClient.SqlConnection("Server=$SqlServer;Database=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True")
$writer = New-Object IO.StreamWriter($outPath, $false, (New-Object Text.UTF8Encoding($false)))
$errorWriter = New-Object IO.StreamWriter($errorPath, $false, (New-Object Text.UTF8Encoding($false)))
try {
    $connection.Open()
    foreach ($spec in @(
        @('comment','SELECT CommentId, Comment FROM dbo.Comments'),
        @('meeting_note','SELECT MeetingId * 1000000 + CustomUserId, MeetingNote FROM dbo.MeetingPresences WHERE MeetingNote IS NOT NULL AND DATALENGTH(MeetingNote) > 0'),
        @('approval_comment','SELECT CAST(PaperId AS bigint) * 1000000 + CustomUserId, ApprovalComment FROM dbo.PaperDecisionViews WHERE ApprovalComment IS NOT NULL AND DATALENGTH(ApprovalComment) > 0')
    )) {
        $count = 0
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = $spec[1]
        $reader = $cmd.ExecuteReader()
        try {
            while ($reader.Read()) {
                $id = [long]$reader.GetValue(0)
                try {
                    $plain = $decrypt.Invoke($null, @($reader.GetString(1), $key, $iv, $false, $false))
                    if ([string]::IsNullOrWhiteSpace($plain)) { throw 'empty result' }
                    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($plain))
                    $writer.WriteLine("$($spec[0])`t$id`t$encoded")
                    $count++
                } catch {
                    $errorWriter.WriteLine("$($spec[0])`t$id`tdecryption_failed")
                }
            }
        } finally { $reader.Close() }
        Write-Output "$($spec[0]): $count decrypted records"
    }
} finally {
    $writer.Close()
    $errorWriter.Close()
    $connection.Close()
}
Write-Output "Activity export complete: $outPath"
