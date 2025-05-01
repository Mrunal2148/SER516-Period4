# SER516 Period 4

# System Requirements

MacBook Pro (or equivalent system)

Processor: Intel Core i5 or higher / Apple M1 or higher
RAM: Minimum 16GB (18GB recommended)
Storage: At least 10GB of free space

Docker Desktop installed and running
Git installed
Stable internet connection

## Setting up the GitHub token
GITHUB Token
To generate a GitHub personal access token (PAT) for developers, follow these steps:

Step 1: Log into GitHub
  Go to GitHub and log into your account.
Step 2: Navigate to Developer Settings
  Click on your profile picture (top-right corner).
  Select "Settings" from the dropdown.
  Scroll down and find "Developer settings" (on the left sidebar).
  Click "Personal access tokens", then choose "Tokens (classic)" (or "Fine-grained tokens" if you need more control).
Step 3: Generate a New Token
  Click "Generate new token", then choose:
  Classic token (widely used and easier to configure)
  Fine-grained token (for more specific permissions)
  Give your token a note/name for identification.
  Set Expiration (recommended for security).
Select Permissions:
![image](https://github.com/user-attachments/assets/cc2e48b4-d508-41cf-8617-8328aa794b99)
  For repository access, check repo.
  For GitHub Actions, check workflow.
  For Git operations (push/pull), check write:packages, read:packages.
  For Full access, check all necessary scopes.
  Click "Generate token".
Step 4: Copy and Store the Token
  Copy the token immediately and store it securely (e.g., in a password manager).

## How to Run

1. Clone the repository
2. Navigate to the root directory of the cloned repository
3. Paste your github token in the .env file (Please ensure there are no white spaces)
4. Run below commands (Please note - This script will prune existing docker containers from your local machine before creating new containers)
   ```bash
   echo GITHUB_TOKEN=your_github_token_here >> .env
   chmod -X start.sh
   ./start.sh
   ```
7. The backend will be available at `http://localhost:8080`.
8. The frontend will be available at `http://localhost:8043`.

## Setting the Ports

The ports for the frontend are set in the `.env` file. You can change the ports by modifying the `CLIENT_PORT` variables in the `.env` file.


