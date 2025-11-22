#!/bin/bash

# Sourcer le logger
source utils/logger.sh

#definition du fichier
SITES="config/sites.conf"

# implémentation de la lecture des sites 
read_sites() {

    if [ ! -f "${SITES}" ];then
    log_error "Le fichier ${SITES} n'existe pas!"
    return 1
    fi

    echo "=== Sites configurés ==="
    echo ""
    local i=0

    while IFS= read -r type url interval description; do
        if [[ ! -z "${type}" ]] && [[ ! "${type}" =~ ^#.* ]]; then 
            i=$((i + 1))
        
            printf "  %2d. %-30s [%s]\n" "${i}" "${url}" "${type}"
            printf "      Interval: %ss | %s\n" "${interval}" "${description}"
            echo ""
        fi

    done < "${SITES}"

    if [ ${i} -eq 0 ];then
        echo "Aucun site configuré"
    else
        echo "Total : ${i} site(s) configuré(s)"
    fi
}

#implémentation de l'ajout de site
add_site() {
    if [[ $# -ne 4 ]]; then
        echo "Erreur: Il faut entrer exactement 4 arguments"
        return 1
    fi

    local type="$1"
    local url="$2"
    local interval="$3"
    local description="$4"

    mkdir -p config
    touch "${SITES}"

    # Vérifier les doublons
    if grep -q "${url}" "${SITES}" 2>/dev/null; then
        log_warning "Le site existe déjà : ${url}"
        return 1
    fi

    echo "${type}|${url}|${interval}|${description}" >> "${SITES}"

}

# implémentation de la suppression de site à partir de l'url
remove_site() {
    if [[ ! -f "${SITES}" ]]; then
        log_error "Le fichier ${SITES} n'existe pas!"
        return 1
    fi

    if [[ $# -ne 1 ]]; then
        log_error "remove_site attend 1 argument : URL"
        return 1
    fi

    local url="$1"

    if ! grep -q "${url}" "${SITES}"; then
        log_error "L'URL n'a pas été trouvée : ${url}"
        return 1
    fi

    # Supprimer la ligne (méthode portable)
    grep -v "${url}" "${SITES}" > "${SITES}.tmp"
    mv "${SITES}.tmp" "${SITES}"
    
    log_success "Site supprimé : ${url}"
}

get_site_by_url() {
    if [ ! -f "${SITES}" ];then
    log_error "Le fichier ${SITES} n'existe pas!"
    return 1
    fi

    if [[ $# -ne 1 ]];then
        echo "Error: la fonction n'admet qu'un seul argument!"
        return 1
    fi

    local url="$1"

    grep "${url}" "${SITES}"
    local _status=$?
    return ${_status}
 
}

# === TESTS ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=========================================="
    echo "    TESTS DE utils/db.sh"
    echo "=========================================="
    echo ""
    
    # Test 1 : Ajouter des sites
    log_info "Test 1 : Ajout de sites"
    add_site HTTP https://google.com 60 "Google Search"
    add_site HTTP https://github.com 120 "GitHub Platform"
    add_site HTTP https://stackoverflow.com 180 "Stack Overflow"
    echo ""
    
    # Test 2 : Essayer d'ajouter un doublon
    log_info "Test 2 : Tentative d'ajout d'un doublon (doit échouer)"
    add_site HTTP https://google.com 60 "Google Search (doublon)"
    echo ""
    
    # Test 3 : Lire tous les sites
    log_info "Test 3 : Lecture de tous les sites"
    read_sites
    echo ""
    
    # Test 4 : Chercher un site inexistant
    log_info "Test 4 : Recherche d'un site"
    get_site_by_url https://stackoverflow.com
    echo ""
    
    # Test 5 : Supprimer un site
    log_info "Test 5 : Suppression d'un site"
    remove_site https://stackoverflow.com
    echo ""
    
    # Test 6 : Vérifier la suppression
    log_info "Test 6 : Vérification après suppression"
    read_sites
    echo ""
    
    echo "=========================================="
    log_success "TOUS LES TESTS SONT TERMINÉS !"
    echo "=========================================="
    echo ""
    log_info "Vérifiez le fichier : cat config/sites.conf"
fi
