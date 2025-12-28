from rest_framework import serializers
from .models import User, UserProfile
from django.contrib.auth import authenticate

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'password', 'phone', 'profile_picture', 'bio', 'is_verified', 'google_id', 'profile')
        read_only_fields = ('id', 'is_verified', 'google_id')

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user

class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone', 'profile_picture', 'bio')

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')

        if username and password:
            user = authenticate(username=username, password=password)
            if user:
                if not user.is_active:
                    raise serializers.ValidationError("User account is disabled.")
                return {'user': user}
            else:
                raise serializers.ValidationError("Unable to log in with provided credentials.")
        else:
            raise serializers.ValidationError("Must include 'username' and 'password'.")

class GoogleLoginSerializer(serializers.Serializer):
    access_token = serializers.CharField()
