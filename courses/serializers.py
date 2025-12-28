from rest_framework import serializers
from .models import Category, Course, Module, Lesson, Enrollment, UserLessonProgress, Certificate
from authentication.models import User
from authentication.serializers import UserSerializer

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class CourseSerializer(serializers.ModelSerializer):
    instructor_details = UserSerializer(source='instructor', read_only=True)
    category_details = CategorySerializer(source='category', read_only=True)
    
    class Meta:
        model = Course
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class ModuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Module
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class LessonSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lesson
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',)

class EnrollmentSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    course_details = CourseSerializer(source='course', read_only=True)
    
    class Meta:
        model = Enrollment
        fields = '__all__'
        read_only_fields = ('enrolled_at',)

class UserLessonProgressSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    lesson_details = LessonSerializer(source='lesson', read_only=True)
    
    class Meta:
        model = UserLessonProgress
        fields = '__all__'
        read_only_fields = ('completed_at',)

class CertificateSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    course_details = CourseSerializer(source='course', read_only=True)
    
    class Meta:
        model = Certificate
        fields = '__all__'
        read_only_fields = ('issued_at',)