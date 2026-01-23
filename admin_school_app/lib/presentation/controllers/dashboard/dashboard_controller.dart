import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/dashboard_stats_entity.dart';
import '../../../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import '../../../core/network/network_fallback.dart';

class DashboardController extends GetxController {
  final GetDashboardStatsUseCase getDashboardStatsUseCase =
      GetIt.instance.get<GetDashboardStatsUseCase>();

  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  Rx<DashboardStatsEntity?> stats = Rx<DashboardStatsEntity?>(null);

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await getDashboardStatsUseCase();
      stats.value = result;

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value =
          'Eroare la încărcarea statisticilor: ${NetworkFallback.describe(e is Object ? e : Exception('Unknown error'))}';
    }
  }

  Future<void> refresh() async {
    await loadDashboardStats();
  }
}