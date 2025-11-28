#!/bin/bash
# Garfenter ERP Entrypoint Script
# Generates Odoo config from environment variables at runtime

set -e

# Configuration file location
CONFIG_FILE="/etc/odoo/odoo.conf"

# Default values (can be overridden by environment variables)
DB_HOST="${HOST:-garfenter-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${USER:-garfenter}"
DB_PASSWORD="${PASSWORD:-garfenter_dev_2024}"
DB_NAME="${DB_NAME:-garfenter_erp}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-garfenter_admin_2024}"

# Generate the Odoo configuration file
cat > "$CONFIG_FILE" << EOF
[options]
; Garfenter ERP Configuration File (Generated at runtime)

; Database settings
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
db_name = ${DB_NAME}
db_maxconn = 64
db_template = template0

; Server settings
http_port = 8069
http_interface = 0.0.0.0

; Multiprocessing and Workers
workers = 2
max_cron_threads = 1

; Memory limits (per worker)
limit_memory_soft = 2147483648
limit_memory_hard = 2684354560
limit_time_cpu = 600
limit_time_real = 1200
limit_request = 8192

; Logging
logfile = False
log_level = info
log_handler = :INFO
log_db = False

; Addons
addons_path = /opt/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo

; Admin password
admin_passwd = ${ADMIN_PASSWORD}

; Localization
lang = es_GT

; Security
list_db = True
proxy_mode = True

; Session
session_timeout = 86400
EOF

echo "Odoo configuration generated successfully"
echo "Database Host: ${DB_HOST}"
echo "Database User: ${DB_USER}"
echo "Database Name: ${DB_NAME}"

# Execute the main command (odoo-bin)
exec "$@"
