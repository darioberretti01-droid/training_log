class LoggedSetInput {
  const LoggedSetInput({
    required this.reps,
    required this.weightKg,
    this.restSeconds,
    this.rpe,
  });

  final int reps;
  final double weightKg;
  final int? restSeconds;
  final double? rpe;
}
