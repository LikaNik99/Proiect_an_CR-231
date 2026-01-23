import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../data/data_sources/auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_email_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../config/app_config.dart';
import '../network/auth_interceptor.dart';
import '../../core/database/database_connection_manager.dart';


import '../../data/data_sources/school_data_source.dart';
import '../../data/repositories/school_repository_impl.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/usecases/school/get_schools_usecase.dart';
import '../../domain/usecases/school/get_school_usecase.dart';
import '../../domain/usecases/school/create_school_usecase.dart';
import '../../domain/usecases/school/update_school_usecase.dart';
import '../../domain/usecases/school/delete_school_usecase.dart';


import '../../data/data_sources/class_data_source.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/repositories/class_repository.dart';
import '../../domain/usecases/class/get_classes_usecase.dart';
import '../../domain/usecases/class/get_class_usecase.dart';
import '../../domain/usecases/class/create_class_usecase.dart';
import '../../domain/usecases/class/update_class_usecase.dart';
import '../../domain/usecases/class/delete_class_usecase.dart';


import '../../data/data_sources/teacher_data_source.dart';
import '../../data/repositories/teacher_repository_impl.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../domain/usecases/teacher/get_teachers_usecase.dart';
import '../../domain/usecases/teacher/get_teacher_usecase.dart';
import '../../domain/usecases/teacher/create_teacher_usecase.dart';
import '../../domain/usecases/teacher/update_teacher_usecase.dart';
import '../../domain/usecases/teacher/delete_teacher_usecase.dart';


import '../../data/data_sources/student_data_source.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/student/get_students_usecase.dart';
import '../../domain/usecases/student/get_student_usecase.dart';
import '../../domain/usecases/student/create_student_usecase.dart';
import '../../domain/usecases/student/update_student_usecase.dart';
import '../../domain/usecases/student/delete_student_usecase.dart';


import '../../data/data_sources/admin_user_data_source.dart';
import '../../data/repositories/admin_user_repository_impl.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../../domain/usecases/admin_user/get_users_usecase.dart';
import '../../domain/usecases/admin_user/get_user_usecase.dart';
import '../../domain/usecases/admin_user/create_user_usecase.dart';
import '../../domain/usecases/admin_user/update_user_usecase.dart';
import '../../domain/usecases/admin_user/delete_user_usecase.dart';


import '../../data/data_sources/dashboard_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {

  sl.registerLazySingleton<Dio>(
    () {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      dio.interceptors.add(AuthInterceptor());

      return dio;
    },
  );


  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => CheckEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));


  sl.registerLazySingleton<DatabaseConnectionManager>(
    () {
      final mgr = DatabaseConnectionManager();
      mgr.configure(
        host: AppConfig.dbHost,
        port: AppConfig.dbPort,
        database: AppConfig.dbName,
        username: AppConfig.dbUser,
        password: AppConfig.dbPassword,
        useSSL: AppConfig.dbUseSSL,
      );
      return mgr;
    },
  );


  sl.registerLazySingleton<SchoolDataSource>(
    () => SchoolDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<SchoolRepository>(
    () => SchoolRepositoryImpl(sl<SchoolDataSource>()),
  );
  sl.registerLazySingleton(() => GetSchoolsUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => GetSchoolUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => CreateSchoolUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => UpdateSchoolUseCase(sl<SchoolRepository>()));
  sl.registerLazySingleton(() => DeleteSchoolUseCase(sl<SchoolRepository>()));


  sl.registerLazySingleton<ClassDataSource>(
    () => ClassDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<ClassRepository>(
    () => ClassRepositoryImpl(sl<ClassDataSource>()),
  );
  sl.registerLazySingleton(() => GetClassesUseCase(sl<ClassRepository>()));
  sl.registerLazySingleton(() => GetClassUseCase(sl<ClassRepository>()));
  sl.registerLazySingleton(() => CreateClassUseCase(sl<ClassRepository>()));
  sl.registerLazySingleton(() => UpdateClassUseCase(sl<ClassRepository>()));
  sl.registerLazySingleton(() => DeleteClassUseCase(sl<ClassRepository>()));


  sl.registerLazySingleton<TeacherDataSource>(
    () => TeacherDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(sl<TeacherDataSource>()),
  );
  sl.registerLazySingleton(() => GetTeachersUseCase(sl<TeacherRepository>()));
  sl.registerLazySingleton(() => GetTeacherUseCase(sl<TeacherRepository>()));
  sl.registerLazySingleton(() => CreateTeacherUseCase(sl<TeacherRepository>()));
  sl.registerLazySingleton(() => UpdateTeacherUseCase(sl<TeacherRepository>()));
  sl.registerLazySingleton(() => DeleteTeacherUseCase(sl<TeacherRepository>()));


  sl.registerLazySingleton<StudentDataSource>(
    () => StudentDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(sl<StudentDataSource>()),
  );
  sl.registerLazySingleton(() => GetStudentsUseCase(sl<StudentRepository>()));
  sl.registerLazySingleton(() => GetStudentUseCase(sl<StudentRepository>()));
  sl.registerLazySingleton(() => CreateStudentUseCase(sl<StudentRepository>()));
  sl.registerLazySingleton(() => UpdateStudentUseCase(sl<StudentRepository>()));
  sl.registerLazySingleton(() => DeleteStudentUseCase(sl<StudentRepository>()));


  sl.registerLazySingleton<AdminUserDataSource>(
    () => AdminUserDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<AdminUserRepository>(
    () => AdminUserRepositoryImpl(sl<AdminUserDataSource>()),
  );
  sl.registerLazySingleton(() => GetUsersUseCase(sl<AdminUserRepository>()));
  sl.registerLazySingleton(() => GetUserUseCase(sl<AdminUserRepository>()));
  sl.registerLazySingleton(() => CreateUserUseCase(sl<AdminUserRepository>()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl<AdminUserRepository>()));
  sl.registerLazySingleton(() => DeleteUserUseCase(sl<AdminUserRepository>()));


  sl.registerLazySingleton<DashboardDataSource>(
    () => DashboardDataSource(sl<Dio>(), sl<DatabaseConnectionManager>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl<DashboardDataSource>()),
  );
  sl.registerLazySingleton(() => GetDashboardStatsUseCase(sl<DashboardRepository>()));
}
