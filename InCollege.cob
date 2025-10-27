 *>    team Oklahoma 
 *>    compile code - cobc -x -free -Wall -o incollege InCollege.cob  
 *>    run - ./incollege   
      
      identification division.
      program-id. InCollege.
*>    We are separating divisons with a blank line for readability
      environment division.
      input-output section.
      file-control.
*>    Define three files: input-file, output-file, and accounts-file and assign them to text files
*>    The accounts-file will be used to store user account information
          select input-file assign to 'InCollege-Input.txt'
              organization is line sequential.
          select output-file assign to 'InCollege-Output.txt'
              organization is line sequential.
          select accounts-file assign to 'InCollege-Accounts.txt'
              organization is line sequential
              file status is ws-userdata-status.
*>    A - New file creation for each user linked by username
          select profiles-file assign to 'InCollege-Profiles.txt'
              organization is line sequential
              file status is ws-profiles-status.
*>    temp file used for atomic profile updates
          select temp-profiles-file assign to 'InCollege-Profiles.tmp'
              organization is line sequential
              file status is ws-profiles-status.

   *> Pending requests (sender -> recipient)
          select pending-requests-file assign to 'InCollege-PendingRequests.txt'
                organization is line sequential
                file status is ws-requests-status.
*>    Established connections (userA <-> userB).  Used only for validation.
          select connections-file assign to 'InCollege-Connections.txt'
                organization is line sequential
                file status is ws-connections-status.
*>    temp file for pending requests update (atomic remove)   
          select temp-pending-file assign to 'InCollege-PendingRequests.tmp'
            organization is line sequential
            file status is ws-temp-status.

*>    Jobs file for storing job postings
          select jobs-file assign to 'InCollege-Jobs.txt'
            organization is line sequential
            file status is ws-jobs-status.

*>    Applications file for storing who applied to which job
          select applications-file assign to 'InCollege-Applications.txt'
            organization is line sequential
            file status is ws-app-status.




      data division.
      file section.
*>    Define the record structure for each of the three files
      fd input-file.
      01  input-record      pic x(500).
      fd  output-file.
      01  output-record     pic x(200).
      fd  accounts-file.
      01  account-record.
*>    Each account record consists of a username and password
          05  username        pic x(20).
          05  password        pic x(12).
*>    A - profile file structure added here - added missing fields
      fd  profiles-file.
        01  profile-record.
            05  profile-username     pic x(20).


            *> required scalars
            05  profile-first-name   pic x(20).
            05  profile-last-name    pic x(20).
            05  profile-school       pic x(50).
            05  profile-major        pic x(40).
            05  profile-grad-year    pic 9(4).


            *> optional "about me"
            05  profile-about        pic x(200).


            *> experience (up to 3)
            05  profile-exp occurs 3.
                10  exp-title        pic x(30).
                10  exp-company      pic x(40).
                10  exp-dates        pic x(30).
                10  exp-desc         pic x(120).


            *> education (up to 3)
            05  profile-edu occurs 3.
                10  edu-degree       pic x(30).
                10  edu-school       pic x(40).
                10  edu-years        pic x(20).




*>    A - temp files for profile editing
      fd  temp-profiles-file.
        01  temp-profile-record.
            05  temp-profile-username     pic x(20).


            *> required scalars
            05  temp-profile-first-name   pic x(20).
            05  temp-profile-last-name    pic x(20).
            05  temp-profile-school       pic x(50).
            05  temp-profile-major        pic x(40).
            05  temp-profile-grad-year    pic 9(4).


            *> optional "about me"
            05  temp-profile-about        pic x(200).


            *> experience (up to 3)
            05  temp-profile-exp occurs 3.
                10  temp-exp-title        pic x(30).
                10  temp-exp-company      pic x(40).
                10  temp-exp-dates        pic x(30).
                10  temp-exp-desc         pic x(120).


            *> education (up to 3)
            05  temp-profile-edu occurs 3.
                10  temp-edu-degree       pic x(30).
                10  temp-edu-school       pic x(40).
                10  temp-edu-years        pic x(20).

      fd  pending-requests-file.
           01  request-record.
               05  req-sender      pic x(20).
               05  req-recipient   pic x(20).
           
      fd  connections-file.
           01  connection-record.
               05  conn-user-a     pic x(20).
               05  conn-user-b     pic x(20).

      fd  temp-pending-file.
           01  temp-request-record.
               05  temp-req-sender    pic x(20).
               05  temp-req-recipient pic x(20).

      fd  jobs-file.
           01  job-record.
               05  job-title          pic x(50).
               05  job-description    pic x(500).
               05  job-employer       pic x(50).
               05  job-location       pic x(50).
               05  job-salary         pic x(20).
               05  job-poster         pic x(20).

      fd  applications-file.
           01  application-record.
               05  app-username      pic x(20).
               05  app-job-title     pic x(50).
               05  app-job-employer  pic x(50).
               05  app-job-location  pic x(50).
               05  app-job-salary    pic x(20).




      working-storage section.
*>    Ensure all variables here start with "ws" to indicate they are in working-storage section.
*>    For example, ws-username, ws-password, etc


*>    - FILE STATUS AND EOF FLAGS -
      01  ws-userdata-status  pic x(2).
      01  ws-input-eof        pic a(1) value 'N'.
      88  input-ended         value 'Y'.


      01  ws-last-input     pic x(500) value spaces.
      01  ws-profile-header        pic x(30) value spaces.
      01  ws-prev-degree            pic x(30).

      01 MAX-ABOUT       pic 9(3) value 200.
      01 MAX-EXP-TITLE   pic 9(3) value 30.
      01 MAX-EXP-COMP    pic 9(3) value 40.
      01 MAX-EXP-DATES   pic 9(3) value 30.
      01 MAX-EXP-DESC    pic 9(3) value 120.
      01 MAX-JOB-DESC    pic 9(3) value 500.
       
      01 ws-input-len    pic 9(4) value 0.


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
         
*>    A - profile menu option
          88  at-profile-menu         value 'PROFILE-MENU'.
      01  ws-user-choice      pic x(40).

      *> Debug mode switch: Y = interactive (ACCEPT), N = file (READ)
      01  ws-debug-mode    pic a(1) value 'N'.
          88 debug-mode    value 'Y'.
          
*>    - ACCOUNT DATA - We keep a copy of the accounts file locally at runtime for faster access instead of reading the file everytime (simply for good practice)
      01  ws-account-table.
          05  ws-user-account     occurs 5 times.
              10  ws-username         pic x(20).
              10  ws-password         pic x(12).
      01  ws-current-account-count    pic 9 value 0.
      01  ws-max-accounts             pic 9 value 5.
      01  ws-account-found            pic a(1) value 'N'.
          88  account-found            value 'Y'.
      01  ws-validation-passed       pic a(1) value 'N'.
          88  validation-passed       value 'Y'.
      01  ws-i                        pic 99 value 1.
      01  ws-prev-title            pic x(30).

      *> ===== Session state =====
        01  ws-current-username        PIC X(20) VALUE SPACES.
        01  ws-current-username-upper  PIC X(20) VALUE SPACES.  *> helper for case-insensitive compares




      *> Find someone 
      01 ws-search-first         pic x(12).
      01 ws-search-last          pic x(12).
      01 ws-name-match-found     pic a(1) value 'N'.
         88 name-match-found     value 'Y'.


      01  ws-validation-counters.
          05  ws-number-count       pic 9 value 0.
          05  ws-specialchar-count  pic 9 value 0.


      01  ws-accounts-eof           pic a(1) value 'N'.
          88 accounts-file-ended    value 'Y'.
*>    A - storage section for profile file creation
      01  ws-profiles-status        pic x(2).
      01  ws-profiles-eof           pic a(1) value 'N'.
          88 profiles-file-ended    value 'Y'.
      01  ws-profile-found          pic a(1) value 'N'.
          88 profile-found          value 'Y'.
      01  ws-profile-data.


         *> required scalars
         05  ws-profile-first-name   pic x(20).
         05  ws-profile-last-name    pic x(20).
         05  ws-profile-school       pic x(50).
         05  ws-profile-major        pic x(40).
         05  ws-profile-grad-year    pic 9(4).


         *> optional
         05  ws-profile-about        pic x(200).


         *> experiences (up to 3 entries)
         05  ws-profile-exp occurs 3.
             10  ws-exp-title        pic x(30).
             10  ws-exp-company      pic x(40).
             10  ws-exp-dates        pic x(30).
             10  ws-exp-desc         pic x(120).


         *> education (up to 3 entries)
         05  ws-profile-edu occurs 3.
             10  ws-edu-degree       pic x(30).
             10  ws-edu-school       pic x(40).
             10  ws-edu-years        pic x(20).




      01  ws-profile-updated    pic a(1) value 'N'.
          88 profile-updated    value 'Y'.


     *>    - PROFILE YEAR HELPERS -
      01  ws-grad-year-text      pic x(4).


      01  ws-year-valid-flag     pic a(1) value 'N'.
          88 year-valid          value 'Y'.


      01  ws-year-len            pic 99    value 0.
      01  ws-year-num            pic 9(4) value 0.




*>    - TEMPORARY INPUT FOR LOGIN/REGISTRATION -
      01  ws-input-username   pic x(99).
      01  ws-input-password   pic x(99).


*>    - Variable to hold message for display + write -
        01  ws-message          pic x(200).
        01  ws-temp-message     pic x(200).
        01  ws-blank-line       pic x(200) value spaces.
        01  ws-line-separator   pic x(80) value all "-".

