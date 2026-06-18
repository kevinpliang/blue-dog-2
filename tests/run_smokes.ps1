param(
    [string]$Godot = "C:\Users\kevin\Documents\Game Dev\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$env:APPDATA = Join-Path $workspace ".codex-godot\appdata"
$env:LOCALAPPDATA = Join-Path $workspace ".codex-godot\localappdata"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

if (-not (Test-Path -LiteralPath $Godot)) {
    $fallback = Join-Path $env:TEMP "godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe"
    if (Test-Path -LiteralPath $fallback) {
        $Godot = $fallback
    } else {
        throw "Godot console executable not found. Pass -Godot with the full path to Godot_v4.x-stable_win64_console.exe."
    }
}

$smokes = @(
    "res://tests/test_main_smoke.gd",
    "res://tests/test_mobile_tap.gd"
)

foreach ($smoke in $smokes) {
    & $Godot --headless --path $workspace --script $smoke
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
