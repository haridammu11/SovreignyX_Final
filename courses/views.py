from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Category, Course, Module, Lesson, Enrollment, UserLessonProgress, Certificate
from .serializers import CategorySerializer, CourseSerializer, ModuleSerializer, LessonSerializer, EnrollmentSerializer, UserLessonProgressSerializer, CertificateSerializer

# Courses Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def courses_list(request):
    courses = Course.objects.all()
    serializer = CourseSerializer(courses, many=True)
    return Response(serializer.data)

# Enrollments Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def enrollments_list(request):
    user_id = request.query_params.get('user', None)
    if user_id:
        enrollments = Enrollment.objects.filter(user_id=user_id)
    else:
        enrollments = Enrollment.objects.all()
    
    serializer = EnrollmentSerializer(enrollments, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def enroll_course(request):
    serializer = EnrollmentSerializer(data=request.data)
    if serializer.is_valid():
        # Check if already enrolled
        existing_enrollment = Enrollment.objects.filter(
            user_id=request.data.get('user'),
            course_id=request.data.get('course')
        ).first()
        
        if existing_enrollment:
            return Response({"error": "Already enrolled in this course"}, status=status.HTTP_400_BAD_REQUEST)
        
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)