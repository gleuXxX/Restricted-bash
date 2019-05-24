#!/bin/bash

LIVDIR=$(pwd)
INSTALL_DIR=/opt/restricted-bash
CONF_DIR=/etc/restricted-bash
BASH_VERSION=bash-4.4
EXEC_CMD=execute_cmd.c
GES_CMD=ges_commandes_gid.sh
USER=root
LISTE_FICS_TXT=liste_fics_txt.txt
LISTE_FICS_SH=liste_fics_sh.txt
GID_MIN=1000


#------------------------------------------------------------
# Affiche un ecran d'aide sur la sortie standard
#------------------------------------------------------------
function show_usage
{
cat << END_USAGE
Usage :
        $(basename $0) --help

Description :
        Installe Le composant Security for BASH.

Parametres :     
        --help         : Affiche cet ecran d'aide.

Exemple :
        $(basename $0) --help
        
END_USAGE
}


#------------------------------------------------------------
# Corps principal du script
#
#------------------------------------------------------------

# Verification des parametres
if [ "$1" = "--help" ]
then
	show_usage >&2
	exit 1
fi

# Verifie que l'on se trouve bien avec le user root
curUser=`whoami`
if [ "$curUser" != "${USER}" ]
then
	echo "Erreur : ce script doit être lancé avec l'utilisateur ${USER}"
	exit 1
fi
 

echo ""
echo -e "Installation du composant Security for BASH"
echo -e "--------------------------------"
echo ""

echo ""
echo -e "Verification / Creation environnement"
echo -e "--------------------------------"
echo ""


numgid=""
echo -n "Valeur minimale du GID pour lequel la restriction du bash sera faite (${GID_MIN}) : "
read numgid
echo ""
checknum=`echo "$numgid" | grep -E ^\-?[0-9]*\.?[0-9]+$`
if [ "$checknum" = '' ]; then    
  # ce n est pas un numeric
	echo "Erreur : le GID minimal n est pas un numeric ! : $numgid"
	exit 1
fi

if [ ! -d ${INSTALL_DIR}/save ]
then
	echo "creation env : $INSTALL_DIR"
	mkdir -p ${INSTALL_DIR}/save
	chmod -R 700 ${INSTALL_DIR}
	chown -R root:root ${INSTALL_DIR}
else
	echo "Mise a jour env : ${INSTALL_DIR}"
	chmod -R 700 ${INSTALL_DIR}
	chown -R root:root ${INSTALL_DIR}
fi

if [ ! -d ${CONF_DIR} ]
then
	echo "creation env : ${CONF_DIR}"
	mkdir -p ${CONF_DIR}
	chmod -R 755 ${CONF_DIR}
	chown -R root:root ${CONF_DIR}
else
	echo "Mise a jour env : ${CONF_DIR}"
	chmod -R 755 ${CONF_DIR}
	chown -R root:root ${CONF_DIR}
fi

echo ""
echo -e "Sauvegarde du Bash courant"
echo -e "--------------------------------"
echo ""
NOW=$(date +"%Y%m%d-%H%M%S")
BASH_ORIG=$(which bash)
cp -p ${BASH_ORIG} ${INSTALL_DIR}/save/bash_${NOW}
if [ $? -ne 0 ]
then
	echo "Erreur sur la copie de sauvegarde"
	exit 1
fi

echo ""
echo -e "Installation du nouveau Bash"
echo -e "--------------------------------"
echo ""
if [ ! -f ${LIVDIR}/${BASH_VERSION}.tar.gz ]
then 
	echo "fichier ${BASH_VERSION}.tar.gz : introuvable !"
	exit 1
fi
	
cp ${LIVDIR}/${BASH_VERSION}.tar.gz ${INSTALL_DIR}
cd ${INSTALL_DIR}

#on decompresse l'archive qui sera modifiee
tar xzf ./${BASH_VERSION}.tar.gz
if [ $? -ne 0 ]
then
	echo "Erreur sur le detar de ${BASH_VERSION}.tar.gz"
	exit 1
fi

if [ ! -d ${INSTALL_DIR}/${BASH_VERSION} ]
then
	echo "repertoire ${INSTALL_DIR}/${BASH_VERSION} : introuvable !"
	exit 1
fi

#modifie les sources pour ajouter le MIN_GID
NB=0
NB=`grep -c "#define GID_MIN" $LIVDIR/${EXEC_CMD}`
if [ $NB -ne 1 ]
then
	echo "Erreur : probleme de mise a jour du MIN_GID dans ${EXEC_CMD} !"
	exit 1
