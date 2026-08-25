class PasswordValidation {
  final bool hasLowerCase;
  final bool hasUpperCase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool hasMinLength;

  const PasswordValidation({
    this.hasLowerCase = false,
    this.hasUpperCase = false,
    this.hasNumber = false,
    this.hasSpecialChar = false,
    this.hasMinLength = false,
  });

  bool get isValid =>
      hasLowerCase && hasUpperCase && hasNumber && hasSpecialChar && hasMinLength;

  factory PasswordValidation.fromPassword(String password) {
    return PasswordValidation(
      hasLowerCase: RegExp(r"[a-z]").hasMatch(password),
      hasUpperCase: RegExp(r"[A-Z]").hasMatch(password),
      hasNumber: RegExp(r"\d").hasMatch(password),
      hasSpecialChar: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      hasMinLength: password.length >= 8,
    );
  }
}

/// One-shot UI events the notifier wants the screen to perform
/// (show an alert, navigate somewhere). The screen consumes these
/// via ref.listen and the notifier clears them right after emitting.
class CreateAccountAlert {
  final bool isSuccess;
  final String title;
  final String message;

  const CreateAccountAlert({
    required this.isSuccess,
    required this.title,
    required this.message,
  });
}

class CreateAccountState {
  final bool isLoading;
  final bool isPasswordObscured;
  final bool hasAttemptedSubmit;
  final String? identity;
  final String? creatorIdentity;
  final PasswordValidation passwordValidation;

  // One-shot fields, consumed then cleared by the screen.
  final CreateAccountAlert? pendingAlert;
  final String? navigateToRouteId;

  const CreateAccountState({
    this.isLoading = false,
    this.isPasswordObscured = true,
    this.hasAttemptedSubmit = false,
    this.identity,
    this.creatorIdentity,
    this.passwordValidation = const PasswordValidation(),
    this.pendingAlert,
    this.navigateToRouteId,
  });

  factory CreateAccountState.initial() => const CreateAccountState();

  CreateAccountState copyWith({
    bool? isLoading,
    bool? isPasswordObscured,
    bool? hasAttemptedSubmit,
    String? identity,
    String? creatorIdentity,
    PasswordValidation? passwordValidation,
    CreateAccountAlert? pendingAlert,
    bool clearPendingAlert = false,
    String? navigateToRouteId,
    bool clearNavigateToRouteId = false,
  }) {
    return CreateAccountState(
      isLoading: isLoading ?? this.isLoading,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      hasAttemptedSubmit: hasAttemptedSubmit ?? this.hasAttemptedSubmit,
      identity: identity ?? this.identity,
      creatorIdentity: creatorIdentity ?? this.creatorIdentity,
      passwordValidation: passwordValidation ?? this.passwordValidation,
      pendingAlert: clearPendingAlert ? null : (pendingAlert ?? this.pendingAlert),
      navigateToRouteId: clearNavigateToRouteId
          ? null
          : (navigateToRouteId ?? this.navigateToRouteId),
    );
  }
}