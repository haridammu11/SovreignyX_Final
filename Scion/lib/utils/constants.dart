class AppConstants {
  // Groq API configuration
  // To get a free Groq API key, visit: https://console.groq.com/
  // 1. Sign up for a free account
  // 2. Create a new API key
  // 3. Copy the key and paste it below, replacing the existing placeholder
  static const String groqApiKey =
      'YOUR_GROQ_API_KEY'; // Replace with your actual Groq API key

  // static const String grokApiKey = 'YOUR_XAI_API_KEY';
  // static const String grokApiUrl = 'https://api.x.ai/v1/chat/completions';

  // Default system prompt for the AI assistant
  static const String defaultSystemPrompt =
      'You are an AI assistant for a Learning Management System (LMS). '
      'Help users with educational questions, course recommendations, study tips, '
      'and learning-related topics. Be friendly, informative, and supportive.';

  // System prompt for code-related AI assistance
  static const String codeAssistantPrompt =
      'You are an expert programming tutor helping students learn to code. '
      'Provide clear explanations, correct errors, and generate educational code examples. '
      'Focus on teaching programming concepts and best practices.';

      
  static const String youtubeApiKey = 'AIzaSyD4NdAz9me6Z1kvdNFXaeaCWj7oxzT5v84'; // Replace with valid Key
}
