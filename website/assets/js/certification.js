// Certification JavaScript Functions

// Exam configuration
const examConfig = {
    utilisateur: {
        title: 'Certification Utilisateur SAMA CONAI',
        duration: 120, // minutes
        totalQuestions: 20,
        passingScore: 70,
        maxAttempts: 3
    },
    formateur: {
        title: 'Certification Formateur SAMA CONAI',
        duration: 240, // minutes
        totalQuestions: 40,
        passingScore: 80,
        maxAttempts: 2
    },
    expert: {
        title: 'Certification Expert SAMA CONAI',
        duration: 360, // minutes
        totalQuestions: 60,
        passingScore: 85,
        maxAttempts: 2
    }
};

// Current exam state
let currentExam = {
    type: 'utilisateur',
    currentQuestion: 0,
    answers: {},
    startTime: null,
    timeRemaining: 0,
    timer: null,
    questions: []
};

// Sample questions for demonstration
const sampleQuestions = {
    utilisateur: [
        {
            id: 1,
            question: "Quel est le délai légal maximum pour répondre à une demande d'accès à l'information au Sénégal ?",
            type: "multiple",
            options: [
                { id: 'a', text: '15 jours' },
                { id: 'b', text: '30 jours' },
                { id: 'c', text: '20 jours' },
                { id: 'd', text: '45 jours' }
            ],
            correct: 'c',
            explanation: "Selon la loi sénégalaise, le délai maximum est de 20 jours."
        },
        {
            id: 2,
            question: "Les alertes citoyennes dans SAMA CONAI peuvent être soumises de manière anonyme.",
            type: "boolean",
            options: [
                { id: 'true', text: 'Vrai' },
                { id: 'false', text: 'Faux' }
            ],
            correct: 'true',
            explanation: "Le système permet l'anonymisation complète des alertes pour protéger les citoyens."
        },
        {
            id: 3,
            question: "Dans quelle section du tableau de bord pouvez-vous consulter les statistiques de transparence en temps réel ?",
            type: "multiple",
            options: [
                { id: 'a', text: 'Mes demandes' },
                { id: 'b', text: 'Dashboard public' },
                { id: 'c', text: 'Paramètres' },
                { id: 'd', text: 'Notifications' }
            ],
            correct: 'b',
            explanation: "Le Dashboard public affiche toutes les statistiques de transparence en temps réel."
        },
        {
            id: 4,
            question: "Quels sont les trois types principaux de demandes dans SAMA CONAI ?",
            type: "multiple",
            options: [
                { id: 'a', text: 'Information, Document, Statistique' },
                { id: 'b', text: 'Publique, Privée, Confidentielle' },
                { id: 'c', text: 'Urgente, Normale, Différée' },
                { id: 'd', text: 'Simple, Complexe, Spécialisée' }
            ],
            correct: 'a',
            explanation: "Les trois types sont : demandes d'information, de documents et de statistiques."
        },
        {
            id: 5,
            question: "Le module SAMA CONAI est compatible avec quelle version d'Odoo ?",
            type: "multiple",
            options: [
                { id: 'a', text: 'Odoo 16.0' },
                { id: 'b', text: 'Odoo 17.0' },
                { id: 'c', text: 'Odoo 18.0' },
                { id: 'd', text: 'Toutes les versions' }
            ],
            correct: 'c',
            explanation: "SAMA CONAI est spécifiquement développé pour Odoo 18.0."
        }
        // Add more questions as needed...
    ]
};

// Initialize certification page
document.addEventListener('DOMContentLoaded', function() {
    // Initialize AOS
    AOS.init({
        duration: 800,
        easing: 'ease-in-out',
        once: true
    });

    // Load previous attempts
    loadAttemptHistory();
    
    // Set up event listeners
    setupEventListeners();
    
    console.log('Certification page initialized');
});

// Set up event listeners
function setupEventListeners() {
    // Exam navigation buttons
    const prevBtn = document.getElementById('prevQuestion');
    const nextBtn = document.getElementById('nextQuestion');
    const submitBtn = document.getElementById('submitExam');
    
    if (prevBtn) {
        prevBtn.addEventListener('click', previousQuestion);
    }
    
    if (nextBtn) {
        nextBtn.addEventListener('click', nextQuestion);
    }
    
    if (submitBtn) {
        submitBtn.addEventListener('click', submitExam);
    }
}

