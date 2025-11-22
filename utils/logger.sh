#!/bin/bash

# === LOGGER UTILITY
# Fonctions pour afficher et enregistrer des logs

# Définir les couleurs
VERT='\033[0;32m'
JAUNE='\033[1;33m'
ROUGE='\033[0;31m'
NC='\033[0m'

# Définir le fichier de log 

LOG_FILE="logs/health_check.log"


log_info() {
    local message="$1"
    echo "[INFO] ${message}"
    log_to_file "INFO" "${message}" 
}

log_success() {
    local message="$1"
    echo -e "${VERT}[SUCCESS] ${message}${NC}"
    log_to_file "SUCCESS" "${message}"
}

log_warning() {
    local message="$1"
    echo -e "${JAUNE}[WARNING] ${message}${NC}"
    log_to_file "[WARNING]" "${message}"
}

log_error() {
    local message="$1"
    echo -e "${ROUGE}[ERROR] ${message}${NC}"
    log_to_file "[ERROR]" "${message}"
}

log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    mkdir -p logs

    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"

}

# === TESTS ===
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       echo "=== Test du logger ==="
       log_info "Ceci est un message d'information"
       log_success "Ceci est un succès"
       log_warning "Ceci est un avertissement"
       log_error "Ceci est une erreur"
       echo "Vérifiez le fichier logs/health_check.log"
   fi