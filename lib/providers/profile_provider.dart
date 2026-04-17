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

  void updateFromAuth({
    required String name,
    required String userId,
  }) {
    state = state.copyWith(
      name: name,
      email: 'No email bound',
      userId: userId,
    );
  }

  void resetProfile() {
    state = state.copyWith(
      name: '张三',
      email: 'zhangsan@example.com',
      userId: '123456789',
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