// Start certification exam
function startCertification(examType = 'utilisateur') {
    // Check attempt limit
    const attempts = getAttemptCount(examType);
    const maxAttempts = examConfig[examType].maxAttempts;
    
    if (attempts >= maxAttempts) {
        showNotification(`Vous avez atteint le nombre maximum de tentatives (${maxAttempts}) pour cette certification.`, 'error');
        return;
    }
    
    // Initialize exam
    currentExam.type = examType;
    currentExam.currentQuestion = 0;
    currentExam.answers = {};
    currentExam.startTime = new Date();
    currentExam.timeRemaining = examConfig[examType].duration * 60; // Convert to seconds
    currentExam.questions = generateQuestions(examType);
    
    // Show exam modal
    const examModal = new bootstrap.Modal(document.getElementById('examModal'));
    examModal.show();
    
    // Start timer
    startExamTimer();
    
    // Load first question
    loadQuestion(0);
    
    // Track analytics
    trackEvent('Certification', 'Start Exam', examType);
    
    showNotification('Examen démarré ! Bonne chance !', 'success');
}

// Generate questions for exam
function generateQuestions(examType) {
    const availableQuestions = sampleQuestions[examType] || sampleQuestions.utilisateur;
    const totalQuestions = examConfig[examType].totalQuestions;
    
    // Shuffle and select questions
    const shuffled = [...availableQuestions].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, Math.min(totalQuestions, shuffled.length));
}

// Start exam timer
function startExamTimer() {
    const timerElement = document.getElementById('examTimer');
    
    currentExam.timer = setInterval(() => {
        currentExam.timeRemaining--;
        
        if (currentExam.timeRemaining <= 0) {
            clearInterval(currentExam.timer);
            autoSubmitExam();
            return;
        }
        
        // Update timer display
        const hours = Math.floor(currentExam.timeRemaining / 3600);
        const minutes = Math.floor((currentExam.timeRemaining % 3600) / 60);
        const seconds = currentExam.timeRemaining % 60;
        
        const timeString = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        timerElement.textContent = timeString;
        
        // Warning when 5 minutes left
        if (currentExam.timeRemaining === 300) {
            showNotification('⚠️ Il vous reste 5 minutes !', 'warning');
        }
        
        // Change color when time is running out
        if (currentExam.timeRemaining <= 300) {
            timerElement.style.background = 'rgba(239, 68, 68, 0.2)';
            timerElement.style.color = '#dc2626';
        }
        
    }, 1000);
}

// Load specific question
function loadQuestion(questionIndex) {
    const question = currentExam.questions[questionIndex];
    if (!question) return;
    
    const examContent = document.getElementById('examContent');
    const progressBar = document.getElementById('examProgress');
    const prevBtn = document.getElementById('prevQuestion');
    const nextBtn = document.getElementById('nextQuestion');
    const submitBtn = document.getElementById('submitExam');
    
    // Update progress
    const progress = ((questionIndex + 1) / currentExam.questions.length) * 100;
    progressBar.style.width = progress + '%';
    progressBar.textContent = `Question ${questionIndex + 1} sur ${currentExam.questions.length}`;
    
    // Generate question HTML
    const questionHTML = `
        <div class="exam-question active">
            <h4>Question ${questionIndex + 1}</h4>
            <p class="question-text">${question.question}</p>
            <div class="exam-options">
                ${question.options.map(option => `
                    <div class="exam-option ${currentExam.answers[question.id] === option.id ? 'selected' : ''}" 
                         onclick="selectAnswer(${question.id}, '${option.id}')">
                        <input type="radio" name="question_${question.id}" value="${option.id}" 
                               ${currentExam.answers[question.id] === option.id ? 'checked' : ''}>
                        <label>${option.text}</label>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
    
    examContent.innerHTML = questionHTML;
    
    // Update navigation buttons
    prevBtn.disabled = questionIndex === 0;
    
    if (questionIndex === currentExam.questions.length - 1) {
        nextBtn.style.display = 'none';
        submitBtn.style.display = 'inline-block';
    } else {
        nextBtn.style.display = 'inline-block';
        submitBtn.style.display = 'none';
    }
    
    currentExam.currentQuestion = questionIndex;
}

