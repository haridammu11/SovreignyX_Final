import requests
import json

# Test the code execution API
BASE_URL = "http://127.0.0.1:8000"

# Use the token we just created
TOKEN = "b8335ce47836b7cf459e31a857e06b3cdcaf432c"

def test_python_execution():
    """Test Python code execution"""
    python_code = '''
print("Hello, World!")
x = 5
y = 10
print(f"The sum of {x} and {y} is {x + y}")
'''
    
    headers = {
        "Authorization": f"Token {TOKEN}",
        "Content-Type": "application/json"
    }
    
    data = {
        "language": "python",
        "code": python_code
    }
    
    print("Testing Python code execution...")
    try:
        response = requests.post(f"{BASE_URL}/api/code/execute/", headers=headers, json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_python_execution()