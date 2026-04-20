enum AdviceTone { info, success, warning }

class FinanceAdvice {
  const FinanceAdvice({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final AdviceTone tone;
}
