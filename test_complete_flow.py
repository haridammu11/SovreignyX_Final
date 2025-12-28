import requests
import json

# Test the complete flow
BASE_URL = "http://127.0.0.1:8000"

def test_complete_flow():
    print("Testing complete code execution flow...")
    
    # Step 1: Authenticate
    print("\n1. Authenticating...")
    auth_response = requests.post(f"{BASE_URL}/api/code/auth/", json={"supabase_token": "test_token"})
    print(f"Auth Status: {auth_response.status_code}")
    
    if auth_response.status_code != 200:
        print("Authentication failed!")
        return
        
    auth_data = auth_response.json()
    django_token = auth_data.get('token')
    print(f"Django Token: {django_token}")
    
    # Step 2: Execute code
    print("\n2. Executing code...")
    headers = {
        "Authorization": f"Token {django_token}",
        "Content-Type": "application/json"
    }
    
    code_data = {
        "language": "python",
        "code": '''
print("Hello, World!")
x = 5
y = 10
print(f"The sum of {x} and {y} is {x + y}")
'''
    }
    
    exec_response = requests.post(f"{BASE_URL}/api/code/execute/", headers=headers, json=code_data)
    print(f"Execution Status: {exec_response.status_code}")
    
    if exec_response.status_code == 200:
        exec_data = exec_response.json()
        print(f"Output:\n{exec_data.get('output', 'No output')}")
    else:
        print(f"Execution failed: {exec_response.text}")

if __name__ == "__main__":
    test_complete_flow()