*>    formatting
       01  ws-label                  pic x(30) value spaces.
        01  ws-value                  pic x(200) value spaces.
        01  ws-colon-space            pic x(2) value ": ".


       01  ws-requests-status     pic x(2).
       01  ws-connections-status  pic x(2).
       01  ws-temp-status         pic x(2).
       
       01  ws-requests-eof        pic a(1) value 'N'.
          88 requests-file-ended  value 'Y'.
       01  ws-conns-eof           pic a(1) value 'N'.
          88 conns-file-ended     value 'Y'.
       
       01  ws-pending-found       pic a(1) value 'N'.
          88 pending-found        value 'Y'.
       01  ws-pending-other-way   pic a(1) value 'N'.
          88 pending-other-way    value 'Y'.
       01  ws-connected-flag      pic a(1) value 'N'.
          88 users-already-connected value 'Y'.

*>    - JOB POSTING VARIABLES -
       01  ws-jobs-status         pic x(2).
       01  ws-jobs-eof            pic a(1) value 'N'.
          88 jobs-file-ended      value 'Y'.
       
       01  ws-job-data.
           05  ws-job-title       pic x(50).
           05  ws-job-description pic x(500).
           05  ws-job-employer    pic x(50).
           05  ws-job-location    pic x(50).
           05  ws-job-salary      pic x(20).

*>    - APPLICATION PERSISTENCE -
       01  ws-app-status          pic x(2).
       01  ws-app-eof             pic a(1) value 'N'.
          88 applications-file-ended value 'Y'.

*>    - BROWSE/VIEW TEMP STATE -
       01  ws-selected-index      pic 9(4) value 0.
       01  ws-wrap-cols           pic 9(3) value 70.
       01  ws-desc-idx            pic 9(4) value 1.
       01  ws-desc-len            pic 9(4) value 0.
       01  ws-remaining           pic 9(4) value 0.
       01  ws-chunk-len           pic 9(4) value 0.
       01  ws-j                   pic 9(4) value 0.

       01  ws-total-jobs          pic 9(4) value 0.
       01  ws-num-2              pic 99     value 0.
       01  ws-num-txt            pic x(2)   value spaces.



*>    Buffer for a selected job (used by view/apply)
       01  ws-selected-job.
           05  sj-title           pic x(50).
           05  sj-description     pic x(500).
           05  sj-employer        pic x(50).
           05  sj-location        pic x(50).
           05  sj-salary          pic x(20).

       
       01  ws-found-username      pic x(20) value spaces.  *> username from matched profile
       01  ws-list-count          pic 9(4)  value 0.
       01  ws-request-index       pic 9(4)  value 0.
       01  ws-found-request       pic a(1) value 'N'.
           88  found-request       value 'Y'.
       01  ws-no-more-pending     pic a(1) value 'N'.
           88  no-more-pending-requests value 'Y'.

       01  ws-action-choice     pic x(1) value spaces.
       01  ws-processed-any     pic a(1) value 'N'.
          88 processed-any      value 'Y'.
       01  ws-current-sender    pic x(20) value spaces.
       01  ws-network-count     pic 9(4)  value 0.
        


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
              if ws-user-choice = '1'
                  move "LOGIN-SCREEN" to ws-program-state
              else if ws-user-choice = '2'
                  move "REGISTER-SCREEN" to ws-program-state
              else if ws-user-choice = '3'
                  perform cleanup-files
                  stop run
              else   
                  move "Invalid option. Please try again" to ws-message
                  perform display-error
                  move "INITIAL-MENU" to ws-program-state
              end-if
*>    If they choose to log in, prompt for username and password and look them up in the accounts file (must match)
          else if at-login-screen
              move "Please enter your username:" to ws-message
              perform display-prompt
              perform read-user-choice
              perform username-lookup
              if account-found    
                  move "Please enter your password:" to ws-message
                  perform display-prompt
                  perform read-user-choice
                  perform password-lookup
               end-if


*>    If they choose to create an account, prompt them for their username and password
          else if at-register-screen
              if ws-current-account-count >= ws-max-accounts
                  move "All permitted accounts have been created, please come back later." to ws-message
                  perform display-info
                  move "INITIAL-MENU" to ws-program-state
              else
                  move "Please create a username:" to ws-message
                  perform display-prompt
                  perform read-user-choice
                  perform validate-username
                  if validation-passed and not account-found and not input-ended
                      move "Enter a password:" to ws-message
                      perform display-prompt
                      move "(8-12 chars, 1 uppercase, 1 lower, 1 special)" to ws-message
                      perform display-info
                      perform read-user-choice
                      perform validate-password
                  end-if
              end-if


          else if at-main-menu
              perform display-main-menu
              perform read-user-choice
               if ws-user-choice = '1'
                    move "JOB-SEARCH-MENU" to ws-program-state
               else if ws-user-choice = '2'
                    move "FIND-SOMEONE-MENU" to ws-program-state
               else if ws-user-choice = '3'
                    move "SKILL-MENU" to ws-program-state
     *>   A - profile create/edit else if
               else if ws-user-choice = '4'
                    move "PROFILE-MENU" to ws-program-state
               else if ws-user-choice = '5'
                    perform view-profile
*>         option 6 to view pending requests
               else if ws-user-choice = '6'
                   perform process-my-pending-requests

*>         option 7 to view network
               else if ws-user-choice = '7'
                   perform view-my-network
                   move "MAIN-MENU" to ws-program-state
               else if ws-user-choice = '8'
                    move "Successfully Logged Out!" to ws-message
                    perform display-success
                    move spaces to ws-current-username              
                    move "INITIAL-MENU" to ws-program-state
               else if ws-user-choice = '9'
                   perform cleanup-files
                   stop run
               else   
                    move "Invalid option. Please try again" to ws-message
                    perform display-error
                    move "MAIN-MENU" to ws-program-state
               end-if
          else if at-job-search-menu
              perform handle-job-search-menu
          else if at-find-someone-menu
              perform handle-find-someone
          else if at-learn-skill-menu
              perform display-skills
              perform read-user-choice
              if ws-user-choice = '6'
                  move "MAIN-MENU" to ws-program-state
              else
                  perform display-under-construction
                  move "SKILL-MENU" to ws-program-state
              end-if
