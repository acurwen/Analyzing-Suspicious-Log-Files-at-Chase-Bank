# Analyzing Chase Bank login records

This was a fun script to keep re-writing and testing. I also learned some new Bash commands and flags along the way.

## Task

1. Run the auth_log_creation.sh [script](https://github.com/kura-labs-org/install-sh/blob/main/auth_log_creation.sh) to create auth_log.log. 
2. Write a Bash script to analyze auth_log.log by reading through each line of the log file, searching for each keyword that indicates a potentially suspicious login attempt, and writing the line to a new file called suspicious_activity.log that will store all matching entries.
3. Automate the script to run daily.

## Steps taken

- Read through auth_log_creation.sh script to understand what it was doing
- Ran auth_log_creation.sh script and reviewed output of auth_log.log for keywords
- Wrote down pseudo code in new script called suspicious.sh
- Edited, ran and tested suspicious.sh script
- Set cron log to have script run daily

## Reviewing auth_log_creation.sh

What does the auth_log_creation.sh script do?

1. Defines the log_file variable which is the source of the normal and suspicious logs
    1. Clears this file of its contents if it already exists
2. Defines 2 arrays for either normal log messages or suspicious log messages 
3. Adds a mix of the normal and suspicious log messages to auth_log.log
    1. Also adds in additional normal log messages to auth_log.log for more balanced results
4. Prints a message that the log file has been created at "/var/log/auth_log.log”

After running this script and reviewing the contents of auth_log.log, I noticed the suspicious messages included either “Failed”, “Unauthorized” or ”error” and that each keyword was case-sensitive.

## Initial Thought Process

First iteration of pseudo code:
 ![image](https://github.com/user-attachments/assets/580a3cee-a259-4892-91fc-7b5328eeb44f)

My initial pseudo code included an if statement, but when I wrote my first draft of subsequent code, I found I didn’t need one — which implied I was maybe missing part of the puzzle. I defined my source and destination variables, my array of suspicious keywords and decided to use grep to output lines that matched any of the keywords.

1st draft (ignore middle comments):

![image](https://github.com/user-attachments/assets/e18e59ce-2293-43d3-8183-346cd9c58a13)

The script above ran successfully until I ran it again and realized it added duplicate lines to the results file (suspicious_activity.log). Here is when I also noticed that the original auth_log.log also had duplicates itself!

I edited the script again, but this time with an if loop that read through the lines of the logfile and if any read lines matched any of the suspicious keywords, they were copied to the results file. I ran this version (below) and the script seemed to work until I realized the log files copied over were both normal and suspicious messages. My error here was comparing "$line" to the "${suspiciousWords}” array instead of a variable representing the array. So all the messages were being copied over without a condition.

2nd draft:

![image](https://github.com/user-attachments/assets/5aa948db-4ee3-47ac-9353-e0bd6fb261a1)


## Final Code (Changes I Made)

To account for duplicates, I added in an associative array that holds all the contents of suspicious_activity.log. That way my script can check against this array for duplicates before adding in a new entry into suspicious_activity.log. Even if an identical suspicious login attempt is made and logged in auth-log.log file, the date of the error log is always included, making each line unique.

To have the lines of auth_log.log checked multiple times for different reasons, I used nested if loops to check first if lines read in the log file included any suspicious key words and second if they already existed in the results file before copying them over to suspicious_activity.log.

Within my nested if loop, I rewrote the if conditional to instead have the lines read from auth_log.log compared to a variable called “susword” which represented each suspicious keyword in my 'suspiciousWords' array.

Lastly, I edited my pseudo code to be more descriptive, especially for the loop sections, to explain each process as its written. I also did something new and used pseudo code to break my script up into sections with “titles”. These titles start with a “# - -” and are indented to the center of the script. I’d like to know if this is good practice or not.

Example of 'titles':

![image](https://github.com/user-attachments/assets/276b7e18-cc92-4884-b6b2-4c5da6b0a91f)


### Cron Log

I set the script to run daily in the cron tab with “0 0 * * * /home/ubuntu/suspicious.sh”

Did not include file for appending script results since results will already show in suspicious_activity.log.

![image](https://github.com/user-attachments/assets/e5b7581c-1df4-4086-b76d-07daa0e92fac)

## Testing
For testing, I copied over the contents from auth_log.log into my own log file and used that as the ‘logfile’ variable in my script. I ran the script to see if it would parse out and copy over the suspicious logs into the results file and it did! 

 ![image](https://github.com/user-attachments/assets/fcf4b359-7cc5-497a-8f77-2fea39119fd9)

I ran it again to make sure duplicates were not showing up.

 ![image](https://github.com/user-attachments/assets/c4d2767b-eea0-4c02-9bc1-77a4cc781881)

Then I added in my own nonsense lines into the log file that either included a suspicious key word or did not. 
 ![image](https://github.com/user-attachments/assets/65a2a1f4-7ab3-4e54-9a08-66e30c7b8310)

Ran the script again to check if the new suspicious lines were logged and they were!

![image](https://github.com/user-attachments/assets/441c986d-7a0e-4232-9880-7c6ba8088c8c)

## New commands and other things I learned

- “> filename.txt” clears the contents of filename.txt.
    - Whenever I wanted to start over with testing, I’d type “ > suspicious_attempts.log”
- Can use redirection (’<’) at the end of a while loop to indicate what file’s contents should be used as the input of the while loop.
    - In the case of my script, it indicated which file’s contents should be read throughout the while loop
- Can set a counter  with ”counter=0” and increment it with “((counter++))” in your code where needed
- Can use an associative array (which you have to declare) to store “key-value pairs” — every key is unique and has an associated value.
    - Since the keys in an associative array must be unique, cross-checking suspicious lines in auth_log.log with the ‘existing_suslogs’ array prevented duplicate lines from being added to the ‘results’ file.
- Flags
    - declare **-A** existing_suslogs
        - '-A' makes the declaration for an associative array
    - if [ **-f** "$results" ]
        - **'-f'** checks if the file exists and if it's a regular file
    - while IFS= read -r line
        - '**-r'** ensures backslashes are not read as escape characters; instead read as regular characters
    - if [ **-z** "${existing_suslogs["$line"]}" ]
        - **'z'** checks if the existing_logs array does not contain the current line and returns TRUE if that’s the case

## Optimization

Initially, I had an echo message of “suspicious_attempts.log has been updated.” to end the script. Then, when I was testing the script to see if duplicate entries were being bypassed, the echo message didn’t really seem to make sense since technically, the results log wasn’t being updated each time the script ran. So, I added in a counter to the script that incremented when a line was successfully added into the results file (within the nested if loop). Then I added the counter variable into my echo message so when you run the script, it reports back if 0 or more entries were added to suspicious_attempts.log. I thought that was pretty cool!

![image](https://github.com/user-attachments/assets/18571f9d-14f5-447a-9940-b3a6f6263d00)

Lastly, it would be cool to not have to worry about case-sensitivity here as I set the keywords to be exactly how they show up in the log files. In the chance that incoming suspicious logs have a format change, where say for example a suspicious log contains “Error” instead of “error”, a script that runs a case insensitive check would be helpful. I didn’t optimize my script in this way, but an idea is to add both the lowercase and upper case versions of "Failed", "Unauthorized", "error” to the array. Online mentions you can use normalization on the words of an array to retrieve them as lower case or upper case, but I’ll have to read up on that more.

## Conclusion

Was a great challenge. As usual, took me longer than expected!