fi
sed -i "s/#define GID_MIN.*/#define GID_MIN $numgid/g" $LIVDIR/${EXEC_CMD}
RET=$?
if [ $RET -ne 0 ]
then
	echo "Erreur : probleme de mise a jour du MIN_GID dans ${EXEC_CMD} !"
	exit 1
fi

cp ${LIVDIR}/${EXEC_CMD} ${INSTALL_DIR}/${BASH_VERSION}
# les modifications effectuees dans le fichier execute_cmd.c sont commentées par /*CNAMTS*/

if [ ! -f ${INSTALL_DIR}/${BASH_VERSION}/${EXEC_CMD} ]
then
	echo "fichier  ${INSTALL_DIR}/${BASH_VERSION}/${EXEC_CMD} : introuvable !"
	exit 1
fi


echo ""
echo -e "configure make ..."
echo -e "--------------------------------"
echo ""

cd ${INSTALL_DIR}/${BASH_VERSION}
./configure
make

echo ""
echo -e "remplacement du bash d'origine"
echo -e "--------------------------------"
echo ""
#on remplace le bash d'origine
cp -pf ${INSTALL_DIR}/${BASH_VERSION}/bash ${BASH_ORIG}

echo ""
echo -e "remplacement du lien du sh"
echo -e "--------------------------------"
echo ""
#on fait le lien avec sh 
SH_ORIG=$(which sh)
SH_DIR=$(dirname ${SH_ORIG})
BASH_DIR=$(dirname ${BASH_ORIG})
cd ${SH_DIR}
if [ ${SH_DIR} = ${BASH_DIR} ]
then
	ln -sf bash sh
else
	ls -sf ${BASH_ORIG} sh
fi
if [ ! -L ${SH_DIR}/sh ]
then
	echo "lien sh sur le bash est KO!"
	exit 1
fi	

echo ""
echo -e "Recopie des fichiers de Commandes Autorisees "
echo -e "--------------------------------"
echo ""
echo "format : <gid>.txt"
echo "liste des commandes autorisees avec chemin complet et absolu"
echo "A positionner dans ${CONF_DIR}"
echo "via ${INSTALL_DIR}/${GES_CMD}"

#on copie les fichiers de conf txt et sh
while read fic
do
	cp -f "$LIVDIR/$fic" ${CONF_DIR}
done < $LIVDIR/${LISTE_FICS_TXT}

while read fic
do
	cp -f "$LIVDIR/$fic" ${INSTALL_DIR}
	chmod +x "${INSTALL_DIR}/${fic}"
done < $LIVDIR/${LISTE_FICS_SH}

sed -i "s/#define GID_MIN.*/#define GID_MIN $numgid/g" ${INSTALL_DIR}/${GES_CMD}
RET=$?
if [ $RET -ne 0 ]
then
	echo "Erreur : probleme de mise a jour du MIN_GID dans ${INSTALL_DIR}/${GES_CMD}!"
fi

echo ""
echo -e "Suppressions des sources"
echo -e "--------------------------------"
echo ""
while read fic
do
	rm -f "$LIVDIR/$fic"
done < $LIVDIR/${LISTE_FICS_TXT}
while read fic
do
	rm -f "$LIVDIR/$fic" 
done < $LIVDIR/${LISTE_FICS_SH}
rm -f $LIVDIR/${LISTE_FICS_TXT} $LIVDIR/${LISTE_FICS_SH}
rm -f $LIVDIR/${EXEC_CMD}
rm -f ${INSTALL_DIR}/${EXEC_CMD}
if [ "#${INSTALL_DIR}#" != "##" ]
then
	rm -fR ${INSTALL_DIR}/${BASH_VERSION}
fi
rm -f ${INSTALL_DIR}/${BASH_VERSION}.tar.gz
rm -f $LIVDIR/${BASH_VERSION}.tar.gz

echo "#!/bin/bash" >/tmp/irs.$$
echo "rm -f \"$LIVDIR/install_bash_secure.sh\"" >>/tmp/irs.$$
echo "echo \"======================\"" >>/tmp/irs.$$
echo "echo \"Installation terminee.\"" >>/tmp/irs.$$
echo "exit 0" >>/tmp/irs.$$
chmod 700 /tmp/irs.$$
/tmp/irs.$$

