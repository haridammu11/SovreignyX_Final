import requests
import json

# Test the authentication flow
BASE_URL = "https://9qcb6b3j-8000.inc1.devtunnels.ms"

def test_auth_flow():
    # First, let's try to register a test user
    register_data = {
        "username": "testuser123",
        "email": "testuser123@example.com",
        "password": "testpassword123",
        "first_name": "Test",
        "last_name": "User"
    }
    
    print("Attempting to register...")
    register_response = requests.post(f"{BASE_URL}/api/auth/register/", json=register_data)
    print(f"Register status: {register_response.status_code}")
    print(f"Register response: {register_response.text}")
    
    if register_response.status_code == 201:
        register_result = register_response.json()
        token = register_result.get('token')
        print(f"Received token: {token}")
        
        # Now test accessing a protected endpoint
        print("\nTesting profile access...")
        profile_response = requests.get(
            f"{BASE_URL}/api/auth/profile/",
            headers={"Authorization": f"Token {token}"}
        )
        print(f"Profile status: {profile_response.status_code}")
        print(f"Profile response: {profile_response.text}")
        
        # Test social achievements endpoint
        print("\nTesting social achievements access...")
        achievements_response = requests.get(
            f"{BASE_URL}/api/social/achievements/?user=1",
            headers={"Authorization": f"Token {token}"}
        )
        print(f"Achievements status: {achievements_response.status_code}")
        print(f"Achievements response: {achievements_response.text}")
    else:
        print("Registration failed, trying to login...")
        login_data = {
            "email": "testuser123@example.com",
            "password": "testpassword123"
        }
        
        login_response = requests.post(f"{BASE_URL}/api/auth/login/", json=login_data)
        print(f"Login status: {login_response.status_code}")
        print(f"Login response: {login_response.text}")
        
        if login_response.status_code == 200:
            login_result = login_response.json()
            token = login_result.get('token')
            print(f"Received token: {token}")
            
            # Test accessing a protected endpoint
            print("\nTesting profile access...")
            profile_response = requests.get(
                f"{BASE_URL}/api/auth/profile/",
                headers={"Authorization": f"Token {token}"}
            )
            print(f"Profile status: {profile_response.status_code}")
            print(f"Profile response: {profile_response.text}")

if __name__ == "__main__":
    test_auth_flow()
