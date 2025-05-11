$exeName = "hello.exe"
$sourcePath = Join-Path -Path (Get-Location) -ChildPath $exeName
$destDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$destPath = Join-Path -Path $destDir -ChildPath $exeName

if (-Not (Test-Path $sourcePath)) {
    Write-Error "Executable '$exeName' not found in current directory."
    exit 1
}

Copy-Item -Path $sourcePath -Destination $destPath -Force
Write-Output "Installed '$exeName' to '$destDir'. It should now be accessible globally."

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")

