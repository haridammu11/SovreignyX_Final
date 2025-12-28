#!/usr/bin/env python3
"""
Test script for the backend code execution service
"""

import requests
import json

# Test the code execution API
BASE_URL = "http://127.0.0.1:8000/api"

# Replace with a valid token from your system
TOKEN = "your_valid_token_here"

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
    response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_javascript_execution():
    """Test JavaScript code execution"""
    js_code = '''
console.log("Hello from JavaScript!");
let arr = [1, 2, 3, 4, 5];
console.log("Array sum:", arr.reduce((a, b) => a + b, 0));
'''
    
    headers = {
        "Authorization": f"Token {TOKEN}",
        "Content-Type": "application/json"
    }
    
    data = {
        "language": "javascript",
        "code": js_code
    }
    
    print("Testing JavaScript code execution...")
    response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_java_execution():
    """Test Java code execution"""
    java_code = '''
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
        int x = 5, y = 10;
        System.out.println("The sum of " + x + " and " + y + " is " + (x + y));
    }
}
'''
    
    headers = {
        "Authorization": f"Token {TOKEN}",
        "Content-Type": "application/json"
    }
    
    data = {
        "language": "java",
        "code": java_code
    }
    
    print("Testing Java code execution...")
    response = requests.post(f"{BASE_URL}/code/execute/", headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

if __name__ == "__main__":
    print("Code Execution Service Test Script")
    print("=" * 40)
    
    # Test different languages
    test_python_execution()
    test_javascript_execution()
    test_java_execution()
    
    print("Test completed!")
