from rest_framework import serializers
from .models import CodeSnippet

class CodeSnippetSerializer(serializers.ModelSerializer):
    class Meta:
        model = CodeSnippet
        fields = ['id', 'language', 'title', 'code', 'output', 'created_at', 'updated_at']
        read_only_fields = ['user', 'output', 'created_at', 'updated_at']