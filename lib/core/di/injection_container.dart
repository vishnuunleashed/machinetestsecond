import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/network_info.dart';
import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/watch_auth_state.dart';

import '../../features/tasks/data/datasources/task_local_data_source.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/usecases/create_task.dart';
import '../../features/tasks/domain/usecases/delete_task.dart';
import '../../features/tasks/domain/usecases/sync_tasks_now.dart';
import '../../features/tasks/domain/usecases/toggle_task_completion.dart';
import '../../features/tasks/domain/usecases/update_task.dart';
import '../../features/tasks/domain/usecases/watch_sync_status.dart';
import '../../features/tasks/domain/usecases/watch_tasks.dart';

/// Global get_it service locator instance. Riverpod Notifiers pull their
/// use cases from here (see `sl<...>()` calls in each feature's notifier),
/// keeping dependency wiring centralized in one place.
final sl = GetIt.instance;

/// Registers every dependency the app needs. Call once from `main()` before
/// `runApp`. Order matters: core singletons first, then each feature's
/// data source -> repository -> use case chain.
Future<void> initDependencies() async {
  // ---- Core ----
  const secureStorage = FlutterSecureStorage();
  final secureStorageService = SecureStorageService(secureStorage);
  final hiveService = HiveService(secureStorageService);
  await hiveService.init();

  sl.registerLazySingleton<SecureStorageService>(() => secureStorageService);
  sl.registerLazySingleton<HiveService>(() => hiveService);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ---- Auth ----
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<SignIn>(() => SignIn(sl()));
  sl.registerFactory<SignUp>(() => SignUp(sl()));
  sl.registerFactory<SignOut>(() => SignOut(sl()));
  sl.registerFactory<WatchAuthState>(() => WatchAuthState(sl()));

  // ---- Tasks ----
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(hiveService: sl()),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<TaskRepository>(() {
    final repository = TaskRepositoryImpl(
      local: sl(),
      remote: sl(),
      networkInfo: sl(),
      firebaseAuth: sl(),
    );
    // Kicks off the connectivity-triggered auto-sync + an initial
    // catch-up sync (fire-and-forget).
    repository.startAutoSync();
    return repository;
  });

  sl.registerFactory<CreateTask>(() => CreateTask(sl()));
  sl.registerFactory<UpdateTask>(() => UpdateTask(sl()));
  sl.registerFactory<DeleteTask>(() => DeleteTask(sl()));
  sl.registerFactory<ToggleTaskCompletion>(() => ToggleTaskCompletion(sl()));
  sl.registerFactory<SyncTasksNow>(() => SyncTasksNow(sl()));
  sl.registerFactory<WatchTasks>(() => WatchTasks(sl()));
  sl.registerFactory<WatchSyncStatus>(() => WatchSyncStatus(sl()));
}
