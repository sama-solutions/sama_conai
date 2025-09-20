import React, { useEffect, useState } from 'react';
import {
  View,
  ScrollView,
  RefreshControl,
  StyleSheet,
  Alert,
  Text,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { citizenApi } from '../../services/api';
import { colors, spacing } from '../../theme';

interface DashboardData {
  user_stats: {
    total_requests: number;
    pending_requests: number;
    completed_requests: number;
    overdue_requests: number;
  };
  recent_requests: Array<{
    id: number;
    name: string;
    description: string;
    request_date: string;
    state: string;
    state_label: string;
    days_to_deadline: number;
    is_overdue: boolean;
  }>;
  public_stats: {
    total_public_requests: number;
    avg_response_time: number;
    success_rate: number;
  };
}

export const CitizenDashboardScreen: React.FC = () => {
  const navigation = useNavigation();
  const [refreshing, setRefreshing] = useState(false);
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadDashboard = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await citizenApi.getDashboard();
      if (data.success) {
        setDashboardData(data.data);
      } else {
        setError(data.error || 'Erreur lors du chargement');
      }
    } catch (err) {
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadDashboard();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadDashboard();
    setRefreshing(false);
  };

  const getStateColor = (state: string, isOverdue: boolean) => {
    if (isOverdue) return colors.error;
    switch (state) {
      case 'submitted':
        return colors.warning;
      case 'in_progress':
        return colors.info;
      case 'responded':
        return colors.success;
      case 'refused':
        return colors.error;
      default:
        return colors.surface;
    }
  };

  const navigateToCreateRequest = () => {
    Alert.alert('Info', 'Fonctionnalité en développement');
  };

  const navigateToMyRequests = () => {
    Alert.alert('Info', 'Fonctionnalité en développement');
  };

  const navigateToCreateAlert = () => {
    Alert.alert('Info', 'Fonctionnalité en développement');
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Chargement du tableau de bord...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>
          {error}
        </Text>
        <TouchableOpacity style={styles.retryButton} onPress={loadDashboard}>
          <Text style={styles.retryButtonText}>Réessayer</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* En-tête de bienvenue */}
        <View style={styles.welcomeCard}>
          <Text style={styles.welcomeTitle}>
            Bienvenue sur SAMA CONAI
          </Text>
          <Text style={styles.welcomeSubtitle}>
            Votre portail de transparence gouvernementale
          </Text>
        </View>

        {/* Statistiques personnelles */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Mes Statistiques</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statItem}>
              <Text style={styles.statNumber}>
                {dashboardData?.user_stats.total_requests || 0}
              </Text>
              <Text style={styles.statLabel}>Total</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={[styles.statNumber, { color: colors.warning }]}>
                {dashboardData?.user_stats.pending_requests || 0}
              </Text>
              <Text style={styles.statLabel}>En cours</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={[styles.statNumber, { color: colors.success }]}>
                {dashboardData?.user_stats.completed_requests || 0}
              </Text>
              <Text style={styles.statLabel}>Terminées</Text>
            </View>
            <View style={styles.statItem}>
              <Text style={[styles.statNumber, { color: colors.error }]}>
                {dashboardData?.user_stats.overdue_requests || 0}
              </Text>
              <Text style={styles.statLabel}>En retard</Text>
            </View>
          </View>
        </View>

        {/* Actions rapides */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Actions Rapides</Text>
          <View style={styles.actionButtons}>
            <TouchableOpacity
              style={[styles.actionButton, styles.primaryButton]}
              onPress={navigateToCreateRequest}
            >
              <Text style={styles.actionButtonText}>📄 Nouvelle Demande</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.actionButton, styles.secondaryButton]}
              onPress={navigateToCreateAlert}
            >
              <Text style={[styles.actionButtonText, styles.secondaryButtonText]}>
                🚨 Signaler une Alerte
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Demandes récentes */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Mes Demandes Récentes</Text>
            <TouchableOpacity onPress={navigateToMyRequests}>
              <Text style={styles.linkText}>Voir tout</Text>
            </TouchableOpacity>
          </View>
          
          {!dashboardData?.recent_requests.length ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyStateText}>
                Aucune demande récente
              </Text>
              <TouchableOpacity
                style={styles.emptyStateButton}
                onPress={navigateToCreateRequest}
              >
                <Text style={styles.emptyStateButtonText}>
                  Créer ma première demande
                </Text>
              </TouchableOpacity>
            </View>
          ) : (
            dashboardData?.recent_requests.map((request) => (
              <View key={request.id} style={styles.requestCard}>
                <View style={styles.requestHeader}>
                  <Text style={styles.requestNumber}>{request.name}</Text>
                  <View style={[
                    styles.statusChip,
                    { backgroundColor: getStateColor(request.state, request.is_overdue) }
                  ]}>
                    <Text style={styles.statusChipText}>{request.state_label}</Text>
                  </View>
                </View>
                <Text style={styles.requestDescription} numberOfLines={2}>
                  {request.description}
                </Text>
                <View style={styles.requestFooter}>
                  <Text style={styles.requestDate}>
                    {new Date(request.request_date).toLocaleDateString('fr-FR')}
                  </Text>
                  {request.is_overdue ? (
                    <Text style={[styles.deadline, { color: colors.error }]}>
                      En retard de {Math.abs(request.days_to_deadline)} jours
                    </Text>
                  ) : (
                    <Text style={styles.deadline}>
                      {request.days_to_deadline} jours restants
                    </Text>
                  )}
                </View>
              </View>
            ))
          )}
        </View>

        {/* Statistiques publiques */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Transparence Publique</Text>
          <View style={styles.publicStats}>
            <View style={styles.publicStatItem}>
              <Text style={styles.publicStatNumber}>
                {dashboardData?.public_stats.total_public_requests || 0}
              </Text>
              <Text style={styles.publicStatLabel}>
                Demandes publiques totales
              </Text>
            </View>
            <View style={styles.publicStatItem}>
              <Text style={styles.publicStatNumber}>
                {dashboardData?.public_stats.avg_response_time || 0} jours
              </Text>
              <Text style={styles.publicStatLabel}>
                Temps de réponse moyen
              </Text>
            </View>
            <View style={styles.publicStatItem}>
              <Text style={styles.publicStatNumber}>
                {dashboardData?.public_stats.success_rate || 0}%
              </Text>
              <Text style={styles.publicStatLabel}>
                Taux de succès
              </Text>
            </View>
          </View>
        </View>
      </ScrollView>

      {/* Bouton d'action flottant */}
      <TouchableOpacity
        style={styles.fab}
        onPress={navigateToCreateRequest}
      >
        <Text style={styles.fabText}>+</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollView: {
    flex: 1,
    padding: spacing.md,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  loadingText: {
    marginTop: spacing.md,
    color: colors.text,
    fontSize: 16,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing.lg,
    backgroundColor: colors.background,
  },
  errorText: {
    textAlign: 'center',
    marginBottom: spacing.lg,
    color: colors.error,
    fontSize: 16,
  },
  retryButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 8,
  },
  retryButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  welcomeCard: {
    padding: spacing.lg,
    marginBottom: spacing.md,
    borderRadius: 12,
    backgroundColor: colors.surface,
    elevation: 2,
  },
  welcomeTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.primary,
    textAlign: 'center',
  },
  welcomeSubtitle: {
    textAlign: 'center',
    color: colors.textSecondary,
    marginTop: spacing.sm,
    fontSize: 16,
  },
  card: {
    marginBottom: spacing.md,
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: spacing.lg,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.text,
    marginBottom: spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  linkText: {
    color: colors.primary,
    fontSize: 14,
    fontWeight: '600',
  },
  statsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.primary,
  },
  statLabel: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: spacing.xs,
  },
  actionButtons: {
    gap: spacing.md,
  },
  actionButton: {
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: 8,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: colors.primary,
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: colors.primary,
  },
  actionButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  secondaryButtonText: {
    color: colors.primary,
  },
  emptyState: {
    alignItems: 'center',
    padding: spacing.lg,
  },
  emptyStateText: {
    color: colors.textSecondary,
    marginBottom: spacing.md,
    fontSize: 16,
  },
  emptyStateButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 8,
  },
  emptyStateButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  requestCard: {
    marginBottom: spacing.sm,
    padding: spacing.md,
    backgroundColor: colors.surface,
    borderRadius: 8,
    elevation: 1,
  },
  requestHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  requestNumber: {
    fontWeight: 'bold',
    color: colors.primary,
    fontSize: 16,
  },
  statusChip: {
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: 12,
  },
  statusChipText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
  },
  requestDescription: {
    color: colors.text,
    marginBottom: spacing.sm,
    fontSize: 14,
  },
  requestFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  requestDate: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  deadline: {
    fontSize: 12,
    fontWeight: 'bold',
    color: colors.textSecondary,
  },
  publicStats: {
    gap: spacing.md,
  },
  publicStatItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  publicStatNumber: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
  },
  publicStatLabel: {
    flex: 1,
    marginLeft: spacing.md,
    color: colors.text,
    fontSize: 14,
  },
  fab: {
    position: 'absolute',
    width: 56,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    right: spacing.lg,
    bottom: spacing.lg,
    backgroundColor: colors.primary,
    borderRadius: 28,
    elevation: 8,
  },
  fabText: {
    fontSize: 24,
    color: 'white',
    fontWeight: 'bold',
  },
});

export default CitizenDashboardScreen;