#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de nettoyage des doublons de menus Odoo
"""

import os
import shutil
from datetime import datetime

def clean_menu_duplicates():
    """Nettoie les fichiers dupliqués qui causent des doublons de menus"""
    
    print("🧹 NETTOYAGE DES DOUBLONS DE MENUS ODOO")
    print("=" * 50)
    
    # Fichiers et répertoires à supprimer
    files_to_remove = [
        'views/menus_old.xml',
        'views/information_request_views.xml.backup',
        'data/email_templates.xml'  # Si ce fichier existe et n'est pas dans le manifest
    ]
    
    directories_to_remove = [
        'backups/sama_conai_stable_20250906_055044'
    ]
    
    # Créer un répertoire de sauvegarde pour les fichiers supprimés
    backup_dir = f"deleted_files_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    removed_files = []
    removed_dirs = []
    
    print(f"📦 Création du répertoire de sauvegarde: {backup_dir}")
    os.makedirs(backup_dir, exist_ok=True)
    
    # Supprimer les fichiers
    print(f"\\n🗑️ Suppression des fichiers dupliqués:")
    for file_path in files_to_remove:
        if os.path.exists(file_path):
            try:
                # Sauvegarder avant suppression
                backup_path = os.path.join(backup_dir, os.path.basename(file_path))
                shutil.copy2(file_path, backup_path)
                
                # Supprimer le fichier
                os.remove(file_path)
                print(f"   ✅ Supprimé: {file_path}")
                print(f"      💾 Sauvegardé dans: {backup_path}")
                removed_files.append(file_path)
            except Exception as e:
                print(f"   ❌ Erreur lors de la suppression de {file_path}: {e}")
        else:
            print(f"   ⚠️ Fichier non trouvé: {file_path}")
    
    # Supprimer les répertoires
    print(f"\\n📁 Suppression des répertoires de backup:")
    for dir_path in directories_to_remove:
        if os.path.exists(dir_path):
            try:
                # Sauvegarder le répertoire entier
                backup_path = os.path.join(backup_dir, os.path.basename(dir_path))
                shutil.copytree(dir_path, backup_path)
                
                # Supprimer le répertoire
                shutil.rmtree(dir_path)
                print(f"   ✅ Supprimé: {dir_path}")
                print(f"      💾 Sauvegardé dans: {backup_path}")
                removed_dirs.append(dir_path)
            except Exception as e:
                print(f"   ❌ Erreur lors de la suppression de {dir_path}: {e}")
        else:
            print(f"   ⚠️ Répertoire non trouvé: {dir_path}")
    
    # Vérifier les fichiers restants
    print(f"\\n🔍 Vérification des fichiers restants:")
    
    remaining_menu_files = []
    for root, dirs, files in os.walk('.'):
        # Ignorer le répertoire de sauvegarde qu'on vient de créer
        if backup_dir in root:
            continue
            
        for file in files:
            if file.endswith('.xml') and 'menu' in file.lower():
                remaining_menu_files.append(os.path.join(root, file))
    
    if remaining_menu_files:
        print(f"   📄 Fichiers de menus restants:")
        for file in remaining_menu_files:
            print(f"      📋 {file}")
    
    # Vérifier le manifest
    print(f"\\n📋 Vérification du manifest:")
    try:
        with open('__manifest__.py', 'r') as f:
            manifest_content = f.read()
        
        # Vérifier que seul le bon fichier de menus est référencé
        if "'views/menus.xml'" in manifest_content:
            print(f"   ✅ Fichier de menus correct dans le manifest: views/menus.xml")
        else:
            print(f"   ⚠️ Fichier de menus non trouvé dans le manifest")
            
        # Vérifier qu'aucun fichier supprimé n'est référencé
        for removed_file in removed_files:
            if f"'{removed_file}'" in manifest_content:
                print(f"   ⚠️ ATTENTION: Fichier supprimé encore référencé: {removed_file}")
                
    except Exception as e:
        print(f"   ❌ Erreur lors de la vérification du manifest: {e}")
    
    # Résumé
    print(f"\\n📊 RÉSUMÉ DU NETTOYAGE:")
    print(f"   🗑️ Fichiers supprimés: {len(removed_files)}")
    print(f"   📁 Répertoires supprimés: {len(removed_dirs)}")
    print(f"   💾 Sauvegarde créée: {backup_dir}")
    
    if removed_files or removed_dirs:
        print(f"\\n✅ Nettoyage terminé avec succès!")
        print(f"\\n🔄 PROCHAINES ÉTAPES:")
        print(f"   1. Redémarrer Odoo pour appliquer les changements")
        print(f"   2. Vérifier que les menus s'affichent correctement")
        print(f"   3. Si tout fonctionne, supprimer le répertoire: {backup_dir}")
        print(f"\\n🚀 Commande de redémarrage suggérée:")
        print(f"   ./start_sama_conai_analytics_fixed.sh")
    else:
        print(f"\\n✅ Aucun fichier à nettoyer trouvé")
    
    return len(removed_files) > 0 or len(removed_dirs) > 0

if __name__ == "__main__":
    success = clean_menu_duplicates()
    exit(0)