*>    A - profile menu logic
          else if at-profile-menu
              perform handle-profile-menu
          end-if.


      initialize-files.
          open input input-file.
          open output output-file.
          open i-o accounts-file.


          if ws-userdata-status = "35"
              move "Accounts file not found. Creating a new one." to ws-message
              perform display-info
              open output accounts-file
              if ws-userdata-status not = "00"
                  move "Could not create accounts file. Status: " to ws-message
                  string ws-message ws-userdata-status into ws-message
                  perform display-error
                  perform cleanup-files
                  stop run
              end-if
              close accounts-file


              open i-o accounts-file
          end-if.
          if ws-userdata-status not = "00"
              move "FATAL ERROR opening accounts file. Status: " to ws-message
              string ws-message ws-userdata-status into ws-message
              perform display-error
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
              end-read
          end-perform.
          close accounts-file.


      display-initial-menu.
          move "Welcome to InCollege!" to ws-message
          perform display-title
          move "1. Log In" to ws-message
          perform display-option
          move "2. Create an Account" to ws-message
          perform display-option
          display ws-line-separator
          perform write-separator
          move "3. Exit Program" to ws-message
          perform display-special-option
          display ws-line-separator
          perform write-separator
          move "Enter your choice: " to ws-message
          perform display-prompt.


      display-main-menu.
          move "Main Menu" to ws-message
          perform display-title
          move "1. Job Search/Internship" to ws-message
          perform display-option
          move "2. Find Someone You Know" to ws-message
          perform display-option
          move "3. Learn a New Skill" to ws-message
          perform display-option
          display ws-line-separator
          perform write-separator
          move "4. Create/Edit My Profile" to ws-message
          perform display-special-option
          move "5. View My Profile" to ws-message
          perform display-special-option
          move "6. View My Pending Connection Requests" to ws-message
          perform display-special-option
          move "7. View My Network" to ws-message
          perform display-special-option
          move "8. Log Out" to ws-message
          perform display-special-option
          display ws-line-separator
          perform write-separator
          move "9. Exit program" to ws-message
          perform display-special-option

          move "Enter your choice: " to ws-message
          perform display-prompt.


      display-skills.
          move "Learn a New Skill" to ws-message
          perform display-title
          move "1. Time Management" to ws-message
          perform display-option
          move "2. Professional Communication and Networking" to ws-message
          perform display-option
          move "3. Coding" to ws-message
          perform display-option
          move "4. Financial Literacy" to ws-message
          perform display-option
          move "5. Physical Wellbeing" to ws-message
          perform display-option
          display ws-line-separator
          perform write-separator
          move "6. Go Back" to ws-message
          perform display-special-option
          display ws-line-separator
          perform write-separator
          move "Enter your choice: " to ws-message
          perform display-prompt.


      display-under-construction.
          move "This feature is under construction." to ws-message
          perform display-info
          if at-learn-skill-menu
              move "SKILL-MENU" to ws-program-state
          else
              move "MAIN-MENU" to ws-program-state
          end-if.


      read-next-input.
        if debug-mode
            accept ws-last-input
            if ws-last-input = spaces
                set input-ended to true
            else
                move function trim(ws-last-input) to ws-last-input
            end-if
        else
            read input-file
                at end
                    set input-ended to true
                not at end
                    move function trim(input-record) to ws-last-input
            end-read
        end-if.
    


         read-user-choice.
       perform read-next-input
       if not input-ended
           move ws-last-input to ws-user-choice
           move function trim(ws-user-choice) to ws-user-choice
       end-if.




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
                  perform display-error
                  move "INITIAL-MENU" to ws-program-state
              end-if.


      password-lookup.
          move function trim(ws-user-choice) to ws-input-password
          if account-found
              if ws-input-password = function trim(ws-password(ws-i))
                  move "You have successfully logged in." to ws-message
                  perform display-success
                  move spaces to ws-message
                  string "Welcome, " function trim(ws-input-username) "!" delimited by size
                      into ws-message
                  perform display-info

                  *> Canonical current user for the whole session:
                  move function trim(ws-input-username) to ws-current-username

                  move "MAIN-MENU" to ws-program-state
              else
                  move "Incorrect password. Returning to menu." to ws-message
                  perform display-error
                  move "INITIAL-MENU" to ws-program-state
              end-if
          end-if.


      validate-username.
          move ws-user-choice to ws-input-username
          move 'N' to ws-account-found
          move 'N' to ws-validation-passed
          if ws-input-username = spaces
              move "Username cannot be empty. Returning to menu." to ws-message
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else if function length(function trim(ws-input-username)) > 20
              move "Username cannot be longer than 20 characters. Returning to menu." to ws-message
              perform display-error
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
                  perform display-error
                  move "INITIAL-MENU" to ws-program-state
                  move "Y" to ws-input-eof
              else
                  set validation-passed to true
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
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else if ws-input-password = function upper-case(ws-input-password)
              move "Password must contain a lowercase letter." to ws-message
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else if ws-input-password = function lower-case(ws-input-password)
              move "Password must contain an uppercase letter." to ws-message
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else if ws-number-count = zero
              move "Password must contain a number." to ws-message
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else if ws-specialchar-count = zero
              move "Password must contain a special character." to ws-message
              perform display-error
              move "INITIAL-MENU" to ws-program-state
          else
              add 1 to ws-current-account-count
              move ws-input-username to ws-username(ws-current-account-count)
              move ws-input-password to ws-password(ws-current-account-count)
              move "Account created successfully!" to ws-message
              perform display-success

              *> If creation means you’re signed in, remember who that is:
              move function trim(ws-input-username) to ws-current-username

              move "MAIN-MENU" to ws-program-state
          end-if.


      display-title.
          display ws-blank-line
          perform write-blank-line
          move ws-message to ws-temp-message
          move spaces to ws-message
          string "=== " function trim(ws-temp-message) " ===" delimited by size into ws-message
          display function trim(ws-message)
          perform write-message
          display ws-blank-line
          perform write-blank-line.


      display-option.
          move ws-message to ws-temp-message
          move spaces to ws-message
          string "  " function trim(ws-temp-message) delimited by size into ws-message
          display function trim(ws-message)
          perform write-message.


      display-special-option.
          move ws-message to ws-temp-message
          move spaces to ws-message
          string "  " function trim(ws-temp-message) delimited by size into ws-message
          display function trim(ws-message)
          perform write-message.


      display-prompt.
          display function trim(ws-message) " " with no advancing
          perform write-message.


      display-info.
          display ws-blank-line
          perform write-blank-line
          display function trim(ws-message)
          perform write-message
          display ws-blank-line
          perform write-blank-line.

       display-line.
          *> Prints a single line with no extra blank lines
          move function trim(ws-message) to ws-message
          display function trim(ws-message)
          perform write-message
          exit paragraph.

      *> Join "Label: Value" into one line and print it (no extra blank lines)
      display-labeled-line.
          move spaces to ws-message
          string
              function trim(ws-label)       delimited by size
              ": "                          delimited by size
              function trim(ws-value)       delimited by size
            into ws-message
          end-string
          perform display-line
          exit paragraph.

      display-error.
          display ws-blank-line
          perform write-blank-line
          move ws-message to ws-temp-message
          move spaces to ws-message
          string "ERROR: " function trim(ws-temp-message) delimited by size into ws-message
          display function trim(ws-message)
          perform write-message
          display ws-blank-line
          perform write-blank-line.
      
      display-success.
          display ws-blank-line
          perform write-blank-line
          move ws-message to ws-temp-message
          move spaces to ws-message
          string "SUCCESS: " function trim(ws-temp-message) delimited by size into ws-message
          display function trim(ws-message)
          perform write-message
          display ws-blank-line
          perform write-blank-line.

      *> ========= Validation helpers =========

        check-already-connected.
            *> Uses ws-input-username and ws-found-username from WORKING-STORAGE
            move 'N' to ws-connected-flag
            move 'N' to ws-conns-eof
            open input connections-file
            evaluate ws-connections-status
                when "00" continue
                when "35"
                    close connections-file
                    exit paragraph
                when other
                    move "Connections file error." to ws-message
                    perform display-error
                    close connections-file
                    exit paragraph
            end-evaluate

            perform until conns-file-ended
                read connections-file next record
                    at end set conns-file-ended to true
                    not at end
                        if (function trim(conn-user-a) = function trim(ws-input-username) and
                            function trim(conn-user-b) = function trim(ws-found-username))
                         or (function trim(conn-user-b) = function trim(ws-input-username) and
                             function trim(conn-user-a) = function trim(ws-found-username))
                            set users-already-connected to true
                            set conns-file-ended to true
                        end-if
                end-read
            end-perform
            close connections-file
            exit paragraph.

       check-pending-between.
           *> Uses ws-input-username and ws-found-username from WORKING-STORAGE
                                           
           move 'N' to ws-pending-found
           move 'N' to ws-pending-other-way
           move 'N' to ws-requests-eof
           open input pending-requests-file
           evaluate ws-requests-status
               when "00" continue
               when "35"
                   close pending-requests-file
                   exit paragraph
               when other
                   move "Pending-requests file error." to ws-message
                   perform display-error
                   close pending-requests-file
                   exit paragraph
           end-evaluate
       
           perform until requests-file-ended
               read pending-requests-file next record
                   at end set requests-file-ended to true
                   not at end
                       if function trim(req-sender) = function trim(ws-input-username) and
                          function trim(req-recipient) = function trim(ws-found-username)
                           set pending-found to true
                       end-if
                       if function trim(req-sender) = function trim(ws-found-username) and
                          function trim(req-recipient) = function trim(ws-input-username)
                           set pending-other-way to true
                       end-if
               end-read
           end-perform
           close pending-requests-file
           exit paragraph.
       
       *> ========= Action: Send Request =========
       send-connection-request.
           if function upper-case(function trim(ws-input-username))
              = function upper-case(function trim(ws-found-username))
               move "You cannot connect with yourself." to ws-message
               perform display-info
               exit paragraph
           end-if
       
           perform check-already-connected
           if users-already-connected
               move "You are already connected with this user." to ws-message
               perform display-info
               exit paragraph
           end-if
       
           perform check-pending-between
           if pending-found
               move "You have already sent this user a connection request." to ws-message
               perform display-info
               exit paragraph
           end-if
           if pending-other-way
               move "This user has already sent you a connection request." to ws-message
               perform display-info
               exit paragraph
           end-if
       
           open extend pending-requests-file
           if ws-requests-status = "35"
               open output pending-requests-file
               close pending-requests-file
               open extend pending-requests-file
           end-if
           if ws-requests-status not = "00"
               move "Could not open pending-requests file." to ws-message
               perform display-error
               exit paragraph
           end-if
       
           move function trim(ws-input-username) to req-sender
           move function trim(ws-found-username) to req-recipient
           write request-record
           close pending-requests-file
       
           move "Successfully sent Connection Request" to ws-message
           perform display-success
           exit paragraph.
       
       *> ========= View My Pending Requests =========
        view-my-pending-requests.
        move 0 to ws-list-count


        display ws-line-separator
        move "Pending Connection Requests" to ws-message
        perform display-title

        move 'N' to ws-requests-eof
        open input pending-requests-file
        evaluate ws-requests-status
            when "00"
                continue
            when "35"
                move "You have no pending connection requests at this time." to ws-message
                perform display-info
                close pending-requests-file
                exit paragraph
            when other
                move "Pending-requests file error." to ws-message
                perform display-error
                close pending-requests-file
                exit paragraph
        end-evaluate

        *> Normalize the current username once (upper + trim) for comparisons
        move function upper-case(function trim(ws-current-username)) to ws-temp-message


        perform until requests-file-ended
            read pending-requests-file next record
                at end
                    set requests-file-ended to true
                not at end
                    *> Compare recipient (normalized) to current user (normalized)
                    if function upper-case(function trim(req-recipient)) =
                       function trim(ws-temp-message)
                        add 1 to ws-list-count
                        move spaces to ws-message
                        string
                            " - "                      delimited by size
                            function trim(req-sender)  delimited by size
                          into ws-message
                        end-string
                        perform display-line

                    end-if
            end-read
        end-perform

        close pending-requests-file

        if ws-list-count = 0
            move "You have no pending connection requests at this time." to ws-message
            perform display-line
        end-if.
           exit paragraph.

