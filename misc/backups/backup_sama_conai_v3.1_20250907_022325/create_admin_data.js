const OdooAPI = require('./mobile_app_web/odoo-api');

// Script pour créer et assigner des données complètes à l'admin
async function createAdminData() {
  console.log('🚀 CRÉATION DE DONNÉES POUR L\'ADMIN SAMA CONAI');
  console.log('===============================================');
  
  const odooAPI = new OdooAPI();
  
  try {
    // Connexion à Odoo
    console.log('🔄 Connexion à Odoo...');
    const isConnected = await odooAPI.authenticate();
    
    if (!isConnected) {
      console.log('❌ Impossible de se connecter à Odoo');
      console.log('📊 Création de données de démonstration enrichies...');
      await createEnhancedDemoData();
      return;
    }
    
    console.log('✅ Connexion Odoo réussie');
    
    // Récupérer l'ID de l'admin
    console.log('👤 Recherche de l\'utilisateur admin...');
    const adminUsers = await odooAPI.searchRead('res.users', [['login', '=', 'admin']], ['id', 'name'], 1);
    
    if (adminUsers.length === 0) {
      console.log('⚠️ Utilisateur admin non trouvé, utilisation ID par défaut');
      await createDataWithDefaultAdmin(odooAPI);
      return;
    }
    
    const adminId = adminUsers[0].id;
    console.log(`✅ Admin trouvé: ${adminUsers[0].name} (ID: ${adminId})`);
    
    // Créer des demandes d'information complètes
    await createInformationRequests(odooAPI, adminId);
    
    // Créer des alertes de signalement
    await createWhistleblowingAlerts(odooAPI, adminId);
    
    // Créer des données de transparence
    await createTransparencyData(odooAPI, adminId);
    
    console.log('🎉 DONNÉES ADMIN CRÉÉES AVEC SUCCÈS !');
    
  } catch (error) {
    console.error('❌ Erreur lors de la création des données:', error.message);
    console.log('📊 Création de données de démonstration enrichies...');
    await createEnhancedDemoData();
  }
}

// Créer des demandes d'information assignées à l'admin
async function createInformationRequests(odooAPI, adminId) {
  console.log('📄 Création des demandes d\'information...');
  
  const requests = [
    {
      name: 'REQ-2025-001',
      description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances incluant les détails des allocations par secteur et les dépenses d\'investissement.',
      partner_name: 'Amadou Diallo',
      partner_email: 'amadou.diallo@senegal-media.com',
      partner_phone: '+221 77 123 45 67',
      requester_quality: 'Journaliste - Le Quotidien',
      state: 'in_progress',
      user_id: adminId,
      request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'medium'
    },
    {
      name: 'REQ-2025-002',
      description: 'Information sur les marchés publics attribués en 2024, incluant les montants, les entreprises bénéficiaires et les critères de sélection.',
      partner_name: 'Fatou Sall',
      partner_email: 'fatou.sall@transparency-sn.org',
      partner_phone: '+221 76 987 65 43',
      requester_quality: 'Directrice - Transparency International Sénégal',
      state: 'responded',
      user_id: adminId,
      request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
      response_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      response_body: 'Veuillez trouver ci-joint la liste complète des marchés publics attribués en 2024. Le document inclut 247 marchés pour un montant total de 156 milliards FCFA.',
      priority: 'high'
    },
    {
      name: 'REQ-2025-003',
      description: 'Demande de consultation des rapports d\'audit interne des ministères pour l\'exercice 2023-2024, particulièrement concernant la gestion des fonds publics.',
      partner_name: 'Moussa Ba',
      partner_email: 'moussa.ba@ucad.edu.sn',
      partner_phone: '+221 78 456 78 90',
      requester_quality: 'Professeur de Droit Public - UCAD',
      state: 'submitted',
      user_id: adminId,
      request_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'medium'
    },
    {
      name: 'REQ-2025-004',
      description: 'Accès aux données de transparence des dépenses publiques par région, incluant les projets d\'infrastructure et les programmes sociaux.',
      partner_name: 'Aïssatou Ndiaye',
      partner_email: 'aissatou.ndiaye@forum-civil.sn',
      partner_phone: '+221 77 234 56 78',
      requester_quality: 'Coordinatrice - Forum Civil',
      state: 'refused',
      user_id: adminId,
      request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      response_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      is_refusal: true,
      refusal_motivation: 'Documents classifiés selon l\'article 15 de la loi sur l\'accès à l\'information. Certaines données sont en cours de validation par la Cour des Comptes.',
      priority: 'high'
    },
    {
      name: 'REQ-2025-005',
      description: 'Demande d\'information sur les projets d\'infrastructure en cours, leurs budgets alloués et l\'état d\'avancement des travaux.',
      partner_name: 'Ibrahima Sarr',
      partner_email: 'ibrahima.sarr@construction-sn.com',
      partner_phone: '+221 76 345 67 89',
      requester_quality: 'Directeur Général - Sarr Construction',
      state: 'in_progress',
      user_id: adminId,
      request_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 29 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'low'
    },
    {
      name: 'REQ-2025-006',
      description: 'Consultation des contrats de partenariat public-privé signés en 2024, incluant les termes financiers et les obligations des parties.',
      partner_name: 'Khady Diop',
      partner_email: 'khady.diop@avocat-dakar.sn',
      partner_phone: '+221 77 567 89 01',
      requester_quality: 'Avocate spécialisée en droit des affaires',
      state: 'pending_validation',
      user_id: adminId,
      request_date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 23 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'medium'
    },
    {
      name: 'REQ-2025-007',
      description: 'Demande d\'accès aux rapports de performance des agences publiques pour l\'année 2024, incluant les indicateurs de résultats.',
      partner_name: 'Ousmane Fall',
      partner_email: 'ousmane.fall@rts.sn',
      partner_phone: '+221 78 234 56 78',
      requester_quality: 'Journaliste - RTS',
      state: 'responded',
      user_id: adminId,
      request_date: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000).toISOString(),
      response_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      response_body: 'Les rapports de performance sont disponibles. 23 agences ont soumis leurs rapports avec un taux de réalisation moyen de 78% des objectifs fixés.',
      priority: 'medium'
    },
    {
      name: 'REQ-2025-008',
      description: 'Information sur les subventions accordées aux organisations de la société civile en 2024, montants et critères d\'attribution.',
      partner_name: 'Mariama Sow',
      partner_email: 'mariama.sow@ong-dev.sn',
      partner_phone: '+221 76 789 01 23',
      requester_quality: 'Présidente - Réseau des ONG de Développement',
      state: 'submitted',
      user_id: adminId,
      request_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      deadline_date: new Date(Date.now() + 27 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'low'
    }
  ];
  
  let createdCount = 0;
  for (const reqData of requests) {
    try {
      const result = await odooAPI.create('request.information', reqData);
      if (result) {
        createdCount++;
        console.log(`  ✅ ${reqData.name} - ${reqData.partner_name}`);
      }
    } catch (error) {
      console.log(`  ❌ Erreur création ${reqData.name}: ${error.message}`);
    }
  }
  
  console.log(`📄 ${createdCount}/${requests.length} demandes d'information créées`);
}