// Select answer for current question
function selectAnswer(questionId, answerId) {
    currentExam.answers[questionId] = answerId;
    
    // Update UI
    const options = document.querySelectorAll('.exam-option');
    options.forEach(option => {
        option.classList.remove('selected');
        const radio = option.querySelector('input[type="radio"]');
        radio.checked = false;
    });
    
    const selectedOption = document.querySelector(`input[value="${answerId}"]`).closest('.exam-option');
    selectedOption.classList.add('selected');
    selectedOption.querySelector('input[type="radio"]').checked = true;
    
    // Track analytics
    trackEvent('Certification', 'Answer Selected', `Q${questionId}_${answerId}`);
}

// Navigate to previous question
function previousQuestion() {
    if (currentExam.currentQuestion > 0) {
        loadQuestion(currentExam.currentQuestion - 1);
    }
}

// Navigate to next question
function nextQuestion() {
    if (currentExam.currentQuestion < currentExam.questions.length - 1) {
        loadQuestion(currentExam.currentQuestion + 1);
    }
}

// Submit exam
function submitExam() {
    // Check if all questions are answered
    const unansweredQuestions = currentExam.questions.filter(q => !currentExam.answers[q.id]);
    
    if (unansweredQuestions.length > 0) {
        const proceed = confirm(`Vous avez ${unansweredQuestions.length} question(s) non répondue(s). Voulez-vous vraiment terminer l'examen ?`);
        if (!proceed) return;
    }
    
    // Stop timer
    clearInterval(currentExam.timer);
    
    // Calculate results
    const results = calculateResults();
    
    // Save attempt
    saveAttempt(results);
    
    // Show results
    showResults(results);
    
    // Track analytics
    trackEvent('Certification', 'Submit Exam', `${currentExam.type}_${results.passed ? 'PASS' : 'FAIL'}`);
}

// Auto-submit when time runs out
function autoSubmitExam() {
    showNotification('⏰ Temps écoulé ! Soumission automatique de l\'examen.', 'warning');
    submitExam();
}

// Calculate exam results
function calculateResults() {
    let correctAnswers = 0;
    const totalQuestions = currentExam.questions.length;
    const questionResults = [];
    
    currentExam.questions.forEach(question => {
        const userAnswer = currentExam.answers[question.id];
        const isCorrect = userAnswer === question.correct;
        
        if (isCorrect) correctAnswers++;
        
        questionResults.push({
            questionId: question.id,
            question: question.question,
            userAnswer: userAnswer,
            correctAnswer: question.correct,
            isCorrect: isCorrect,
            explanation: question.explanation
        });
    });
    
    const score = Math.round((correctAnswers / totalQuestions) * 100);
    const passingScore = examConfig[currentExam.type].passingScore;
    const passed = score >= passingScore;
    
    const endTime = new Date();
    const timeSpent = Math.round((endTime - currentExam.startTime) / 1000 / 60); // minutes
    
    return {
        examType: currentExam.type,
        score: score,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        passed: passed,
        passingScore: passingScore,
        timeSpent: timeSpent,
        date: endTime.toISOString(),
        questionResults: questionResults,
        certificateId: passed ? generateCertificateId() : null
    };
}

