# Scripts de lancement Odoo

Ce dossier contient des scripts pour gérer l'environnement de développement Odoo pour le module `sama_conai`.

## Fichiers

- `reset_and_init.sh`: Ce script effectue une réinitialisation complète de l'environnement de test. Il arrête tous les processus Odoo en cours sur le port 8070, supprime la base de données de test `sama_conai_test`, la recrée, puis installe le module `sama_conai` et ses dépendances. **Ce script doit être exécuté manuellement une seule fois pour la configuration initiale, car le processus d'installation est très long et peut dépasser les délais d'attente des outils automatisés.**

- `start.sh`: Ce script est utilisé pour le développement quotidien. Il arrête les processus Odoo en cours sur le port 8070 et démarre le serveur avec la base de données `sama_conai_test`. 

## Utilisation

1.  **Initialisation (à faire une seule fois manuellement) :**
    Ouvrez un terminal dans le répertoire du projet et exécutez la commande suivante :
    ```bash
    ./scripts/reset_and_init.sh
    ```
    Ce processus peut prendre beaucoup de temps. Veuillez patienter jusqu'à ce qu'il se termine.

2.  **Démarrage pour le développement :**
    Pour démarrer le serveur Odoo pour le développement, exécutez la commande suivante :
    ```bash
    ./scripts/start.sh
    ```
