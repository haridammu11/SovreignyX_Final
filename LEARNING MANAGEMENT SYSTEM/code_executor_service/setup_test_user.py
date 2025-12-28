import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'code_executor.settings')
django.setup()

from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

# Create a test user
try:
    user = User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpassword123'
    )
    print(f"Created user: {user.username}")
    
    # Create auth token
    token = Token.objects.create(user=user)
    print(f"Auth token: {token.key}")
    
except Exception as e:
    print(f"Error: {e}")
    # If user already exists, get the token
    try:
        user = User.objects.get(username='testuser')
        token, created = Token.objects.get_or_create(user=user)
        print(f"Existing user: {user.username}")
        print(f"Auth token: {token.key}")
    except Exception as e2:
        print(f"Error getting existing user: {e2}")