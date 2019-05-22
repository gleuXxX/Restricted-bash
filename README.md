# Restricted-Bash
                                                                      
                                                                      



## Version 1.01 : 21/05/2019



  
 
## Principe: 

- Surcharger le bash par défaut afin de ne bloquer que les commandes non spécifiquement autorisées.
- Fonctionnement plus souple et complet que le rbash.
- Traçabilité des actions
 
## Fonctionnement : 

- On surcharge le /bin/bash avec une version de bash modifiée et on force le lien /bin/sh à pointer vers le nouveau /bin/bash
- Version du bash : 4.4
- Lorsque un utilisateur veut lancer une commande, le programme:
	- Vérifie la liste des caractères autorisés "/etc/restricted-bash/car.txt"
	- Cherche un fichier contenant les commandes autorisés. Ce fichier porte le nom "/etc/restricted-bash/N°GID_utilisateur.txt"
	- Si la commande existe dans le fichier alors il l'exécute, sinon il la rejette.
	- La commande peut avoir des options interdites. Elles sont exprimées sous la forme d'une expression reguliere. Si les options passées correspondent avec celles ci, alors la commande est rejettée.  
	- Tous les utilisateurs dont le gid est inférieur à une valeur saisie à l'installation sont contrôlés. L'utilisateur root et les autres utilisateurs privilégiés ne sont donc pas impactés par ces restrictions
	- Le syslog redirige dans /var/log/message le log dans lancement (réussi ou non) des commandes. Il faut donc s'en servir pour construire la liste de droits d'un utilisateur.
 
 ## Configuration :
- on copie les sources dans un répertoire temporaire
- on lance le script "install_bash_secure.sh". Il efface à la fin les fichiers temporaires et le code source modifié.
- les fichiers textes du répertoire /etc/restricted-bash/ doivent avoir les droits 644 et appartenir à root..
- La base du filtrage s'effectuant via le gid, la constante du fichier execute_cmd.c "#define GID_MIN 1000" contient la valeur à partir de laquelle le filtrage fonctionne. Les utilisations dont le GID est inférieur ne sont pas sousmis à ce filtrage (root par exemple)
- pour les liens symbolique il faut mettre dans le fichier le binaire d'orgine . Exemple : /usr/bin/python2.7  à la place de /usr/bin/python


## Fichier de commande :
- Le format est :
	- BINAIRE#LETTRE#REGEX où :
		- BINAIRE = Chemin absolu du binaire  à autoriser
		- LETTRE = 
			- N --> Mode normal (liste noire) . bloque les commandes dont l'option est spécifiée dans cette regex
			- I --> Mode inversée (liste blanche) . Autorise uniquement les options présentes dans cette regex
			- O --> Mode Matched Only. Seule (ou les) lignes complètes sont autorisés (commande fournie au bash). 			- REGEX 
		- exemples:
			- bash#O#--login POUET -c /usr/bin/[[:alnum:]]*  bloquera "bash --login POUET -c /usr/bin/toto
			- /bin/ps#I#-{1,2}[[:alnum:]]*(ef)+[[:alnum:]]* n'autorisera que l'option -ef de la commande ps
			- /bin/ls#N#-{1,2}[[:alnum:]]*(a)+[[:alnum:]]* interdira l'usage de l'option a de la commande ls			- 
 
 ## Divers
	- Les sources du bash restrinet se situe dans le fichier execute_cmd.c .
	- Les balises /*SHELL RESTREINT */ indique le code rajouté.
	- Il n'y a aucune modification de code source existant. Il y a juste des rajouts (plus facile à maintenir en cas de grosse modification du bash pour les versions futures)

## Post-scriptum
I'm not developper ;-)

## About Us

- Un grand merci à Arnauld Daniel pour son aide précieuse.
- LEG [@2951210a5fea430](https://twitter.com/2951210a5fea430)


## License

GNU GENERAL PUBLIC LICENSE (GPL) Version 3
