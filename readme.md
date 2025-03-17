# 🛠️ WordPress Backup Script

This script automates the process of creating a complete backup of a WordPress staging site, including all files and the database. It ensures a reliable and systematic approach to safeguard your WordPress site data.

## 📝 Version Information
- **Version:** 1.1.1
- **Author:** Landing Page Team
- **Author URI:** [https://appetiser.com.au/](https://appetiser.com.au/)

🔄 Changes in Version 1.1.1
🔧 configuration file adjustment. it is now available for prompt if you want to use another other than the default

🔄 Changes in Version 1.1.0
🔧 Configuration file (`backup-wp.conf`) support** for `WEB_ROOT` and `FOLDER_NAME`.
🔒 Database details (`DB_NAME`, `DB_USER`, `DB_PASSWORD`) are now extracted from `wp-config.php`** instead of being manually configured.
🛠 Minor Fixes: Addressed minor bugs and improved script stability.

---

## 🔧 Prerequisites
Before running this script, ensure the following are set up:

1. **🛠️ WP-CLI Installed**:
   - The script requires [WP-CLI](https://wp-cli.org/#installing) to interact with the WordPress database.
   - Verify installation with:
     ```bash
     wp --info
     ```

2. **🔑 Proper Permissions**:
   - The script assumes the use of `www-data` (or equivalent) for file and database operations.
   - Ensure the user running the script has `sudo` privileges.

3. **📁 Web Server Directory**:
   - Confirm the root directory of the web server (default: `/var/www`).
   - Make sure the directory for the WordPress site exists within the web server directory.

4. **📝 Logging Directory**:
   - The script writes logs to `/var/log/`. Ensure the user has write permissions for this directory.

5. **🛠️ Bash Shell**:
   - The script is written for environments with `bash` available.

---

## 🛠️ Steps Performed by the Script

The script performs the following steps:

1. **✅ Check WP-CLI Installation**:
   - Validates that WP-CLI is installed and accessible.

2. **📃 Check for Configuration File (`backup-wp.conf`)**:
   - If the config file exists, it loads `WEB_ROOT` and `FOLDER_NAME` from it.
   - If no config file is found, it prompts the user for values.
   - Default values:
     - `WEB_ROOT="/var/www"`
     - `FOLDER_NAME="html"`
     - **Final `SITE_DIR` becomes `/var/www/html/`**.

3. **🔢 Validate `wp-config.php`**:
   - Ensures that `wp-config.php` exists in `SITE_DIR`.
   - Extracts `DB_NAME`, `DB_USER`, and `DB_PASSWORD` from `wp-config.php`.
   - **If `wp-config.php` is missing, the script logs an error and exits.**

4. **📄 Export Database**:
   - Uses WP-CLI to export the WordPress database to a file (`wordpress.sql`) in the site's directory.

5. **💾 Create Backup Archive**:
   - Compresses all files in the site folder, including the database dump, into a `.tar.gz` archive.

6. **🛁 Clean Up**:
   - Removes the temporary database dump file after successfully creating the archive.

7. **📙 Logging**:
   - Logs all actions to a log file located in `/var/log/`.

---

## 🔧 Configuration File (`backup-wp.conf`)

To avoid prompts and automate the backup process, you can create a `backup-wp.conf` file in the same directory as `backup-wp.sh`.

### **📚 Example `backup-wp.conf` File:**
```bash
# Configuration file for backup-wp.sh
# This file sets default values for automation.
# Database details are extracted from wp-config.php and should not be included here.

# Web server root directory (default: /var/www/)
WEB_ROOT="/var/www"

# Folder name of the WordPress site (default: html)
FOLDER_NAME="html"
```

---

## 🛠️ Usage
### **1. 🔧 Make the Script Executable**
```bash
chmod +x backup-wp.sh
```

### **2. ▶️ Run the Script**
```bash
./backup-wp.sh
```

### **3. ⚙️ Automate with `backup-wp.conf` (Optional)**
If `backup-wp.conf` is present, the script runs without prompting for input.

### **4. 👁 Create a Symlink to Run from Anywhere** (Optional)
If you want to run `backup-wp` from anywhere:
```bash
ln -s /usr/local/bin/shellscripts/backup-wp/backup-wp.sh /usr/local/bin/backup-wp
```
Now you can run the script from anywhere using:
```bash
backup-wp
```

---

## 🏆 Conclusion
This script provides an efficient way to back up your WordPress staging site, ensuring both files and the database are preserved. Regular backups are crucial to safeguard against data loss and facilitate recovery in case of issues.

If you encounter any issues, contact the authors fo the script or  double-check the prerequisites and permissions to ensure smooth execution.

---

🚀 **Version 1.1.0 is now fully automated with configuration file support and better database handling. Happy Backing Up!** 🚀

