#!/bin/bash
source utils/logger.sh
source utils/db.sh

check_http() {
    if [[ $# -ne 1 ]];then
        echo "La fonction admet un unique argument!"
        return 1
    fi

    local url="$1"

    log_info "Vérification de ${url}"

    # Récupérer status ET temps en une seule fois
    response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" -L --max-time 10 --connect-timeout 5 "${url}" 2>&1)

    # Découper
    IFS='|' read -r status_code response_time <<< "${response}"

    if ! [[ "${status_code}" =~ ^[0-9]+$ ]];then
        save_check_result "HTTP" "${url}" "DOWN" "${status_code}" "${response_time}" "network fail"
        log_error "Site DOWN - Status: ${status_code} - Erreur: Erreur réseau"
        return 1
    fi

    if [[ ${status_code} -eq 0 ]]; then
        save_check_result "HTTP" "${url}" "DOWN" "${status_code}" "${response_time}" "network fail"
        log_error "Site DOWN - Status: 000 - Erreur réseau"
        return 1
    fi

    if [[ "${status_code}" -ge 200 ]] && [[ "${status_code}" -lt 400 ]];then
        save_check_result "HTTP" "${url}" "UP" "${status_code}" "${response_time}" ""
        if (( $(echo "${response_time} > 3" | bc -l) )); then
            log_warning "Site UP mais lent - Status: ${status_code} - Temps: ${response_time}s"
        else
            log_success "Site UP - Status: ${status_code} - Temps: ${response_time}s"
        fi
        return 0
    fi

    if [[ "${status_code}" -gt 399 ]] && [[ "${status_code}" -lt 500 ]]; then
        save_check_result "HTTP" "${url}" "DOWN" "${status_code}" "${response_time}" "client fail"
        log_error "Site DOWN - Status: ${status_code} - Erreur: Erreur client"
        return 1
    fi

    if [[ "${status_code}" -gt 499 ]] && [[ "${status_code}" -lt 600 ]]; then
        save_check_result "HTTP" "${url}" "DOWN" "${status_code}" "${response_time}" "server fail"
        log_error "Site DOWN - Status: ${status_code} - Erreur: Erreur serveur"
        return 1
    fi

}

# === TESTS ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=========================================="
    echo "    TESTS DU HTTP CHECKER"
    echo "=========================================="
    echo ""
    
    # Test 1 : Site qui marche
    log_info "Test 1 : Site qui fonctionne (google.com)"
    check_http "https://google.com"
    echo ""
    
    # Test 2 : Autre site qui marche
    log_info "Test 2 : GitHub"
    check_http "https://github.com"
    echo ""
    
    # Test 3 : 404 Not Found
    log_info "Test 3 : Erreur 404"
    check_http "https://google.com/page-inexistante-xyz"
    echo ""
    
    # Test 4 : Site inexistant (DNS fail)
    log_info "Test 4 : DNS fail (site inexistant)"
    check_http "https://site-totalement-inexistant-xyz123.com"
    echo ""
    
    # Test 5 : URL invalide (connexion refusée)
    log_info "Test 5 : Connexion refusée"
    check_http "http://localhost:9999"
    echo ""
    
    # Test 6 : Stack Overflow
    log_info "Test 6 : Stack Overflow"
    check_http "https://stackoverflow.com"
    echo ""
    
    echo "=========================================="
    log_success "TOUS LES TESTS SONT TERMINÉS !"
    echo "=========================================="
fi