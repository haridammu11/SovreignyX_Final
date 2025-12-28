from django.contrib import admin
from .models import Category, Course, Module, Lesson, Enrollment, UserLessonProgress, Certificate

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'created_at')
    search_fields = ('name', 'description')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('title', 'instructor', 'category', 'price', 'is_published', 'created_at')
    list_filter = ('category', 'is_published', 'created_at')
    search_fields = ('title', 'description', 'instructor__username', 'instructor__email')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'order', 'created_at')
    list_filter = ('course', 'created_at')
    search_fields = ('title', 'description', 'course__title')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'order', 'created_at')
    list_filter = ('module__course', 'module', 'created_at')
    search_fields = ('title', 'content', 'module__title', 'module__course__title')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'course', 'enrolled_at', 'completed_at', 'progress')
    list_filter = ('course', 'enrolled_at', 'completed_at')
    search_fields = ('user__username', 'user__email', 'course__title')
    readonly_fields = ('enrolled_at',)

@admin.register(UserLessonProgress)
class UserLessonProgressAdmin(admin.ModelAdmin):
    list_display = ('user', 'lesson', 'completed', 'completed_at')
    list_filter = ('completed', 'completed_at', 'lesson__module__course')
    search_fields = ('user__username', 'user__email', 'lesson__title')
    readonly_fields = ('completed_at',)

@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = ('user', 'course', 'issued_at', 'expiry_date')
    list_filter = ('course', 'issued_at', 'expiry_date')
    search_fields = ('user__username', 'user__email', 'course__title')
    readonly_fields = ('issued_at',)