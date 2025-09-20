/**
 * SAMA CONAI Formation - JavaScript Functionality
 * Gestion de la navigation, progression et interactivité des formations
 */

// État global de la formation
let formationState = {
    currentLesson: '1.1',
    completedLessons: [],
    currentModule: 1,
    totalModules: 6,
    quizScores: {},
    startTime: null,
    lastActivity: null
};

// Configuration des leçons par module
const moduleConfig = {
    1: ['1.1', '1.2', '1.3'],
    2: ['2.1', '2.2', '2.3'],
    3: ['3.1', '3.2', '3.3', '3.4'],
    4: ['4.1', '4.2', '4.3', '4.4'],
    5: ['5.1', '5.2', '5.3'],
    6: ['6.1', '6.2', '6.3']
};

// Réponses correctes des quiz
const quizAnswers = {
    '1.1': { q1: 'b', q2: 'a' },
    '1.2': { q1: 'a', q2: 'b' },
    '1.3': { q1: 'a', q2: 'b' },
    '2.1': { q1: 'b', q2: 'b' },
    '2.2': { q1: 'b', q2: 'b' },
    '2.3': { q1: 'b', q2: 'b' },
    '3.1': { q1: 'b', q2: 'a' },
    '3.2': { q1: 'a', q2: 'b' },
    '3.3': { q1: 'b', q2: 'a' },
    '3.4': { q1: 'a', q2: 'b' },
    '4.1': { q1: 'a', q2: 'b' },
    '4.2': { q1: 'b', q2: 'a' },
    '4.3': { q1: 'b', q2: 'b' },
    '4.4': { q1: 'b', q2: 'b' },
    '5.1': { q1: 'a', q2: 'b' },
    '5.2': { q1: 'b', q2: 'b' },
    '5.3': { q1: 'b', q2: 'b' },
    '6.1': { q1: 'b', q2: 'b' },
    '6.2': { q1: 'b', q2: 'b' },
    '6.3': { q1: 'b', q2: 'b' }
};

/**
 * Initialisation de la formation
 */
function initFormation() {
    console.log('🚀 Initialisation de la formation SAMA CONAI');
    
    // Charger l'état sauvegardé
    loadFormationState();
    
    // Initialiser les événements
    initEventListeners();
    
    // Afficher la première leçon
    showLesson(formationState.currentLesson);
    
    // Mettre à jour la progression
    updateProgress();
    
    // Marquer le début de la formation
    if (!formationState.startTime) {
        formationState.startTime = new Date().toISOString();
        saveFormationState();
    }
    
    console.log('✅ Formation initialisée avec succès');
}

/**
 * Initialiser les écouteurs d'événements
 */
function initEventListeners() {
    // Liens de leçons dans la sidebar
    document.querySelectorAll('.lesson-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const lessonId = this.getAttribute('data-lesson');
            if (lessonId) {
                showLesson(lessonId);
            }
        });
    });
    
    // Sauvegarde automatique toutes les 30 secondes
    setInterval(saveFormationState, 30000);
    
    // Sauvegarde avant fermeture de page
    window.addEventListener('beforeunload', saveFormationState);
}

/**
 * Démarrer la formation
 */
function startFormation() {
    console.log('▶️ Démarrage de la formation');
    formationState.startTime = new Date().toISOString();
    showLesson('1.1');
    updateProgress();
    saveFormationState();
    
    // Animation de démarrage
    const button = document.querySelector('button[onclick="startFormation()"]');
    if (button) {
        button.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Chargement...';
        setTimeout(() => {
            button.innerHTML = '<i class="fas fa-play me-2"></i>Formation en cours...';
            button.disabled = true;
        }, 1000);
    }
}

/**
 * Afficher une leçon spécifique
 */
function showLesson(lessonId) {
    console.log(`📖 Affichage de la leçon ${lessonId}`);
    
    // Cacher toutes les leçons
    document.querySelectorAll('.lesson-section').forEach(section => {
        section.style.display = 'none';
        section.classList.remove('active');
    });
    
    // Afficher la leçon demandée
    const targetLesson = document.getElementById(`lesson-${lessonId}`);
    if (targetLesson) {
        targetLesson.style.display = 'block';
        targetLesson.classList.add('active');
        
        // Mettre à jour l'état
        formationState.currentLesson = lessonId;
        formationState.lastActivity = new Date().toISOString();
        
        // Mettre à jour la navigation
        updateSidebarNavigation(lessonId);
        
        // Scroll vers le haut
        window.scrollTo({ top: 0, behavior: 'smooth' });
        
        // Sauvegarder l'état
        saveFormationState();
        
        console.log(`✅ Leçon ${lessonId} affichée`);
    } else {
        console.error(`❌ Leçon ${lessonId} non trouvée`);
        showNotification('Leçon non trouvée', 'error');
    }
}

