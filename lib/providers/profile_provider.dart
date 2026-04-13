import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  const ProfileState({
    required this.name,
    required this.email,
    required this.userId,
    required this.isDarkModeEnabled,
  });

  final String name;
  final String email;
  final String userId;
  final bool isDarkModeEnabled;

  ProfileState copyWith({
    String? name,
    String? email,
    String? userId,
    bool? isDarkModeEnabled,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier()
      : super(
          const ProfileState(
            name: '张三',
            email: 'zhangsan@example.com',
            userId: '123456789',
            isDarkModeEnabled: false,
          ),
        );

  void setDarkModeEnabled(bool value) {
    state = state.copyWith(isDarkModeEnabled: value);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
