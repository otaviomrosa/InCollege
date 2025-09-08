       identification division.
       program-id. InCollege.
      *    We are separating divisons with a blank line for readability
       environment division.
       input-output section.
       file-control.
      *    Define three files: input-file, output-file, and accounts-file and assign them to text files
      *    The accounts-file will be used to store user account information
           select input-file assign to 'InCollege-Input.txt'
               organization is line sequential.
           select output-file assign to 'InCollege-Output.txt'
               organization is line sequential.
           select accounts-file assign to 'InCollege-Accounts.txt'
               organization is line sequential.

       data division.
       file section.
      *    Define the record structure for each of the three files
       fd input-file.
       01  input-record      pic x(80).
       fd  output-file.
       01  output-record     pic x(80).
       fd  accounts-file.
       01  account-record.
      *    Each account record consists of a username and password
           05  username        pic x(20).
           05  password        pic x(12).
       working-storage section.
      *    Ensure all variables here start with "ws" to indicate they are in working-storage section.
      *    For example, ws-username, ws-password, etc

      *    - FILE STATUS AND EOF FLAGS - 
       01  ws-userdata-status  pic x(2).
       01  ws-input-eof        pic a(1) value 'N'.
           88  input-ended         value 'Y'.
      *    - PROGRAM FLOW AND INPUT -
       01  ws-program-state    pic x(20) value 'INITIAL-MENU'.
      *    Initial menu is the first thing the user sees, prompting them to choose between logging in or creating an account 
           88  at-initial-menu         value 'INITIAL-MENU'.
           88  at-login-screen         value 'LOGIN-SCREEN'.
           88  at-register-screen      value 'REGISTER-SCREEN'.
           88  at-main-menu            value 'MAIN-MENU'.
           88  at-job-search-menu      value 'JOB-SEARCH-MENU'.
           88  at-find-someone-menu    value 'FIND-SOMEONE-MENU'.
           88  at-learn-skill-menu     value 'SKILL-MENU'.
       01  ws-user-choice      pic x(20).
      *    - ACCOUNT DATA - We keep a copy of the accounts file locally at runtime for faster access instead of reading the file everytime (simply for good practice)
       01  ws-account-table.
           05  ws-user-account     occurs 5 times.
               10  ws-username         pic x(20).
               10  ws-password         pic x(12).
       01  ws-current-account-count    pic 9 value 0.
       01  ws-max-accounts             pic 9 value 5.
      *    - TEMPORARY INPUT FOR LOGIN/REGISTRATION -
       01  ws-input-username   pic x(20).
       01  ws-input-password   pic x(12).

       linkage section.

       procedure division.
      *    Open all files that wil be used
       perform initialize-files.
      *    The whole program will run inside this loop that iterates through every line of input until the file ends
       perform main-program-loop until input-ended.

       perform cleanup-files.
       stop run.

       main-program-loop.
      *    First, give users the option of 1) logging in or 2) creating an account
           if at-initial-menu
               perform display-initial-menu
               perform read-user-choice
               if ws-user-choice is equal to '1'
                   move "LOGIN-SCREEN" to ws-program-state
      *    If they choose to log in, prompt for username and password and look them up in the accounts file (must match)
           else if at-login-screen
               perform display-username-prompt
               perform read-user-choice
               perform username-lookup     
               perform display-password-prompt
               perform read-user-choice
               perform password-lookup
      *    If they choose to create an account, prompt them for their username and password
           else if at-register-screen
               perform display-username-prompt
               perform read-user-choice
               perform validate-username     
               perform display-password-prompt
               perform read-user-choice
               perform validate-password
           else if at-main-menu
               perform display-main-menu
               perform read-user-choice
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

       display-initial-menu.
           display "Welcome to InCollege!".
           display "(1) Log In".
           display "(2) Create an Account".
           display "Enter your choice:".

       display-main-menu.
           display "(1) Search for a job".
           display "(2) Find someone you know".
           display "(3) Learn a new skill"
           display "(4) Enter your choice:"

       read-user-choice.
      *    Read the next line of input and assign it to ws-user-choice 
           read input-file into ws-user-choice
               at end set input-ended to true
           end-read.

      *    Validate both inputs and if valid AND if the accounts file has less than 5 accounts,
      *    Create the account by storing the username and password in a file. If the file does not exist create it
      *    If the file already has 5 accounts, display a message that the maximum number of accounts has been reached
      *    If the inputs are invalid, display a message indicating what was wrong with the input
      *    After creating an account, return to the initial prompt.
      *    If they choose to log in, prompt them for their username and password

      *    Make a function that validates password input when creating an account

       cleanup-files.
           close input-file, output-file, accounts-file.

       end program InCollege.