/**
 * Navigation vers la leçon suivante
 */
function nextLesson(nextLessonId) {
    console.log(`➡️ Navigation vers la leçon suivante: ${nextLessonId}`);
    
    // Marquer la leçon actuelle comme complétée
    if (!formationState.completedLessons.includes(formationState.currentLesson)) {
        formationState.completedLessons.push(formationState.currentLesson);
        console.log(`✅ Leçon ${formationState.currentLesson} marquée comme complétée`);
    }
    
    // Afficher la leçon suivante
    showLesson(nextLessonId);
    
    // Mettre à jour la progression
    updateProgress();
    
    // Animation de transition
    showNotification(`Leçon ${nextLessonId} chargée`, 'success');
}

/**
 * Navigation vers la leçon précédente
 */
function previousLesson(prevLessonId) {
    console.log(`⬅️ Navigation vers la leçon précédente: ${prevLessonId}`);
    showLesson(prevLessonId);
    showNotification(`Retour à la leçon ${prevLessonId}`, 'info');
}

/**
 * Basculer l'affichage d'un module
 */
function toggleModule(moduleNumber) {
    console.log(`🔄 Basculement du module ${moduleNumber}`);
    
    const moduleItem = document.querySelector(`[data-module="${moduleNumber}"]`);
    if (!moduleItem) return;
    
    const moduleContent = moduleItem.querySelector('.module-content');
    const moduleToggle = moduleItem.querySelector('.module-toggle');
    
    if (moduleContent && moduleToggle) {
        const isExpanded = moduleContent.style.display !== 'none';
        
        if (isExpanded) {
            moduleContent.style.display = 'none';
            moduleToggle.style.transform = 'rotate(0deg)';
        } else {
            moduleContent.style.display = 'block';
            moduleToggle.style.transform = 'rotate(90deg)';
        }
    }
}

/**
 * Vérifier les réponses d'un quiz
 */
function checkQuiz() {
    const currentLesson = formationState.currentLesson;
    console.log(`🧩 Vérification du quiz pour la leçon ${currentLesson}`);
    
    if (!quizAnswers[currentLesson]) {
        showNotification('Quiz non configuré pour cette leçon', 'warning');
        return;
    }
    
    const correctAnswers = quizAnswers[currentLesson];
    let score = 0;
    let totalQuestions = Object.keys(correctAnswers).length;
    let results = [];
    
    // Vérifier chaque question
    Object.keys(correctAnswers).forEach(questionKey => {
        const selectedAnswer = document.querySelector(`input[name="${questionKey}"]:checked`);
        const isCorrect = selectedAnswer && selectedAnswer.value === correctAnswers[questionKey];
        
        if (isCorrect) {
            score++;
        }
        
        results.push({
            question: questionKey,
            correct: isCorrect,
            selected: selectedAnswer ? selectedAnswer.value : null,
            expected: correctAnswers[questionKey]
        });
    });
    
    // Calculer le pourcentage
    const percentage = Math.round((score / totalQuestions) * 100);
    
    // Sauvegarder le score
    formationState.quizScores[currentLesson] = {
        score: score,
        total: totalQuestions,
        percentage: percentage,
        timestamp: new Date().toISOString()
    };
    
    // Afficher les résultats
    displayQuizResults(score, totalQuestions, percentage, results);
    
    // Sauvegarder l'état
    saveFormationState();
    
    console.log(`📊 Quiz terminé: ${score}/${totalQuestions} (${percentage}%)`);
}

/**
 * Afficher les résultats du quiz
 */
function displayQuizResults(score, total, percentage, results) {
    // Créer le message de résultat
    let resultClass = 'success';
    let resultIcon = 'fa-check-circle';
    let resultMessage = 'Excellent !';
    
    if (percentage < 50) {
        resultClass = 'danger';
        resultIcon = 'fa-times-circle';
        resultMessage = 'À revoir';
    } else if (percentage < 80) {
        resultClass = 'warning';
        resultIcon = 'fa-exclamation-triangle';
        resultMessage = 'Bien';
    }
    
    // Créer l'HTML des résultats
    const resultsHTML = `
        <div class="quiz-results alert alert-${resultClass} mt-3">
            <h5><i class="fas ${resultIcon} me-2"></i>${resultMessage}</h5>
            <p><strong>Score:</strong> ${score}/${total} (${percentage}%)</p>
            <div class="results-detail">
                ${results.map((result, index) => `
                    <div class="result-item ${result.correct ? 'text-success' : 'text-danger'}">
                        <i class="fas ${result.correct ? 'fa-check' : 'fa-times'} me-2"></i>
                        Question ${index + 1}: ${result.correct ? 'Correct' : 'Incorrect'}
                        ${!result.correct ? `(Réponse: ${result.expected})` : ''}
                    </div>
                `).join('')}
            </div>
            <button class="btn btn-outline-${resultClass} btn-sm mt-2" onclick="retryQuiz()">
                <i class="fas fa-redo me-2"></i>Recommencer
            </button>
        </div>
    `;
    
    // Insérer les résultats après le quiz
    const quizSection = document.querySelector(`#lesson-${formationState.currentLesson} .quiz-section`);
    if (quizSection) {
        // Supprimer les anciens résultats
        const existingResults = quizSection.querySelector('.quiz-results');
        if (existingResults) {
            existingResults.remove();
        }
        
        // Ajouter les nouveaux résultats
        quizSection.insertAdjacentHTML('beforeend', resultsHTML);
    }
}

