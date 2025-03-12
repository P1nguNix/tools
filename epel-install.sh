#!/bin/bash
# Crée par Paul SCHMITT

if [ $EUID -ne 0 ]
then
	echo "Ce programme doit être exécuté avec des privilèges administrateurs"
	exit 1
fi
releasever=$(source /etc/os-release && echo ${VERSION_ID%%.*}) # Permet de fecth depuis un fichier système la version majeure de RedHat
epelTarget="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$releasever.noarch.rpm" # Adresse distante de epel (Extra Package for Enterprise Linux)
dnf install -y $epelTarget # Install de EPEL
dnf config-manager --set-enabled epel # command line pour s'assurer qu'EPEL est activé
if [[ -z $(dnf repolist | grep epel) ]]
then
	echo "EPEL n'a pas pu être trouvé dans la liste de dépôt"
	exit 1
fi
/usr/bin/crb enable # EPEL requiert pour pas mal de paquets d'avoir Linux CodeReady Builder de disponible, "crb enable" permet de l'activer
echo "Extra Packages for Enterprise Linux $releasever et CodeReady Builder pour Linux ont été installés