*> ==== Process My Pending Requests (Accept/Reject with updates) ====
       process-my-pending-requests.
           move "Pending Connection Requests" to ws-message
           perform display-title

           *> RESET LOOP/STATE FLAGS FOR A FRESH RUN - added by A
            move 'N' to ws-no-more-pending
            move 'N' to ws-requests-eof
            move 'N' to ws-found-request
            move spaces to ws-action-choice
            move 'N' to ws-processed-any

           *> Process requests one by one until no more pending requests
           perform until no-more-pending-requests
               move spaces to ws-requests-status     *> ensure fresh status each iteration
               move 'N' to ws-requests-eof
               move 'N' to ws-found-request
               open input pending-requests-file
               evaluate ws-requests-status
                   when "00" continue
                   when "35"
                       move "You have no pending connection requests at this time." to ws-message
                       perform display-info
                       close pending-requests-file
                       move "MAIN-MENU" to ws-program-state
                       exit paragraph
                   when other
                       move "Pending-requests file error." to ws-message
                       perform display-error
                       close pending-requests-file
                       move "MAIN-MENU" to ws-program-state
                       exit paragraph
               end-evaluate

               move 'N' to ws-requests-eof
               move 'N' to ws-found-request

               perform until requests-file-ended or found-request
                   read pending-requests-file next record
                       at end
                           set requests-file-ended to true
                       not at end
                           if function upper-case(function trim(req-recipient))
                              = function upper-case(function trim(ws-current-username))
                               move req-sender to ws-current-sender
                               set found-request to true
                           end-if
                   end-read
               end-perform

               close pending-requests-file

               if not found-request
                   move "You have no more pending connection requests." to ws-message
                   perform display-info
                   set no-more-pending-requests to true
               end-if

               if found-request
                   move spaces to ws-message
                   string "Request from: " delimited by size
                           function trim(ws-current-sender) delimited by size
                   into ws-message
                   end-string
                   perform display-line

                   move "  1. Accept" to ws-message
                   perform display-option
                   move "  2. Reject" to ws-message
                   perform display-option
                   move "Enter your choice: " to ws-message
                   perform display-prompt
                   perform read-user-choice
                   move function trim(ws-user-choice) to ws-action-choice

                   *> Accept
                   if ws-action-choice = '1'
                        *> Close before mutating
                        close pending-requests-file

                        perform add-established-connection

                        *> Remove the processed row (this rewrites the file)
                        perform remove-single-pending-request

                        move "Connection request accepted!" to ws-message
                        perform display-success

                        *> Restart next outer iteration; do NOT reopen here
                        continue
                    end-if

                   *> Reject
                   if ws-action-choice = '2'
                       close pending-requests-file
                        perform remove-single-pending-request
                        move "Connection request rejected." to ws-message
                        perform display-success
                        continue
                   end-if

                   if ws-action-choice not = '1' and ws-action-choice not = '2'
                       move "Invalid choice, skipping this request." to ws-message
                       perform display-error
                   end-if
               end-if
           end-perform
           
           move "MAIN-MENU" to ws-program-state.
           exit paragraph.

       add-established-connection.
           open extend connections-file
           if ws-connections-status = "35"
               open output connections-file
               close connections-file
               open extend connections-file
           end-if
           if ws-connections-status not = "00"
               move "Could not open connections file." to ws-message
               perform display-error
               exit paragraph
           end-if

           move function trim(ws-current-sender) to conn-user-a
           move function trim(ws-current-username) to conn-user-b
           write connection-record
           close connections-file
           exit paragraph.

       remove-single-pending-request.
           *> Start clean status
           move spaces to ws-requests-status
           move spaces to ws-temp-status

           open input pending-requests-file

           if ws-requests-status = "35"
               *> Original file missing: ensure no stray temp exists and return
               close pending-requests-file
               exit paragraph
           end-if

           if ws-requests-status not = "00"
               move "Error opening pending requests file for removal" to ws-message
               perform display-error
               close pending-requests-file
               exit paragraph
           end-if

           open output temp-pending-file

           if ws-temp-status not = "00"
               move "Error opening temp file for removal" to ws-message
               perform display-error
               close pending-requests-file
               close temp-pending-file
               exit paragraph
           end-if

           move 'N' to ws-requests-eof
           perform until requests-file-ended
               read pending-requests-file next record
                   at end
                       set requests-file-ended to true
                   not at end
                       if not (
                           function upper-case(function trim(req-sender))    = function upper-case(function trim(ws-current-sender))
                        and function upper-case(function trim(req-recipient)) = function upper-case(function trim(ws-current-username))
                       )
                           move req-sender    to temp-req-sender
                           move req-recipient to temp-req-recipient
                           write temp-request-record
                       end-if
               end-read
           end-perform

           close pending-requests-file
           close temp-pending-file

           *> Replace original with temp atomically
           move "InCollege-PendingRequests.txt" to ws-message
           call "CBL_DELETE_FILE" using ws-message

           move "InCollege-PendingRequests.tmp" to ws-message
           move "InCollege-PendingRequests.txt" to ws-user-choice
           call "CBL_RENAME_FILE" using ws-message, ws-user-choice

           *> Reset statuses so the caller's next OPEN gets fresh codes
           move spaces to ws-requests-status
           move spaces to ws-temp-status

           exit paragraph.

*> ==== View My Network (list established connections, enrich from profiles) ====
       view-my-network.
           move 0 to ws-network-count
           move "Your Network" to ws-message
           perform display-title

           move 'N' to ws-conns-eof
           open input connections-file
           evaluate ws-connections-status
               when "00" continue
               when "35"
                   move "No connections found." to ws-message
                   perform display-info
                   close connections-file
                   exit paragraph
               when other
                   move "Connections file error." to ws-message
                   perform display-error
                   close connections-file
                   exit paragraph
           end-evaluate

           move function upper-case(function trim(ws-current-username)) to ws-temp-message

           perform until conns-file-ended
               read connections-file next record
                   at end set conns-file-ended to true
                   not at end
                       if function upper-case(function trim(conn-user-a)) = function trim(ws-temp-message)
                           move function trim(conn-user-b) to ws-found-username
                           perform display-one-network-entry
                           add 1 to ws-network-count
                       else if function upper-case(function trim(conn-user-b)) = function trim(ws-temp-message)
                           move function trim(conn-user-a) to ws-found-username
                           perform display-one-network-entry
                           add 1 to ws-network-count
                       end-if
               end-read
           end-perform
           close connections-file

           if ws-network-count = 0
               move "No connections found." to ws-message
               perform display-info
           end-if.
           exit paragraph.

       display-one-network-entry.
           move spaces to ws-profile-first-name
           move spaces to ws-profile-last-name
           move spaces to ws-profile-school
           move spaces to ws-profile-major

           move 'N' to ws-profiles-eof
           open input profiles-file
           evaluate ws-profiles-status
               when "00" continue
               when "35"
                   close profiles-file
               when other
                   close profiles-file
           end-evaluate

           if ws-profiles-status = "00"
               perform until profiles-file-ended
                   read profiles-file next record
                       at end set profiles-file-ended to true
                       not at end
                           if function upper-case(function trim(profile-username))
                               = function upper-case(function trim(ws-found-username))
                               move profile-first-name to ws-profile-first-name
                               move profile-last-name  to ws-profile-last-name
                               move profile-school     to ws-profile-school
                               move profile-major      to ws-profile-major
                               set profiles-file-ended to true
                           end-if
                   end-read
               end-perform
               close profiles-file
           end-if

           if ws-profile-first-name not = spaces or ws-profile-last-name not = spaces
               move spaces to ws-message
               string
               "Connected with: "              delimited by size
               function trim(ws-profile-first-name) delimited by size
               " "                             delimited by size
               function trim(ws-profile-last-name)  delimited by size
               into ws-message
               end-string
               perform display-line

               if ws-profile-school not = spaces or ws-profile-major not = spaces
                   move spaces to ws-message
                   string
                   "  (" delimited by size
                    "University: " delimited by size
                   function trim(ws-profile-school) delimited by size
                   ", Major: " delimited by size
                   function trim(ws-profile-major) delimited by size
                   ")" delimited by size
                   into ws-message
                   end-string
                   perform display-line
               end-if
            else
               move spaces to ws-message
               string
               "Connected with: " delimited by size
               function trim(ws-found-username) delimited by size
               into ws-message
               end-string
               perform display-line
           end-if.

      write-message.
          move ws-message to output-record
          write output-record.


      write-blank-line.
          move ws-blank-line to output-record
          write output-record.


      write-separator.
          move ws-line-separator to output-record
          write output-record.


