class ApiConfig {
  // Backend URL - Modifica solo questa variabile per cambiare l'URL del backend
  static const String baseUrl = 'https://gigi.azienda-agricola-gentile.it/api/';

  // API endpoints - Non modificare questi, usano automaticamente baseUrl
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String user = '/user';
  static const String userProfile = '/user/profile';
  static const String exercises = '/exercises';
  static const String workoutPlans = '/workout-plans';
  static const String workoutPlansCurrent = '/workout-plans/current';
  static const String workoutPlansGenerate = '/workout-plans/generate';
  static const String customWorkouts = '/custom-workouts';

  // OpenAI Configuration
  // IMPORTANT: Do not commit API keys to version control!
  // To configure:
  // 1. Add flutter_dotenv package
  // 2. Create .env file with OPENAI_API_KEY=your-key-here
  // 3. Load with dotenv.env['OPENAI_API_KEY']
  // For now, the API is called through the backend which has the key
  static const String openAiApiKey = '';
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiModel = 'gpt-5-nano';
  static const String openAiChatCompletionsEndpoint = '/chat/completions';
}