// Show exam results
function showResults(results) {
    // Hide exam modal
    const examModal = bootstrap.Modal.getInstance(document.getElementById('examModal'));
    examModal.hide();
    
    // Create results modal
    const resultsModal = document.createElement('div');
    resultsModal.className = 'modal fade results-modal';
    resultsModal.innerHTML = `
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header ${results.passed ? 'bg-success' : 'bg-danger'} text-white">
                    <h5 class="modal-title">
                        <i class="fas ${results.passed ? 'fa-trophy' : 'fa-times-circle'} me-2"></i>
                        Résultats de l'Examen
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="results-score ${results.passed ? 'pass' : 'fail'}">
                        ${results.score}%
                    </div>
                    <div class="results-message">
                        ${results.passed ? 
                            `🎉 Félicitations ! Vous avez réussi la certification ${examConfig[results.examType].title}` :
                            `😔 Vous n'avez pas atteint le score requis de ${results.passingScore}%. Vous pouvez réessayer.`
                        }
                    </div>
                    
                    <div class="results-details">
                        <div class="results-breakdown">
                            <div class="breakdown-item">
                                <div class="breakdown-number">${results.correctAnswers}</div>
                                <div class="breakdown-label">Bonnes réponses</div>
                            </div>
                            <div class="breakdown-item">
                                <div class="breakdown-number">${results.totalQuestions - results.correctAnswers}</div>
                                <div class="breakdown-label">Erreurs</div>
                            </div>
                            <div class="breakdown-item">
                                <div class="breakdown-number">${results.timeSpent}</div>
                                <div class="breakdown-label">Minutes</div>
                            </div>
                            <div class="breakdown-item">
                                <div class="breakdown-number">${results.passingScore}%</div>
                                <div class="breakdown-label">Requis</div>
                            </div>
                        </div>
                    </div>
                    
                    ${results.passed ? `
                        <div class="certificate-preview">
                            <div class="certificate-header">
                                <h3 class="certificate-title">Certificat de Réussite</h3>
                                <p class="certificate-subtitle">${examConfig[results.examType].title}</p>
                            </div>
                            <div class="certificate-recipient">
                                Utilisateur Certifié
                            </div>
                            <div class="certificate-details">
                                <div>Numéro: ${results.certificateId}</div>
                                <div>Date: ${new Date(results.date).toLocaleDateString('fr-FR')}</div>
                                <div>Score: ${results.score}%</div>
                            </div>
                        </div>
                        <button class="btn btn-primary" onclick="downloadCertificate('${results.certificateId}')">
                            <i class="fas fa-download me-2"></i>Télécharger le Certificat
                        </button>
                    ` : `
                        <div class="retry-info">
                            <p>Vous pouvez repasser l'examen après 24 heures.</p>
                            <p>Tentatives restantes: ${examConfig[results.examType].maxAttempts - getAttemptCount(results.examType)}</p>
                        </div>
                    `}
                    
                    <button class="btn btn-outline-primary mt-3" onclick="showDetailedResults('${results.date}')">
                        <i class="fas fa-list me-2"></i>Voir les Réponses Détaillées
                    </button>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(resultsModal);
    const modal = new bootstrap.Modal(resultsModal);
    modal.show();
    
    // Remove modal from DOM when hidden
    resultsModal.addEventListener('hidden.bs.modal', function() {
        document.body.removeChild(resultsModal);
    });
    
    // Save certification result if passed
    if (results.passed) {
        saveCertificationResult(results.examType, results.score, true);
    }
}

// Generate certificate ID
function generateCertificateId() {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substr(2, 5).toUpperCase();
    return `SAMA-${currentExam.type.toUpperCase()}-${timestamp}-${random}`;
}

// Save attempt to localStorage
function saveAttempt(results) {
    let attempts = JSON.parse(localStorage.getItem('certification_attempts') || '[]');
    attempts.push(results);
    localStorage.setItem('certification_attempts', JSON.stringify(attempts));
}

// Get attempt count for specific exam type
function getAttemptCount(examType) {
    const attempts = JSON.parse(localStorage.getItem('certification_attempts') || '[]');
    return attempts.filter(attempt => attempt.examType === examType).length;
}

// Load attempt history
function loadAttemptHistory() {
    const attempts = JSON.parse(localStorage.getItem('certification_attempts') || '[]');
    
    // Update UI with attempt history if needed
    const historyContainer = document.getElementById('attemptHistory');
    if (historyContainer && attempts.length > 0) {
        const historyHTML = attempts.map(attempt => `
            <div class="attempt-item ${attempt.passed ? 'passed' : 'failed'}">
                <div class="attempt-info">
                    <strong>${examConfig[attempt.examType].title}</strong>
                    <span class="attempt-score">${attempt.score}%</span>
                </div>
                <div class="attempt-date">
                    ${new Date(attempt.date).toLocaleDateString('fr-FR')}
                </div>
            </div>
        `).join('');
        
        historyContainer.innerHTML = historyHTML;
    }
}