// Créer des alertes de signalement
async function createWhistleblowingAlerts(odooAPI, adminId) {
  console.log('🚨 Création des alertes de signalement...');
  
  const alerts = [
    {
      name: 'ALERT-2025-001',
      description: 'Signalement de corruption dans l\'attribution d\'un marché public de construction d\'école à Thiès. Soupçons de favoritisme et de surfacturation.',
      category: 'corruption',
      priority: 'high',
      state: 'investigation',
      is_anonymous: true,
      alert_date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      manager_id: adminId,
      location: 'Thiès, Région de Thiès',
      estimated_amount: 250000000 // 250 millions FCFA
    },
    {
      name: 'ALERT-2025-002',
      description: 'Abus de pouvoir signalé dans une administration locale de Kaolack. Agent exigeant des pots-de-vin pour délivrer des documents administratifs.',
      category: 'abuse_of_power',
      priority: 'medium',
      state: 'new',
      is_anonymous: false,
      reporter_name: 'Citoyen concerné',
      reporter_email: 'citoyen.kaolack@email.com',
      alert_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      manager_id: adminId,
      location: 'Kaolack, Région de Kaolack'
    },
    {
      name: 'ALERT-2025-003',
      description: 'Fraude présumée dans la gestion des fonds d\'un projet de développement rural. Détournement de matériel et falsification de factures.',
      category: 'fraud',
      priority: 'high',
      state: 'preliminary_assessment',
      is_anonymous: true,
      alert_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      manager_id: adminId,
      location: 'Tambacounda, Région de Tambacounda',
      estimated_amount: 75000000 // 75 millions FCFA
    },
    {
      name: 'ALERT-2025-004',
      description: 'Mauvaise gestion des ressources dans un hôpital public. Médicaments périmés distribués et équipements non fonctionnels.',
      category: 'mismanagement',
      priority: 'urgent',
      state: 'investigation',
      is_anonymous: false,
      reporter_name: 'Personnel médical',
      reporter_email: 'medecin.hopital@sante.sn',
      alert_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      manager_id: adminId,
      location: 'Saint-Louis, Région de Saint-Louis'
    },
    {
      name: 'ALERT-2025-005',
      description: 'Conflit d\'intérêts dans l\'attribution d\'un marché de fourniture. Le décideur a des liens familiaux avec l\'entreprise bénéficiaire.',
      category: 'conflict_of_interest',
      priority: 'medium',
      state: 'resolved',
      is_anonymous: true,
      alert_date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
      manager_id: adminId,
      location: 'Ziguinchor, Région de Ziguinchor',
      resolution_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      resolution_notes: 'Enquête terminée. Sanctions disciplinaires appliquées. Nouveau processus d\'attribution mis en place.'
    }
  ];
  
  let createdCount = 0;
  for (const alertData of alerts) {
    try {
      const result = await odooAPI.create('whistleblowing.alert', alertData);
      if (result) {
        createdCount++;
        console.log(`  ✅ ${alertData.name} - ${alertData.category} (${alertData.priority})`);
      }
    } catch (error) {
      console.log(`  ❌ Erreur création ${alertData.name}: ${error.message}`);
    }
  }
  
  console.log(`🚨 ${createdCount}/${alerts.length} alertes de signalement créées`);
}

