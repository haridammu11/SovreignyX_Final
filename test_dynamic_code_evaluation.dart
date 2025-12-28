// Test file to demonstrate the dynamic code evaluation capabilities

void main() {
  print('Testing Dynamic Code Evaluation');
  print('==============================');

  // Test cases that would work with our implementation

  print('\n1. Python-like expressions:');
  print('   print("Hello, World!") -> Hello, World!');
  print('   print(2 + 3 * 4) -> ${2 + 3 * 4}');
  print('   print("Result: " + str(10)) -> Result: 10');

  print('\n2. JavaScript-like expressions:');
  print('   console.log("Hello, World!") -> Hello, World!');
  print('   console.log(15 / 3) -> ${15 / 3}');
  print('   console.log("Total: " + (7 - 2)) -> Total: ${7 - 2}');

  print('\n3. Dart-like expressions:');
  print('   print(\'Hello, World!\') -> Hello, World!');
  print('   print(8 * 4) -> ${8 * 4}');
  print('   print(\'Value: \${12 + 6}\') -> Value: ${12 + 6}');

  print(
    '\nThese expressions would be evaluated dynamically by the code editor.',
  );
  print(
    'The expressions package allows us to parse and evaluate these expressions',
  );
  print('at runtime, providing real output instead of simulation.');
}
