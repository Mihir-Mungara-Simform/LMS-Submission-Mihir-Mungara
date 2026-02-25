# Task 7: Error Handling
try:
    with open('non_existent_file.txt', 'r') as f:
        pass
  
# handle the FileNotFoundError
except FileNotFoundError:
    print('there is no file named \'non_existent_file.txt\' in the current directory')
    
# Handle other potential exceptions that may arise during file operations.
except Exception:
    print('Unknown Error Occured')