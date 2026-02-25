# Task 4: Analyze the File
total_students = 0
students_grade_a = 0

with open('students.txt', 'r') as f:
    for line in f:
        total_students += 1
        if 'A' in line.strip().split(', '):
            students_grade_a += 1

print(f'total number of students :- {total_students - 1}')
print(f'number of students having grade A :- {students_grade_a}')