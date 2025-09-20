import React from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Alert,
} from 'react-native';
import {Provider as PaperProvider} from 'react-native-paper';
import {NavigationContainer} from '@react-navigation/native';
import {createStackNavigator} from '@react-navigation/stack';
import CitizenDashboardScreen from './screens/citizen/CitizenDashboardScreen';

const Stack = createStackNavigator();

// Écran d'accueil temporaire
const HomeScreen = ({navigation}: any) => {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#ffffff" />
      <ScrollView contentInsetAdjustmentBehavior="automatic" style={styles.scrollView}>
        <View style={styles.header}>
          <Text style={styles.title}>🇸🇳 SAMA CONAI</Text>
          <Text style={styles.subtitle}>Transparence Gouvernementale</Text>
        </View>
        
        <View style={styles.content}>
          <Text style={styles.description}>
            Bienvenue dans l'application mobile SAMA CONAI pour la transparence 
            gouvernementale au Sénégal.
          </Text>
          
          <View style={styles.buttonContainer}>
            <TouchableOpacity 
              style={[styles.button, styles.primaryButton]}
              onPress={() => navigation.navigate('CitizenDashboard')}
            >
              <Text style={styles.buttonText}>👥 Interface Citoyen</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={[styles.button, styles.secondaryButton]}
              onPress={() => Alert.alert('Info', 'Interface Agent en développement')}
            >
              <Text style={[styles.buttonText, styles.secondaryButtonText]}>
                🏛️ Interface Agent
              </Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.features}>
            <Text style={styles.featuresTitle}>Fonctionnalités :</Text>
            <Text style={styles.feature}>📋 Demandes d'accès à l'information</Text>
            <Text style={styles.feature}>🚨 Signalements d'alerte anonymes</Text>
            <Text style={styles.feature}>📊 Suivi en temps réel</Text>
            <Text style={styles.feature}>🔔 Notifications push</Text>
            <Text style={styles.feature}>📱 Interface mobile optimisée</Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const App = () => {
  return (
    <PaperProvider>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="Home">
          <Stack.Screen 
            name="Home" 
            component={HomeScreen} 
            options={{title: 'SAMA CONAI'}}
          />
          <Stack.Screen 
            name="CitizenDashboard" 
            component={CitizenDashboardScreen} 
            options={{title: 'Tableau de Bord Citoyen'}}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </PaperProvider>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  scrollView: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    paddingVertical: 40,
    backgroundColor: '#f8f9fa',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#7f8c8d',
    textAlign: 'center',
  },
  content: {
    padding: 20,
  },
  description: {
    fontSize: 16,
    lineHeight: 24,
    color: '#34495e',
    textAlign: 'center',
    marginBottom: 30,
  },
  buttonContainer: {
    marginBottom: 30,
  },
  button: {
    paddingVertical: 15,
    paddingHorizontal: 20,
    borderRadius: 8,
    marginBottom: 15,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: '#3498db',
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: '#3498db',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
  },
  secondaryButtonText: {
    color: '#3498db',
  },
  features: {
    backgroundColor: '#ecf0f1',
    padding: 20,
    borderRadius: 8,
  },
  featuresTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 15,
  },
  feature: {
    fontSize: 14,
    color: '#34495e',
    marginBottom: 8,
    paddingLeft: 10,
  },
});

export default App;