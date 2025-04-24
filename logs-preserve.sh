#!/bin/bash

# =======================
#       SPINNER
# =======================
spinner() {
    local pid=$! # PID du dernier processus en arrière-plan (Le processus ou on veut afficher le spinner)
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null # Tant que le processus est en cours d'exécution
	do
        i=$(( (i+1) % 4 )) # On fait tourner le spinner
        printf "\r[%c] %s" "${spin:$i:1}" "$1" 
        sleep 0.1 
    done
    printf "\r[✔] %s\n" "$1" 
}

# =======================
#      ROOT CHECK
# =======================
if [ $EUID -ne 0 ]
then
    echo "Ce script doit être exécuté en tant qu'Administrateur"
    exit 1
fi

# =======================
#  Dossier journal check
# =======================
if [ -d "/var/log/journal" ]
then
    echo "Dossier Journal déjà présent"
else
    echo "Création du dossier de journal"
    (mkdir -p /var/log/journal) & spinner "Création de /var/log/journal"
fi

# =======================
#  Modification journald
# =======================
(sleep 1) & spinner "Configuration de journald"
(sed -i '.backup' -e 's/#Storage/Storage/' /etc/systemd/journald.conf) & spinner "Décommenter Storage"
(sed -ie '/Storage/s/auto/persistent/' /etc/systemd/journald.conf) & spinner "Passage de auto à persistent"

# =======================
#  Redémarrage service
# =======================
(systemctl restart systemd-journald.service) & spinner "Redémarrage de systemd-journald"

echo "Configurations Appliquées"
echo "La persistance des journaux se trouvera dans /var/log/journal"

# =======================
#      Redémarrage
# =======================
sleep 1
echo "La machine doit redémarrer pour terminer la configuration,"
read -p "Souhaitez-vous redémarrer maintenant ? [Y,n] " choice

if [[ $choice == "y" || $choice == "Y" ]]
then
    echo "Redémarrage de la machine"
    reboot
elif [[ $choice == "n" || $choice == "N" ]]
then
    echo "Pas de soucis, la configuration se terminera une fois la machine redémarrée"
    exit 0
else
    echo "Choix inconnu, restauration de la configuration de base"
    (rm -v -f /etc/systemd/journald.conf) & spinner "Suppression du fichier modifié"
    (mv -v /etc/systemd/journald.conf.backup /etc/systemd/journald.conf) & spinner "Restauration de la sauvegarde"
    (rm -r -f -v /var/log/journal) & spinner "Suppression du dossier journal"
    (systemctl restart systemd-journald.service) & spinner "Redémarrage du service"
    exit 2
fi
