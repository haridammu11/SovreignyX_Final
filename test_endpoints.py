import requests
import json
import random
import string

# Test the API endpoints
BASE_URL = "http://127.0.0.1:8000"

def generate_random_string(length=8):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def test_endpoints():
    print("Testing API Endpoints...")
    
    # First, register and login to get a token
    random_suffix = generate_random_string()
    username = f"testuser_{random_suffix}"
    email = f"test_{random_suffix}@example.com"
    
    # Register
    register_data = {
        "username": username,
        "email": email,
        "password": "testpassword123",
        "first_name": "Test",
        "last_name": "User"
    }
    
    print(f"\n1. Registering user {email}...")
    response = requests.post(f"{BASE_URL}/api/auth/register/", json=register_data)
    if response.status_code != 201:
        print(f"Registration failed: {response.text}")
        return
    
    token = response.json().get('token')
    user_id = response.json().get('user', {}).get('id')
    print(f"Token: {token}")
    print(f"User ID: {user_id}")
    
    # Set up headers with authentication
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }
    
    # Test social endpoints
    print("\n2. Testing Social Endpoints...")
    
    # Test achievements endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/social/achievements/?user={user_id}", headers=headers)
        print(f"Achievements endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("Achievements endpoint working!")
        else:
            print(f"Achievements endpoint failed: {response.text}")
    except Exception as e:
        print(f"Achievements endpoint error: {e}")
    
    # Test leaderboard endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/social/leaderboard/", headers=headers)
        print(f"Leaderboard endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("Leaderboard endpoint working!")
        else:
            print(f"Leaderboard endpoint failed: {response.text}")
    except Exception as e:
        print(f"Leaderboard endpoint error: {e}")
    
    # Test chat endpoints
    print("\n3. Testing Chat Endpoints...")
    
    # Test private chats endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/chat/private-chats/?user={user_id}", headers=headers)
        print(f"Private chats endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("Private chats endpoint working!")
        else:
            print(f"Private chats endpoint failed: {response.text}")
    except Exception as e:
        print(f"Private chats endpoint error: {e}")
    
    # Test courses endpoints
    print("\n4. Testing Courses Endpoints...")
    
    # Test courses endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/courses/", headers=headers)
        print(f"Courses endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("Courses endpoint working!")
        else:
            print(f"Courses endpoint failed: {response.text}")
    except Exception as e:
        print(f"Courses endpoint error: {e}")
    
    # Test payments endpoints
    print("\n5. Testing Payments Endpoints...")
    
    # Test subscription plans endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/payments/plans/", headers=headers)
        print(f"Subscription plans endpoint status: {response.status_code}")
        if response.status_code == 200:
            print("Subscription plans endpoint working!")
        else:
            print(f"Subscription plans endpoint failed: {response.text}")
    except Exception as e:
        print(f"Subscription plans endpoint error: {e}")

if __name__ == "__main__":
    test_endpoints()
