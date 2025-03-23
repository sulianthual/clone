#!/bin/bash

# How to setup github/git (e.g on new computer):
# 1. Log in to github: main email, main pwd (possible main phone confirmation)
# 2. Go to Profile/Settings/Developper Settings/Personal access tokens/Tokens (classic)
# 3. Generate new token (classic): note as name of computer, expiration 90 days, scope "repo"
# 4. Copy token code and save in text file
# 5. in terminal: git config --global credential.helper store
# 6. Log to git in some way (git clone or git push, etc)
# 7. Enter username (main email) and token as pwd
# 8. These credentials are now stored for later reuse (as long as token is valid)

# Automated code for git push
echo "Pushing to git:"

COMMIT=$(date +"%Y%m%d-%H%M%S")
#read -p "commit name: " COMMIT

# Add all changes
git add -A
# Commit changes with a message
git commit -m "$COMMIT"

# Push changes to the remote repository
git push

# End message
echo "done"


#####################################
## NOTES:
## 1) always create new repo from github following their instructions
## 2) Above script for regular pushes
## 3) If not working, probably password expired:
## - make new password (token) on github (attach extra rights to edit/overwrite)
##)- update password locally by entering:
# git config --global credential.helper store 
## and then making a manual push entering username and password


