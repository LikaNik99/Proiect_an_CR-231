import '../../entities/dashboard_stats_entity.dart';
import '../../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  final DashboardRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<DashboardStatsEntity> call() async {
    return await repository.getDashboardStats();
  }
}