import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiRecruitmentService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Comprehensive AI analysis with ATS scoring, profile analysis, and recommendations
  static Future<Map<String, dynamic>> analyzeApplication({
    required String jobTitle,
    required String jobDescription,
    required String candidateName,
    required String resumeText,
    String? coverNote,
    String? linkedinUrl,
    String? githubUrl,
  }) async {
    debugPrint('🤖 Advanced AI Analysis Started for: $candidateName');
    debugPrint('📋 Job: $jobTitle');
    
    // Step 1: Main Resume Analysis with ATS Scoring
    final mainAnalysis = await _performMainAnalysis(
      jobTitle: jobTitle,
      jobDescription: jobDescription,
      candidateName: candidateName,
      resumeText: resumeText,
      coverNote: coverNote,
    );

    // Step 2: LinkedIn Analysis (if provided)
    Map<String, dynamic>? linkedinAnalysis;
    if (linkedinUrl != null && linkedinUrl.isNotEmpty && linkedinUrl != 'Not provided') {
      try {
        linkedinAnalysis = await _analyzeLinkedInProfile(linkedinUrl, candidateName);
      } catch (e) {
        debugPrint('⚠️ LinkedIn analysis failed: $e');
      }
    }

    // Step 3: GitHub Analysis (if provided)
    Map<String, dynamic>? githubAnalysis;
    if (githubUrl != null && githubUrl.isNotEmpty && githubUrl != 'Not provided') {
      try {
        githubAnalysis = await _analyzeGitHubProfile(githubUrl, candidateName);
      } catch (e) {
        debugPrint('⚠️ GitHub analysis failed: $e');
      }
    }

    // Combine all analyses
    final result = {
      ...mainAnalysis,
      'linkedin_analysis': linkedinAnalysis ?? {'status': 'not_provided'},
      'github_analysis': githubAnalysis ?? {'status': 'not_provided'},
    };

    debugPrint('✅ Comprehensive Analysis Complete');
    return result;
  }

  /// Main resume analysis with multi-dimensional scoring
  static Future<Map<String, dynamic>> _performMainAnalysis({
    required String jobTitle,
    required String jobDescription,
    required String candidateName,
    required String resumeText,
    String? coverNote,
  }) async {
    final prompt = '''
You are an expert ATS (Applicant Tracking System) and HR AI specialized in comprehensive candidate evaluation.

JOB TITLE: $jobTitle
JOB DESCRIPTION: $jobDescription

CANDIDATE: $candidateName
COVER LETTER: ${coverNote ?? 'Not provided'}
RESUME/PROFILE:
$resumeText

Perform a comprehensive multi-dimensional analysis and return ONLY valid JSON with this exact structure:

{
  "ats_score": 85,
  "overall_score": 78,
  "technical_score": 82,
  "experience_score": 75,
  "cultural_fit_score": 70,
  
  "summary": "2-3 sentence executive summary of candidate fit",
  
  "detailed_analysis": {
    "strengths": ["specific strength 1", "specific strength 2", "specific strength 3"],
    "weaknesses": ["specific weakness 1", "specific weakness 2"],
    "key_skills_matched": ["skill1", "skill2", "skill3"],
    "missing_skills": ["skill1", "skill2"],
    "experience_level": "Entry/Mid/Senior level with X years"
  },
  
  "recommendation": {
    "decision": "Interview|Hold|Reject",
    "confidence": "High|Medium|Low",
    "reasoning": "Specific reason for the decision",
    "next_steps": ["action 1", "action 2"]
  }
}

SCORING GUIDELINES:
- ATS Score (0-100): Resume format, keyword match, completeness
- Overall Score (0-100): Holistic fit for the role
- Technical Score (0-100): Technical skills and expertise match
- Experience Score (0-100): Years and relevance of experience
- Cultural Fit Score (0-100): Soft skills, communication, values alignment

Be strict but fair. Scores above 85 should be rare and reserved for exceptional candidates.
Return ONLY the JSON object, no markdown formatting.
''';

    return await _callGroqAPI(prompt, 'Main Analysis');
  }

  /// Analyze LinkedIn profile
  static Future<Map<String, dynamic>> _analyzeLinkedInProfile(String url, String candidateName) async {
    debugPrint('🔗 Analyzing LinkedIn: $url');
    
    final prompt = '''
You are a LinkedIn profile analyzer. Based on the URL pattern and typical LinkedIn profiles, provide intelligent insights.

LINKEDIN URL: $url
CANDIDATE: $candidateName

Analyze and return ONLY valid JSON:

{
  "profile_quality": "Strong|Moderate|Weak",
  "estimated_connections": "500+|100-500|<100|Unknown",
  "key_highlights": ["highlight 1", "highlight 2", "highlight 3"],
  "red_flags": ["flag 1 if any"],
  "professional_summary": "Brief assessment of their professional presence"
}

Note: Since we cannot directly access LinkedIn, provide intelligent estimates based on:
- URL structure (custom URL suggests active profile)
- Candidate's resume information
- Industry standards

Return ONLY the JSON object.
''';

    return await _callGroqAPI(prompt, 'LinkedIn Analysis');
  }

  /// Analyze GitHub profile
  static Future<Map<String, dynamic>> _analyzeGitHubProfile(String url, String candidateName) async {
    debugPrint('💻 Analyzing GitHub: $url');
    
    final prompt = '''
You are a GitHub profile analyzer. Based on the URL and typical developer profiles, provide intelligent insights.

GITHUB URL: $url
CANDIDATE: $candidateName

Analyze and return ONLY valid JSON:

{
  "activity_level": "Very Active|Active|Moderate|Low",
  "profile_quality": "Strong|Moderate|Weak",
  "estimated_repos": "20+|10-20|5-10|<5|Unknown",
  "primary_languages": ["language1", "language2"],
  "key_insights": ["insight 1", "insight 2"],
  "contribution_quality": "High|Medium|Low|Unknown"
}

Note: Since we cannot directly access GitHub API, provide intelligent estimates based on:
- Username in URL
- Candidate's technical skills from resume
- Industry standards for developers

Return ONLY the JSON object.
''';

    return await _callGroqAPI(prompt, 'GitHub Analysis');
  }

  /// Generic Groq API caller
  static Future<Map<String, dynamic>> _callGroqAPI(String prompt, String analysisType) async {
    try {
      debugPrint('🌐 Calling Groq API for: $analysisType');
      
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are an expert HR AI. Return only valid JSON without markdown.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out after 30 seconds'),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        throw Exception('❌ API Key Invalid or Expired (401)');
      } else if (response.statusCode == 429) {
        throw Exception('⏱️ Rate Limit Exceeded (429)');
      } else if (response.statusCode != 200) {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body);
      String content = data['choices'][0]['message']['content'].trim();
      
      // Clean markdown
      if (content.contains('```json')) {
        content = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        content = content.split('```')[1].trim();
      }
      
      debugPrint('✅ $analysisType Complete');
      return jsonDecode(content);
      
    } catch (e) {
      debugPrint('❌ $analysisType Error: $e');
      rethrow;
    }
  }
}
