#!/bin/bash

# === LOGGER UTILITY
# Fonctions pour afficher et enregistrer des logs

# Définir les couleurs

# Définir le fichier de log 


log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo -e "\033[0;32m [SUCCESS] $1\033[0m"
}

log_warning() {
    echo -e "\033[1;33m [WARNING] $1\033[0m"
}

log_error() {
    echo -e "\033[0;31m [ERROR] $1\033[0m"
}

log_to_file() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    mkdir -p logs

    if [[ "$1" == "INFO" ]]; then
        message=$(log_info "$2")

        echo "${timestamp} ${message}" >> logs/health_check.log
    fi

    if [[ "$1" == "ERROR" ]]; then
        message=$(log_error "$2")

        echo "${timestamp} ${message}" >> logs/health_check.log
    fi

    if [[ "$1" == "SUCCESS" ]]; then
        message=$(log_success "$2")

        echo "${timestamp} ${message}" >> logs/health_check.log
    fi

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