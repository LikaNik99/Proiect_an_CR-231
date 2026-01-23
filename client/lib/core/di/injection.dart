import 'package:SchoolApp/features/student/domain/repositories/student_repository.dart';
import 'package:SchoolApp/features/student/domain/usecase/student_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:get/get.dart' as getx;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../features/auth/data/datasource/auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_email_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/school/data/datasource/school_remote_data_source.dart';
import '../../features/school/data/repositories/school_repository_impl.dart';
import '../../features/school/domain/repositories/school_repository.dart';
import '../../features/school/domain/usecases/get_schools_usecase.dart';
import '../../features/school/domain/usecases/create_school_usecase.dart';
import '../../features/school/domain/usecases/update_school_usecase.dart';
import '../../features/school/domain/usecases/delete_school_usecase.dart';
import '../../features/school/presentation/controllers/school_controllers.dart';
import '../../features/student/data/datasource/student_remote_data_source.dart';
import '../../features/student/data/repositories/student_repository_impl.dart';
import '../../features/student/presentation/controllers/student_controller.dart';
import '../../features/teacher/data/datasource/teacher_remote_data_source.dart';
import '../../features/teacher/data/repositories/teacher_repository_impl.dart';
import '../../features/teacher/domain/repositories/teacher_repository.dart';
import '../../features/teacher/domain/usecases/get_current_teacher.dart';
import '../../features/teacher/data/datasource/grade_remote_data_source.dart';
import '../../features/teacher/data/datasource/homework_remote_data_source.dart';
import '../../features/teacher/data/datasource/attendance_remote_data_source.dart';
import '../../features/teacher/data/datasource/schedule_remote_data_source.dart';
import '../../features/teacher/data/datasource/material_remote_data_source.dart';
import '../../features/teacher/presentation/controllers/teacher_dashboard_controller.dart';
import '../config/app_config.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/data/datasource/password_data_source.dart';
import '../../features/auth/data/repositories/password_repositories_impl.dart';
import '../../features/auth/domain/repositories/password_repositories.dart';
import '../../features/auth/domain/usecases/send_reset_code_usecase.dart';
import '../../features/auth/presentation/controllers/password_controller.dart';
import '../network/connectivity_manager.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_manager.dart';
import '../network/api_health_service.dart';
import '../offline/offline_action_handler.dart';

final sl = GetIt.instance;

bool _isRedirectingToLogin = false;

