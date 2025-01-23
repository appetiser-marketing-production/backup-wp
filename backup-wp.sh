#!/bin/bash

# Backup script for staging site
echo "Usage: $0 <foldername>"
echo "This script will back up ALL files including database dump file of the specified site."

LOGFILE="/var/log/backup-wp_$(whoami)_$(date +'%Y%m%d_%H%M%S').log"

log_action() {
  local result=$?
  local time_stamp
  time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$time_stamp: $1: $2" | sudo tee -a "$LOGFILE" > /dev/null
  return $result
}

# Function to check if a variable is blank
check_blank() {
  local value="$1"
  local var_name="$2"

  case "$value" in
    "")
      echo "Error: $var_name cannot be blank. Please provide a valid $var_name."
      log_action "Error" "$var_name cannot be blank. Please provide a valid $var_name."
      
      exit 1
      ;;
    *)
      echo "$var_name is set to: $value"
      ;;
  esac
}

# Check if wp-cli is installed
if ! which wp > /dev/null; then
  errormsg="WP CLI could not be found. Please install WP-CLI before running this script."
  echo "$errormsg"
  echo "For installation instructions, visit: https://wp-cli.org/#installing"
  log_action "ERROR" "$errormsg"
  exit 1
fi

# Web directory
web_root=${1:-$(read -p "Enter the web server's root directory (default: /var/www/html): " tmp && echo "${tmp:-/var/www/html}")}

# Navigate to the specified web server's root directory
cd "$web_root" || {
    errormsg="Failed to navigate to $web_root. Ensure the directory exists."
    echo "$errormsg"
    log_action "ERROR" "$errormsg"
    exit 1
}
log_action "CHECK" "Webroot is accessible"
echo "Webroot is accessible"

# Get the folder name from arguments or prompt
foldername=${1:-$(read -p "Enter folder name: " tmp && echo $tmp)}
# Check for blank
check_blank "$foldername" "Folder name"

# Define the full path
site_dir="$web_root/$foldername"

# Use a case statement to check if the directory exists
case "$(test -d "$site_dir" && echo "exists" || echo "not_exists")" in
    "exists")
        echo "The directory $site_dir exists and is accessible."
        log_action "CHECK" "web directory is accessible"
        ;;
    "not_exists")
        errormsg="Error: The directory $site_dir does not exist. Please check the folder name and web root."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="Unexpected error occurred while checking the directory."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
esac

# Define paths
backup_file="$web_root/${foldername}_backup.tar.gz"
db_backup_file="$site_dir/wordpress.sql"

# Path to wp-config.php
wp_config_file="$site_dir/wp-config.php"

# Check if wp-config.php exists
case "$(test -f "$wp_config_file" && echo "exists" || echo "not_exists")" in
    "exists")
        errormsg="wp-config.php found at $wp_config_file."
        echo "$errormsg"
        log_action "Done" "$errormsg"
        ;;
    "not_exists")
        errormsg="Error: wp-config.php not found at $wp_config_file."
        echo "$errormsg"
        log_action "Error" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="Unexpected error occurred while checking wp-config.php."
        echo "$errormsg"
        log_action "Error" "$errormsg"
        exit 1
        ;;
esac
# Extract DB_NAME
db_name=$(grep "DB_NAME" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')

# Check if DB_NAME was extracted successfully
case "$db_name" in
    "")
        errormsg="Error: Failed to extract DB_NAME from wp-config.php."
        echo "$errormsg"
        log_action "Error" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="DB_NAME successfully extracted: $db_name."
        echo "$errormsg"
        log_action "Success" "$errormsg"
        ;;
esac

# Extract DB_USER
db_user=$(grep "DB_USER" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')

# Check if DB_USER was extracted successfully
case "$db_user" in
    "")
        errormsg="Error: Failed to extract DB_USER from wp-config.php."
        echo "$errormsg"
        log_action "Error" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="DB_USER successfully extracted: $db_user."
        echo "$errormsg"
        log_action "Success" "$errormsg"
        ;;
esac

# Extract DB_PASSWORD
db_password=$(grep "DB_PASSWORD" "$wp_config_file" | awk -F", '" '{print $2}' | awk -F"'" '{print $1}')

# Check if DB_PASSWORD was extracted successfully
case "$db_password" in
    "")
        errormsg="Error: Failed to extract DB_PASSWORD from wp-config.php."
        echo "$errormsg"
        log_action "Error" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="DB_PASSWORD successfully extracted."
        echo "$errormsg"
        log_action "Success" "$errormsg"
        ;;
esac


# Backup database
echo "Exporting database..."
cd "$site_dir" || {
    echo "Error: Failed to navigate to $site_dir."
    exit 1
}
echo "Navigated to site directory $site_dir."

#export_status=$(sudo -u www-data mysqldump --add-drop-database --add-drop-table --databases "$db_name" -u"$db_user" -p"$db_password" > "$db_backup_file" 2>/dev/null && echo "success" || echo "failure")

cmd="sudo -u www-data mysqldump --add-drop-database --add-drop-table --databases \"$db_name\" -u\"$db_user\" -p\"$db_password\" > \"$db_backup_file\""
echo "Executing command: $cmd"
export_status=$(eval "$cmd 2>/dev/null && echo success || echo failure")

case "$export_status" in
    "success")
        errormsg="Database exported to $db_backup_file."
        echo "$errormsg"
        log_action "Done" "$errormsg"
        ;;
    "failure")
        errormsg="Error: Database export failed."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="Unexpected error occurred during database export."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
esac


# Create tar.gz file including all files and database dump
echo "Creating backup archive..."
archive_status=$(sudo -u www-data tar -czvf "$backup_file" -C "$web_root" "$foldername" > /dev/null 2>&1 && echo "success" || echo "failure")

case "$archive_status" in
    "success")
        errormsg="Backup archive created: $backup_file"
        echo "$errormsg"
        log_action "Done" "$errormsg"
        ;;
    "failure")
        errormsg="Error: Failed to create backup archive."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="Unexpected error occurred during archive creation."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
esac

# Clean up the database dump file
echo "Cleaning up temporary database dump file..."
cleanup_status=$(sudo -u www-data rm "$db_backup_file" > /dev/null 2>&1 && echo "success" || echo "failure")

case "$cleanup_status" in
    "success")
        errormsg="Backup archive created: $backup_file"
        echo "$errormsg"
        log_action "Done" "$errormsg"
        ;;
    "failure")
        errormsg="Error: Failed to remove temporary database dump file."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
    *)
        errormsg="Unexpected error occurred during cleanup."
        echo "$errormsg"
        log_action "ERROR" "$errormsg"
        exit 1
        ;;
esac


echo "Done cleaning up temporary database dump file..."
log_action "done" "Cleaning up temporary database dump file..."

echo "Backup complete. Archive is located at $backup_file."

# Echo the log file path at the end of the script
echo "Log file created at: $LOGFILE";