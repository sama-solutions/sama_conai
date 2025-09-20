#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test pour la vague 1 des données de démo
"""

def test_demo_wave_1():
    """
    Teste que les données de démo de la vague 1 sont correctement chargées
    """
    print("🧪 Test de la vague 1 des données de démo...")
    
    try:
        # Test 1: Vérifier les demandes d'information
        info_requests = env['request.information'].search([])
        print(f"   📊 Demandes d'information trouvées: {len(info_requests)}")
        
        if info_requests:
            for request in info_requests:
                print(f"      - {request.name}: {request.partner_name} ({request.state})")
        
        # Test 2: Vérifier les signalements d'alerte
        whistleblowing_alerts = env['whistleblowing.alert'].search([])
        print(f"   🚨 Signalements d'alerte trouvés: {len(whistleblowing_alerts)}")
        
        if whistleblowing_alerts:
            for alert in whistleblowing_alerts:
                print(f"      - {alert.name}: {alert.category} ({alert.state})")
        
        # Test 3: Vérifier les étapes
        info_stages = env['request.information.stage'].search([])
        print(f"   📋 Étapes d'information trouvées: {len(info_stages)}")
        
        wb_stages = env['whistleblowing.alert.stage'].search([])
        print(f"   📋 Étapes de signalement trouvées: {len(wb_stages)}")
        
        # Test 4: Vérifier les motifs de refus
        refusal_reasons = env['request.refusal.reason'].search([])
        print(f"   ❌ Motifs de refus trouvés: {len(refusal_reasons)}")
        
        # Test 5: Vérifier les vues Kanban
        print("   🎯 Test des vues...")
        
        # Simuler l'ouverture des vues principales
        action_info = env.ref('sama_conai.action_information_request')
        print(f"      - Action demandes d'info: {action_info.name}")
        
        # Résumé
        print("\\n✅ Résumé des tests:")
        print(f"   - Demandes d'information: {len(info_requests)}")
        print(f"   - Signalements d'alerte: {len(whistleblowing_alerts)}")
        print(f"   - Étapes d'information: {len(info_stages)}")
        print(f"   - Étapes de signalement: {len(wb_stages)}")
        print(f"   - Motifs de refus: {len(refusal_reasons)}")
        
        if len(info_requests) > 0 and len(whistleblowing_alerts) > 0:
            print("\\n🎉 Vague 1 des données de démo: SUCCÈS!")
            return True
        else:
            print("\\n⚠️  Vague 1 des données de démo: DONNÉES MANQUANTES")
            return False
            
    except Exception as e:
        print(f"\\n❌ Erreur lors du test: {e}")
        return False

# Exécuter le test si dans le contexte Odoo
try:
    result = test_demo_wave_1()
    if result:
        print("\\n🚀 Prêt pour la vague 2 des données de démo!")
    else:
        print("\\n🔧 Corriger les problèmes avant de continuer.")
except NameError:
    print("❌ Ce script doit être exécuté dans le shell Odoo.")
    print("   Usage: ./odoo-bin shell -c odoo.conf -d your_database")
    print("   Puis: exec(open('scripts/test_demo_wave_1.py').read())")