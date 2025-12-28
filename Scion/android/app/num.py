import numpy as np

# 1. Create arrays
arr1 = np.array([1, 2, 3, 4, 5])
arr2 = np.arange(1, 6)   

print("Array 1:", arr1)
print("Array 2:", arr2)

sum_arr = arr1 + arr2
product_arr = arr1 * arr2

print("Sum:", sum_arr)
print("Product:", product_arr)

mean_val = np.mean(arr1)
std_val = np.std(arr1)

print("Mean of arr1:", mean_val)
print("Standard Deviation of arr1:", std_val)

matrix_a = np.array([[1, 2], [3, 4]])
matrix_b = np.array([[5, 6], [7, 8]])

dot_product = np.dot(matrix_a, matrix_b)
transpose_a = matrix_a.T

print("Dot Product:\n", dot_product)
print("Transpose of matrix_a:\n", transpose_a)