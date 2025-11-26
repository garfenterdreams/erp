#!/bin/bash
# Garfenter ERP - One-Click Deployment Script
# This script sets up and starts the Garfenter ERP system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Garfenter ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
  ____             __            _
 / ___| __ _ _ __ / _| ___ _ __ | |_ ___ _ __
| |  _ / _` | '__| |_ / _ \ '_ \| __/ _ \ '__|
| |_| | (_| | |  |  _|  __/ | | | ||  __/ |
 \____|\__,_|_|  |_|  \___|_| |_|\__\___|_|

  _____ ____  ____    ____            _
 | ____|  _ \|  _ \  / ___| _   _ ___| |_ ___ _ __ ___
 |  _| | |_) | |_) | \___ \| | | / __| __/ _ \ '_ ` _ \
 | |___|  _ <|  __/   ___) | |_| \__ \ ||  __/ | | | | |
 |_____|_| \_\_|     |____/ \__, |___/\__\___|_| |_| |_|
                            |___/
EOF
    echo -e "${NC}"
    echo -e "${BOLD}${GREEN}Garfenter ERP - Enterprise Resource Planning${NC}"
    echo -e "${CYAN}Powered by Odoo | Localized for Guatemala${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}\n"
}

# Print section header
print_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${BLUE}─────────────────────────────────────────────────${NC}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Print info message
print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if Docker is installed
check_docker() {
    print_section "Checking Docker Installation"
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo -e "Visit: ${CYAN}https://docs.docker.com/get-docker/${NC}"
        exit 1
    fi
    print_success "Docker is installed: $(docker --version)"

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Check if .env file exists, create from example if not
setup_env() {
    print_section "Setting Up Environment"

    if [ ! -f .env ]; then
        print_info "Creating .env file from .env.example..."
        cp .env.example .env
        print_success ".env file created"
        print_warning "Please review and update .env file with your configuration"
        echo -e "${YELLOW}Press Enter to continue with default settings, or Ctrl+C to exit and edit .env${NC}"
        read -r
    else
        print_success ".env file already exists"
    fi
}

# Create necessary directories
create_directories() {
    print_section "Creating Directories"

    mkdir -p nginx/ssl
    mkdir -p nginx

    # Create basic nginx config if it doesn't exist
    if [ ! -f nginx/nginx.conf ]; then
        print_info "Creating nginx configuration..."
        cat > nginx/nginx.conf << 'NGINX_EOF'
events {
    worker_connections 1024;
}

http {
    upstream odoo {
        server garfenter-erp:8069;
    }

    upstream odoochat {
        server garfenter-erp:8072;
    }

    server {
        listen 80;
        server_name _;

        proxy_read_timeout 720s;
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;

        # Add Headers for Odoo proxy mode
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;

        # log
        access_log /var/log/nginx/odoo.access.log;
        error_log /var/log/nginx/odoo.error.log;

        # Redirect longpoll requests to odoo longpolling port
        location /longpolling {
            proxy_pass http://odoochat;
        }

        # Redirect requests to odoo backend server
        location / {
            proxy_redirect off;
            proxy_pass http://odoo;
        }

        # common gzip
        gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
        gzip on;
    }
}
NGINX_EOF
        print_success "Nginx configuration created"
    fi

    print_success "Directories created successfully"
}

# Build and start containers
start_services() {
    print_section "Building and Starting Services"

    print_info "Building Docker images (this may take a few minutes on first run)..."
    docker-compose -f docker-compose.garfenter.yml build
    print_success "Docker images built successfully"

    print_info "Starting Garfenter ERP services..."
    docker-compose -f docker-compose.garfenter.yml up -d
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_section "Waiting for Services to Initialize"

    print_info "Waiting for PostgreSQL to be ready..."
    sleep 5

    MAX_ATTEMPTS=60
    ATTEMPT=0
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if docker-compose -f docker-compose.garfenter.yml exec -T garfenter-postgres pg_isready -U odoo &> /dev/null; then
            print_success "PostgreSQL is ready"
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        echo -n "."
        sleep 2
    done

    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        print_error "PostgreSQL failed to start in time"
        exit 1
    fi

    print_info "Waiting for Odoo to be ready..."
    ATTEMPT=0
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if docker-compose -f docker-compose.garfenter.yml logs garfenter-erp 2>&1 | grep -q "odoo.modules.loading: Modules loaded"; then
            print_success "Odoo is ready"
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        echo -n "."
        sleep 3
    done

    echo ""
}

# Initialize database
initialize_database() {
    print_section "Database Initialization"

    print_info "Checking if database needs initialization..."

    # Check if database already exists and has data
    DB_EXISTS=$(docker-compose -f docker-compose.garfenter.yml exec -T garfenter-postgres psql -U odoo -d garfenter_erp -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")

    if [ "$DB_EXISTS" -gt 5 ]; then
        print_success "Database already initialized"
        return
    fi

    print_info "Initializing database with Spanish (Guatemala) localization..."
    print_warning "This may take several minutes..."

    # The database will be initialized automatically on first run
    # We just need to wait for Odoo to complete the initialization
    sleep 10
    print_success "Database initialization in progress"
}

# Display access information
display_info() {
    print_section "Garfenter ERP is Running!"

    # Get the configured port from .env or use default
    ODOO_PORT=$(grep ODOO_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "8069")

    echo -e "${BOLD}${GREEN}Access Information:${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}Garfenter ERP URL:${NC}      ${GREEN}http://localhost:${ODOO_PORT}${NC}"
    echo -e "${BOLD}Default Language:${NC}       ${YELLOW}Spanish (Guatemala)${NC}"
    echo -e "${BOLD}Default Country:${NC}        ${YELLOW}Guatemala (GT)${NC}"
    echo -e "${BOLD}Database Name:${NC}          ${CYAN}garfenter_erp${NC}"
    echo -e ""
    echo -e "${BOLD}${YELLOW}Initial Setup:${NC}"
    echo -e "1. Open ${GREEN}http://localhost:${ODOO_PORT}${NC} in your browser"
    echo -e "2. Create your first database or login to existing one"
    echo -e "3. Default master password: ${RED}garfenter_admin_2024${NC} ${YELLOW}(CHANGE THIS!)${NC}"
    echo -e "4. Choose 'Spanish (GT) / Español (GT)' during setup"
    echo -e ""
    echo -e "${BOLD}${CYAN}Useful Commands:${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "View logs:          ${GREEN}docker-compose -f docker-compose.garfenter.yml logs -f${NC}"
    echo -e "Stop services:      ${YELLOW}docker-compose -f docker-compose.garfenter.yml down${NC}"
    echo -e "Restart services:   ${YELLOW}docker-compose -f docker-compose.garfenter.yml restart${NC}"
    echo -e "View status:        ${GREEN}docker-compose -f docker-compose.garfenter.yml ps${NC}"
    echo -e ""
    echo -e "${BOLD}${MAGENTA}With Nginx Proxy:${NC}"
    echo -e "Start with nginx:   ${GREEN}docker-compose -f docker-compose.garfenter.yml --profile with-nginx up -d${NC}"
    echo -e ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}Thank you for using Garfenter ERP!${NC}"
    echo -e "${CYAN}For support and documentation, visit the Garfenter portal.${NC}\n"
}

# Show logs option
show_logs() {
    print_section "Service Logs"
    print_info "Showing last 50 lines of logs (Press Ctrl+C to exit)"
    sleep 2
    docker-compose -f docker-compose.garfenter.yml logs --tail=50 -f
}

# Main execution
main() {
    print_banner

    # Change to script directory
    cd "$(dirname "$0")"

    check_docker
    setup_env
    create_directories
    start_services
    wait_for_services
    initialize_database

    echo ""
    display_info

    # Ask if user wants to see logs
    echo -e "${YELLOW}Would you like to view the service logs? (y/N)${NC}"
    read -r -n 1 response
    echo ""
    if [[ "$response" =~ ^([yY])$ ]]; then
        show_logs
    fi
}

# Run main function
main
