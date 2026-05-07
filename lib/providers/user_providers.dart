import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/providers/storage_providers.dart';
import 'package:ocean_rent/repository/user_repository.dart';
import 'package:ocean_rent/services/user/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userService    = ref.watch(userServiceProvider);
  final storageService = ref.watch(firebaseStorageServiceProvider);
  return UserRepository(userService, storageService);
});