*>    A - profile menu routines
      handle-profile-menu.
          perform check-profile-exists
          if profile-found
              move "Editing your existing profile..." to ws-message
              perform display-info
              perform edit-profile
          else
              move "Creating new profile..." to ws-message
              perform display-info
              perform create-profile
          end-if
          move "MAIN-MENU" to ws-program-state.


      view-profile.
            perform check-profile-exists
            if ws-profile-found = 'Y'
                move "Your Profile" to ws-profile-header
                perform render-profile
            else
                move "No profile found. Please create a profile first." to ws-message
                perform display-info
            end-if
            move "MAIN-MENU" to ws-program-state.

      *> ===================== Profile Rendering (no reset) =====================
       render-profile.
        *> Print header only if caller provided one
        if ws-profile-header not = spaces
            move function trim(ws-profile-header) to ws-message
            perform display-title
        end-if

        *> First Name
        if ws-profile-first-name not = spaces
            move "First Name" to ws-label
            move ws-profile-first-name to ws-value
            perform display-labeled-line
        end-if

        *> Last Name
        if ws-profile-last-name not = spaces
            move "Last Name" to ws-label
            move ws-profile-last-name to ws-value
            perform display-labeled-line
        end-if

        *> University/College
        if ws-profile-school not = spaces
            move "University/College" to ws-label
            move ws-profile-school to ws-value
            perform display-labeled-line
        end-if

        *> Major
        if ws-profile-major not = spaces
            move "Major" to ws-label
            move ws-profile-major to ws-value
            perform display-labeled-line
        end-if

        *> Graduation Year
        if ws-profile-grad-year not = spaces and ws-profile-grad-year not = zeros
            move "Graduation Year" to ws-label
            move ws-profile-grad-year to ws-value
            perform display-labeled-line
        end-if

        *> About Me
        if ws-profile-about not = spaces
            move "About Me" to ws-label
            move ws-profile-about to ws-value
            perform display-labeled-line
        end-if

        *> spacer before lists
        move spaces to ws-message
        perform display-info

        *> -------- Experience(s) --------
        move "Experience(s):" to ws-message
        perform display-info
        perform varying ws-i from 1 by 1 until ws-i > 3
            if ws-exp-title(ws-i) not = spaces
                *> Job Title
                move "Job Title" to ws-label
                move ws-exp-title(ws-i) to ws-value
                perform display-labeled-line
                *> Company
                if ws-exp-company(ws-i) not = spaces
                    move "Company" to ws-label
                    move ws-exp-company(ws-i) to ws-value
                    perform display-labeled-line
                end-if
                *> Dates Worked
                if ws-exp-dates(ws-i) not = spaces
                    move "Dates Worked" to ws-label
                    move ws-exp-dates(ws-i) to ws-value
                    perform display-labeled-line
                end-if
                *> Description (optional)
                if ws-exp-desc(ws-i) not = spaces
                    move "Description" to ws-label
                    move ws-exp-desc(ws-i) to ws-value
                    perform display-labeled-line
                end-if

                *> blank line between entries
                move spaces to ws-message
                perform display-info
            end-if
        end-perform


        *> Education(s)
        move "Education(s):" to ws-message
        perform display-info
        perform varying ws-i from 1 by 1 until ws-i > 3
            if ws-edu-degree(ws-i) not = spaces
                *> Degree
                move "Degree" to ws-label
                move ws-edu-degree(ws-i) to ws-value
                perform display-labeled-line
                *> School
                move "School" to ws-label
                move ws-edu-school(ws-i) to ws-value
                perform display-labeled-line
                *> Years
                if ws-edu-years(ws-i) not = spaces
                    move "Years" to ws-label
                    move ws-edu-years(ws-i) to ws-value
                    perform display-labeled-line
                end-if
                *> blank line between entries
                move spaces to ws-message
                perform display-info
            end-if
        end-perform
       
       move spaces to ws-profile-header
        exit paragraph.

          check-profile-exists.
          move 'N' to ws-profile-found
          move 'N' to ws-profiles-eof


          open input profiles-file
          evaluate ws-profiles-status
             when "00"
                continue
             when "35"
                *> file doesn’t exist yet: treat as no profile, no error
                close profiles-file
                exit paragraph
             when other
                move "Profile file error" to ws-message
                perform display-error
                close profiles-file
                exit paragraph
          end-evaluate


          perform until profiles-file-ended
             
               read profiles-file next record
                   at end
                       set profiles-file-ended to true
                   not at end
                       if profile-username = ws-input-username
                           set profile-found to true
                          
                           *> moving required scalers
                           move profile-first-name to ws-profile-first-name
                           move profile-last-name  to ws-profile-last-name
                           move profile-school     to ws-profile-school
                           move profile-major      to ws-profile-major
                           move profile-grad-year  to ws-profile-grad-year




                           *> copy scalar
                           move profile-about to ws-profile-about


                           *> copy the 3 experience entries
                           perform varying ws-i from 1 by 1 until ws-i > 3
                               move exp-title   (ws-i) to ws-exp-title   (ws-i)
                               move exp-company (ws-i) to ws-exp-company (ws-i)
                               move exp-dates   (ws-i) to ws-exp-dates   (ws-i)
                               move exp-desc    (ws-i) to ws-exp-desc    (ws-i)
                           end-perform


                           *> copy the 3 education entries
                           perform varying ws-i from 1 by 1 until ws-i > 3
                               move edu-degree  (ws-i) to ws-edu-degree  (ws-i)
                               move edu-school  (ws-i) to ws-edu-school  (ws-i)
                               move edu-years   (ws-i) to ws-edu-years   (ws-i)
                           end-perform


                           set profiles-file-ended to true  *> stop early once found
                       end-if
               end-read
           end-perform
           close profiles-file.


          create-profile.
       *> optional: clear working fields so blanks don't keep stale data
       move spaces to ws-profile-about
       perform varying ws-i from 1 by 1 until ws-i > 3
           move spaces to ws-exp-title   (ws-i)
           move spaces to ws-exp-company (ws-i)
           move spaces to ws-exp-dates   (ws-i)
           move spaces to ws-exp-desc    (ws-i)
       end-perform
       perform varying ws-i from 1 by 1 until ws-i > 3
           move spaces to ws-edu-degree (ws-i)
           move spaces to ws-edu-school (ws-i)
           move spaces to ws-edu-years  (ws-i)
       end-perform


       perform collect-profile-input.


       *> write new profile record
       open extend profiles-file
       if ws-profiles-status = "35"
           open output profiles-file
           close profiles-file
           open extend profiles-file
       end-if
       if ws-profiles-status not = "00"
           move "profile open failed" to ws-message
           perform display-error
           exit paragraph
       end-if


       move ws-input-username to profile-username
       move ws-profile-first-name to profile-first-name
       move ws-profile-last-name  to profile-last-name
       move ws-profile-school     to profile-school
       move ws-profile-major      to profile-major
       move ws-profile-grad-year  to profile-grad-year


       move ws-profile-about  to profile-about


       perform varying ws-i from 1 by 1 until ws-i > 3
           move ws-exp-title   (ws-i) to exp-title   (ws-i)
           move ws-exp-company (ws-i) to exp-company (ws-i)
           move ws-exp-dates   (ws-i) to exp-dates   (ws-i)
           move ws-exp-desc    (ws-i) to exp-desc    (ws-i)
       end-perform


       perform varying ws-i from 1 by 1 until ws-i > 3
           move ws-edu-degree  (ws-i) to edu-degree  (ws-i)
           move ws-edu-school  (ws-i) to edu-school  (ws-i)
           move ws-edu-years   (ws-i) to edu-years   (ws-i)
       end-perform


       write profile-record
       close profiles-file


       move "Profile created successfully!" to ws-message
       perform display-success.




      edit-profile.
       *> prompt for changes
       perform collect-profile-input.


       *> now, atomically update the profiles file
       move 'N' to ws-profile-updated
       open input profiles-file
       open output temp-profiles-file


       move 'N' to ws-profiles-eof
       perform until profiles-file-ended
           read profiles-file next record
               at end
                   set profiles-file-ended to true
               not at end
                   if profile-username = ws-input-username
                       *> this is the user to update; write our new record
                       move ws-input-username to temp-profile-username
                       move ws-profile-first-name to temp-profile-first-name
                       move ws-profile-last-name  to temp-profile-last-name
                       move ws-profile-school     to temp-profile-school
                       move ws-profile-major      to temp-profile-major
                       move ws-profile-grad-year  to temp-profile-grad-year


                       move ws-profile-about  to temp-profile-about


                       perform varying ws-i from 1 by 1 until ws-i > 3
                           move ws-exp-title  (ws-i) to temp-exp-title  (ws-i)
                           move ws-exp-company(ws-i) to temp-exp-company(ws-i)
                           move ws-exp-dates  (ws-i) to temp-exp-dates  (ws-i)
                           move ws-exp-desc   (ws-i) to temp-exp-desc   (ws-i)
                       end-perform


                       perform varying ws-i from 1 by 1 until ws-i > 3
                           move ws-edu-degree (ws-i) to temp-edu-degree (ws-i)
                           move ws-edu-school (ws-i) to temp-edu-school (ws-i)
                           move ws-edu-years  (ws-i) to temp-edu-years  (ws-i)
                       end-perform


                       write temp-profile-record
                       move 'Y' to ws-profile-updated
                   else
                       *> copy other users' records verbatim
                       write temp-profile-record from profile-record
                   end-if
           end-read
       end-perform


       close profiles-file
       close temp-profiles-file


       *> now, delete original and rename temp file
       if ws-profile-updated = 'Y'
           move "InCollege-Profiles.txt" to ws-message
           call "CBL_DELETE_FILE" using ws-message
          
           move "InCollege-Profiles.tmp" to ws-message
           move "InCollege-Profiles.txt" to ws-user-choice
           call "CBL_RENAME_FILE" using ws-message, ws-user-choice


           move "Profile updated successfully!" to ws-message
           perform display-success
       else
           move "Could not find profile to update." to ws-message
           perform display-error
       end-if.


      handle-find-someone.
       move "Find someone you know" to ws-message
       perform display-title
       move spaces to ws-found-username
   
       *> FIRST NAME
       move "Enter FIRST name (or 0 to go back): " to ws-message
       perform display-prompt
       perform read-next-input
       if input-ended
           move "MAIN-MENU" to ws-program-state
           exit paragraph
       end-if
       move function trim(ws-last-input) to ws-search-first
       if ws-search-first = "0"
           move "MAIN-MENU" to ws-program-state
           exit paragraph
       end-if
   
       *> LAST NAME
       move "Enter LAST name: " to ws-message
       perform display-prompt
       perform read-next-input
       if input-ended
           move "MAIN-MENU" to ws-program-state
           exit paragraph
       end-if
       move function trim(ws-last-input) to ws-search-last
   
       if ws-search-first = spaces or ws-search-last = spaces
           move "Please enter both first and last name." to ws-message
           perform display-error
           move "MAIN-MENU" to ws-program-state
           exit paragraph
       end-if
   
       *> Scan profiles for exact (trimmed) match
       move 'N' to ws-name-match-found
       move 'N' to ws-profiles-eof
   
       open input profiles-file
       evaluate ws-profiles-status
           when "00"
               continue
           when "35"
               move "No profile exists for that name" to ws-message
               perform display-info
               close profiles-file
               move "MAIN-MENU" to ws-program-state
               exit paragraph
           when other
               move "Profile file error while searching." to ws-message
               perform display-error
               close profiles-file
               move "MAIN-MENU" to ws-program-state
               exit paragraph
       end-evaluate
   
       perform until profiles-file-ended
           read profiles-file next record
               at end
                   set profiles-file-ended to true
               not at end
                   if function upper-case(function trim(profile-first-name))
                       = function upper-case(function trim(ws-search-first))
                      and
                      function upper-case(function trim(profile-last-name))
                          = function upper-case(function trim(ws-search-last))
                set name-match-found to true

   
                       *> copy found profile into WS to reuse your display logic
                       move profile-first-name to ws-profile-first-name
                       move profile-last-name  to ws-profile-last-name
                       move profile-school     to ws-profile-school
                       move profile-major      to ws-profile-major
                       move profile-grad-year  to ws-profile-grad-year
                       move profile-about      to ws-profile-about
                       move profile-username to ws-found-username
   
                       perform varying ws-i from 1 by 1 until ws-i > 3
                           move exp-title   (ws-i) to ws-exp-title   (ws-i)
                           move exp-company (ws-i) to ws-exp-company (ws-i)
                           move exp-dates   (ws-i) to ws-exp-dates   (ws-i)
                           move exp-desc    (ws-i) to ws-exp-desc    (ws-i)
                       end-perform
   
                       perform varying ws-i from 1 by 1 until ws-i > 3
                           move edu-degree  (ws-i) to ws-edu-degree  (ws-i)
                           move edu-school  (ws-i) to ws-edu-school  (ws-i)
                           move edu-years   (ws-i) to ws-edu-years   (ws-i)
                       end-perform
   
                       set profiles-file-ended to true  *> stop after first hit
                   end-if
           end-read
       end-perform
       close profiles-file
   
        *> Render result
        if name-match-found
            move "User Profile" to ws-profile-header
            perform render-profile
            
            if name-match-found
            *> *> profile already copied into WS; also capture username for requests
            *> move profile-username to ws-found-username
        
            move "1. Send Connection Request" to ws-message
            perform display-option
            move "2. Back to Main Menu" to ws-message
            perform display-option
            move "Enter your choice: " to ws-message
            perform display-prompt
            perform read-user-choice
        
            if ws-user-choice = '1'
                perform send-connection-request
              end-if
            end-if
        
        else
            move "No user profile exists for the name you have entered." to ws-message
            perform display-info
        end-if

        move "MAIN-MENU" to ws-program-state.        


      collect-profile-input.
      *> ensure a clean slate if we are creating a new profile
       if not profile-found
           initialize ws-profile-data
       end-if
      *> first name (required)
       if profile-found
           move "First name (press enter to keep current): " to ws-message
           perform display-prompt
           perform read-next-input
           if not input-ended and function trim(ws-last-input) not = spaces
               move function trim(ws-last-input) to ws-profile-first-name
           end-if
       else
           perform until ws-profile-first-name not = spaces
               move "First name: " to ws-message
               perform display-prompt
               perform read-next-input
               if input-ended exit paragraph end-if
               move function trim(ws-last-input) to ws-profile-first-name
               if ws-profile-first-name = spaces
                   move "First name is required." to ws-message
                   perform display-error
               end-if
           end-perform
       end-if


       *> last name (required)
       if profile-found
           move "Last name (press enter to keep current): " to ws-message
           perform display-prompt
           perform read-next-input
           if not input-ended and function trim(ws-last-input) not = spaces
               move function trim(ws-last-input) to ws-profile-last-name
           end-if
       else
           perform until ws-profile-last-name not = spaces
               move "Last name: " to ws-message
               perform display-prompt
               perform read-next-input
               if input-ended exit paragraph end-if
               move function trim(ws-last-input) to ws-profile-last-name
               if ws-profile-last-name = spaces
                   move "Last name is required." to ws-message
                   perform display-error
               end-if
           end-perform
       end-if

       *> university/college attended (required)
       if profile-found
           move "University/college (press enter to keep current): " to ws-message
           perform display-prompt
           perform read-next-input
           if not input-ended and function trim(ws-last-input) not = spaces
               move function trim(ws-last-input) to ws-profile-school
           end-if
       else
           perform until ws-profile-school not = spaces
               move "University/college attended: " to ws-message
               perform display-prompt
               perform read-next-input
               if input-ended exit paragraph end-if
               move function trim(ws-last-input) to ws-profile-school
               if ws-profile-school = spaces
                   move "University/college is required." to ws-message
                   perform display-error
               end-if
           end-perform
       end-if

       *> major (required)
       if profile-found
           move "Major (press enter to keep current): " to ws-message
           perform display-prompt
           perform read-next-input
           if not input-ended and function trim(ws-last-input) not = spaces
               move function trim(ws-last-input) to ws-profile-major
           end-if
       else
           perform until ws-profile-major not = spaces
               move "Major: " to ws-message
               perform display-prompt
               perform read-next-input
               if input-ended exit paragraph end-if
               move function trim(ws-last-input) to ws-profile-major
               if ws-profile-major = spaces
                   move "Major is required." to ws-message
                   perform display-error
               end-if
           end-perform
       end-if
  
       *> graduation year (required, 4 digits)
       move 'N' to ws-year-valid-flag
       perform until year-valid
           if profile-found
               move "Graduation year (yyyy, press enter to keep current): " to ws-message
           else
               move "Graduation year (yyyy): " to ws-message
           end-if
           perform display-prompt
           perform read-next-input
           if input-ended
               exit paragraph
           end-if


           *> length of the TRIMMED expression (not the 80-char buffer!)
           compute ws-year-len = function length(function trim(ws-last-input))


           *> edit mode: Enter keeps current
           if profile-found and ws-year-len = 0
               set year-valid to true
           else
               if ws-year-len = 4
                   *> put exactly 4 chars into a 4-char scratch
                   move function trim(ws-last-input) to ws-grad-year-text


                   *> verify all 4 are digits (operate on first 4 only)
                   move spaces to ws-temp-message
                   move ws-grad-year-text to ws-temp-message(1:4)
                   inspect ws-temp-message(1:4)
                       converting '0123456789' to '0000000000'


                   if ws-temp-message(1:4) = "0000"
                       move ws-grad-year-text to ws-year-num
                       if ws-year-num >= 1900 and ws-year-num <= 2100
                           move ws-year-num to ws-profile-grad-year
                           set year-valid to true
                       else
                           move "Please enter a 4-digit year between 1900 and 2100." to ws-message
                           perform display-error
                       end-if
                   else
                       move "Please use digits only (yyyy)." to ws-message
                       perform display-error
                   end-if
               else
                   move "Please enter a valid 4-digit year (yyyy)." to ws-message
                   perform display-error
               end-if
           end-if
       end-perform


