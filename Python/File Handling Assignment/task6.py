# Task 6: Work with Large Files

# Create a file named numbers.txt and write numbers from 1 to 1000, each on a new line.
with open('numbers.txt', 'w') as f:
    for i in range (1,1001):
        f.write(str(i) + '\n')

# Calculate and display the sum of all numbers in the file.
sum = 0
with open('numbers.txt', 'r') as f:
    for line in f:
        sum += int(line)

print(f'sum of all the numbers :- {sum}')