// Couleurs du thème SAMA CONAI
export const colors = {
  // Couleurs principales
  primary: '#3498db',
  primaryDark: '#2980b9',
  primaryLight: '#85c1e9',
  
  // Couleurs secondaires
  secondary: '#e74c3c',
  secondaryDark: '#c0392b',
  secondaryLight: '#f1948a',
  
  // Couleurs d'état
  success: '#27ae60',
  warning: '#f39c12',
  error: '#e74c3c',
  info: '#3498db',
  
  // Couleurs de fond
  background: '#ffffff',
  surface: '#f8f9fa',
  card: '#ffffff',
  
  // Couleurs de texte
  text: '#2c3e50',
  textSecondary: '#7f8c8d',
  textLight: '#bdc3c7',
  
  // Couleurs d'interface
  border: '#ecf0f1',
  divider: '#e0e0e0',
  overlay: 'rgba(0, 0, 0, 0.5)',
  
  // Couleurs spécifiques SAMA CONAI
  samaGreen: '#27ae60',
  samaBlue: '#3498db',
  samaRed: '#e74c3c',
  samaYellow: '#f1c40f',
  
  // Couleurs pour les états des demandes
  submitted: '#f39c12',
  inProgress: '#3498db',
  responded: '#27ae60',
  refused: '#e74c3c',
  overdue: '#e74c3c',
  
  // Couleurs pour les priorités
  low: '#95a5a6',
  medium: '#f39c12',
  high: '#e67e22',
  urgent: '#e74c3c',
};

// Espacements
export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

// Tailles de police
export const typography = {
  h1: 32,
  h2: 28,
  h3: 24,
  h4: 20,
  h5: 18,
  h6: 16,
  body1: 16,
  body2: 14,
  caption: 12,
  button: 16,
};

// Rayons de bordure
export const borderRadius = {
  small: 4,
  medium: 8,
  large: 12,
  xlarge: 16,
  round: 50,
};

// Ombres
export const shadows = {
  small: {
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.18,
    shadowRadius: 1.0,
    elevation: 1,
  },
  medium: {
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  large: {
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.30,
    shadowRadius: 4.65,
    elevation: 8,
  },
};

// Thème complet
export const theme = {
  colors,
  spacing,
  typography,
  borderRadius,
  shadows,
};

export default theme;