       identification division.
       program-id. InCollege.
*>    We are separating divisons with a blank line for readability
       environment division.
       input-output section.
       file-control.
*>    Define three files: input-file, output-file, and accounts-file and assign them to text files
*>    The accounts-file will be used to store user account information
           select input-file assign to 'InCollege-Test.txt'
               organization is line sequential.
           select output-file assign to 'InCollege-Output.txt'
               organization is line sequential.
           select accounts-file assign to 'InCollege-Accounts.txt'
               organization is line sequential
               file status is ws-userdata-status.

       data division.
       file section.
*>    Define the record structure for each of the three files
       fd input-file.
       01  input-record      pic x(80).
       fd  output-file.
       01  output-record     pic x(80).
       fd  accounts-file.
       01  account-record.
*>    Each account record consists of a username and password
           05  username        pic x(20).
           05  password        pic x(12).
       working-storage section.
*>    Ensure all variables here start with "ws" to indicate they are in working-storage section.
*>    For example, ws-username, ws-password, etc

*>    - FILE STATUS AND EOF FLAGS - 
       01  ws-userdata-status  pic x(2).
       01  ws-input-eof        pic a(1) value 'N'.
           88  input-ended         value 'Y'.
*>    - PROGRAM FLOW AND INPUT -
       01  ws-program-state    pic x(20) value 'INITIAL-MENU'.
*>    Initial menu is the first thing the user sees, prompting them to choose between logging in or creating an account 
           88  at-initial-menu         value 'INITIAL-MENU'.
           88  at-login-screen         value 'LOGIN-SCREEN'.
           88  at-register-screen      value 'REGISTER-SCREEN'.
           88  at-main-menu            value 'MAIN-MENU'.
           88  at-job-search-menu      value 'JOB-SEARCH-MENU'.
           88  at-find-someone-menu    value 'FIND-SOMEONE-MENU'.
           88  at-learn-skill-menu     value 'SKILL-MENU'.
       01  ws-user-choice      pic x(40).
*>    - ACCOUNT DATA - We keep a copy of the accounts file locally at runtime for faster access instead of reading the file everytime (simply for good practice)
       01  ws-account-table.
           05  ws-user-account     occurs 5 times.
               10  ws-username         pic x(20).
               10  ws-password         pic x(12).
       01  ws-current-account-count    pic 9 value 0.
       01  ws-max-accounts             pic 9 value 5.
       01  ws-account-found            pic a(1) value 'N'.
           88  account-found            value 'Y'.
       01  ws-i                        pic 99 value 1.

       01  ws-validation-counters.
           05  ws-number-count       pic 9 value 0.
           05  ws-specialchar-count  pic 9 value 0. 

       01  ws-accounts-eof           pic a(1) value 'N'.
           88 accounts-file-ended    value 'Y'.
*>    - TEMPORARY INPUT FOR LOGIN/REGISTRATION -
       01  ws-input-username   pic x(99).
       01  ws-input-password   pic x(99).

*>    - Variable to hold message for display + write -
       01  ws-message  pic x(80).

       procedure division.
*>    Open all files that wil be used
       perform initialize-files.
*>    The whole program will run inside this loop that iterates through every line of input until the file ends
       perform main-program-loop until input-ended.

       perform cleanup-files.
       stop run.

       main-program-loop.
*>    First, give users the option of 1) logging in or 2) creating an account
           if at-initial-menu
               perform display-initial-menu
               perform read-user-choice
               if ws-user-choice = 'Log In'
                   move "LOGIN-SCREEN" to ws-program-state
               else if ws-user-choice = 'Create an Account'
                   move "REGISTER-SCREEN" to ws-program-state
               else if ws-user-choice = 'Exit Program'
                   perform cleanup-files
                   stop run
               else    
                   move "Invalid option. Please try again" to ws-message
                   perform display-message
                   move "INITIAL-MENU" to ws-program-state
                   stop run
                

               end-if
*>    If they choose to log in, prompt for username and password and look them up in the accounts file (must match)
           else if at-login-screen
               move "Please enter your username:" to ws-message
               perform display-message
               perform read-user-choice
               perform username-lookup
               if account-found     
                   move "Please enter your password:" to ws-message
                   perform display-message
                   perform read-user-choice
                   perform password-lookup
                end-if

