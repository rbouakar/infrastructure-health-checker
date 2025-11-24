#!/bin/bash

# Sourcer le logger
source utils/logger.sh

#definition du fichier
SITES="config/sites.conf"
DATA_CHECK="data/checks_history.csv"

# implémentation de la lecture des sites 
read_sites() {

    if [ ! -f "${SITES}" ];then
    log_error "Le fichier ${SITES} n'existe pas!"
    return 1
    fi

    log_info "Liste des sites configurés :"
    echo ""

    local i=0

    while IFS='|' read -r type url interval description; do
        if [[ ! -z "${type}" ]] && [[ ! "${type}" =~ ^#.* ]]; then 
            i=$((i + 1))
        
            printf "%2d. %-30s [%s]\n" "${i}" "${url}" "${type}"
            printf "Interval: %ss | %s\n" "${interval}" "${description}"
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

save_check_result() {   
    if [[ $# -ne 6 ]];then
        log_error "La fonction admet exactement 6 arguments!"
        return 1
    fi

    local type="$1"
    local url="$2"
    local status="$3"
    local status_code="$4"
    local response_time="$5"
    local error_msg="$6"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ ! -f "${DATA_CHECK}" ]];then
        touch "${DATA_CHECK}"
        echo "TIMESTAMP,TYPE,URL,STATUS,STATUS_CODE,RESPONSE_TIME,ERROR_MSG" >> "${DATA_CHECK}"
    fi

    echo "${timestamp},${type},${url},${status},${status_code},${response_time},${error_msg}" >> "${DATA_CHECK}"

}

show_history_by_url() {
    if [[ $# -ne 1 ]];then
        log_error "La fonction admet un unique argument!"
        return 1
    fi

    local url="$1"
    local up=0
    local down=0

    if [[ ! -f ${DATA_CHECK} ]];then 
        touch "${DATA_CHECK}"
        echo "TIMESTAMP,TYPE,URL,STATUS,STATUS_CODE,RESPONSE_TIME,ERROR_MSG" >> "${DATA_CHECK}"
    fi

    while IFS= read -r line;do
        IFS=',' read -r timestamp type urla status status_code response_time error_msg <<< "${line}"
        if [[ "${url}" = "${urla}" ]];then
            echo "${line}"

            if [[ "${status}" = "DOWN" ]];then
            down=$((down+1))
            else
                up=$((up+1))
            fi
        fi

    done < ${DATA_CHECK}

    local tot=$((up+down))

    if [[ ${tot} -eq 0 ]];then
        log_warning "Aucun historique pour cette URL"
    fi

    echo ""
    echo "========================================"
    echo "Résumé : ${up} UP / ${down} DOWN sur ${tot} sites"
    echo "========================================"


}

# === TESTS ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=========================================="
    echo "    TESTS DE utils/db.sh"
    echo "=========================================="
    echo ""
    
    # ==========================================
    # PARTIE 1 : TESTS DE GESTION DES SITES
    # ==========================================
    
    log_info "=== PARTIE 1 : Gestion des sites ==="
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
    
    # Test 4 : Chercher un site existant
    log_info "Test 4 : Recherche d'un site existant"
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
    
    # ==========================================
    # PARTIE 2 : TESTS DE L'HISTORIQUE CSV
    # ==========================================
    
    log_info "=== PARTIE 2 : Historique des checks ==="
    echo ""
    
    # Test 7 : Supprimer l'ancien historique pour repartir de zéro
    log_info "Test 7 : Nettoyage de l'historique"
    rm -f data/checks_history.csv
    log_success "Ancien historique supprimé"
    echo ""
    
    # Test 8 : Sauvegarder plusieurs checks
    log_info "Test 8 : Sauvegarde de plusieurs checks"
    save_check_result "HTTP" "https://google.com" "UP" "200" "0.234" ""
    save_check_result "HTTP" "https://github.com" "UP" "200" "0.456" ""
    save_check_result "HTTP" "https://google.com" "UP" "200" "0.189" ""
    save_check_result "HTTP" "https://site-down.com" "DOWN" "000" "0.123" "DNS fail"
    save_check_result "HTTP" "https://google.com" "DOWN" "000" "0.567" "Timeout"
    save_check_result "HTTP" "https://google.com" "UP" "200" "0.345" ""
    log_success "6 checks enregistrés"
    echo ""
    
    # Test 9 : Afficher l'historique de google.com
    log_info "Test 9 : Historique de https://google.com (4 checks attendus)"
    show_history_by_url "https://google.com"
    echo ""
    
    # Test 10 : Afficher l'historique de github.com
    log_info "Test 10 : Historique de https://github.com (1 check attendu)"
    show_history_by_url "https://github.com"
    echo ""
    
    # Test 11 : Afficher l'historique de site-down.com
    log_info "Test 11 : Historique de https://site-down.com (1 check DOWN attendu)"
    show_history_by_url "https://site-down.com"
    echo ""
    
    # Test 12 : Afficher l'historique d'une URL inexistante
    log_info "Test 12 : Historique d'une URL inexistante (doit afficher un warning)"
    show_history_by_url "https://url-qui-nexiste-pas.com"
    echo ""
    
    # ==========================================
    # RÉSUMÉ FINAL
    # ==========================================
    
    echo "=========================================="
    log_success "TOUS LES TESTS SONT TERMINÉS !"
    echo "=========================================="
    echo ""
    
    # Afficher les fichiers créés
    log_info "Fichiers créés pendant les tests :"
    echo "  - config/sites.conf"
    echo "  - data/checks_history.csv"
    echo ""
    log_info "Commandes pour vérifier :"
    echo "  cat config/sites.conf"
    echo "  cat data/checks_history.csv"
fi