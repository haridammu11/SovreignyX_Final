from django.urls import path
from rest_framework.routers import DefaultRouter
from . import views

urlpatterns = [
    path('activities/', views.user_activities_list, name='user_activities_list'),
    path('course-progress/', views.course_progress_list, name='course_progress_list'),
    path('quiz-analytics/', views.quiz_analytics_list, name='quiz_analytics_list'),
    path('engagement-metrics/', views.engagement_metrics_list, name='engagement_metrics_list'),
    path('system-performance/', views.system_performance_list, name='system_performance_list'),
]