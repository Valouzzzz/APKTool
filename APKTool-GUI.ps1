
Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="APKTool GUI" Height="400" Width="600">
    <StackPanel Margin="10">
        <TextBlock FontSize="16" FontWeight="Bold" Text="Outil APKTool pour Windows" Margin="0,0,0,10"/>
        <Button Name="btnInstall" Content="1️⃣ Installer apktool + Java" Height="40" Margin="0,0,0,10"/>
        <Button Name="btnDecompile" Content="2️⃣ Décompiler un APK" Height="40" Margin="0,0,0,10"/>
        <Button Name="btnRecompile" Content="3️⃣ Recompiler et signer" Height="40" Margin="0,0,0,10"/>
        <Button Name="btnQuit" Content="❌ Quitter" Height="40" />
    </StackPanel>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$btnInstall = $window.FindName("btnInstall")
$btnDecompile = $window.FindName("btnDecompile")
$btnRecompile = $window.FindName("btnRecompile")
$btnQuit = $window.FindName("btnQuit")

$btnInstall.Add_Click({
    Start-Process powershell -Verb RunAs -ArgumentList '-Command', @'
# === Dossier d'installation ===
$apktoolPath = "C:\apktools"
$jdkPath = "C:\Java"

# === Crée les dossiers ===
New-Item -ItemType Directory -Force -Path $apktoolPath | Out-Null
New-Item -ItemType Directory -Force -Path $jdkPath | Out-Null

# === Télécharge apktool.jar et apktool.bat ===
Invoke-WebRequest -Uri "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar" -OutFile "$apktoolPath\apktool.jar"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/windows/apktool.bat" -OutFile "$apktoolPath\apktool.bat"

# === Télécharge OpenJDK 17 ===
Invoke-WebRequest -Uri "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" -OutFile "$jdkPath\jdk.zip"
Expand-Archive -Path "$jdkPath\jdk.zip" -DestinationPath "$jdkPath"
Remove-Item "$jdkPath\jdk.zip"

# === Ajout au PATH (temporairement) ===
$jdkFolder = Get-ChildItem -Directory "$jdkPath" | Select-Object -First 1
$env:PATH += ";$apktoolPath;$($jdkFolder.FullName)\bin"
'@
})

$btnDecompile.Add_Click({
    Start-Process powershell -Verb RunAs -ArgumentList '-Command', @'
$apkName = Read-Host "Nom du fichier APK à décompiler"
$apkNameSansExt = [System.IO.Path]::GetFileNameWithoutExtension($apkName)
$folder = "$apkNameSansExt"
apktool d $apkName -o $folder -f
Read-Host "Modification manuelle : appuie sur Entrée pour continuer"
'@
})

$btnRecompile.Add_Click({
    Start-Process powershell -Verb RunAs -ArgumentList '-Command', @'
$apkName = Read-Host "Nom du fichier APK de base"
$apkNameSansExt = [System.IO.Path]::GetFileNameWithoutExtension($apkName)
$apkUnsigned = "$apkNameSansExt-unsigned.apk"
$apkSigned = "$apkNameSansExt-signed.apk"
$folder = "$apkNameSansExt"
$keystore = "my-release-key.keystore"
$alias = "monalias"
$pwd = "motdepasse"

apktool b $folder -o $apkUnsigned

if (-not (Test-Path $keystore)) {
    keytool -genkeypair -v -keystore $keystore -alias $alias -keyalg RSA -keysize 2048 -validity 10000 -storepass $pwd -keypass $pwd -dname "CN=User, OU=APK, O=ORG, L=City, S=State, C=FR"
}

jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $keystore -storepass $pwd -keypass $pwd $apkUnsigned $alias
Rename-Item $apkUnsigned $apkSigned -Force
'@
})

$btnQuit.Add_Click({ $window.Close() })

$window.ShowDialog() | Out-Null