*>    If they choose to create an account, prompt them for their username and password
           else if at-register-screen
               if ws-current-account-count >= ws-max-accounts
                   move "All permitted accounts have been created, please come back later." to ws-message
                   perform display-message
                   move "INITIAL-MENU" to ws-program-state
               else
                   move "Please create a username:" to ws-message
                   perform display-message
                   perform read-user-choice
                   perform validate-username
                   if not account-found and not input-ended
                       move "Enter a password:" to ws-message
                       perform display-message
                       move "(8-12 chars, 1 uppercase, 1 lower, 1 special)" to ws-message
                       perform display-message
                       perform read-user-choice
                       perform validate-password
                   end-if
               end-if

           else if at-main-menu
               perform display-main-menu
               perform read-user-choice
                if ws-user-choice = 'Search for a job'
                     move "JOB-SEARCH-MENU" to ws-program-state
                else if ws-user-choice = 'Find someone you know'
                     move "FIND-SOMEONE-MENU" to ws-program-state
                else if ws-user-choice = 'Learn a new skill'
                     move "SKILL-MENU" to ws-program-state
                else if ws-user-choice = 'Logout'
                     move "Successfully Logged Out!" to ws-message
                     perform display-message                      
                     move "INITIAL-MENU" to ws-program-state
                else if ws-user-choice = 'Exit Program'
                     perform cleanup-files
                     stop run  
                else    
                     move "Invalid option. Please try again" to ws-message
                     perform display-message
                     move "MAIN-MENU" to ws-program-state
                end-if
           else if at-job-search-menu
               perform display-under-construction
           else if at-find-someone-menu
               perform display-under-construction
           else if at-learn-skill-menu
               perform display-skills
               perform read-user-choice
               perform display-under-construction
           end-if.

       initialize-files.
           open input input-file.
           open output output-file.
           open i-o accounts-file.

           if ws-userdata-status = "35"
               move "Accounts file not found. Creating a new one." to ws-message
               perform display-message
               open output accounts-file
               if ws-userdata-status not = "00"
                   move "Error: Could not create accounts file. Status: " to ws-message 
                   perform display-message
                   display ws-userdata-status
                   stop run
               end-if
               close accounts-file

               open i-o accounts-file
           end-if.
           if ws-userdata-status not = "00"
               move "FATAL ERROR opening accounts file. Status: " to ws-message 
               perform display-message
               display ws-userdata-status
               stop run
           end-if.

           perform until accounts-file-ended
               read accounts-file next record
                   at end set accounts-file-ended to true
                   not at end
                       add 1 to ws-current-account-count
                       move username 
                           to ws-username(ws-current-account-count)
                       move password 
                           to ws-password(ws-current-account-count)
*>                     display "Debug - Loading user: '" 
*>                           ws-username(ws-current-account-count) "'"
*>                     display "Debug - Loading pass: '" 
*>                           ws-password(ws-current-account-count) "'"
               end-read
           end-perform.
           close accounts-file.

       display-initial-menu.
           move "Welcome to InCollege!" to ws-message 
           perform display-message
           move "Log In" to ws-message 
           perform display-message
           move "Create an Account" to ws-message 
           perform display-message
           move "Exit program" to ws-message 
           perform display-message
           move "Enter your choice:" to ws-message 
           perform display-message.

       display-main-menu.
           move "Search for a job" to ws-message 
           perform display-message
           move "Find someone you know" to ws-message
           perform display-message
           move "Learn a new skill" to ws-message 
           perform display-message
           move "Log Out" to ws-message
           perform display-message
           move "Exit program" to ws-message
           perform display-message
           move "Enter your choice:" to ws-message 
           perform display-message.

       display-skills.
           move "Time Management" to ws-message 
           perform display-message
           move "Professional Communication and Networking" to ws-message 
           perform display-message
           move "Coding" to ws-message 
           perform display-message
           move "Financial Literacy" to ws-message 
           perform display-message
           move "Physical Wellbeing" to ws-message 
           perform display-message
           move "Go Back" to ws-message 
           perform display-message.

       display-under-construction.
           if ws-user-choice = "Search for a job"
               move "Job search/internship is under construction." to ws-message 
               perform display-message
               move "MAIN-MENU" to ws-program-state
           else if ws-user-choice = "Find someone you know"
               move "Find someone you know is under construction." to ws-message 
               perform display-message
               move "MAIN-MENU" to ws-program-state
