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


       data division.
       file section.
*>    Define the record structure for each of the three files
       fd input-file.
       01  input-record      pic x(256).
       fd  output-file.
       01  output-record     pic x(80).
       fd  accounts-file.
       01  account-record.
*>    Each account record consists of a username and password
           05  username        pic x(20).
           05  password        pic x(12).
*>    A - profile file structure added here 
       fd  profiles-file.
        01  profile-record.
            05  profile-username     pic x(20).
            05  profile-about        pic x(200).  *> optional "about me"
            05  profile-exp occurs 3.
                10  exp-title        pic x(30).
                10  exp-company      pic x(40).
                10  exp-dates        pic x(30).
                10  exp-desc         pic x(120).
            05  profile-edu occurs 3.
                10  edu-degree       pic x(30).
                10  edu-school       pic x(40).
                10  edu-years        pic x(20).

*>    A - temp files for profile editing
       fd  temp-profiles-file.
        01  temp-profile-record.
            05  temp-profile-username     pic x(20).
            05  temp-profile-about        pic x(200).
            05  temp-profile-exp occurs 3.
                10  temp-exp-title        pic x(30).
                10  temp-exp-company      pic x(40).
                10  temp-exp-dates        pic x(30).
                10  temp-exp-desc         pic x(120).
            05  temp-profile-edu occurs 3.
                10  temp-edu-degree       pic x(30).
                10  temp-edu-school       pic x(40).
                10  temp-edu-years        pic x(20).


       working-storage section.
*>    Ensure all variables here start with "ws" to indicate they are in working-storage section.
*>    For example, ws-username, ws-password, etc

*>    - FILE STATUS AND EOF FLAGS - 
       01  ws-userdata-status  pic x(2).
       01  ws-input-eof        pic a(1) value 'N'.
       88  input-ended         value 'Y'.

       01  ws-last-input     pic x(256) value spaces.

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
*>    A - storage section for profile file creation
       01  ws-profiles-status        pic x(2).
       01  ws-profiles-eof           pic a(1) value 'N'.
           88 profiles-file-ended    value 'Y'.
       01  ws-profile-found          pic a(1) value 'N'.
           88 profile-found          value 'Y'.
       01  ws-profile-data.
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

*>    - TEMPORARY INPUT FOR LOGIN/REGISTRATION -
       01  ws-input-username   pic x(99).
       01  ws-input-password   pic x(99).

*>    - Variable to hold message for display + write -
       01  ws-message          pic x(80).
       01  ws-temp-message     pic x(80).
       01  ws-blank-line       pic x(80) value spaces.
       01  ws-line-separator   pic x(80) value all "-".

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
                   if not account-found and not input-ended
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
                else if ws-user-choice = '6'
                     move "Successfully Logged Out!" to ws-message
                     perform display-success                      
                     move "INITIAL-MENU" to ws-program-state
                else if ws-user-choice = '7'
                     perform cleanup-files
                     stop run  
                else    
                     move "Invalid option. Please try again" to ws-message
                     perform display-error
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
           move "1. Search for a job" to ws-message 
           perform display-option
           move "2. Find someone you know" to ws-message
           perform display-option
           move "3. Learn a new skill" to ws-message 
           perform display-option
           display ws-line-separator
           perform write-separator
           move "4. Create/Edit My Profile" to ws-message 
           perform display-special-option
           move "5. View My Profile" to ws-message 
           perform display-special-option
           move "6. Log Out" to ws-message
           perform display-special-option
           move "7. Exit program" to ws-message
           perform display-special-option
           display ws-line-separator
           perform write-separator
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
           move "MAIN-MENU" to ws-program-state.
      
       read-next-input.
        read input-file
            at end
                set input-ended to true
            not at end
                move function trim(input-record) to ws-last-input
        end-read.


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
           if ws-input-username = spaces
               move "Username cannot be empty. Returning to menu." to ws-message
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
           if profile-found
               move "Your Profile" to ws-message
               perform display-title
               
               if ws-profile-about not = spaces
                   move "About Me:" to ws-message
                   perform display-info
                   move ws-profile-about to ws-message
                   perform display-info
               end-if
               
               move "Experience:" to ws-message
               perform display-info
               perform varying ws-i from 1 by 1 until ws-i > 3
                   if ws-exp-title(ws-i) not = spaces
                       move ws-exp-title(ws-i) to ws-message
                       perform display-option
                       move ws-exp-company(ws-i) to ws-message
                       perform display-option
                       move ws-exp-dates(ws-i) to ws-message
                       perform display-option
                       move ws-exp-desc(ws-i) to ws-message
                       perform display-option
                       move " " to ws-message
                       perform display-info
                   end-if
               end-perform
               
               move "Education:" to ws-message
               perform display-info
               perform varying ws-i from 1 by 1 until ws-i > 3
                   if ws-edu-degree(ws-i) not = spaces
                       move ws-edu-degree(ws-i) to ws-message
                       perform display-option
                       move ws-edu-school(ws-i) to ws-message
                       perform display-option
                       move ws-edu-years(ws-i) to ws-message
                       perform display-option
                       move " " to ws-message
                       perform display-info
                   end-if
               end-perform
           else
               move "No profile found. Please create a profile first." to ws-message
               perform display-error
           end-if.

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


       collect-profile-input.
        move "About me (optional, press Enter to skip): " to ws-message
        perform display-prompt
        perform read-next-input
        if not input-ended
            move ws-last-input to ws-profile-about
        end-if

        perform varying ws-i from 1 by 1 until ws-i > 3
            move "Experience " to ws-message
            string "Experience " ws-i " Title (or Enter to skip): " delimited by size
                into ws-message
            perform display-prompt
            perform read-next-input
            if input-ended
                exit perform
            end-if
            move ws-last-input to ws-exp-title(ws-i)
            if ws-exp-title(ws-i) = spaces
                exit perform
            end-if

            move "Company: " to ws-message
            perform display-prompt
            perform read-next-input
            if input-ended exit perform end-if
            move ws-last-input to ws-exp-company(ws-i)

            move "Dates (e.g., 2020-2024): " to ws-message
            perform display-prompt
            perform read-next-input
            if input-ended exit perform end-if
            move ws-last-input to ws-exp-dates(ws-i)

            move "Description: " to ws-message
            perform display-prompt
            perform read-next-input
            if input-ended exit perform end-if
            move ws-last-input to ws-exp-desc(ws-i)
        end-perform

        perform varying ws-i from 1 by 1 until ws-i > 3
            move "Education " to ws-message
            string "Education " ws-i " Degree (or Enter to skip): " delimited by size
                into ws-message
            perform display-prompt
            perform read-next-input
            if input-ended
                exit perform
            end-if
            move ws-last-input to ws-edu-degree(ws-i)
            if ws-edu-degree(ws-i) = spaces
                exit perform
            end-if

            move "School: " to ws-message
            perform display-prompt
            perform read-next-input
            if input-ended exit perform end-if
            move ws-last-input to ws-edu-school(ws-i)

            move "Years (e.g., 2016-2020): " to ws-message
            perform display-prompt
            perform read-next-input
            if input-ended exit perform end-if
            move ws-last-input to ws-edu-years(ws-i)
        end-perform.



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

       
