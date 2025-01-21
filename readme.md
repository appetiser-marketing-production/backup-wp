# WordPress Backup Script

This script automates the process of creating a complete backup of a WordPress staging site, including all files and the database. It ensures a reliable and systematic approach to safeguard your WordPress site data.

## Prerequisites

Before running this script, ensure the following are set up:

1. **WP-CLI Installed**:
   - The script requires [WP-CLI](https://wp-cli.org/#installing) to interact with the WordPress database.
   - Verify installation with: `wp --info`.

2. **Proper Permissions**:
   - The script assumes the use of `www-data` (or equivalent) for file and database operations.
   - Ensure the user running the script has `sudo` privileges.

3. **Web Server Directory**:
   - Confirm the root directory of the web server (default: `/var/www/html`).
   - Make sure the directory for the WordPress site exists within the web server directory.

4. **Logging Directory**:
   - The script writes logs to `/var/log/`. Ensure the user has write permissions for this directory.

5. **Bash Shell**:
   - The script is written for environments with `bash` available.

## Steps Performed by the Script

The script performs the following steps:

1. **Check WP-CLI Installation**:
   - Validates that WP-CLI is installed and accessible.

2. **Prompt for Input**:
   - Requests the web server's root directory (default: `/var/www/html`).
   - Requests the name of the WordPress site's folder.

3. **Validate Inputs**:
   - Ensures the web server directory and the WordPress site folder exist.

4. **Export Database**:
   - Uses WP-CLI to export the WordPress database to a file (`wordpress.sql`) in the site's directory.

5. **Create Backup Archive**:
   - Compresses all files in the site folder, including the database dump, into a `.tar.gz` archive.

6. **Clean Up**:
   - Removes the temporary database dump file after successfully creating the archive.

7. **Logging**:
   - Logs all actions to a log file located in `/var/log/`.

## Usage

1. Make the script executable:
   ```bash
   chmod +x backup-wp.sh
