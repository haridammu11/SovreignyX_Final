from django.urls import path
from rest_framework.routers import DefaultRouter
from . import views

urlpatterns = [
    path('', views.courses_list, name='courses_list'),
    path('enrollments/', views.enrollments_list, name='enrollments_list'),
    path('enroll/', views.enroll_course, name='enroll_course'),
]