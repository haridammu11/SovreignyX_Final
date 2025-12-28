from rest_framework import serializers
from .models import UserActivity, CourseProgressAnalytics, QuizAnalytics, EngagementMetric, SystemPerformance
from authentication.models import User
from authentication.serializers import UserSerializer
from courses.models import Course
from courses.serializers import CourseSerializer
from quizzes.models import Quiz
from quizzes.serializers import QuizSerializer

class UserActivitySerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    course_details = CourseSerializer(source='course', read_only=True)
    
    class Meta:
        model = UserActivity
        fields = '__all__'
        read_only_fields = ('timestamp',)

class CourseProgressAnalyticsSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    course_details = CourseSerializer(source='course', read_only=True)
    
    class Meta:
        model = CourseProgressAnalytics
        fields = '__all__'
        read_only_fields = ('last_accessed',)

class QuizAnalyticsSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    quiz_details = QuizSerializer(source='quiz', read_only=True)
    
    class Meta:
        model = QuizAnalytics
        fields = '__all__'
        read_only_fields = ('last_attempted',)

class EngagementMetricSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = EngagementMetric
        fields = '__all__'
        read_only_fields = ('date',)

class SystemPerformanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemPerformance
        fields = '__all__'
        read_only_fields = ('recorded_at',)