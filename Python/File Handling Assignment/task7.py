# Task 7: Error Handling
try:
    with open('non_existent_file.txt', 'r') as f:
        pass

except FileNotFoundError:
    print('there is no file named \'non_existent_file.txt\' in the current directory')
    
except Exception:
    print('Unknown Error Occured')