import 'package:dio/dio.dart';
import '../models/dashboard_stats_model.dart';
import '../../core/network/network_fallback.dart';
import '../../core/database/database_connection_manager.dart';
import '../../core/database/db_error_mapper.dart';
import 'db/dashboard_db_data_source.dart';

class DashboardDataSource {
  final Dio dio;
  final DashboardDbDataSource dbDataSource;

  DashboardDataSource(this.dio, DatabaseConnectionManager dbManager)
      : dbDataSource = DashboardDbDataSource(dbManager);

  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await dio.get('/dashboard/stats');
      return DashboardStatsModel.fromJson(response.data);
    } catch (e) {
      final errObj = e is Object ? e : Exception('Unknown error');
      if (NetworkFallback.shouldFallback(errObj)) {
        try {
          return await dbDataSource.getDashboardStats();
        } catch (dbErr) {
          throw Exception(DbErrorMapper.toUserMessage(dbErr is Object ? dbErr : Exception('Unknown DB error')));
        }
      }
      throw Exception(NetworkFallback.describe(errObj));
    }
  }
}