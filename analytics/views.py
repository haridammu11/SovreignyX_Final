from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import UserActivity, CourseProgressAnalytics, QuizAnalytics, EngagementMetric, SystemPerformance
from .serializers import UserActivitySerializer, CourseProgressAnalyticsSerializer, QuizAnalyticsSerializer, EngagementMetricSerializer, SystemPerformanceSerializer

# Analytics Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_activities_list(request):
    activities = UserActivity.objects.all()
    serializer = UserActivitySerializer(activities, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def course_progress_list(request):
    progress = CourseProgressAnalytics.objects.all()
    serializer = CourseProgressAnalyticsSerializer(progress, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_analytics_list(request):
    analytics = QuizAnalytics.objects.all()
    serializer = QuizAnalyticsSerializer(analytics, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def engagement_metrics_list(request):
    metrics = EngagementMetric.objects.all()
    serializer = EngagementMetricSerializer(metrics, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def system_performance_list(request):
    performance = SystemPerformance.objects.all()
    serializer = SystemPerformanceSerializer(performance, many=True)
    return Response(serializer.data)