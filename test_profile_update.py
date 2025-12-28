import requests
import json

# Test the profile update endpoint
BASE_URL = "http://127.0.0.1:8000/api/auth"

import uuid

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
else:
    print(f"Error: {response.text}")

# Now let's update the profile
update_data = {
    "bio": "This is my updated bio",
    "phone": "+1234567890"
}

headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}

print("\nUpdating profile...")
response = requests.put(f"{BASE_URL}/profile/", json=update_data, headers=headers)
print(f"Status: {response.status_code}")
if response.status_code == 200:
    print("Profile updated successfully!")
    print(json.dumps(response.json(), indent=2))
else:
    print(f"Error: {response.text}")
