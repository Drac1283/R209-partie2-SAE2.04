#!/bin/bash


CYAN='\033[0;36m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
RED='\033[0;31m'
NC='\033[0m'

clear

echo -e "${CYAN}=== Script d'installation SAÉ 2.04 - Samba (Linux) ===${NC}"


SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_PATH="$HOME/Documents/SAMBA SAE2.04 Partie 2"
ZIP_FILE="$SOURCE_DIR/fichiersconf-docker.zip"
EXTRACT_DIR="$BASE_PATH/fichiersconf-docker"

# 1. Vérification de la présence du ZIP
if [ ! -f "$ZIP_FILE" ]; then
    echo -e "${RED}ERREUR : Le fichier $ZIP_FILE est introuvable.${NC}"
    echo -e "${RED}Assurez-vous que le ZIP est dans le même dossier que ce script.${NC}"
    exit 1
fi

# 2. Vérification de l'outil unzip
if ! command -v unzip &> /dev/null; then
    echo -e "${RED}ERREUR : L'outil 'unzip' n'est pas installé.${NC}"
    echo -e "Installez-le en tapant : sudo apt install unzip"
    exit 1
fi

# 3. Vérification de l'outil docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERREUR : Docker n'est pas installé ou n'est pas dans le PATH.${NC}"
    exit 1
fi

echo -e "${CYAN}Vérification du démon Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker ne semble pas tourner ou nécessite 'sudo'. Lancez 'sudo systemctl start docker'.${NC}"
    exit 1
fi
sleep 1

echo -e "${CYAN}Préparation de l'environnement des conteneurs${NC}"

echo -e "${GRAY}    - Création du dossier du projet${NC}"
if ! mkdir -p "$BASE_PATH"; then
    echo -e "${RED}ERREUR : Impossible de créer le dossier $BASE_PATH.${NC}"
    exit 1
fi

echo -e "${GRAY}    - Création de l'arborescence des volumes partagés et des backups${NC}"
if ! mkdir -p "$BASE_PATH/server-SAMBA/samba_dperson/configuration_backup" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/amoi" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/atoi" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/anous" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/public" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/amoi-anous" \
         "$BASE_PATH/server-SAMBA/samba_dperson/partage_stockage/amoi-atoi" \
         "$BASE_PATH/ubuntu-test"; then
    echo -e "${RED}ERREUR : Impossible de créer l'arborescence des dossiers.${NC}"
    exit 1
fi

echo -e "${GRAY}    - Extraction des fichiers nécessaires${NC}"
if ! unzip -o "$ZIP_FILE" -d "$BASE_PATH" > /dev/null 2>&1; then
    echo -e "${RED}ERREUR : L'extraction du ZIP a échoué (archive corrompue ou illisible).${NC}"
    exit 1
fi

# Vérification que l'extraction a bien produit le dossier attendu
if [ ! -d "$EXTRACT_DIR" ]; then
    echo -e "${RED}ERREUR : Le dossier '$EXTRACT_DIR' est absent après extraction.${NC}"
    echo -e "${RED}Vérifiez que le ZIP contient bien un dossier 'fichiersconf-docker' à sa racine.${NC}"
    exit 1
fi

# Vérification de la présence de chaque fichier attendu avant déplacement
MISSING=0
for f in "docker-compose.yml" "Dockerfile.samba" "Dockerfile.ubuntutest"; do
    if [ ! -f "$EXTRACT_DIR/$f" ]; then
        echo -e "${RED}ERREUR : Le fichier '$f' est introuvable dans l'archive extraite.${NC}"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    exit 1
fi

# Déplacement des fichiers (mv = move)
if ! mv -f "$EXTRACT_DIR/docker-compose.yml" "$BASE_PATH/"; then
    echo -e "${RED}ERREUR : Impossible de déplacer docker-compose.yml.${NC}"
    exit 1
fi
if ! mv -f "$EXTRACT_DIR/Dockerfile.samba" "$BASE_PATH/server-SAMBA/samba_dperson/"; then
    echo -e "${RED}ERREUR : Impossible de déplacer Dockerfile.samba.${NC}"
    exit 1
fi
if ! mv -f "$EXTRACT_DIR/Dockerfile.ubuntutest" "$BASE_PATH/ubuntu-test/"; then
    echo -e "${RED}ERREUR : Impossible de déplacer Dockerfile.ubuntutest.${NC}"
    exit 1
fi

cd "$BASE_PATH" || { echo -e "${RED}ERREUR : Impossible d'accéder à $BASE_PATH.${NC}"; exit 1; }

echo -e "${GRAY}    - Nettoyage de l'ancien environnement Docker si déjà créé${NC}"
docker compose down > /dev/null 2>&1
sleep 1

echo -e "${CYAN}Création des images et des conteneurs${NC}"
if ! docker compose up -d --build; then
    echo -e "${RED}ERREUR : 'docker compose up' a échoué. Consultez les logs ci-dessus.${NC}"
    exit 1
fi

echo -e "${CYAN}Suppression de la poussière${NC}"
rm -rf "$EXTRACT_DIR" > /dev/null 2>&1

echo ""
echo -e "${GREEN}=== Installation terminée avec succès ! ===${NC}"
echo -e "Vos conteneurs tournent et le dossier de travail est prêt dans $HOME/Documents."

read -p "Appuyez sur Entrée pour quitter..."