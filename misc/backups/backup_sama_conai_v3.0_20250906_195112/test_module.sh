#!/bin/bash

# Test rapide du module SAMA CONAI

echo "🧪 TEST MODULE SAMA CONAI"
echo "========================="

DB_NAME="${1:-sama_conai_demo}"
ODOO_PATH="/var/odoo/odoo18"
VENV_PATH="/home/grand-as/odoo18-venv"
CUSTOM_ADDONS_PATH="/home/grand-as/psagsn/custom_addons"

source "$VENV_PATH/bin/activate"
cd "$ODOO_PATH"

echo "Test du module dans la base: $DB_NAME"
echo ""

python3 odoo-bin shell \
  -d "$DB_NAME" \
  --addons-path="$CUSTOM_ADDONS_PATH" \
  --db_host=localhost \
  --db_user=odoo \
  --db_password=odoo << 'EOF'

print("🧪 TEST DU MODULE SAMA CONAI")
print("=" * 40)

try:
    # Test 1: Vérifier l'installation du module
    module = env['ir.module.module'].search([('name', '=', 'sama_conai')])
    if module:
        print(f"✅ Module trouvé: {module.name}")
        print(f"   État: {module.state}")
        print(f"   Version: {module.latest_version}")
    else:
        print("❌ Module sama_conai non trouvé")
        exit()
    
    # Test 2: Vérifier les modèles
    print("\n📋 Test des modèles:")
    
    try:
        info_model = env['request.information']
        print("✅ Modèle request.information accessible")
        
        wb_model = env['whistleblowing.alert']
        print("✅ Modèle whistleblowing.alert accessible")
        
        stage_model = env['request.information.stage']
        print("✅ Modèle request.information.stage accessible")
        
        reason_model = env['request.refusal.reason']
        print("✅ Modèle request.refusal.reason accessible")
        
    except Exception as e:
        print(f"❌ Erreur modèles: {e}")
    
    # Test 3: Compter les données
    print("\n📊 Données disponibles:")
    
    try:
        info_count = env['request.information'].search_count([])
        print(f"   Demandes d'information: {info_count}")
        
        wb_count = env['whistleblowing.alert'].search_count([])
        print(f"   Signalements d'alerte: {wb_count}")
        
        stages_count = env['request.information.stage'].search_count([])
        print(f"   Étapes d'information: {stages_count}")
        
        reasons_count = env['request.refusal.reason'].search_count([])
        print(f"   Motifs de refus: {reasons_count}")
        
    except Exception as e:
        print(f"❌ Erreur données: {e}")
    
    # Test 4: Vérifier les vues
    print("\n🎨 Test des vues:")
    
    try:
        views = env['ir.ui.view'].search([
            ('model', 'in', ['request.information', 'whistleblowing.alert'])
        ])
        print(f"✅ Vues trouvées: {len(views)}")
        
        for view in views[:5]:  # Afficher les 5 premières
            print(f"   - {view.name} ({view.type})")
            
    except Exception as e:
        print(f"❌ Erreur vues: {e}")
    
    # Test 5: Vérifier les menus
    print("\n📋 Test des menus:")
    
    try:
        menus = env['ir.ui.menu'].search([
            ('name', 'ilike', 'SAMA CONAI')
        ])
        print(f"✅ Menus trouvés: {len(menus)}")
        
        for menu in menus:
            print(f"   - {menu.name}")
            
    except Exception as e:
        print(f"❌ Erreur menus: {e}")
    
    print("\n🎯 RÉSULTAT:")
    if module.state == 'installed':
        print("✅ Module SAMA CONAI installé et fonctionnel!")
        print("\n🚀 Prochaines étapes:")
        print("   1. Démarrer le serveur: ./start_server.sh")
        print("   2. Aller sur http://localhost:8069")
        print("   3. Se connecter (admin/admin)")
        print("   4. Chercher le menu 'Accès à l'Information'")
    else:
        print("❌ Module non installé correctement")
        
except Exception as e:
    print(f"❌ Erreur générale: {e}")
    import traceback
    traceback.print_exc()

EOF