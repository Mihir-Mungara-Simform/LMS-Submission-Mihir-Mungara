# Task 8: Word Count
lines_list = ['this is line 1\n','this is line 2\n','this is line 3\n','this is line 4\n','this is line 5\n']
with open('paragraph.txt', 'w') as f:
    f.writelines(lines_list)

word_count = 0
word_dict = {}

with open('paragraph.txt', 'r') as f:
    for line in f:
        arr_word = line.split(' ')
        for ind_word in arr_word:
            if ind_word not in word_dict:
                word_dict[ind_word] = 1
            else:
                word_dict[ind_word] += 1
        word_count += len(arr_word)

print(f'total number of words in the file :- {word_count}')
print(word_dict)