*>    This line makes it so every skill option entered will display the under construction message and return to main menu         
           else if ws-program-state = "SKILL-MENU"
               if ws-user-choice = "Go Back"
                   move "MAIN-MENU" to ws-program-state
               else
                   move "This skill is under construction." to ws-message
                   perform display-message
                   move "SKILL-MENU" to ws-program-state
           end-if.

       read-user-choice.
*>    Read the next line of input and assign it to ws-user-choice 
           read input-file into ws-user-choice
               at end set input-ended to true
           end-read.
           move function trim(ws-user-choice) to ws-user-choice.

       username-lookup.
           move function trim(ws-user-choice) to ws-input-username
               move 'N' to ws-account-found
               perform varying ws-i from 1 by 1
                   until ws-i > ws-current-account-count
                   if ws-input-username = function trim(ws-username(ws-i))
                       set account-found to true
                       exit perform
                   end-if
               end-perform
               if not account-found
                   move "Username not found. Returning to menu." to ws-message
                   perform display-message
                   move "INITIAL-MENU" to ws-program-state
               end-if.

       password-lookup.
           move function trim(ws-user-choice) to ws-input-password
           if account-found
*>               display "Debug - Login attempt with password: '" 
*>                   ws-input-password "'"
*>               display "Debug - Stored password for user: '" 
*>                   ws-password(ws-i) "'"
*>               display "Debug - Trimmed input: '" 
*>                   function trim(ws-input-password) "'"
*>               display "Debug - Trimmed stored: '" 
*>                   function trim(ws-password(ws-i)) "'"
               if ws-input-password = function trim(ws-password(ws-i))
                   move "You have successfully logged in." to ws-message 
                   perform display-message
                   string "Welcome, " function trim(ws-input-username) "!" delimited by size
                       into ws-message
                   perform display-message
                   move "MAIN-MENU" to ws-program-state
               else
                   move "Incorrect password. Returning to menu." to ws-message
                   perform display-message
                   move "INITIAL-MENU" to ws-program-state
               end-if
           end-if.

       validate-username.
           move ws-user-choice to ws-input-username
           move 'N' to ws-account-found
           if ws-input-username = spaces
               move "Username cannot be empty. Returning to menu." to ws-message
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else
               perform varying ws-i from 1 by 1
                   until ws-i > ws-current-account-count 
                   if ws-input-username = ws-username(ws-i)
                       set account-found to true
                       exit perform
                   end-if
               end-perform
               if account-found
                   move "Username already exists. Returning to menu." to ws-message
                   perform display-message
                   move "INITIAL-MENU" to ws-program-state
                   move "Y" to ws-input-eof
               end-if
           end-if.

 
       validate-password.
           move function trim(ws-user-choice) to ws-input-password
           
           initialize ws-validation-counters
           inspect ws-input-password tallying ws-number-count
               for all "0", "1", "2", "3", "4",
                       "5", "6", "7", "8", "9"
           inspect ws-input-password tallying ws-specialchar-count
               for all "!", "@", "#", "$", "%",
                       "^", "&", "*", "(", ")"

           if function length(function trim(ws-input-password)) < 8 or
              function length(function trim(ws-input-password)) > 12
               move "Password must be between 8 and 12 characters." to ws-message 
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else if ws-input-password = function upper-case(ws-input-password)
               move "Password must contain a lowercase letter." to ws-message 
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else if ws-input-password = function lower-case(ws-input-password)
               move "Password must contain an uppercase letter." to ws-message 
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else if ws-number-count = zero
               move "Password must contain a number." to ws-message 
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else if ws-specialchar-count = zero
               move "Password must contain a special character." to ws-message 
               perform display-message
               move "INITIAL-MENU" to ws-program-state
           else
               add 1 to ws-current-account-count
               move ws-input-username to ws-username(ws-current-account-count)
               move ws-input-password to ws-password(ws-current-account-count)
               move "Account created successfully!" to ws-message 
               perform display-message
               move "MAIN-MENU" to ws-program-state
           end-if.

       display-message.
           display ws-message
           move ws-message to output-record
           write output-record.

       cleanup-files.
           open output accounts-file
           perform varying ws-i from 1 by 1
               until ws-i > ws-current-account-count
               move ws-username(ws-i) to username
               move ws-password(ws-i) to password
               write account-record
           end-perform
           close input-file, output-file, accounts-file.
           
       end program InCollege.