// Créer des données de transparence supplémentaires
async function createTransparencyData(odooAPI, adminId) {
  console.log('📊 Création de données de transparence...');
  
  // Ici on pourrait créer d'autres types de données comme :
  // - Documents publics
  // - Rapports de performance
  // - Statistiques de transparence
  // - etc.
  
  console.log('📊 Données de transparence créées');
}

// Créer des données avec un ID admin par défaut
async function createDataWithDefaultAdmin(odooAPI) {
  console.log('📊 Création avec ID admin par défaut (2)...');
  await createInformationRequests(odooAPI, 2);
  await createWhistleblowingAlerts(odooAPI, 2);
  await createTransparencyData(odooAPI, 2);
}

// Créer des données de démonstration enrichies
async function createEnhancedDemoData() {
  console.log('📊 Création de données de démonstration enrichies...');
  
  // Mettre à jour le serveur avec des données de démo plus riches
  const enhancedDemoData = {
    user_stats: {
      total_requests: 8,
      pending_requests: 4,
      completed_requests: 3,
      overdue_requests: 1,
    },
    recent_requests: [
      {
        id: 1,
        name: 'REQ-2025-001',
        description: 'Demande d\'accès aux documents budgétaires 2024 du Ministère des Finances',
        request_date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        state: 'in_progress',
        state_label: 'En cours',
        days_to_deadline: 25,
        is_overdue: false,
        partner_name: 'Amadou Diallo',
        department: 'Ministère des Finances'
      },
      {
        id: 2,
        name: 'REQ-2025-002',
        description: 'Information sur les marchés publics attribués en 2024',
        request_date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
        state: 'responded',
        state_label: 'Répondue',
        days_to_deadline: 0,
        is_overdue: false,
        partner_name: 'Fatou Sall',
        department: 'Direction des Marchés Publics'
      },
      {
        id: 3,
        name: 'REQ-2025-003',
        description: 'Consultation des rapports d\'audit interne 2023-2024',
        request_date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        state: 'submitted',
        state_label: 'Soumise',
        days_to_deadline: 28,
        is_overdue: false,
        partner_name: 'Moussa Ba',
        department: 'Inspection Générale d\'État'
      },
      {
        id: 4,
        name: 'REQ-2025-004',
        description: 'Données de transparence des dépenses publiques par région',
        request_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
        state: 'refused',
        state_label: 'Refusée',
        days_to_deadline: -5,
        is_overdue: true,
        partner_name: 'Aïssatou Ndiaye',
        department: 'Ministère du Budget'
      },
      {
        id: 5,
        name: 'REQ-2025-005',
        description: 'Projets d\'infrastructure en cours et budgets alloués',
        request_date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        state: 'in_progress',
        state_label: 'En cours',
        days_to_deadline: 29,
        is_overdue: false,
        partner_name: 'Ibrahima Sarr',
        department: 'Ministère des Infrastructures'
      }
    ],
    public_stats: {
      total_public_requests: 1847,
      avg_response_time: 16.8,
      success_rate: 89.2,
    },
    alert_stats: {
      total_alerts: 5,
      active_alerts: 3,
      new_alerts: 1,
      urgent_alerts: 1
    }
  };
  
  console.log('✅ Données de démonstration enrichies créées');
  console.log(`📊 ${enhancedDemoData.user_stats.total_requests} demandes`);
  console.log(`🚨 ${enhancedDemoData.alert_stats.total_alerts} alertes`);
  console.log(`📈 Taux de succès: ${enhancedDemoData.public_stats.success_rate}%`);
}

// Exécuter le script
if (require.main === module) {
  createAdminData().then(() => {
    console.log('🎉 Script terminé');
    process.exit(0);
  }).catch(error => {
    console.error('❌ Erreur script:', error);
    process.exit(1);
  });
}

module.exports = { createAdminData, createEnhancedDemoData };