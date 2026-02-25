# Task 6: Work with Large Files
with open('numbers.txt', 'w') as f:
    for i in range (1,1001):
        f.write(str(i) + '\n')

sum = 0
with open('numbers.txt', 'r') as f:
    for line in f:
        sum += int(line)

print(f'sum of all the numbers :- {sum}')