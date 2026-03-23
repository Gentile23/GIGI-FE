class ValidationUtils {
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
