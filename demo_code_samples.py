# Demo Code Samples for Testing the Code Editor Feature

# Python Sample
python_sample = '''
# Python Hello World with calculation
print("Hello from Python!")
x = 10
y = 20
print(f"The sum of {x} and {y} is {x + y}")

# Simple loop example
for i in range(5):
    print(f"Iteration {i}")

# Function example
def greet(name):
    return f"Hello, {name}!"

print(greet("Developer"))
'''

# JavaScript Sample
javascript_sample = '''
// JavaScript Hello World with calculation
console.log("Hello from JavaScript!");
let x = 15;
let y = 25;
console.log(`The sum of ${x} and ${y} is ${x + y}`);

// Array operations
let fruits = ["apple", "banana", "orange"];
fruits.forEach((fruit, index) => {
    console.log(`${index + 1}. ${fruit}`);
});

// Function example
function multiply(a, b) {
    return a * b;
}

console.log(`5 * 7 = ${multiply(5, 7)}`);
'''

# Java Sample
java_sample = '''
// Java Hello World with calculation
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
        
        int x = 30;
        int y = 40;
        System.out.println("The sum of " + x + " and " + y + " is " + (x + y));
        
        // Loop example
        for (int i = 0; i < 3; i++) {
            System.out.println("Iteration " + i);
        }
        
        // Method call
        String greeting = greet("Programmer");
        System.out.println(greeting);
    }
    
    public static String greet(String name) {
        return "Hello, " + name + "!";
    }
}
'''

# C Sample
c_sample = '''
#include <stdio.h>

// C Hello World with calculation
int main() {
    printf("Hello from C!\\n");
    
    int x = 50;
    int y = 60;
    printf("The sum of %d and %d is %d\\n", x, y, x + y);
    
    // Loop example
    for (int i = 0; i < 3; i++) {
        printf("Iteration %d\\n", i);
    }
    
    return 0;
}
'''

# C++ Sample
cpp_sample = '''
#include <iostream>
#include <string>
using namespace std;

// C++ Hello World with calculation
int main() {
    cout << "Hello from C++!" << endl;
    
    int x = 70;
    int y = 80;
    cout << "The sum of " << x << " and " << y << " is " << (x + y) << endl;
    
    // Loop example
    for (int i = 0; i < 3; i++) {
        cout << "Iteration " << i << endl;
    }
    
    // String example
    string name = "Coder";
    cout << "Welcome, " << name << "!" << endl;
    
    return 0;
}
'''

# Dart Sample
dart_sample = '''
// Dart Hello World with calculation
void main() {
  print('Hello from Dart!');
  
  int x = 90;
  int y = 100;
  print('The sum of $x and $y is ${x + y}');
  
  // Loop example
  for (int i = 0; i < 3; i++) {
    print('Iteration $i');
  }
  
  // Function example
  String greet(String name) {
    return 'Hello, $name!';
  }
  
  print(greet('Dart Developer'));
}
'''

if __name__ == "__main__":
    print("Demo code samples for the LMS Code Editor feature")
    print("=" * 50)
    print("\\nPython Sample:")
    print(python_sample)
    print("\\nJavaScript Sample:")
    print(javascript_sample)
    print("\\nJava Sample:")
    print(java_sample)
    print("\\nC Sample:")
    print(c_sample)
    print("\\nC++ Sample:")
    print(cpp_sample)
    print("\\nDart Sample:")
    print(dart_sample)
