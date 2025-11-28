/// Exceptions personnalisées pour l'authentification

/// Exception levée quand un utilisateur n'est pas validé
class UserNotValidatedException implements Exception {
  final String statutValidation;
  final String message;

  UserNotValidatedException({
    required this.statutValidation,
    this.message = 'Compte en attente de validation',
  });

  @override
  String toString() => message;
}

/// Exception levée quand un utilisateur est refusé
class UserRefusedException implements Exception {
  final String message;

  UserRefusedException({
    this.message = 'Votre demande d\'inscription a été refusée',
  });

  @override
  String toString() => message;
}
