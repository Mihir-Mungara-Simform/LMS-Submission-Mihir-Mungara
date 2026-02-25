# Task 10: Delete a File
import os


# Python program to delete the file students_backup.txt after confirming from the user.
answer = int(input('Press 1 to Delete \'students_backup.txt\' file :- '))

if answer == 1:
    os.remove('students_backup.txt')
    print('you confirmed to delete a file')
    print('File Deleted Successfully')
else:
    print('Exiting ...')