/**
 * Recommencer le quiz
 */
function retryQuiz() {
    console.log('🔄 Recommencer le quiz');
    
    // Réinitialiser les réponses
    const currentLessonElement = document.querySelector(`#lesson-${formationState.currentLesson}`);
    if (currentLessonElement) {
        currentLessonElement.querySelectorAll('input[type="radio"]').forEach(input => {
            input.checked = false;
        });
    }
    
    // Supprimer les résultats
    const quizResults = document.querySelector('.quiz-results');
    if (quizResults) {
        quizResults.remove();
    }
    
    showNotification('Quiz réinitialisé', 'info');
}

/**
 * Démarrer une démonstration
 */
function startDemo(demoType) {
    console.log(`🎬 Démarrage de la démonstration: ${demoType}`);
    
    // Simuler le chargement d'une démonstration
    const demoMessages = {
        'citizen-portal': 'Démonstration du portail citoyen en cours...',
        'portal-tour': 'Visite guidée du portail SAMA CONAI...',
        'registration-process': 'Processus d\'inscription étape par étape...',
        'profile-setup': 'Configuration du profil utilisateur...',
        'request-types': 'Types de demandes d\'information...',
        'form-filling': 'Remplissage du formulaire de demande...',
        'document-upload': 'Téléchargement de documents...',
        'submission-process': 'Processus de soumission...',
        'dashboard-overview': 'Vue d\'ensemble du tableau de bord...',
        'status-tracking': 'Suivi des statuts de demandes...',
        'notification-setup': 'Configuration des notifications...',
        'history-management': 'Gestion de l\'historique...',
        'alert-creator': 'Créateur d\'alertes citoyennes...',
        'anonymous-reporting': 'Signalement anonyme sécurisé...',
        'privacy-settings': 'Paramètres de confidentialité...',
        'writing-workshop': 'Atelier de rédaction efficace...',
        'request-planner': 'Planificateur de demandes...',
        'appeal-assistant': 'Assistant pour les recours...'
    };
    
    const message = demoMessages[demoType] || 'Démonstration interactive...';
    
    // Afficher une notification de démonstration
    showNotification(message, 'info', 3000);
    
    // Simuler l'ouverture d'une démonstration
    setTimeout(() => {
        showNotification('Démonstration terminée', 'success');
    }, 3000);
}

/**
 * Mettre à jour la progression
 */
function updateProgress() {
    const totalLessons = Object.values(moduleConfig).flat().length;
    const completedCount = formationState.completedLessons.length;
    const progressPercentage = Math.round((completedCount / totalLessons) * 100);
    
    // Mettre à jour la barre de progression
    const progressBar = document.getElementById('overallProgress');
    if (progressBar) {
        progressBar.style.width = `${progressPercentage}%`;
        progressBar.textContent = `${progressPercentage}%`;
    }
    
    // Mettre à jour le compteur de modules
    const completedModulesElement = document.getElementById('completedModules');
    if (completedModulesElement) {
        const completedModules = getCompletedModulesCount();
        completedModulesElement.textContent = completedModules;
    }
    
    console.log(`📊 Progression mise à jour: ${completedCount}/${totalLessons} leçons (${progressPercentage}%)`);
}

/**
 * Calculer le nombre de modules complétés
 */
function getCompletedModulesCount() {
    let completedModules = 0;
    
    Object.keys(moduleConfig).forEach(moduleNum => {
        const moduleLessons = moduleConfig[moduleNum];
        const completedInModule = moduleLessons.filter(lesson => 
            formationState.completedLessons.includes(lesson)
        ).length;
        
        if (completedInModule === moduleLessons.length) {
            completedModules++;
        }
    });
    
    return completedModules;
}

/**
 * Mettre à jour la navigation dans la sidebar
 */
