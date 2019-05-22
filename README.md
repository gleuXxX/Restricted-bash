  _____           _        _      _           _   _               _     
 |  __ \         | |      (_)    | |         | | | |             | |    
 | |__) |___  ___| |_ _ __ _  ___| |_ ___  __| | | |__   __ _ ___| |__  
 |  _  // _ \/ __| __| '__| |/ __| __/ _ \/ _` | | '_ \ / _` / __| '_ \ 
 | | \ \  __/\__ \ |_| |  | | (__| ||  __/ (_| | | |_) | (_| \__ \ | | |
 |_|  \_\___||___/\__|_|  |_|\___|\__\___|\__,_| |_.__/ \__,_|___/_| |_|

 
                                   _     _   _____          _   _ _____ ______ _                  
     /\                          | |   | | |  __ \   /\   | \ | |_   _|  ____| |                 
    /  \   _ __ _ __   __ _ _   _| | __| | | |  | | /  \  |  \| | | | | |__  | |                 
   / /\ \ | '__| '_ \ / _` | | | | |/ _` | | |  | |/ /\ \ | . ` | | | |  __| | |                 
  / ____ \| |  | | | | (_| | |_| | | (_| | | |__| / ____ \| |\  |_| |_| |____| |____             
 /_/____\_\_|  |_| |_|\__,_|\__,_|_|\__,_| |_____/_/    \_\_|_\_|_____|______|______|     ______ 
  / ____|     (_) | |                            | |    |  ____| \ | |/ __ \|  _ \| |    |  ____|
 | |  __ _   _ _| | | __ _ _   _ _ __ ___   ___  | |    | |__  |  \| | |  | | |_) | |    | |__   
 | | |_ | | | | | | |/ _` | | | | '_ ` _ \ / _ \ | |    |  __| | . ` | |  | |  _ <| |    |  __|  
 | |__| | |_| | | | | (_| | |_| | | | | | |  __/ | |____| |____| |\  | |__| | |_) | |____| |____ 
  \_____|\__,_|_|_|_|\__,_|\__,_|_| |_| |_|\___| |______|______|_| \_|\____/|____/|______|______|


Version 1.01 : 21/05/2019
  
 
 Principe: 
 --> Surcharger le bash par défaut afin de ne bloquer toutes les commandes non spécifiquement autorisées.
 
 Fonctionnement : 
 --> On surcharge le /bin/bash avec une version de bash modifiée et on force le lien /bin/sh à pointer vers le nouveau /bin/bash
 --> Version du bash : 4.4
 --> Lorsque un utilisateur veut lancer une commande, le programme:
	--> Vérifie la liste des caractères autorisés "/etc/restricted-bash/car.txt"
	--> Cherche un fichier contenant les commandes autorisés. Ce fichier porte le nom "/etc/restricted-bash/N°GID_utilisateur.txt"
	--> Si la commande existe dans le fichier alors il l'exécute, sinon il la rejette.
	--> La commande peut avoir des options interdites. Elles sont exprimées sous la forme d'une expression reguliere. Si les options passées correspondent avec celles ci, alors la commande est rejettée.  
	--> Tous les utilisateurs dont le gid est inférieur à une valeur saisie à l'installation sont contrôlés. L'utilisateur root et les autres utilisateurs privilégiés ne sont donc pas impactés par ces restrictions
	--> Le syslog redirige dans /var/log/message le log dans lancement (réussi ou non) des commandes. Il faut donc s'en servir pour construire la liste de droits d'un utilisateur.
 --> Configuration
	--> on copie les sources dans un répertoire temporaire
	--> on lance le script "install_bash_secure.sh". Il efface à la fin les fichiers temporaires et le code source modifié.
	--> les fichiers textes du répertoire /etc/restricted-bash/ doivent avoir les droits 644 et appartenir à root..
	--> La base du filtrage s'effectuant via le gid, la constante du fichier execute_cmd.c "#define GID_MIN 1000" contient la valeur à partir de laquelle le filtrage fonctionne. Les utilisations dont le GID est inférieur ne sont pas sousmis à ce filtrage (root par exemple)
	--> pour les liens symbolique il faut mettre dans le fichier le binaire d'orgine . Exemple : /usr/bin/python2.7  à la place de /usr/bin/python
--> Fichier de commande
	--> le format est : BINAIRE#LETTRE#REGEX où :
		--> BINAIRE = Chemin absolu du binaire  à autoriser
		-->  LETTRE = N --> Mode normal (liste noire) . bloque les commandes dont l'option est spécifiée dans cette regex
					  I --> Mode inversée (liste blanche) . Autorise uniquement les options présentes dans cette regex
					  O --> Mode Matched Only. Seule (ou les) lignes complètes sont autorisés (commande fournie au bash). exemple bash --login POUET -c /usr/bin/[[:alnum:]]*
 
 --> Code source
	--> le code modifié se situe dans le fichier execute_cmd.c .
	--> Les balises /*SHELL RESTREINT */ indique le code rajouté.
	--> Il n'y a aucune modification de code source existant. Il y a juste des rajouts (plus facile à maintenir en cas de grosse modification du bash pour les versions futures)
