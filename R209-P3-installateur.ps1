Clear-Host
function prompt { "> " }

$basePath  = "$env:USERPROFILE\Documents\SAMBA SAE2.04 Partie 2"
$sourceDir = $PSScriptRoot
$zipFile   = "$sourceDir\fichiersconf-docker.zip"
$extractDir = "$basePath\fichiersconf-docker"

Set-Location "$env:USERPROFILE\Documents"

Write-Host "=== Script d'installation SAE 2.04 - Samba (Windows) ===" -ForegroundColor Cyan

# 1. Verification de la presence du ZIP
if (-not (Test-Path $zipFile)) {
    Write-Host "ERREUR : Le fichier $zipFile est introuvable." -ForegroundColor Red
    Write-Host "Assurez-vous que le ZIP est dans le meme dossier que ce script." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    Exit 1
}

# 2. Verification que la commande docker existe
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERREUR : Docker n'est pas installe ou n'est pas dans le PATH." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    Exit 1
}

Write-Host "Demarrage de Docker" -ForegroundColor Cyan
docker desktop start

# Attente active jusqu'a ce que le moteur Docker reponde (max ~60s)
Write-Host "    -attente du demarrage complet du moteur Docker" -ForegroundColor Gray
$dockerReady = $false
for ($i = 0; $i -lt 12; $i++) {
    docker info > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerReady = $true
        break
    }
    Start-Sleep -Seconds 5
}

if (-not $dockerReady) {
    Write-Host "ERREUR : Docker n'a pas demarre a temps. Verifiez Docker Desktop manuellement." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    Exit 1
}

Write-Host "Preparation de l'environnement des conteneurs" -ForegroundColor Cyan

Write-Host "    -creation du dossier du projet" -ForegroundColor Gray
try {
    New-Item -Path $basePath -ItemType Directory -Force -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "ERREUR : Impossible de creer le dossier $basePath." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Exit 1
}
Start-Sleep -Seconds 5

Write-Host "    -creation de l'arborescence des volumes partages et des backups" -ForegroundColor Gray
try {
    New-Item -Path "$basePath\server-SAMBA\samba_dperson\configuration_backup",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\atoi",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\anous",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\public",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-anous",
                   "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-atoi",
                   "$basePath\ubuntu-test" -ItemType Directory -Force -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "ERREUR : Impossible de creer l'arborescence des dossiers." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Exit 1
}
Start-Sleep -Seconds 5

Write-Host "    -extraction des fichiers necessaires" -ForegroundColor Gray
try {
    Expand-Archive -Path $zipFile -DestinationPath $basePath -Force -ErrorAction Stop
}
catch {
    Write-Host "ERREUR : L'extraction du ZIP a echoue (archive corrompue ou illisible)." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Exit 1
}

# Verification que l'extraction a bien produit le dossier attendu
if (-not (Test-Path $extractDir)) {
    Write-Host "ERREUR : Le dossier '$extractDir' est absent apres extraction." -ForegroundColor Red
    Write-Host "Verifiez que le ZIP contient bien un dossier 'fichiersconf-docker' a sa racine." -ForegroundColor Red
    Exit 1
}

# Verification de la presence de chaque fichier attendu avant deplacement
$expectedFiles = @("docker-compose.yml", "Dockerfile.samba", "Dockerfile.ubuntutest")
$missing = $false
foreach ($f in $expectedFiles) {
    if (-not (Test-Path "$extractDir\$f")) {
        Write-Host "ERREUR : Le fichier '$f' est introuvable dans l'archive extraite." -ForegroundColor Red
        $missing = $true
    }
}
if ($missing) {
    Exit 1
}

try {
    Move-Item -Path "$extractDir\docker-compose.yml" -Destination $basePath -Force -ErrorAction Stop
    Move-Item -Path "$extractDir\Dockerfile.samba" -Destination "$basePath\server-SAMBA\samba_dperson" -Force -ErrorAction Stop
    Move-Item -Path "$extractDir\Dockerfile.ubuntutest" -Destination "$basePath\ubuntu-test" -Force -ErrorAction Stop
}
catch {
    Write-Host "ERREUR : Impossible de deplacer un ou plusieurs fichiers de configuration." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Exit 1
}

try {
    Set-Location $basePath -ErrorAction Stop
}
catch {
    Write-Host "ERREUR : Impossible d'acceder a $basePath." -ForegroundColor Red
    Exit 1
}
Start-Sleep -Seconds 5

Write-Host "    -nettoyage de l'ancien environnement Docker si deja cree" -ForegroundColor Gray
docker compose down > $null 2>&1
Start-Sleep -Seconds 5

Write-Host "Creation des images et des conteneurs" -ForegroundColor Cyan
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR : 'docker compose up' a echoue. Consultez les logs ci-dessus." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    Exit 1
}
Start-Sleep -Seconds 5

Write-Host "Suppression de la poussiere" -ForegroundColor Cyan
Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "=== Installation terminee avec succes ! ===" -ForegroundColor Green
Write-Host "Vos conteneurs tournent et le dossier de travail est pret dans Documents (dossier 'SAMBA SAE2.04 Partie 2')."

Read-Host "Appuyez sur Entree pour quitter..."