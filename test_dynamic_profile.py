import requests
import json
import uuid

# Test the dynamic profile data loading
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
        
        # Check profile data fields
        required_fields = ['id', 'username', 'email', 'first_name', 'last_name', 'profile_picture_url']
        missing_fields = [field for field in required_fields if field not in profile_data]
        
        if not missing_fields:
            print("\n✓ All required profile fields are present")
        else:
            print(f"\n✗ Missing fields: {missing_fields}")
            
        # Check if profile picture URL is properly formatted
        if 'profile_picture_url' in profile_data:
            profile_pic_url = profile_data['profile_picture_url']
            if profile_pic_url is None:
                print("✓ Profile picture URL is correctly null (no image uploaded)")
            elif profile_pic_url.startswith(('http://', 'https://')):
                print("✓ Profile picture URL is valid (absolute HTTP URL)")
            elif profile_pic_url.startswith('/media/'):
                print("✓ Profile picture URL is valid (relative media path)")
            else:
                print(f"✗ Profile picture URL format is unexpected: {profile_pic_url}")
    else:
        print(f"Error getting profile: {response.text}")
else:
    print(f"Error registering user: {response.text}")
