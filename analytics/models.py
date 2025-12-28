from django.db import models
from authentication.models import User
from courses.models import Course, Lesson
from quizzes.models import Quiz


class UserActivity(models.Model):
    ACTIVITY_TYPES = [
        ('LOGIN', 'Login'),
        ('LOGOUT', 'Logout'),
        ('COURSE_VIEW', 'Course View'),
        ('LESSON_VIEW', 'Lesson View'),
        ('QUIZ_START', 'Quiz Start'),
        ('QUIZ_COMPLETE', 'Quiz Complete'),
        ('VIDEO_WATCH', 'Video Watch'),
        ('ASSIGNMENT_SUBMIT', 'Assignment Submit'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    activity_type = models.CharField(max_length=20, choices=ACTIVITY_TYPES)
    course = models.ForeignKey(Course, on_delete=models.CASCADE, blank=True, null=True)
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, blank=True, null=True)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, blank=True, null=True)
    duration = models.DurationField(blank=True, null=True)  # Time spent on activity
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.username} - {self.activity_type} - {self.timestamp}"


class CourseProgressAnalytics(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    progress_percentage = models.FloatField(default=0.0)
    time_spent = models.DurationField(default=None, blank=True, null=True)
    last_accessed = models.DateTimeField(auto_now=True)
    completed_modules = models.IntegerField(default=0)
    total_modules = models.IntegerField(default=0)

    class Meta:
        unique_together = ('user', 'course')

    def __str__(self):
        return f"{self.user.username} - {self.course.title} - {self.progress_percentage}%"


class QuizAnalytics(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE)
    attempts = models.IntegerField(default=0)
    highest_score = models.FloatField(blank=True, null=True)
    average_score = models.FloatField(blank=True, null=True)
    last_attempted = models.DateTimeField(blank=True, null=True)

    class Meta:
        unique_together = ('user', 'quiz')

    def __str__(self):
        return f"{self.user.username} - {self.quiz.title}"


class EngagementMetric(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateField()
    login_count = models.IntegerField(default=0)
    courses_accessed = models.IntegerField(default=0)
    lessons_completed = models.IntegerField(default=0)
    quizzes_taken = models.IntegerField(default=0)
    time_spent_learning = models.DurationField(default=None, blank=True, null=True)
    streak_maintained = models.BooleanField(default=False)

    class Meta:
        unique_together = ('user', 'date')

    def __str__(self):
        return f"{self.user.username} - {self.date}"


class SystemPerformance(models.Model):
    metric_name = models.CharField(max_length=100)
    value = models.FloatField()
    recorded_at = models.DateTimeField(auto_now_add=True)
    additional_data = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-recorded_at']

    def __str__(self):
        return f"{self.metric_name} - {self.value} - {self.recorded_at}"