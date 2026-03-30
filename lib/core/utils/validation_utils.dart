class ValidationUtils {
  static const int maxFreeTextLength = 500;
  static final RegExp _controlCharsRegex = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');
  static final RegExp _scriptLikeRegex = RegExp(
    r'(<\s*script|javascript:|onerror\s*=|onload\s*=|<\s*iframe|data:text/html)',
    caseSensitive: false,
  );

  static String sanitizeFreeText(
    String value, {
    int maxLength = maxFreeTextLength,
  }) {
    final normalized = value
        .replaceAll(_controlCharsRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  static bool containsSuspiciousMarkup(String value) {
    return _scriptLikeRegex.hasMatch(value);
  }

  static String sanitizeFileName(
    String value, {
    int maxLength = 120,
  }) {
    final safe = value
        .replaceAll(RegExp(r'[/\\]'), '_')
        .replaceAll(RegExp(r'[^\w\-. ]'), '_')
        .trim();

    if (safe.length <= maxLength) {
      return safe;
    }
    return safe.substring(0, maxLength);
  }

  static String? validatePassword(
    String? value, {
    required String enterPasswordMsg,
    required String tooShortMsg,
    required String uppercaseMsg,
    required String numberMsg,
    int minLength = 8,
  }) {
    if (value == null || value.isEmpty) {
      return enterPasswordMsg;
    }
    
    if (value.length < minLength) {
      return tooShortMsg;
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return uppercaseMsg;
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return numberMsg;
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la tua email';
    }
    
    final emailRegex = RegExp(r'^[\w\+\-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Inserisci un\'email valida';
    }
    
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il tuo nome';
    }
    if (value.trim().length < 2) {
      return 'Il nome deve essere di almeno 2 caratteri';
    }
    return null;
  }
}