*>    About me
       move "About me (max 200 chars, Enter to keep/skip): " to ws-message
       perform display-prompt
       perform read-next-input
       if not input-ended
           compute ws-input-len = function length(function trim(ws-last-input))
           if ws-input-len > 0
               if ws-input-len > MAX-ABOUT
                   move "About text too long; trimming to 200 chars." to ws-message
                   perform display-info
                   move spaces to ws-profile-about
                   move ws-last-input(1:MAX-ABOUT) to ws-profile-about
               else
                   move spaces to ws-profile-about
                   move ws-last-input(1:ws-input-len) to ws-profile-about
               end-if
           end-if
       end-if

*>     Experiences
       *> ----- EXPERIENCE (Title adds a NEW row => Company and Dates REQUIRED) -----
        perform varying ws-i from 1 by 1 until ws-i > 3

            *> Remember whether this slot had a Title BEFORE any change
            move ws-exp-title(ws-i) to ws-prev-title

            string "Experience " ws-i " Title (or Enter to keep/skip): "
              delimited by size into ws-message
            perform display-prompt
            perform read-next-input
            if input-ended
                exit perform
            end-if

            move function trim(ws-last-input) to ws-temp-message
            compute ws-input-len = function length(function trim(ws-temp-message))


            *> If user typed a new Title, set it
            if ws-input-len > 0
                if ws-input-len > MAX-EXP-TITLE
                    move "Title too long; trimming to 30 chars." to ws-message
                    perform display-info
                    move spaces to ws-exp-title(ws-i)
                    move ws-temp-message(1:MAX-EXP-TITLE) to ws-exp-title(ws-i)
                else
                    move spaces to ws-exp-title(ws-i)
                    move ws-temp-message(1:ws-input-len) to ws-exp-title(ws-i)
                end-if
            end-if

            *> If the slot now has a Title:
            if ws-exp-title(ws-i) not = spaces

                if ws-prev-title = spaces
                    *> ------- NEW ROW: REQUIRE COMPANY -------
                    perform until ws-exp-company(ws-i) not = spaces
                        move "Company (required): " to ws-message
                        perform display-prompt
                        perform read-next-input
                        if input-ended
                            exit perform
                        end-if
                        move function trim(ws-last-input) to ws-temp-message
                        compute ws-input-len = function length(function trim(ws-temp-message))
                        if ws-input-len = 0
                            move "Company is required when adding an experience." to ws-message
                            perform display-error
                        else
                            if ws-input-len > MAX-EXP-COMP
                                move "Company too long; trimming to 40 chars." to ws-message
                                perform display-info
                                move spaces to ws-exp-company(ws-i)
                                move ws-temp-message(1:MAX-EXP-COMP) to ws-exp-company(ws-i)
                            else
                                move spaces to ws-exp-company(ws-i)
                                move ws-temp-message(1:ws-input-len) to ws-exp-company(ws-i)
                            end-if
                        end-if
                    end-perform

                    *> ------- NEW ROW: REQUIRE DATES -------
                    perform until ws-exp-dates(ws-i) not = spaces
                        move "Dates (e.g., 2020-2024) (required): " to ws-message
                        perform display-prompt
                        perform read-next-input
                        if input-ended
                            exit perform
                        end-if
                        move function trim(ws-last-input) to ws-temp-message
                        compute ws-input-len = function length(function trim(ws-temp-message))
                        if ws-input-len = 0
                            move "Dates are required when adding an experience." to ws-message
                            perform display-error
                        else
                            if ws-input-len > MAX-EXP-DATES
                                move "Dates too long; trimming to 30 chars." to ws-message
                                perform display-info
                                move spaces to ws-exp-dates(ws-i)
                                move ws-temp-message(1:MAX-EXP-DATES) to ws-exp-dates(ws-i)
                            else
                                move spaces to ws-exp-dates(ws-i)
                                move ws-temp-message(1:ws-input-len) to ws-exp-dates(ws-i)
                            end-if
                        end-if
                    end-perform

                else
                    *> ------- EXISTING ROW: KEEP/SKIP ALLOWED -------
                    move "Company (Enter to keep/skip): " to ws-message
                    perform display-prompt
                    perform read-next-input
                    if input-ended
                        exit perform
                    end-if
                    move function trim(ws-last-input) to ws-temp-message
                    compute ws-input-len = function length(function trim(ws-temp-message))
                    if ws-input-len > 0
                        if ws-input-len > MAX-EXP-COMP
                            move "Company too long; trimming to 40 chars." to ws-message
                            perform display-info
                            move spaces to ws-exp-company(ws-i)
                            move ws-temp-message(1:MAX-EXP-COMP) to ws-exp-company(ws-i)
                        else
                            move spaces to ws-exp-company(ws-i)
                            move ws-temp-message(1:ws-input-len) to ws-exp-company(ws-i)
                        end-if
                    end-if

                    move "Dates (e.g., 2020-2024) (Enter to keep/skip): " to ws-message
                    perform display-prompt
                    perform read-next-input
                    if input-ended
                        exit perform
                    end-if
                    move function trim(ws-last-input) to ws-temp-message
                    compute ws-input-len = function length(function trim(ws-temp-message))
                    if ws-input-len > 0
                        if ws-input-len > MAX-EXP-DATES
                            move "Dates too long; trimming to 30 chars." to ws-message
                            perform display-info
                            move spaces to ws-exp-dates(ws-i)
                            move ws-temp-message(1:MAX-EXP-DATES) to ws-exp-dates(ws-i)
                        else
                            move spaces to ws-exp-dates(ws-i)
                            move ws-temp-message(1:ws-input-len) to ws-exp-dates(ws-i)
                        end-if
                    end-if
                end-if

                *> Description optional in both cases
                move "Description (Enter to keep/skip): " to ws-message
                perform display-prompt
                perform read-next-input
                if not input-ended
                    move function trim(ws-last-input) to ws-temp-message
                    compute ws-input-len = function length(function trim(ws-temp-message))
                    if ws-input-len > 0
                        if ws-input-len > MAX-EXP-DESC
                            move "Description too long; trimming to 120 chars." to ws-message
                            perform display-info
                            move spaces to ws-exp-desc(ws-i)
                            move ws-temp-message(1:MAX-EXP-DESC) to ws-exp-desc(ws-i)
                        else
                            move spaces to ws-exp-desc(ws-i)
                            move ws-temp-message(1:ws-input-len) to ws-exp-desc(ws-i)
                        end-if
                    end-if
                end-if

            end-if

        end-perform

