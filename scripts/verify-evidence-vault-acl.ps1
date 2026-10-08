# Read-only EAGLT02 laboratory ACL verification. NEVER changes ACLs.
# This report is NOT approval for live applicant uploads or file custody.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Root
)
$ErrorActionPreference = 'Stop'
function Deny([string]$Reason) {
  [Console]::Error.WriteLine("SEALED_VAULT_ACL_DENIED: " + $Reason)
  exit 1
}
try {
  if (-not [System.IO.Path]::IsPathRooted($Root) -or $Root.StartsWith('\\')) {
    Deny 'Absolute local drive path required'
  }
  $full = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
  if (-not $item.PSIsContainer -or (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)) {
    Deny 'Directory required; reparse point not permitted'
  }
  if ($full -notmatch '^[A-Za-z]:\\') { Deny 'Local drive letter required' }
  $volume = Get-Volume -DriveLetter $full.Substring(0,1) -ErrorAction Stop
  if ($volume.FileSystem -ne 'NTFS') { Deny 'NTFS volume required' }
  $acl = Get-Acl -LiteralPath $full -ErrorAction Stop
  if (-not $acl.AreAccessRulesProtected) { Deny 'Inheritance must be disabled' }
  $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  $systemSid = 'S-1-5-18'
  $expected = @($currentSid, $systemSid)
  $seen = @{}
  foreach ($ace in $acl.Access) {
    $sid = $ace.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
    if ($ace.IsInherited -or $ace.AccessControlType -ne 'Allow' -or
        $expected -notcontains $sid) {
      Deny 'Inherited, denied, or non-service principal access present'
    }
    $fullRights = [System.Security.AccessControl.FileSystemRights]::FullControl
    if (($ace.FileSystemRights -band $fullRights) -ne $fullRights) {
      Deny 'Expected account lacks full file custody control'
    }
    $seen[$sid] = $true
  }
  if ($seen.Count -ne 2 -or -not $seen.ContainsKey($currentSid) -or
      -not $seen.ContainsKey($systemSid)) {
    Deny 'SYSTEM and current service account must be the only explicit grants'
  }
  # This is a local, observed ACL state. It is NOT a negative-access logon test.
  Write-Output 'EVIDENCE_VAULT_ACL_LAB_PASS'
  Write-Output ('Path: ' + $full)
  Write-Output ('Filesystem: ' + $volume.FileSystem)
  Write-Output 'Inheritance: disabled'
  Write-Output 'Explicit allowed identities: current EAGLT02 user and SYSTEM only'
  Write-Output 'Live uploads permitted: NO'
} catch {
  Deny 'ACL verification could not be completed'
}
