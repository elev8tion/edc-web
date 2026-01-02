import 'secure_auth_provider.dart';

extension SecureAuthStateExtension on SecureAuthState {
  bool get isLoading => this == SecureAuthState.loading;
  bool get isAuthenticated => this == SecureAuthState.authenticated;
  bool get isUnauthenticated => this == SecureAuthState.unauthenticated;
  bool get isError => this == SecureAuthState.error;
  bool get isInitial => this == SecureAuthState.initial;
}
