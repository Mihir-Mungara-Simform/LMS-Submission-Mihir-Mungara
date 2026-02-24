users = {
    "trainer1": "Train@123",
    "trainer2": "Learn@123",
}

# -------------------- LOGIN SYSTEM --------------------

for i in range(3):
    print("Attempt number:", i + 1)
    user_name = input("Enter user_name: ")
    password = input("Enter Password: ")

    if user_name in users and users[user_name] == password:
        print("User logged in successfully\n")
        break
    else:
        print("Invalid credentials\n")
else:
    print("Access Denied. Please contact admin.")
    exit()

# -------------------- DATA STORAGE --------------------

marks = {}
average_scores = {}
grades = {}

# -------------------- GRADE FUNCTION --------------------

def grade(score):
    if score >= 85:
        return "Excellent"
    elif score >= 70:
        return "Good"
    elif score >= 50:
        return "Average"
    else:
        return "Needs Improvement"

# -------------------- MAIN MENU --------------------

while True:

    case_number = int(input(
        "\nEnter case_number"
        "\n1. Create New Trainee"
        "\n2. Performance Evaluation"
        "\n3. Analytics and Reporting"
        "\n4. Trainer Decision"
        "\n5. Quit"
        "\nChoice: "
    ))

    if case_number not in range(1, 6):
        print("Invalid option, Please select correct option")
        continue

    # -------------------- CASE 1 --------------------
    if case_number == 1:

        trainee_name = input("Enter Trainee Name: ")
        trainee_password = input("Enter Password: ")

        def get_valid_marks(subject):
            while True:
                marks = int(input(f"Enter {subject} Marks: "))
                if 0 <= marks <= 100:
                    return marks
                else:
                    print("Enter marks between 0 and 100")

        python_marks = get_valid_marks("Python Basics")
        data_structures_marks = get_valid_marks("Data Structures")
        control_flow_marks = get_valid_marks("Control Flow")

        users[trainee_name] = trainee_password
        marks[trainee_name] = [
            python_marks,
            data_structures_marks,
            control_flow_marks
        ]

        print("Trainee created successfully!")

    # -------------------- CASE 2 --------------------
    elif case_number == 2:

        if not marks:
            print("No trainee records found.")
            continue

        for user in marks:
            total = sum(marks[user])
            average = total / len(marks[user])
            average_scores[user] = average
            grades[user] = grade(average)

            print(f"{user} -> Total: {total}, Average: {average:.2f}, Grade: {grades[user]}")

    # -------------------- CASE 3 --------------------
    elif case_number == 3:

        if not average_scores:
            print("Please run Performance Evaluation first.")
            continue

        highest = ''
        lowest = ''
        h_marks = 0
        l_marks = 200
        for user in average_scores:
            if average_scores[user] > h_marks:
                h_marks = average_scores[user]
                highest = user
            if average_scores[user] < l_marks:
                l_marks = average_scores[user]
                lowest = user
        print("Highest scorer:", highest)
        print("Lowest scorer:", lowest)

        grades_list = {
            "Excellent": 0,
            "Good": 0,
            "Average": 0,
            "Needs Improvement": 0
        }

        for user in grades:
            grades_list[grades[user]] += 1

        print("Grade Distribution:", grades_list)

        # Identify failed trainees
        failed_trainees = []

        for user in marks:
            if min(marks[user]) < 40:
                failed_trainees.append(user)

        print("Failed trainees:", failed_trainees)

    # -------------------- CASE 4 --------------------
    elif case_number == 4:

        answer = input("Do you want to schedule remedial training? (yes/no): ")

        if answer.lower() == "yes":
            print("Trainees for remedial training:", failed_trainees)
        else:
            print("Report finalized successfully")

    # -------------------- CASE 5 --------------------
    else:
        print("Exiting program...")
        break