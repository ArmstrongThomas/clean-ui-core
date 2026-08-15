[CmdletBinding()]
param(
  [string] $OutputDirectory
)

$builder = Join-Path $PSScriptRoot "..\..\scripts\build_example.ps1"
$parameters = @{ ExamplePath = $PSScriptRoot }
if ($PSBoundParameters.ContainsKey("OutputDirectory")) {
  $parameters.OutputDirectory = $OutputDirectory
}

try {
  & $builder @parameters
  if (-not $?) { exit 1 }
} catch {
  Write-Error $_
  exit 1
}