*>    Educations
       *>    Educations (degree adds a NEW row => School and Years are REQUIRED)
       perform varying ws-i from 1 by 1 until ws-i > 3

           *> Ask for Degree (this is the “switch” that decides if a row exists)
           string "Education " ws-i " Degree (or Enter to keep/skip): " delimited by size
               into ws-message
           perform display-prompt
           perform read-next-input
           if input-ended
               exit perform
           end-if

           *> Remember whether this slot was empty BEFORE any change
           move ws-edu-degree(ws-i) to ws-prev-degree

           move function trim(ws-last-input) to ws-temp-message

           *> If the user typed a new Degree, set it
           if ws-temp-message not = spaces
               move ws-temp-message to ws-edu-degree(ws-i)
           end-if

           *> If the slot now has a Degree, we either:
           *>   - REQUIRE School/Years (if this was a NEW row), or
           *>   - allow keep/skip (if editing an existing row)
           if ws-edu-degree(ws-i) not = spaces

               if ws-prev-degree = spaces
                   *> ------- NEW ROW: REQUIRE SCHOOL -------
                   perform until ws-edu-school(ws-i) not = spaces
                       move "School (required): " to ws-message
                       perform display-prompt
                       perform read-next-input
                       if input-ended
                           exit perform
                       end-if
                       move function trim(ws-last-input) to ws-temp-message
                       if ws-temp-message = spaces
                           move "School is required when adding an education." to ws-message
                           perform display-error
                       else
                           move ws-temp-message to ws-edu-school(ws-i)
                       end-if
                   end-perform

                   *> ------- NEW ROW: REQUIRE YEARS -------
                   perform until ws-edu-years(ws-i) not = spaces
                       move "Years (e.g., 2016-2020) (required): " to ws-message
                       perform display-prompt
                       perform read-next-input
                       if input-ended
                           exit perform
                       end-if
                       move function trim(ws-last-input) to ws-temp-message
                       if ws-temp-message = spaces
                           move "Years are required when adding an education." to ws-message
                           perform display-error
                       else
                           move ws-temp-message to ws-edu-years(ws-i)
                       end-if
                   end-perform

               else
                   *> ------- EXISTING ROW: KEEP/SKIP ALLOWED -------
                   move "School (Enter to keep/skip): " to ws-message
                   perform display-prompt
                   perform read-next-input
                   if input-ended
                       exit perform
                   end-if
                   move function trim(ws-last-input) to ws-temp-message
                   if ws-temp-message not = spaces
                       move ws-temp-message to ws-edu-school(ws-i)
                   end-if

                   move "Years (e.g., 2016-2020) (Enter to keep/skip): " to ws-message
                   perform display-prompt
                   perform read-next-input
                   if input-ended
                       exit perform
                   end-if
                   move function trim(ws-last-input) to ws-temp-message
                   if ws-temp-message not = spaces
                       move ws-temp-message to ws-edu-years(ws-i)
                   end-if
               end-if

           end-if
       end-perform.

*>    ===================== Job Search/Posting Procedures =====================
      handle-job-search-menu.
          perform display-job-search-menu
          perform read-user-choice
          if ws-user-choice = '1'
              perform post-job
