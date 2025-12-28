import requests

# Test the posts API
url = "http://127.0.0.1:8000/api/social/posts/"

# Replace with a valid token from your system
TOKEN = "your_valid_token_here"

headers = {
    "Authorization": f"Token {TOKEN}",
    "Content-Type": "application/json"
}

try:
    response = requests.get(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