Future<void> initDependencies() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );


  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final path = error.requestOptions.path;



        const noisyPaths = ['/'];
        final isNoisy = noisyPaths.any((p) => path.contains(p));

        if (!isNoisy) {
          debugPrint(
            '>>> DI Dio Error: ${error.response?.statusCode} on ${error.requestOptions.path}',
          );
        }


        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.unknown ||
            error.response == null) {
          ApiHealthService.markDown();
        }

        if (error.response?.statusCode == 401) {

          final refreshed = await _tryRefreshToken(dio);
          if (refreshed) {

            final token = await SecureStorageService.getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              if (e is DioException && e.response?.statusCode == 401) {
                _handleUnauthorized();
              }
              return handler.next(error);
            }
          } else {
            _handleUnauthorized();
          }
        }
        return handler.next(error);
      },
      onResponse: (response, handler) {
        ApiHealthService.markUp();
        handler.next(response);
      },
    ),
  );

  sl.registerLazySingleton<Dio>(() => dio);


  sl.registerLazySingleton<ConnectivityManager>(
    () => ConnectivityManager(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue());
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      queue: sl<SyncQueue>(),
      connectivity: sl<ConnectivityManager>(),
      dio: sl<Dio>(),
    ),
  );


  await sl<SyncManager>().start();

  sl.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(sl<Dio>()),
  );


  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(sl<StudentRemoteDataSource>()),
  );


  sl.registerLazySingleton(() => StudentUseCase(sl<StudentRepository>()));


  sl.registerFactory(() => StudentController(sl<StudentUseCase>()));



  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );


  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );


  sl.registerLazySingleton(() => CheckEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));


  sl.registerFactory(
    () => LoginController(sl<CheckEmailUseCase>(), sl<LoginUseCase>()),
  );



  sl.registerLazySingleton<SchoolRemoteDataSource>(
    () => SchoolRemoteDataSourceImpl(sl<Dio>()),
  );


  sl.registerLazySingleton<SchoolRepository>(
    () => SchoolRepositoryImpl(sl<SchoolRemoteDataSource>()),
  );


  sl.registerLazySingleton(() => GetSchoolsUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => CreateSchoolUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => UpdateSchoolUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => DeleteSchoolUseCase(sl<SchoolRepository>()));

  sl.registerFactory(() => SchoolController());


  sl.registerLazySingleton<PasswordDataSource>(
    () => PasswordDataSourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<PasswordRepository>(
    () => PasswordRepositoryImpl(sl<PasswordDataSource>()),
  );

  sl.registerLazySingleton(
    () => SendResetCodeUseCase(sl<PasswordRepository>()),
  );
  sl.registerLazySingleton(
    () => ResetPasswordUseCase(sl<PasswordRepository>()),
  );
  sl.registerLazySingleton(
    () => SendActivationCodeUseCase(sl<PasswordRepository>()),
  );
  sl.registerLazySingleton(() => SetPasswordUseCase(sl<PasswordRepository>()));

  sl.registerFactory(
    () => PasswordController(
      sendResetCodeUseCase: sl<SendResetCodeUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      sendActivationCodeUseCase: sl<SendActivationCodeUseCase>(),
      setPasswordUseCase: sl<SetPasswordUseCase>(),
    ),
  );

  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<TeacherRepository>(
    () =>
        TeacherRepositoryImpl(remoteDataSource: sl<TeacherRemoteDataSource>()),
  );


  sl.registerLazySingleton(
    () => GetCurrentTeacherUseCase(sl<TeacherRepository>()),
  );


  sl.registerLazySingleton<GradeRemoteDataSource>(
    () => GradeRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<HomeworkRemoteDataSource>(
    () => HomeworkRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<MaterialRemoteDataSource>(
    () => MaterialRemoteDataSourceImpl(dio: sl<Dio>()),
  );


  sl.registerFactory(() => TeacherDashboardController());

  sl.registerLazySingleton<OfflineActionHandler>(
    () => OfflineActionHandler(
      connectivity: sl<ConnectivityManager>(),
      queue: sl<SyncQueue>(),
    ),
  );
}

Future<bool> _tryRefreshToken(Dio dio) async {
  try {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null) {
      debugPrint('>>> No refresh token available');
      return false;
    }

    debugPrint('>>> Attempting token refresh...');
    final freshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
    final response = await freshDio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    if (response.statusCode == 200) {
      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];
      final role = await SecureStorageService.getRole();
      final userId = await SecureStorageService.getUserId();

      await SecureStorageService.saveToken(
        newAccessToken,
        role ?? '',
        userId ?? '',
      );
      if (newRefreshToken != null) {
        await SecureStorageService.saveRefreshToken(newRefreshToken);
      }
      debugPrint('>>> Token refreshed successfully');
      return true;
    }
  } catch (e) {
    debugPrint('>>> Token refresh failed: $e');
  }
  return false;
}

void _handleUnauthorized() async {
  if (_isRedirectingToLogin) return;
  _isRedirectingToLogin = true;

  debugPrint('>>> Unauthorized - redirecting to login');

  await SecureStorageService.deleteToken();


  WidgetsBinding.instance.addPostFrameCallback((_) {
    getx.Get.snackbar(
      'Sesiune expirată',
      'Te rugăm să te autentifici din nou',
      snackPosition: getx.SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    getx.Get.offAll(() => const LoginPage());
  });

  Future.delayed(const Duration(seconds: 2), () {
    _isRedirectingToLogin = false;
  });
}
