# Task 9: Copy File Content

# Python program to copy the content of students.txt into a new file named students_backup.txt
with open('students.txt', 'r') as rf:
    with open('students_backup.txt', 'w') as wf:
        for line in rf:
            wf.write(line)

with open('students_backup.txt', 'r') as f:
    content = f.read()
    print(content)