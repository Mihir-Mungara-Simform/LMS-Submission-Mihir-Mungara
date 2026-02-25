# Task 2: Read the File
with open('students.txt', 'r') as f:
    content = f.read()
    print(content)

print()

with open('students.txt', 'r') as f:
    for line in f:
        print(line, end ='')