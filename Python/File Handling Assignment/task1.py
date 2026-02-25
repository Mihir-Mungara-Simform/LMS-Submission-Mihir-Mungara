# Task 1: Create a File

# create a file named students.txt.
with open('students.txt', 'x'):
    pass

# writing data to file
with open('students.txt', 'w') as f:
    f.write('Name, Age, Grade \n')
    f.write('John, 20, A  \n')
    f.write('Alice, 19, B  \n')
    f.write('Mark, 21, A \n')
    f.write('Sophie, 22, C \n')