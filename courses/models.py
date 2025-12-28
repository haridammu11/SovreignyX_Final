from django.db import models
from django.conf import settings
from authentication.models import User


class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class Course(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='courses')
    instructor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='courses_taught')
    thumbnail = models.ImageField(upload_to='course_thumbnails/', blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class Module(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='modules')
    title = models.CharField(max_length=200)
    description = models.TextField()
    order = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.course.title} - {self.title}"


class Lesson(models.Model):
    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name='lessons')
    title = models.CharField(max_length=200)
    content = models.TextField()
    video_url = models.URLField(blank=True, null=True)
    order = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.module.title} - {self.title}"


class Enrollment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='enrollments')
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='enrollments')
    enrolled_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    progress = models.FloatField(default=0.0)  # Percentage completion

    class Meta:
        unique_together = ('user', 'course')

    def __str__(self):
        return f"{self.user.username} - {self.course.title}"


class UserLessonProgress(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE)
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(blank=True, null=True)
    time_spent = models.DurationField(default=None, blank=True, null=True)  # Time spent on lesson

    class Meta:
        unique_together = ('user', 'lesson')

    def __str__(self):
        return f"{self.user.username} - {self.lesson.title} - {'Completed' if self.completed else 'In Progress'}"


class Certificate(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='certificates')
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    certificate_image = models.ImageField(upload_to='certificates/', blank=True, null=True)
    issued_at = models.DateTimeField(auto_now_add=True)
    expiry_date = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} - {self.course.title} Certificate"