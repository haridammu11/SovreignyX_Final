import requests
import json

# Test the code execution API
BASE_URL = "http://127.0.0.1:8000/api"

# First, let's register a test user or use existing one
# For simplicity, we'll assume you have a valid token
# You can get this from your Django admin or by logging in

# Replace with a valid token from your system
TOKEN = "your_valid_token_here"

# Test Python code execution
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
response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

# Test JavaScript code execution
js_code = '''
console.log("Hello from JavaScript!");
let arr = [1, 2, 3, 4, 5];
console.log("Array sum:", arr.reduce((a, b) => a + b, 0));
'''

data = {
    "language": "javascript",
    "code": js_code
}

print("\nTesting JavaScript code execution...")
response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

# Test C code execution
c_code = '''
#include <stdio.h>

int main() {
    printf("Hello from C!\\n");
    int x = 5, y = 10;
    printf("The sum of %d and %d is %d\\n", x, y, x + y);
    return 0;
}
'''

data = {
    "language": "c",
    "code": c_code
}

print("\nTesting C code execution...")
response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")