*>     No longer under construction - A (week 7)
          else if ws-user-choice = '2'
              perform browse-jobs
              move "JOB-SEARCH-MENU" to ws-program-state
          else if ws-user-choice = '3'
              perform view-my-applications
              move "JOB-SEARCH-MENU" to ws-program-state
          else if ws-user-choice = '4'
              move "MAIN-MENU" to ws-program-state
          else
              move "Invalid option. Please try again" to ws-message
              perform display-error
              move "JOB-SEARCH-MENU" to ws-program-state
          end-if.

      display-job-search-menu.
          move "Job Search/Internship" to ws-message
          perform display-title
          move "1. Post a Job/Internship" to ws-message
          perform display-option
          move "2. Browse Jobs/Internships" to ws-message
          perform display-option
          move "3. View My Applications" to ws-message
          perform display-option
          display ws-line-separator
          perform write-separator
          move "4. Go Back to Main Menu" to ws-message
          perform display-special-option
          display ws-line-separator
          perform write-separator
          move "Enter your choice: " to ws-message
          perform display-prompt.

      post-job.
          initialize ws-job-data
          
          move "Post a New Job" to ws-message
          perform display-title
          
          *> Job Title (required)
          perform until ws-job-title not = spaces
              move "Job Title: " to ws-message
              perform display-prompt
              perform read-next-input
              if input-ended 
                  move "JOB-SEARCH-MENU" to ws-program-state
                  exit paragraph
              end-if
              if function length(function trim(ws-last-input)) > 50
                  move "WARNING: Job title is too long! Truncating to 50 characters." to ws-message
                  perform display-info
                  move ws-last-input(1:50) to ws-job-title
              else
                  move function trim(ws-last-input) to ws-job-title
              end-if
              if ws-job-title = spaces
                  move "Job title is required." to ws-message
                  perform display-error
              end-if
          end-perform
          
          *> Job Description (required)
          perform until ws-job-description not = spaces
              move "Job Description (max 500 chars): " to ws-message
              perform display-prompt
              perform read-next-input
              if input-ended 
                  move "JOB-SEARCH-MENU" to ws-program-state
                  exit paragraph
              end-if
              if function length(function trim(ws-last-input)) > MAX-JOB-DESC
                  move "WARNING: Job description is too long! Truncating to 500 characters." to ws-message
                  perform display-info
                  move ws-last-input(1:MAX-JOB-DESC) to ws-job-description
              else
                  move function trim(ws-last-input) to ws-job-description
              end-if
              if ws-job-description = spaces
                  move "Job description is required." to ws-message
                  perform display-error
              end-if
          end-perform
          
          *> Employer (required)
          perform until ws-job-employer not = spaces
              move "Employer: " to ws-message
              perform display-prompt
              perform read-next-input
              if input-ended 
                  move "JOB-SEARCH-MENU" to ws-program-state
                  exit paragraph
              end-if
              if function length(function trim(ws-last-input)) > 50
                  move "WARNING: Employer name is too long! Truncating to 50 characters." to ws-message
                  perform display-info
                  move ws-last-input(1:50) to ws-job-employer
              else
                  move function trim(ws-last-input) to ws-job-employer
              end-if
              if ws-job-employer = spaces
                  move "Employer is required." to ws-message
                  perform display-error
              end-if
          end-perform
          
          *> Location (required)
          perform until ws-job-location not = spaces
              move "Location: " to ws-message
              perform display-prompt
              perform read-next-input
              if input-ended 
                  move "JOB-SEARCH-MENU" to ws-program-state
                  exit paragraph
              end-if
              if function length(function trim(ws-last-input)) > 50
                  move "WARNING: Location is too long! Truncating to 50 characters." to ws-message
                  perform display-info
                  move ws-last-input(1:50) to ws-job-location
              else
                  move function trim(ws-last-input) to ws-job-location
              end-if
              if ws-job-location = spaces
                  move "Location is required." to ws-message
                  perform display-error
              end-if
          end-perform
          
          *> Salary (optional)
          move "Salary (optional, press Enter to skip): " to ws-message
          perform display-prompt
          perform read-next-input
          if not input-ended
              if function length(function trim(ws-last-input)) > 20
                  move "WARNING: Salary is too long! Truncating to 20 characters." to ws-message
                  perform display-info
                  move ws-last-input(1:20) to ws-job-salary
              else
                  move function trim(ws-last-input) to ws-job-salary
              end-if
          end-if
          
          *> Save the job to file
          perform save-job
          
          move "Job posted successfully!" to ws-message
          perform display-success
          move "MAIN-MENU" to ws-program-state.

      save-job.
          open extend jobs-file
          
          if ws-jobs-status = "35"
              *> File doesn't exist, create it
              close jobs-file
              open output jobs-file
              close jobs-file
              open extend jobs-file
          end-if
          
          if ws-jobs-status not = "00"
              move "Error opening jobs file. Status: " to ws-message
              string ws-message ws-jobs-status into ws-message
              perform display-error
          else
              move ws-job-title to job-title
              move ws-job-description to job-description
              move ws-job-employer to job-employer
              move ws-job-location to job-location
              move ws-job-salary to job-salary
              move ws-current-username to job-poster
              write job-record
              close jobs-file
          end-if.

      *> =========================================================
      *>  Browse Jobs / Internships
      *>  - Lists jobs with numbering (Title, Employer, Location)
      *>  - Lets user pick a number to view full details
      *> =========================================================
      browse-jobs.
          move 0 to ws-list-count
          move 0 to ws-total-jobs
          move "Browse Jobs/Internships" to ws-message
          perform display-title

          open input jobs-file

          if ws-jobs-status = "35"
             *> jobs file does not exist yet
             move "No jobs posted yet." to ws-message
             perform display-info
             close jobs-file
             exit paragraph
          end-if

          if ws-jobs-status not = "00"
             move "Error opening jobs file. Status: " to ws-message
             string ws-message ws-jobs-status into ws-message
             perform display-error
             close jobs-file
             exit paragraph
          end-if

          move 'N' to ws-jobs-eof
          perform until jobs-file-ended
              read jobs-file
                at end
                  move 'Y' to ws-jobs-eof
                not at end
                  add 1 to ws-list-count
                  move ws-list-count to ws-total-jobs
                  *> Show short line: "n) Title  |  Employer  |  Location"
                  move spaces to ws-message
                move ws-list-count to ws-num-2               *> numeric 2-digit (leading zeros)
                move ws-num-2      to ws-num-txt             *> now '01', '02', ... '10'


                string
                      function trim(ws-num-txt)              ") "       delimited by size
                      function trim(job-title)               "  |  "    delimited by size
                      function trim(job-employer)            "  |  "    delimited by size
                      function trim(job-location)
                  into ws-message
                end-string

                perform display-option

              end-read
          end-perform
          close jobs-file

          if ws-total-jobs = 0
              move "No jobs posted yet." to ws-message
              perform display-info
              exit paragraph
          end-if

          display ws-line-separator
          perform write-separator
          move "Enter a job number to view, or 0 to go back: " to ws-message
          perform display-prompt
          perform read-next-input
          if input-ended
              exit paragraph
          end-if

          *> Convert input to number (invalid -> loop back)
          move function numval(ws-last-input) to ws-selected-index
          if ws-selected-index = 0
              exit paragraph
          end-if
          if ws-selected-index < 1 or ws-selected-index > ws-total-jobs
              move "Invalid selection. Please try again." to ws-message
              perform display-error
              perform browse-jobs
              exit paragraph
          end-if

          perform show-job-details.

      *> =========================================================
      *>  Show Job Details for ws-selected-index
      *>  - Displays full details
      *>  - Offers: 1) Apply,  2) Back to list
      *> =========================================================
      show-job-details.
          open input jobs-file
          if ws-jobs-status not = "00"
             move "Error opening jobs file. Status: " to ws-message
             string ws-message ws-jobs-status into ws-message
             perform display-error
             close jobs-file
             exit paragraph
          end-if

          move 0 to ws-list-count
          move 'N' to ws-jobs-eof
          perform until jobs-file-ended
              read jobs-file
                at end
                  move 'Y' to ws-jobs-eof
                not at end
                  add 1 to ws-list-count
                  if ws-list-count = ws-selected-index
                      *> Cache selected job into ws-selected-job
                      move job-title       to sj-title
                      move job-description to sj-description
                      move job-employer    to sj-employer
                      move job-location    to sj-location
                      move job-salary      to sj-salary
                      exit perform
                  end-if
              end-read
          end-perform
          close jobs-file

          if sj-title = spaces
              move "That job could not be found." to ws-message
              perform display-error
              exit paragraph
          end-if

          display ws-line-separator
          perform write-separator
          move "Job Details" to ws-message
          perform display-title

          move spaces to ws-message
          string "Title: "     function trim(sj-title)     into ws-message
          perform display-info
          move spaces to ws-message
          string "Employer: "  function trim(sj-employer)  into ws-message
          perform display-info
          move spaces to ws-message
          string "Location: "  function trim(sj-location)  into ws-message
          perform display-info

          if function trim(sj-salary) not = spaces
             move spaces to ws-message
             string "Salary: "   function trim(sj-salary)  into ws-message
             perform display-info
          end-if

          move spaces to ws-message
          string "Description: " into ws-message
          perform display-info

          *> old single-line print removed, now wrap across lines
          perform print-long-description


          display ws-line-separator
          perform write-separator
          move "1. Apply for this Job" to ws-message
          perform display-option
          move "2. Back to Job List"   to ws-message
          perform display-special-option
          display ws-line-separator
          perform write-separator
          move "Enter your choice: " to ws-message
          perform display-prompt
          perform read-user-choice

          if ws-user-choice = '1'
              perform apply-for-job
              *> after applying, go back to list
              perform browse-jobs
          else if ws-user-choice = '2'
              perform browse-jobs
          else
              move "Invalid option. Please try again." to ws-message
              perform display-error
              perform show-job-details
          end-if.

    *> =========================================================
    *>  Apply to currently selected job (uses sj-* + ws-current-username)
    *>  Persists to InCollege-Applications.txt
    *> =========================================================
    apply-for-job.
        *> First try to append. If the file doesn't exist (status 35), create it, then append.
        open extend applications-file

        if ws-app-status = "35"
            *> File missing -> create then append
            open output applications-file
            if ws-app-status not = "00"
                move "Error creating applications file. Status: " to ws-message
                string ws-message ws-app-status into ws-message
                perform display-error
                exit paragraph
            end-if
            close applications-file
            open extend applications-file
        end-if

        if ws-app-status not = "00"
            move "Error opening applications file. Status: " to ws-message
            string ws-message ws-app-status into ws-message
            perform display-error
            exit paragraph
        end-if

        *> Populate record fields
        move ws-current-username to app-username
        move sj-title            to app-job-title
        move sj-employer         to app-job-employer
        move sj-location         to app-job-location
        move sj-salary           to app-job-salary

        *> Write the record
        write application-record

        if ws-app-status not = "00"
            move "Error writing application record. Status: " to ws-message
            string ws-message ws-app-status into ws-message
            perform display-error
            close applications-file
            exit paragraph
        end-if

        close applications-file

        *> Confirmation to user
        move spaces to ws-message
        string
          "Your application for "
          function trim(sj-title)
          " at "
          function trim(sj-employer)
          " has been submitted."
          into ws-message
        perform display-success.


      *> =========================================================
      *>  Print sj-description wrapped across lines (no word split)
      *> =========================================================
      print-long-description.
          move function length(function trim(sj-description)) to ws-desc-len
          if ws-desc-len = 0
              move "(No description provided.)" to ws-message
              perform display-info
              exit paragraph
          end-if

          move 1 to ws-desc-idx
          perform until ws-desc-idx > ws-desc-len
              compute ws-remaining = ws-desc-len - ws-desc-idx + 1
              if ws-remaining <= ws-wrap-cols
                  move ws-remaining to ws-chunk-len
              else
                  move ws-wrap-cols to ws-chunk-len
                  *> try not to cut a word: search backward for a space
            compute ws-j = ws-desc-idx + ws-chunk-len - 1
            perform varying ws-j from ws-j by -1
                    until ws-j < ws-desc-idx or sj-description(ws-j:1) = " "
                continue
            end-perform

            if ws-j >= ws-desc-idx and sj-description(ws-j:1) = " "
                compute ws-chunk-len = ws-j - ws-desc-idx + 1
            end-if

              end-if

              move spaces to ws-message
              move sj-description(ws-desc-idx:ws-chunk-len) to ws-message
              perform display-info

              add ws-chunk-len to ws-desc-idx

              *> skip any extra spaces at the new start
              perform until ws-desc-idx > ws-desc-len
                         or sj-description(ws-desc-idx:1) not = " "
                  add 1 to ws-desc-idx
              end-perform
          end-perform.

      *> =========================================================
      *>  View My Applications - Display report of all applications
      *>  submitted by the current user
      *> =========================================================
      view-my-applications.
          move 0 to ws-list-count
          
          move "Your Job Applications" to ws-message
          perform display-title

          open input applications-file

          if ws-app-status = "35"
              *> Applications file does not exist yet
              move "You have not applied to any jobs yet." to ws-message
              perform display-info
              close applications-file
              exit paragraph
          end-if

          if ws-app-status not = "00"
              move "Error opening applications file. Status: " to ws-message
              string ws-message ws-app-status into ws-message
              perform display-error
              close applications-file
              exit paragraph
          end-if

          *> Read through all applications and display those for current user
          move 'N' to ws-app-eof
          perform until applications-file-ended
              read applications-file
                at end
                  move 'Y' to ws-app-eof
                not at end
                  *> Check if this application belongs to current user
                  if function upper-case(function trim(app-username))
                     = function upper-case(function trim(ws-current-username))
                      add 1 to ws-list-count
                      
                      *> Display application details
                      move spaces to ws-message
                      string
                        "Application #"
                        ws-list-count
                        into ws-message
                      perform display-info
                      
                      move spaces to ws-message
                      string
                        "  Job Title: "
                        function trim(app-job-title)
                        into ws-message
                      perform display-line
                      
                      move spaces to ws-message
                      string
                        "  Employer: "
                        function trim(app-job-employer)
                        into ws-message
                      perform display-line
                      
                      move spaces to ws-message
                      string
                        "  Location: "
                        function trim(app-job-location)
                        into ws-message
                      perform display-line
                      
                      if function trim(app-job-salary) not = spaces
                          move spaces to ws-message
                          string
                            "  Salary: "
                            function trim(app-job-salary)
                            into ws-message
                          perform display-line
                      end-if
                      
                      *> Blank line between applications
                      move spaces to ws-message
                      perform display-info
                  end-if
              end-read
          end-perform

          close applications-file

          *> Display summary
          display ws-line-separator
          perform write-separator
          
          if ws-list-count = 0
              move "You have not applied to any jobs yet." to ws-message
              perform display-info
          else
              move spaces to ws-message
              string
                "Total Applications: "
                ws-list-count
                into ws-message
              perform display-info
          end-if.


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


     