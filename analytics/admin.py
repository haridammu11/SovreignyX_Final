from django.contrib import admin
from .models import UserActivity, CourseProgressAnalytics, QuizAnalytics, EngagementMetric, SystemPerformance

@admin.register(UserActivity)
class UserActivityAdmin(admin.ModelAdmin):
    list_display = ('user', 'activity_type', 'course', 'timestamp')
    list_filter = ('activity_type', 'timestamp', 'course')
    search_fields = ('user__username', 'user__email', 'activity_type')
    readonly_fields = ('timestamp',)

@admin.register(CourseProgressAnalytics)
class CourseProgressAnalyticsAdmin(admin.ModelAdmin):
    list_display = ('user', 'course', 'progress_percentage', 'last_accessed')
    list_filter = ('course', 'last_accessed')
    search_fields = ('user__username', 'user__email', 'course__title')
    readonly_fields = ('last_accessed',)

@admin.register(QuizAnalytics)
class QuizAnalyticsAdmin(admin.ModelAdmin):
    list_display = ('user', 'quiz', 'attempts', 'highest_score', 'average_score', 'last_attempted')
    list_filter = ('quiz', 'last_attempted')
    search_fields = ('user__username', 'user__email', 'quiz__title')
    readonly_fields = ('last_attempted',)

@admin.register(EngagementMetric)
class EngagementMetricAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'login_count', 'courses_accessed', 'lessons_completed', 'quizzes_taken')
    list_filter = ('date', 'streak_maintained')
    search_fields = ('user__username', 'user__email')
    readonly_fields = ('date',)

@admin.register(SystemPerformance)
class SystemPerformanceAdmin(admin.ModelAdmin):
    list_display = ('metric_name', 'value', 'recorded_at')
    list_filter = ('recorded_at',)
    search_fields = ('metric_name',)
    readonly_fields = ('recorded_at',)