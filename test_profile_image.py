import requests
import json
import uuid

# Test the profile image upload and retrieval
BASE_URL = "http://127.0.0.1:8000/api/auth"

# First, let's register a test user
unique_id = str(uuid.uuid4())[:8]
register_data = {
    "username": f"testuser_{unique_id}",
    "email": f"testuser_{unique_id}@example.com",
    "password": "testpass123",
    "first_name": "Test",
    "last_name": "User"
}

print("Registering test user...")
response = requests.post(f"{BASE_URL}/register/", json=register_data)
print(f"Status: {response.status_code}")
if response.status_code == 201:
    token = response.json()['token']
    print(f"Token: {token}")
    
    # Get initial profile
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }
    
    print("\nGetting initial profile...")
    response = requests.get(f"{BASE_URL}/profile/", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        profile_data = response.json()
        print("Initial profile:")
        print(json.dumps(profile_data, indent=2))
        
        # Check if profile picture URL is present
        if 'profile_picture_url' in profile_data:
            print(f"\nProfile picture URL: {profile_data['profile_picture_url']}")
        else:
            print("\nNo profile picture URL in response")
    else:
        print(f"Error getting profile: {response.text}")
else:
    print(f"Error registering user: {response.text}")
