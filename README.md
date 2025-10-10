# InCollege COBOL Program

This project is a **menu-driven simulation** of the InCollege application, written in **COBOL**.  
It allows users to:
- Create an account (with validation rules)
- Log in with an existing account
- Search for jobs (placeholder feature)
- Find and connect with other users
- Send and see connection requests
- Create and edit personal profiles
- Learn new skills (placeholder feature)
- Logout and return to the initial menu
- Exit the application safely while saving account data

---

## 📦 Requirements

- [GnuCOBOL](https://gnucobol.sourceforge.io/) installed on your machine  
  (On macOS/Linux you can usually install via `brew install gnu-cobol` or your package manager).

---

## ⚙️ Compilation

Run the following command to compile:

```bash
cobc -x -free -o InCollege InCollege.cob
```

This will create an executable named `InCollege`.

---

## ▶️ Running the Program

Run the program with:

```bash
./InCollege
```

The program expects an **input file** (`InCollege-Input.txt`) to simulate user input.

---

## 📂 Files Used

- **`InCollege-Input.txt`** → Input file  
  Contains the sequence of menu choices and text the user would normally type interactively.

- **`InCollege-Output.txt`** → Output file  
  All messages displayed by the program are also written to this file.

- **`InCollege-Accounts.txt`** → Account storage  
  Stores created usernames and passwords between runs.  
  - If this file does not exist when running the code, proper output will not be generated using our input file, so please refer to the info below about the accounts information we used in our cod.
  - Maximum **5 accounts** can be created.
  - the accounts we use for our code
  alice               Aa1!aaaa
  bob                 Abcdef1!
  carol               Abcdefg1!
  dave                AbcDef1!Gh$Q
  eve                 Aa1!aaaaa

- **`InCollege-Profiles.txt`** → Profile storage  
  Stores user profile information including personal details, education, and work experience.
  - Created automatically when users create their first profile.

- **`InCollege-Pending-Requests.txt`** → Connection requests storage  
  Stores pending connection requests between users.
  - Created automatically when the first connection request is sent.

---

## ✨ Features

### 🔐 Account Management
- **Create Account**: Register with username and password validation
- **Login**: Access your account with credentials
- **Logout**: Return to welcome screen
- **Exit**: Save data and close program

### 👤 Profile Management
- **Create/Edit Profile**: Add personal information, education, and work experience
- **View Profile**: Display your complete profile information
- Profile includes:
  - Personal details (name, university, major, graduation year)
  - About Me section
  - Work experience entries
  - Education entries

### 🤝 Social Features
- **Find Someone**: Search for other users by first and last name
- **Send Connection Requests**: Connect with users who have profiles
- **View Pending Requests**: See who has sent you connection requests
- Case-insensitive name searches
- Prevents duplicate requests and self-connections

### 🚧 Placeholder Features
- **Search for Jobs**: Under construction
- **Learn New Skills**: Under construction

---

## 📝 Preparing Input File

The input file should contain **one command or response per line**.  

### Example: Complete workflow
```text
2
alice
Aa1!aaaa
4
Alice
Smith
University of Miami
Computer Science
2025
Enthusiastic CS student focusing on systems and AI.
Software Intern
Microsoft
Summer 2024
Built features in a web application with teammates.
Research Assistant
UM AI Lab
2023-2024
Worked on NLP models and experiments for publications.

B.Sc. Computer Science
University of Miami
2021-2025


2
Bob
Johnson
1
7
6
3
```

This simulates:
1. Logging in as "alice"
2. Creating a profile with education and work experience
5. Finding and sending connection request to Bob Johnson
6. Viewing pending requests
7. Logging out
8. Exiting program

---

## 🎯 Menu Navigation

### Welcome Screen
- `1` → Log In
- `2` → Create an Account  
- `3` → Exit Program

### Main Menu (after login)
- `1` → Search for a job (under construction)
- `2` → Find someone you know
- `3` → Learn a new skill (under construction)
- `4` → Create/Edit My Profile
- `5` → View My Profile
- `6` → Log Out
- `7` → View My Pending Connection Requests
- `8` → Exit program

### Find Someone Menu
- Enter first name (or `0` to go back)
- Enter last name
- `1` → Send Connection Request
- `2` → Back to Main Menu

---

## 📤 Output

After running, check **`InCollege-Output.txt`** to see the program's messages.  

### Example output:
```text
=== Welcome to InCollege! ===

  1. Log In
  2. Create an Account
--------------------------------------------------------------------------------
  3. Exit Program
--------------------------------------------------------------------------------
Enter your choice:

SUCCESS: You have successfully logged in.

Welcome, alice!

=== Main Menu ===

  1. Search for a job
  2. Find someone you know
  3. Learn a new skill
--------------------------------------------------------------------------------
  4. Create/Edit My Profile
  5. View My Profile
  6. Log Out
  7. View My Pending Connection Requests
--------------------------------------------------------------------------------
  8. Exit program
Enter your choice:

=== Pending Connection Requests ===

- bob
- carol

SUCCESS: Successfully Logged Out!
```

---

## ⚠️ Important Notes

### Password Validation Rules
- 8–12 characters long  
- Must include at least one uppercase letter  
- Must include at least one lowercase letter  
- Must include at least one number  
- Must include at least one special character (`!@#$%^&*()`)

### Connection Request Rules
- Users must have profiles to send/receive connection requests
- Cannot send requests to yourself
- Cannot send duplicate requests to the same user
- Name searches are case-insensitive

### System Limitations
- Maximum **5 user accounts**
- Profile information is stored persistently between sessions
- Connection requests persist until accepted/declined (future implementation)

### Error Handling
- Invalid menu selections show: `"ERROR: Invalid option. Please try again"`
- Non-existent users show: `"No user profile exists for the name you have entered."`
- Duplicate requests show: `"You have already sent this user a connection request."`
- Self-connection attempts show: `"You cannot connect with yourself."`

---

## 🧪 Testing

Use the provided test files:
- **`InCollege-Test-Requests.txt`** → Comprehensive test of connection request functionality
- Tests include valid connections, error cases, edge cases, and menu navigation

---
