# InCollege COBOL Program

This project is a **menu-driven simulation** of the InCollege application, written in **COBOL**.  
It allows users to:
- Create an account (with validation rules)
- Log in with an existing account
- Explore placeholder menus for "Search for a job", "Find someone you know", and "Learn a new skill"
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
cobc -x InCollege.cob -o InCollege
```

This will create an executable named `InCollege`.

---

## ▶️ Running the Program

Run the program with:

```bash
./InCollege
```

The program expects an **input file** (`InCollege-Test.txt`) to simulate user input.

---

## 📂 Files Used

- **`InCollege-Test.txt`** → Input file  
  Contains the sequence of menu choices and text the user would normally type interactively.

- **`InCollege-Output.txt`** → Output file  
  All messages displayed by the program are also written to this file.

- **`InCollege-Accounts.txt`** → Persistent storage  
  Stores created usernames and passwords between runs.  
  - If this file does not exist, the program will automatically create it.  
  - Maximum **5 accounts** can be created.

---

## 📝 Preparing Input File

The input file (`InCollege-Test.txt`) should contain **one command or response per line**.  
For example, to create an account, log in, and then exit:

```text
Create an Account
myUser
MyPass123!
Log In
myUser
MyPass123!
Exit Program
```

This simulates:
1. Choosing "Create an Account"
2. Entering `myUser` as the username
3. Entering `MyPass123!` as the password
4. Logging in with that account
5. Exiting the program

---

## 📤 Output

After running, check **`InCollege-Output.txt`** to see the program’s messages.  
For example:

```text
Welcome to InCollege!
Log In
Create an Account
Exit program
Enter your choice:
Please create a username:
Enter a password:
(8-12 chars, 1 uppercase, 1 lower, 1 special)
Account created successfully!
You have successfully logged in.
Welcome, myUser!
Successfully Logged Out!
```

---

## 🚪 Exiting and Logging Out

- Choosing **Logout** → returns you to the initial menu with the message:  
  `"Successfully Logged Out!"`  
- Choosing **Exit Program** → ends the program after saving data.

---

## ⚠️ Notes

- Password validation rules:  
  - 8–12 characters long  
  - Must include at least one uppercase letter  
  - Must include at least one lowercase letter  
  - Must include at least one number  
  - Must include at least one special character (`!@#$%^&*()`)

- If invalid menu input is entered, the program will respond with:  
  `"Invalid option. Please try again"`

---
