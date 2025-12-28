from django.db import models
from django.contrib.auth.models import User

class CodeSnippet(models.Model):
    LANGUAGE_CHOICES = [
        ('python', 'Python'),
        ('java', 'Java'),
        ('c', 'C'),
        ('cpp', 'C++'),
        ('javascript', 'JavaScript'),
        ('dart', 'Dart'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
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