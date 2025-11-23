#!/bin/bash

#sourcer les utilitaires 
source scripts/http_checker.sh
source utils/db.sh
source utils/logger.sh

SITES="config/sites.conf"
LOGS="logs/health_check.log"

show_menu() {
    echo "========================================"
    echo "  INFRASTRUCTURE HEALTH CHECKER"
    echo "========================================"
    echo ""
    echo "1. Lister tous les sites configurés"
    echo "2. Ajouter un nouveau site"
    echo "3. Supprimer un site"
    echo "4. Vérifier un site spécifique"
    echo "5. Vérifier tous les sites HTTP"
    echo "6. Voir les derniers logs"
    echo "7. Quitter"
    echo ""

}

option_1_list_sites() {
    clear
    echo "[Option 1 sélectionnée]"
    read_sites
    read -p "Appuyez sur Entrée pour continuer..."
}

option_2_add_site() {
    clear
    echo "[Option 2 sélectionnée]"
    echo ""
    echo "=== Ajouter un nouveau site ==="
    echo ""
    read -p "Entrez le type de monitoring (HTTP/PING/SSH/PORT) : " type
    read -p "Entrez l'URL ou l'adresse : " adresse
    read -p "Entrez l'intervalle de vérification (en secondes) : " intervalle
    read -p "Entrez une déscription : " description

    add_site "$type" "$adresse" "$intervalle" "$description"

    echo ""
    read -p "Appuyez sur Entrée pour continuer..."

}

option_3_remove_site() {
    clear
    echo "[Option 3 sélectionnée]"
    echo ""
    read_sites 
    echo ''
    read -p "Entrez l'URL du site à supprimer : " url
    read -p "Etes-vous sûr de vouloir supprimer ce site ? (o/N)" reponse

    if [[ "${reponse}" = "o" ]];then    
        remove_site "${url}"
    else
        echo "Annulation de la suppression de ${url}"
    fi

    echo ""
    read -p "Appuyez sur Entrée pour continuer"

}

option_4_check_site() {
    clear
    echo "[Option 4 sélectionnée]"
    echo ""
    echo "=== Vérifier un site ==="
    echo ""
    read -p "Entrez l'URL du site : " url
    echo ""

    check_http "${url}"

   read -p "Appuyez sur Entrée pour continuer..."

}

option_5_all_sites() {
    clear
    echo "[Option 5 sélectionnée]"
    echo ""
    echo "=== Vérification de tous les sites HTTP ==="
    echo ""
    
    local up=0
    local down=0

    while IFS= read -r type url intervalle description;do
            [[ -z "${type}" ]] && continue
            [[ "${type}" =~ ^#.* ]] && continue

        if [[ "${type}" = "HTTP" ]];then
            check_http "${url}"

            if [[ $? -eq 0 ]];then
                up=$((up+1))
            else
                down=$((down+1))
            fi
        fi

    done < ${SITES}

    local tot=$((up + down))

    echo "========================================"
    echo "Résumé : ${up} UP / ${down} DOWN sur ${tot} sites"
    echo "========================================"

    read -p "Appuyez sur Entrée pour continuer..."

}

option_6_log() {
    clear
    echo "[Option 6 sélectionnée]"
    echo ""
    echo "=== Derniers logs (20 lignes) ==="
    echo ""
    tail -n 20 "${LOGS}"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."

}

option_7_quitter() {
    clear
    echo "[Option 7 sélectionnée]"
    echo ""
    log_info "Merci d'avoir utilisé Infrastructure Health Checker !"
    echo "Au revoir"

    exit 0

}

main() {
    while true;do
        show_menu
        read -p "Votre choix : " choix

        case ${choix} in
            1) option_1_list_sites;;
            2) option_2_add_site;;
            3) option_3_remove_site;;
            4) option_4_check_site;;
            5) option_5_all_sites;;
            6) option_6_log;;
            7) option_7_quitter;;
            *) log_error "Option invalide" ;;
        esac
    done
}

main


