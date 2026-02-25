# Task 5: Update the File
with open('students.txt', 'r') as f:
    lines = f.readlines()

with open('students.txt', '+w') as f:
    for line in lines:
        if 'Sophie' in line:
            temp_list = line.strip().split(', ')
            temp_list[1] = "23"
            new_line = ", ".join(temp_list) + "\n"
            f.write(new_line)
        else:
            f.write(line)
