import requests
import json
import uuid

# Test the profile image URL construction
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
        
        # Check if profile picture URL is present and valid
        if 'profile_picture_url' in profile_data:
            profile_pic_url = profile_data['profile_picture_url']
            print(f"\nProfile picture URL: {profile_pic_url}")
            
            # Check if it's a valid URL (starts with http)
            if profile_pic_url and profile_pic_url.startswith('http'):
                print("✓ Profile picture URL is valid (starts with http)")
            elif profile_pic_url and profile_pic_url.startswith('/media/'):
                print("✓ Profile picture URL is valid (relative path)")
            else:
                print("✗ Profile picture URL is invalid")
        else:
            print("\nNo profile picture URL in response")
    else:
        print(f"Error getting profile: {response.text}")
else:
    print(f"Error registering user: {response.text}")
