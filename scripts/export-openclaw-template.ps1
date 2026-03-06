param(
    [string]$SourcePath = "$HOME\.openclaw\openclaw.json",
    [string]$OutputPath = "$PSScriptRoot\..\config\openclaw.template.json"
)

$ErrorActionPreference = "Stop"

function Is-SensitiveName([string]$name) {
    return $name -match '(?i)(api[_-]?key|secret|token|password|passwd|credential|auth|private[_-]?key|appsecret)'
}

function Is-SensitiveValue($value) {
    if ($value -isnot [string]) {
        return $false
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $false
    }

    return ($value -match '^(?i)(sk-|ghp_|glpat-|xox[pbar]-|AKIA|AIza|ya29\.)') -or
           ($value.Length -ge 24 -and $value -match '^[A-Za-z0-9_\-=/+\.]+$')
}

function Sanitize-Node($node, [string]$propertyName = "") {
    if ($null -eq $node) {
        return $null
    }

    if ($node -is [string] -or $node -is [ValueType]) {
        if (Is-SensitiveName $propertyName -or (Is-SensitiveValue $node)) {
            return "__REDACTED__"
        }
        return $node
    }

    if ($node -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $node.Keys) {
            $result[$key] = Sanitize-Node $node[$key] $key
        }
        return $result
    }

    if ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) {
        $result = @()
        foreach ($item in $node) {
            $result += ,(Sanitize-Node $item $propertyName)
        }
        return $result
    }

    $props = $node.PSObject.Properties
    if ($props.Count -gt 0) {
        $result = [ordered]@{}
        foreach ($prop in $props) {
            $result[$prop.Name] = Sanitize-Node $prop.Value $prop.Name
        }
        return $result
    }

    return $node
}

function Sanitize-Text([string]$text) {
    $namePattern = '(?i)"(?<k>[^"]*(?:api[_-]?key|secret|token|password|passwd|credential|auth|private[_-]?key|appsecret)[^"]*)"\s*:\s*"[^"]*"'
    $text = [System.Text.RegularExpressions.Regex]::Replace(
        $text,
        $namePattern,
        {
            param($m)
            return '"' + $m.Groups['k'].Value + '": "__REDACTED__"'
        }
    )

    $valuePattern = ':\s*"(?<v>(?:sk-|ghp_|glpat-|xox[pbar]-|AKIA|AIza|ya29\.)[^"]*)"'
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, $valuePattern, ': "__REDACTED__"')

    return $text
}

if (-not (Test-Path $SourcePath)) {
    throw "Source file not found: $SourcePath"
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$raw = Get-Content -Path $SourcePath -Raw
$serialized = $null
$mode = ""

try {
    $json = $raw | ConvertFrom-Json
    $sanitized = Sanitize-Node $json
    $serialized = $sanitized | ConvertTo-Json -Depth 100
    $mode = "json"
}
catch {
    $serialized = Sanitize-Text $raw
    $mode = "text"
}

[System.IO.File]::WriteAllText($OutputPath, $serialized, [System.Text.Encoding]::UTF8)

Write-Host "Sanitized template exported:"
Write-Host "  Source: $SourcePath"
Write-Host "  Output: $OutputPath"
Write-Host "  Mode:   $mode"