// Show detailed results
function showDetailedResults(attemptDate) {
    const attempts = JSON.parse(localStorage.getItem('certification_attempts') || '[]');
    const attempt = attempts.find(a => a.date === attemptDate);
    
    if (!attempt) return;
    
    // Create detailed results modal
    const detailsModal = document.createElement('div');
    detailsModal.className = 'modal fade';
    detailsModal.innerHTML = `
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-list me-2"></i>Réponses Détaillées
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="detailed-results">
                        ${attempt.questionResults.map((result, index) => `
                            <div class="question-result ${result.isCorrect ? 'correct' : 'incorrect'}">
                                <div class="question-header">
                                    <span class="question-number">Question ${index + 1}</span>
                                    <span class="result-icon">
                                        <i class="fas ${result.isCorrect ? 'fa-check-circle text-success' : 'fa-times-circle text-danger'}"></i>
                                    </span>
                                </div>
                                <div class="question-text">${result.question}</div>
                                <div class="answer-info">
                                    <div class="user-answer">
                                        <strong>Votre réponse:</strong> ${result.userAnswer || 'Non répondu'}
                                    </div>
                                    ${!result.isCorrect ? `
                                        <div class="correct-answer">
                                            <strong>Bonne réponse:</strong> ${result.correctAnswer}
                                        </div>
                                    ` : ''}
                                    ${result.explanation ? `
                                        <div class="explanation">
                                            <strong>Explication:</strong> ${result.explanation}
                                        </div>
                                    ` : ''}
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Fermer</button>
                    <button type="button" class="btn btn-primary" onclick="printResults()">
                        <i class="fas fa-print me-2"></i>Imprimer
                    </button>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(detailsModal);
    const modal = new bootstrap.Modal(detailsModal);
    modal.show();
    
    // Remove modal from DOM when hidden
    detailsModal.addEventListener('hidden.bs.modal', function() {
        document.body.removeChild(detailsModal);
    });
}

// Download certificate
window.downloadCertificate = function(certificateId) {
    // In a real implementation, this would generate a PDF certificate
    showNotification(`Téléchargement du certificat ${certificateId} (fonctionnalité à implémenter)`, 'info');
    trackEvent('Certification', 'Certificate Download', certificateId);
};

// Print results
function printResults() {
    window.print();
}

// Reset certification data
function resetCertificationData() {
    if (confirm('Êtes-vous sûr de vouloir supprimer toutes vos données de certification ? Cette action est irréversible.')) {
        localStorage.removeItem('certification_attempts');
        localStorage.removeItem('certifications');
        showNotification('Données de certification supprimées.', 'info');
        loadAttemptHistory();
        trackEvent('Certification', 'Data Reset', 'All');
    }
}

// Utility functions
function formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

function getGradeLevel(score) {
    if (score >= 90) return { grade: 'A+', level: 'Excellent' };
    if (score >= 85) return { grade: 'A', level: 'Très bien' };
    if (score >= 80) return { grade: 'B+', level: 'Bien' };
    if (score >= 75) return { grade: 'B', level: 'Assez bien' };
    if (score >= 70) return { grade: 'C+', level: 'Passable' };
    return { grade: 'F', level: 'Insuffisant' };
}

// Export certification data
function exportCertificationData() {
    const attempts = JSON.parse(localStorage.getItem('certification_attempts') || '[]');
    const certifications = JSON.parse(localStorage.getItem('certifications') || '[]');
    
    const exportData = {
        attempts: attempts,
        certifications: certifications,
        exportDate: new Date().toISOString(),
        version: '1.0'
    };
    
    const dataStr = JSON.stringify(exportData, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `certification_data_${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    
    URL.revokeObjectURL(url);
    
    showNotification('Données de certification exportées !', 'success');
    trackEvent('Certification', 'Data Export', 'JSON');
}