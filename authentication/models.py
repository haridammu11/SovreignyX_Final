from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    phone = models.CharField(max_length=15, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)  # Add this field
    bio = models.TextField(blank=True, null=True)  # Add this field
    is_verified = models.BooleanField(default=False)
    google_id = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.username


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    university = models.CharField(max_length=100, blank=True, null=True)
    department = models.CharField(max_length=100, blank=True, null=True)
    year_of_study = models.IntegerField(blank=True, null=True)
    enrollment_number = models.CharField(max_length=50, blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    streak = models.IntegerField(default=0)
    last_active = models.DateTimeField(auto_now=True)
    google_photo_url = models.URLField(blank=True, null=True)  # Add this field for Google photo URL
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Profile"


class Role(models.Model):
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, null=True)
    permissions = models.JSONField(default=dict, blank=True)  # Store permissions as JSON
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class UserRole(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    assigned_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        unique_together = ('user', 'role')

    def __str__(self):
        return f"{self.user.username} - {self.role.name}"