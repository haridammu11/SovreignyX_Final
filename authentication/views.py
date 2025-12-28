import json
import requests
from django.conf import settings
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.core.mail import send_mail
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from .models import User, UserProfile
from .serializers import UserSerializer, LoginSerializer, GoogleLoginSerializer, UserProfileSerializer, UserUpdateSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        # Create user profile
        UserProfile.objects.create(user=user)
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = serializer.validated_data['user']
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        })
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    serializer = GoogleLoginSerializer(data=request.data)
    if serializer.is_valid():
        access_token = serializer.validated_data['access_token']
        
        # Get user info from Google
        google_response = requests.get(
            'https://www.googleapis.com/oauth2/v2/userinfo',
            params={'access_token': access_token}
        )
        
        if google_response.status_code != 200:
            return Response({'error': 'Failed to fetch user information from Google'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        google_data = google_response.json()
        
        # Check if user exists, create if not
        try:
            user = User.objects.get(email=google_data['email'])
        except User.DoesNotExist:
            user = User.objects.create_user(
                username=google_data['email'],
                email=google_data['email'],
                first_name=google_data.get('given_name', ''),
                last_name=google_data.get('family_name', ''),
                google_id=google_data['id']
            )
            # Create user profile
            UserProfile.objects.create(user=user)
        
        # Update Google ID if not set
        if not user.google_id:
            user.google_id = google_data['id']
            user.save()
        
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# New endpoint for Google Sign-In with user details
@api_view(['POST'])
@permission_classes([AllowAny])
def google_login_direct(request):
    """
    Handle Google Sign-In with user details sent directly from the client
    """
    # Extract required fields from request data
    id_token = request.data.get('id_token')
    email = request.data.get('email')
    first_name = request.data.get('first_name')
    last_name = request.data.get('last_name')
    photo_url = request.data.get('photo_url')
    
    # Validate required fields
    if not id_token:
        return Response({'error': 'ID Token is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not first_name:
        return Response({'error': 'First name is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Make last_name optional but provide fallback
    if not last_name:
        last_name = first_name  # Use first name as last name if not provided
    
    try:
        # Check if user exists, create if not
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            user = User.objects.create_user(
                username=email,
                email=email,
                first_name=first_name,
                last_name=last_name
            )
            # Create user profile
            UserProfile.objects.create(user=user)
        
        # Update user details if they've changed
        user.first_name = first_name
        user.last_name = last_name
        user.google_id = id_token  # Store ID token as Google ID
        # Save the photo URL to the profile
        if photo_url and hasattr(user, 'profile'):
            # We'll save the Google photo URL in the user's profile
            user.profile.google_photo_url = photo_url
            user.profile.save()
        user.save()
        
        login(request, user)
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        })
    
    except Exception as e:
        return Response({'error': f'An error occurred during Google Sign-In: {str(e)}'}, 
                       status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    try:
        request.user.auth_token.delete()
    except:
        pass
    logout(request)
    return Response({'message': 'Successfully logged out'})


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    if request.method == 'GET':
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    elif request.method == 'PUT':
        # Handle file uploads properly
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserProfileDetailView(generics.RetrieveUpdateAPIView):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        # Return the profile of the current user
        return UserProfile.objects.get(user=self.request.user)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_data(request):
    """
    Return dashboard data for the authenticated user
    """
    user = request.user
    profile = user.profile
    
    data = {
        'user': UserSerializer(user).data,
        'profile': UserProfileSerializer(profile).data,
        'streak': profile.streak,
        'last_active': profile.last_active
    }
    
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def test_auth(request):
    """
    Test endpoint to verify authentication is working
    """
    return Response({
        'message': 'Authentication successful!',
        'user': request.user.email,
        'user_id': request.user.id
    })
