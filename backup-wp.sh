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


# Backup database
echo "Exporting database..."
cd "$site_dir" || {
    echo "Error: Failed to navigate to $site_dir."
    exit 1
}

export_status=$(sudo -u www-data wp db export "$db_backup_file" --add-drop-table > /dev/null 2>&1 && echo "success" || echo "failure")

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

echo "Backup complete. Archive is located at $backup_file."

# Echo the log file path at the end of the script
echo "Log file created at: $LOGFILE";