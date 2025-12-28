from django.db import models
from django.conf import settings

class CodeSnippet(models.Model):
    LANGUAGE_CHOICES = [
        ('python', 'Python'),
        ('java', 'Java'),
        ('c', 'C'),
        ('cpp', 'C++'),
        ('javascript', 'JavaScript'),
        ('dart', 'Dart'),
    ]
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    language = models.CharField(max_length=20, choices=LANGUAGE_CHOICES)
    title = models.CharField(max_length=100, blank=True)
    code = models.TextField()
    output = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} ({self.language})" if self.title else f"Snippet ({self.language})"
    
    class Meta:
        ordering = ['-created_at']

class ProjectResult(models.Model):
    project_id = models.CharField(max_length=100)
    output = models.TextField(blank=True, null=True)
    error = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

class EmailLog(models.Model):
    recipient = models.EmailField()
    subject = models.CharField(max_length=255)
    body = models.TextField()
    status = models.CharField(max_length=20, default='PENDING') # PENDING, SENT, FAILED
    error_message = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Email to {self.recipient} - {self.status}"

class ProctorSession(models.Model):
    user_id = models.CharField(max_length=100) # Student ID
    contest_id = models.CharField(max_length=100)
    start_time = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    live_frame = models.TextField(blank=True, null=True) # For real-time video stream (volatile)

    def __str__(self):
        return f"Session: {self.user_id} - Contest: {self.contest_id}"

class ProctorEvent(models.Model):
    EVENT_TYPES = [
        ('FRAME', 'Camera Frame'),
        ('TAB_SWITCH', 'Tab Switch Detected'),
        ('ANOMALY', 'AI Detected Anomaly'),
    ]
    
    session = models.ForeignKey(ProctorSession, on_delete=models.CASCADE, related_name='events')
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES)
    timestamp = models.DateTimeField(auto_now_add=True)
    description = models.TextField(blank=True, null=True)
    image_data = models.TextField(blank=True, null=True) # Base64 encoded frame or URL
    code_content = models.TextField(blank=True, null=True) # Latest code snapshot
    is_suspicious = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.event_type} at {self.timestamp}"

class AIProctorAnalysis(models.Model):
    """Stores AI-powered analysis results for proctoring events"""
    ANALYSIS_TYPES = [
        ('FACE', 'Face Detection'),
        ('GAZE', 'Gaze Direction'),
        ('OBJECT', 'Object Detection'),
        ('BEHAVIOR', 'Behavioral Analysis'),
        ('COMPREHENSIVE', 'Full Analysis'),
    ]
    
    event = models.ForeignKey(ProctorEvent, on_delete=models.CASCADE, related_name='ai_analyses')
    analysis_type = models.CharField(max_length=20, choices=ANALYSIS_TYPES, default='COMPREHENSIVE')
    is_suspicious = models.BooleanField(default=False)
    confidence = models.FloatField(default=0.0)  # 0-100 score
    anomalies = models.JSONField(default=list)  # List of detected anomalies
    details = models.JSONField(default=dict)  # Detailed findings
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"AI Analysis for Event #{self.event.id} - Suspicious: {self.is_suspicious}"
    
    class Meta:
        ordering = ['-timestamp']
        verbose_name_plural = "AI Proctor Analyses"