function updateSidebarNavigation(currentLessonId) {
    // Réinitialiser tous les liens
    document.querySelectorAll('.lesson-link').forEach(link => {
        link.classList.remove('active', 'completed');
    });
    
    // Marquer la leçon actuelle
    const currentLink = document.querySelector(`[data-lesson="${currentLessonId}"]`);
    if (currentLink) {
        currentLink.classList.add('active');
    }
    
    // Marquer les leçons complétées
    formationState.completedLessons.forEach(lessonId => {
        const link = document.querySelector(`[data-lesson="${lessonId}"]`);
        if (link) {
            link.classList.add('completed');
        }
    });
}

/**
 * Terminer la formation
 */
function completeFormation() {
    console.log('🎉 Finalisation de la formation');
    
    // Marquer la dernière leçon comme complétée
    if (!formationState.completedLessons.includes(formationState.currentLesson)) {
        formationState.completedLessons.push(formationState.currentLesson);
    }
    
    // Calculer les statistiques finales
    const totalLessons = Object.values(moduleConfig).flat().length;
    const completedCount = formationState.completedLessons.length;
    const completionPercentage = Math.round((completedCount / totalLessons) * 100);
    
    // Afficher le message de félicitations
    const completionMessage = document.querySelector('.completion-message');
    if (completionMessage) {
        completionMessage.style.display = 'block';
        
        // Scroll vers le message
        completionMessage.scrollIntoView({ behavior: 'smooth' });
    }
    
    // Sauvegarder l'état final
    formationState.completionDate = new Date().toISOString();
    formationState.finalScore = completionPercentage;
    saveFormationState();
    
    // Notification de succès
    showNotification('🎉 Félicitations ! Formation terminée avec succès !', 'success', 5000);
    
    console.log(`✅ Formation terminée: ${completedCount}/${totalLessons} leçons (${completionPercentage}%)`);
}

/**
 * Sauvegarder l'état de la formation
 */
function saveFormationState() {
    try {
        localStorage.setItem('sama_conai_formation_state', JSON.stringify(formationState));
        console.log('💾 État de la formation sauvegardé');
    } catch (error) {
        console.error('❌ Erreur lors de la sauvegarde:', error);
    }
}

/**
 * Charger l'état de la formation
 */
function loadFormationState() {
    try {
        const savedState = localStorage.getItem('sama_conai_formation_state');
        if (savedState) {
            const parsedState = JSON.parse(savedState);
            formationState = { ...formationState, ...parsedState };
            console.log('📂 État de la formation chargé');
        }
    } catch (error) {
        console.error('❌ Erreur lors du chargement:', error);
    }
}

/**
 * Afficher une notification
 */
function showNotification(message, type = 'info', duration = 2000) {
    // Créer l'élément de notification
    const notification = document.createElement('div');
    notification.className = `alert alert-${type} notification-toast`;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 9999;
        min-width: 300px;
        opacity: 0;
        transform: translateX(100%);
        transition: all 0.3s ease;
    `;
    
    // Icônes selon le type
    const icons = {
        success: 'fa-check-circle',
        error: 'fa-times-circle',
        warning: 'fa-exclamation-triangle',
        info: 'fa-info-circle'
    };
    
    notification.innerHTML = `
        <i class="fas ${icons[type]} me-2"></i>
        ${message}
        <button type="button" class="btn-close" onclick="this.parentElement.remove()"></button>
    `;
    
    // Ajouter au DOM
    document.body.appendChild(notification);
    
    // Animation d'entrée
    setTimeout(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Suppression automatique
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 300);
    }, duration);
}

/**
 * Réinitialiser la formation
 */
function resetFormation() {
    if (confirm('Êtes-vous sûr de vouloir réinitialiser votre progression ?')) {
        localStorage.removeItem('sama_conai_formation_state');
        location.reload();
    }
}

/**
 * Exporter les données de formation
 */
function exportFormationData() {
    const data = {
        ...formationState,
        exportDate: new Date().toISOString(),
        userAgent: navigator.userAgent
    };
    
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = `sama_conai_formation_${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    showNotification('Données exportées avec succès', 'success');
}

// Initialisation automatique quand le DOM est prêt
document.addEventListener('DOMContentLoaded', function() {
    console.log('🌐 DOM chargé, initialisation de la formation...');
    
    // Petite pause pour s'assurer que tout est chargé
    setTimeout(initFormation, 500);
});

// Export des fonctions pour utilisation globale
window.startFormation = startFormation;
window.nextLesson = nextLesson;
window.previousLesson = previousLesson;
window.toggleModule = toggleModule;
window.checkQuiz = checkQuiz;
window.startDemo = startDemo;
window.completeFormation = completeFormation;
window.resetFormation = resetFormation;
window.exportFormationData = exportFormationData;

console.log('📚 Module de formation SAMA CONAI chargé');