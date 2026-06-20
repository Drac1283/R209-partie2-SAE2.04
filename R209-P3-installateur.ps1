Clear-Host
function prompt { "> " }

Set-Location $env:USERPROFILE\Documents
$basePath = "$env:USERPROFILE\Documents\SAMBA SAE2.04 Partie 2"
$sourceDir = $PSScriptRoot
$zipFile = "$sourceDir\fichiersconf-docker.zip"

if (-not (Test-Path $zipFile)) {
    Write-Host "ERREUR : Le fichier $zipFile est introuvable." -ForegroundColor Red
    Write-Host "Assurez-vous que le ZIP est dans le meme dossier que ce script." -ForegroundColor Red
    Exit
}

Write-Host "Demarrage de Docker" -ForegroundColor Cyan
docker desktop start   
Start-Sleep -Seconds 10

Write-Host "Preparation de l'envirronement des conteneurs" -ForegroundColor Cyan

Write-Host "    -creation du dossier du project" -ForegroundColor Gray
New-Item -Path $basePath -ItemType Directory -Force | Out-Null
Start-Sleep -Seconds 5

Write-Host "    -creation de l'arborescence des volumes partager et des backups" -ForegroundColor Gray
New-Item -Path "$basePath\server-SAMBA\samba_dperson\configuration_backup",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\atoi",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\anous",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\public",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-anous",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-atoi",
                "$basePath\ubuntu-test" -ItemType Directory -Force | Out-Null 
Start-Sleep -Seconds 5


Write-Host "    -Extraction des fichiers necessaires" -ForegroundColor Gray
Expand-Archive -Path $zipFile -DestinationPath $basePath -Force | Out-Null
Move-Item -Path "$basePath\fichiersconf-docker\docker-compose.yml" -Destination $basePath -Force
Move-Item -Path "$basePath\fichiersconf-docker\Dockerfile.samba" -Destination "$basePath\server-SAMBA\samba_dperson" -Force 
Move-Item -Path "$basePath\fichiersconf-docker\Dockerfile.ubuntutest" -Destination "$basePath\ubuntu-test" -Force
Set-Location $basePath
Start-Sleep -Seconds 5


Write-Host "    -nettoyage de l'ancien environnement Docker si deja creer" -ForegroundColor Gray
docker compose down > $null 2>&1
Start-Sleep -Seconds 5


Write-Host "Création des images et des conteneurs" -ForegroundColor Cyan
Set-Location "$basePath"
docker compose up -d --build
Start-Sleep -Seconds 5

Write-Host "supression des poussiere" -ForegroundColor Cyan
Remove-Item "$basePath\fichiersconf-docker" -Recurse -Force > $null 2>&1
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "=== Installation terminee avec succes ! ===" -ForegroundColor Cyan
Write-Host "Vos conteneurs tournent et le dossier de travail est pret dans Documents."
Read-Host "Appuyez sur Entrée pour quitter..."   