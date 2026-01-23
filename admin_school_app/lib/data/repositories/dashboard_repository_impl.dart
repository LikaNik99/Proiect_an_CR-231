import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/dashboard_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardDataSource dataSource;

  DashboardRepositoryImpl(this.dataSource);

  @override
  Future<DashboardStatsEntity> getDashboardStats() async {
    return await dataSource.getDashboardStats();
  }
}