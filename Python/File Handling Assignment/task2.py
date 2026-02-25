# Task 2: Read the File

# display its content on the console
with open('students.txt', 'r') as f:
    content = f.read()
    print(content)

print()

# Split the content line by line and print each line separately.
with open('students.txt', 'r') as f:
    for line in f:
        print(line, end ='')