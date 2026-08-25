class GoogleRegistrationRequiredException implements Exception {
  const GoogleRegistrationRequiredException({
    required this.email,
    required this.name,
  });

  final String email;
  final String name;

  @override
  String toString() =>
      'No account found for this Google email. Complete business setup to register.';
}
