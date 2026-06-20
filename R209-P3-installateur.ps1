Clear-Host
function prompt { "> " }

Set-Location $env:USERPROFILE\Documents
$basePath = "$env:USERPROFILE\Documents\SAMBA SAE2.04 Partie 2"
$sourceDir = $PSScriptRoot # Le dossier où se trouve ce script (souvent "Téléchargements")
$zipFile = "$sourceDir\fichiersconf-docker.zip"

if (-not (Test-Path $zipFile)) {
    Write-Host "ERREUR : Le fichier $zipFile est introuvable." -ForegroundColor Red
    Write-Host "Assurez-vous que le ZIP est dans le même dossier que ce script." -ForegroundColor Red
    Exit
}

Write-Host "Demarrage de Docker" -ForegroundColor Cyan
docker desktop start   

Write-Host "Preparation de l'envirronement dees conteneurs" -ForegroundColor Cyan

Write-Host "    -creation du dossier du project" -ForegroundColor Gray
New-Item -Path $basePath -ItemType Directory -Force | Out-Null

Write-Host "    -creation de l'arborescence des volumes partagé et des backups" -ForegroundColor Gray
New-Item -Path "$basePath\server-SAMBA\samba_dperson\configuration_backup",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\atoi",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\anous",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\public",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-anous",
                "$basePath\server-SAMBA\samba_dperson\partage_stockage\amoi-atoi",
                "$basePath\ubuntu-test" -ItemType Directory -Force | Out-Null 

Write-Host "    -Extraction des fichiers necessaires" -ForegroundColor Gray
Expand-Archive -Path $zipFile -DestinationPath $basePath -Force | Out-Null
Move-Item -Path "$basePath\fichiersconf-docker\docker-compose.yml" -Destination $basePath  
Move-Item -Path "$basePath\fichiersconf-docker\Dockerfile.samba" -Destination "$basePath\server-SAMBA\samba_dperson"   
Move-Item -Path "$basePath\fichiersconf-docker\Dockerfile.ubuntutest" -Destination "$basePath\ubuntu-test"   

Set-Location $basePath



Write-Host "    -nettoyage de l'ancien environnement Docker si deja créer" -ForegroundColor Gray
docker compose down > $null 2>&1

Write-Host "Création des images et des conteneurs" -ForegroundColor Cyan
Set-Location "$basePath"
docker compose up -d --build

Write-Host "supression des poussiere" -ForegroundColor Cyan
Remove-Item "$basePath\fichiersconf-docker" -Recurse -Force > $null 2>&1

Write-Host ""
Write-Host "=== Installation terminée avec succès ! ===" -ForegroundColor Cyan
Write-Host "Vos conteneurs tournent et le dossier de travail est prêt dans Documents."