#!/bin/bash

# Backup script for a WordPress staging site
# This script backs up ALL files including the database dump of the specified WordPress site.
# It uses a configuration file (backup-wp.conf) for automation but extracts database details from wp-config.php.

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_FILE="$SCRIPT_DIR/backup-wp.conf"

echo "WordPress Backup Script"
echo "This script will create a backup of your WordPress site, including all files and the database."

# Notify the user about the optional config file
if [[ -f "$CONFIG_FILE" ]]; then
    echo "🔹 Using configuration file: $CONFIG_FILE"
else
    echo "⚠️ No configuration file found. You can create '$CONFIG_FILE' to automate input values."
fi

# Define log file for recording script activity
LOGFILE="/var/log/backup-wp_$(whoami)_$(date +'%Y%m%d_%H%M%S').log"

# Function: Logs actions and errors to a log file
log_action() {
  local result=$?
  local time_stamp
  time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$time_stamp: $1: $2" | sudo tee -a "$LOGFILE" > /dev/null
  return $result
}

# Function: Check if a variable is blank, prompting the user if necessary
check_blank() {
  local value="$1"
  local var_name="$2"

  case "$value" in
    "")
      errormsg="Error: $var_name cannot be blank. Please provide a valid $var_name."
      echo "$errormsg"
      log_action "Error" "$errormsg"
      exit 1
      ;;
    *)
      echo "$var_name is set to: $value"
      ;;
  esac
}

# Check if WP-CLI is installed
if ! which wp > /dev/null; then
  errormsg="WP CLI could not be found. Please install WP-CLI before running this script."
  echo "$errormsg"
  echo "For installation instructions, visit: https://wp-cli.org/#installing"
  log_action "ERROR" "$errormsg"
  exit 1
fi

# Load configuration file if it exists
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Get web root directory (from config or use default/prompt)
web_root=${WEB_ROOT:-$(read -p "Enter the web server's root directory (default: /var/www/): " tmp && echo "${tmp:-/var/www/}")}

# Get the WordPress site folder name (from config or use default/prompt)
foldername=${FOLDER_NAME:-$(read -p "Enter folder name (default: html): " tmp && echo "${tmp:-html}")}

# Define the full path to the site directory
site_dir="$web_root/$foldername"

echo "📁 Site directory set to: $site_dir"

# Navigate to the specified web server's root directory
cd "$web_root" || {
    errormsg="Failed to navigate to $web_root. Ensure the directory exists."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
}
log_action "CHECK" "Webroot is accessible"
echo "✅ Webroot is accessible"

# Validate that wp-config.php exists in the site directory
wp_config_file="$site_dir/wp-config.php"

if [[ ! -f "$wp_config_file" ]]; then
    errormsg="❌ Error: wp-config.php not found at $wp_config_file. The script cannot continue."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
fi

echo "✅ wp-config.php found at $wp_config_file."
log_action "CHECK" "wp-config.php found and validated."

# Extract database credentials from wp-config.php
db_name=$(grep "DB_NAME" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')
db_user=$(grep "DB_USER" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')
db_password=$(grep "DB_PASSWORD" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')

check_blank "$db_name" "DB_NAME"
check_blank "$db_user" "DB_USER"
check_blank "$db_password" "DB_PASSWORD"

# Define paths for backup files
backup_file="$web_root/${foldername}_backup.tar.gz"
db_backup_file="$site_dir/wordpress.sql"

# Navigate to the site directory
cd "$site_dir" || {
    errormsg="❌ Error: Failed to navigate to $site_dir."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
}

# Create the database backup file
sudo -u www-data touch "$db_backup_file"

if [[ $? -ne 0 ]]; then
    errormsg="❌ Error: Failed to create file $db_backup_file as www-data."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
else
    errormsg="✅ Successfully created file $db_backup_file."
    echo "$errormsg"
    log_action "Success" "$errormsg"
fi

# Export the database
echo "⏳ Exporting database..."
if sudo -u www-data bash -c "mysqldump --add-drop-database --add-drop-table --databases '$db_name' -u'$db_user' -p'$db_password' > '$db_backup_file' 2>/dev/null"; then
  export_status="success"
else
  export_status="failure"
fi

case "$export_status" in
    "success")
        errormsg="✅ Database exported to $db_backup_file."
        echo "$errormsg"
        log_action "Done" "$errormsg"
        ;;
    "failure")
        errormsg="❌ Error: Database export failed."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
esac

# Create tar.gz archive containing all site files and database dump
echo "⏳ Creating backup archive..."
if sudo -u www-data tar -czvf "$backup_file" -C "$web_root" "$foldername" > /dev/null 2>&1; then
    errormsg="✅ Backup archive created: $backup_file"
    echo "$errormsg"
    log_action "Done" "$errormsg"
else
    errormsg="❌ Error: Failed to create backup archive."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
fi

# Remove the temporary database dump file
echo "🧹 Cleaning up temporary database dump file..."
if sudo -u www-data rm "$db_backup_file"; then
    errormsg="✅ Temporary database dump file removed."
    echo "$errormsg"
    log_action "Done" "$errormsg"
else
    errormsg="❌ Error: Failed to remove temporary database dump file."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
fi

# Final notification
echo "✅ Backup complete. Archive is located at $backup_file."
echo "📜 Log file created at: $LOGFILE."
