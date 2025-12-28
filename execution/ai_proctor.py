"""
AI-Powered Proctoring Analysis Module
Uses Groq Vision API for real-time anomaly detection
"""
import base64
import requests
from typing import Dict, List, Optional
from django.conf import settings

class AIProctorAnalyzer:
    """
    Analyzes proctoring frames using AI vision models to detect anomalies.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or getattr(settings, 'GROQ_API_KEY', None)
        self.api_url = "https://api.groq.com/openai/v1/chat/completions"
        
    def analyze_frame(self, image_data: str) -> Dict:
        """
        Analyze a single frame for proctoring anomalies.
        
        Args:
            image_data: Base64 encoded image string (with or without data URI prefix)
            
        Returns:
            Dict containing:
                - is_suspicious: bool
                - confidence: float (0-100)
                - anomalies: List[str]
                - details: Dict with specific findings
        """
        if not self.api_key:
            return self._mock_analysis()
        
        try:
            # Clean image data
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            # Prepare prompt for vision analysis
            prompt = """Analyze this exam proctoring image and detect any suspicious behavior or violations.

Check for:
1. **Face Detection**: Is there exactly one face? Multiple faces or no face is suspicious.
2. **Gaze Direction**: Is the person looking at the screen or looking away/down (reading notes)?
3. **Objects**: Are there any phones, books, notes, or other prohibited items visible?
4. **Environment**: Is there another person in the background?
5. **Behavior**: Any unusual posture or hand positions suggesting cheating?

Respond in JSON format:
{
  "is_suspicious": true/false,
  "confidence": 0-100,
  "anomalies": ["list of detected issues"],
  "details": {
    "face_count": number,
    "gaze_direction": "screen/away/down",
    "objects_detected": ["list"],
    "background_activity": "description"
  }
}"""

            # Call Groq Vision API
            response = requests.post(
                self.api_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "llama-3.2-90b-vision-preview",
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": f"data:image/jpeg;base64,{image_data}"
                                    }
                                }
                            ]
                        }
                    ],
                    "temperature": 0.1,  # Low temperature for consistent analysis
                    "max_tokens": 500
                },
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result['choices'][0]['message']['content']
                
                # Parse JSON response
                import json
                try:
                    analysis = json.loads(content)
                    return analysis
                except json.JSONDecodeError:
                    # Fallback if AI doesn't return valid JSON
                    return {
                        "is_suspicious": "suspicious" in content.lower() or "violation" in content.lower(),
                        "confidence": 50,
                        "anomalies": ["AI analysis completed but format unclear"],
                        "details": {"raw_response": content}
                    }
            else:
                print(f"Groq API Error: {response.status_code} - {response.text}")
                return self._mock_analysis()
                
        except Exception as e:
            print(f"AI Analysis Error: {e}")
            return self._mock_analysis()
    
    def _mock_analysis(self) -> Dict:
        """
        Fallback mock analysis when AI is unavailable.
        Returns a safe "no anomalies" result.
        """
        return {
            "is_suspicious": False,
            "confidence": 0,
            "anomalies": [],
            "details": {
                "note": "AI analysis unavailable - using mock data"
            }
        }
    
    def batch_analyze(self, frames: List[str]) -> List[Dict]:
        """
        Analyze multiple frames (for historical review).
        
        Args:
            frames: List of base64 encoded images
            
        Returns:
            List of analysis results
        """
        results = []
        for frame in frames:
            results.append(self.analyze_frame(frame))
        return results
    
    def calculate_suspicion_score(self, analyses: List[Dict]) -> float:
        """
        Calculate overall suspicion score from multiple analyses.
        
        Args:
            analyses: List of analysis results
            
        Returns:
            Float score from 0-100
        """
        if not analyses:
            return 0.0
        
        suspicious_count = sum(1 for a in analyses if a.get('is_suspicious', False))
        avg_confidence = sum(a.get('confidence', 0) for a in analyses) / len(analyses)
        
        # Weight: 70% based on frequency, 30% based on confidence
        frequency_score = (suspicious_count / len(analyses)) * 70
        confidence_score = (avg_confidence / 100) * 30
        
        return round(frequency_score + confidence_score, 2)
