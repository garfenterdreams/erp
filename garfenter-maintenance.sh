#!/bin/bash
# Garfenter ERP - Maintenance Script
# Common maintenance operations for Garfenter ERP

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

COMPOSE_FILE="docker-compose.garfenter.yml"

print_header() {
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║  Garfenter ERP - Maintenance Tools    ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}\n"
}

print_menu() {
    echo -e "${BOLD}${BLUE}Available Operations:${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "  ${GREEN}1)${NC} Backup Database"
    echo -e "  ${GREEN}2)${NC} Restore Database"
    echo -e "  ${GREEN}3)${NC} View Logs"
    echo -e "  ${GREEN}4)${NC} Restart Services"
    echo -e "  ${GREEN}5)${NC} Update Odoo"
    echo -e "  ${GREEN}6)${NC} Clean Docker Resources"
    echo -e "  ${GREEN}7)${NC} Check Service Status"
    echo -e "  ${GREEN}8)${NC} Access PostgreSQL Shell"
    echo -e "  ${GREEN}9)${NC} Access Odoo Shell"
    echo -e "  ${GREEN}10)${NC} Export Logs"
    echo -e "  ${GREEN}11)${NC} View System Resources"
    echo -e "  ${RED}0)${NC} Exit"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
}

backup_database() {
    echo -e "\n${BOLD}${BLUE}Database Backup${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"

    BACKUP_DIR="./backups"
    mkdir -p "$BACKUP_DIR"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/garfenter_erp_$TIMESTAMP.sql"

    echo -e "${YELLOW}Creating backup...${NC}"
    docker-compose -f "$COMPOSE_FILE" exec -T garfenter-postgres \
        pg_dump -U odoo garfenter_erp > "$BACKUP_FILE"

    if [ -f "$BACKUP_FILE" ]; then
        # Compress backup
        gzip "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup created successfully:${NC} $BACKUP_FILE.gz"
        echo -e "${CYAN}Size:${NC} $(du -h "$BACKUP_FILE.gz" | cut -f1)"
    else
        echo -e "${RED}✗ Backup failed${NC}"
    fi
}

restore_database() {
    echo -e "\n${BOLD}${BLUE}Database Restore${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"

    BACKUP_DIR="./backups"

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo -e "${RED}No backups found in $BACKUP_DIR${NC}"
        return
    fi

    echo -e "${YELLOW}Available backups:${NC}"
    ls -lh "$BACKUP_DIR"/*.sql* 2>/dev/null | awk '{print $9, "("$5")"}'

    echo -e "\n${YELLOW}Enter backup file path:${NC}"
    read -r BACKUP_FILE

    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}File not found: $BACKUP_FILE${NC}"
        return
    fi

    echo -e "${RED}WARNING: This will replace the current database!${NC}"
    echo -e "${YELLOW}Are you sure? (yes/no)${NC}"
    read -r confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        return
    fi

    # Decompress if needed
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        echo -e "${YELLOW}Decompressing backup...${NC}"
        gunzip -k "$BACKUP_FILE"
        BACKUP_FILE="${BACKUP_FILE%.gz}"
    fi

    echo -e "${YELLOW}Restoring database...${NC}"
    docker-compose -f "$COMPOSE_FILE" exec -T garfenter-postgres \
        psql -U odoo garfenter_erp < "$BACKUP_FILE"

    echo -e "${GREEN}✓ Database restored successfully${NC}"
}

view_logs() {
    echo -e "\n${BOLD}${BLUE}Service Logs${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "1) All services"
    echo -e "2) Odoo only"
    echo -e "3) PostgreSQL only"
    echo -e "4) Nginx only"
    echo -e "${YELLOW}Select option:${NC}"
    read -r option

    case $option in
        1) docker-compose -f "$COMPOSE_FILE" logs --tail=100 -f ;;
        2) docker-compose -f "$COMPOSE_FILE" logs --tail=100 -f garfenter-erp ;;
        3) docker-compose -f "$COMPOSE_FILE" logs --tail=100 -f garfenter-postgres ;;
        4) docker-compose -f "$COMPOSE_FILE" logs --tail=100 -f garfenter-nginx ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

restart_services() {
    echo -e "\n${BOLD}${BLUE}Restart Services${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "1) All services"
    echo -e "2) Odoo only"
    echo -e "3) PostgreSQL only"
    echo -e "4) Nginx only"
    echo -e "${YELLOW}Select option:${NC}"
    read -r option

    case $option in
        1)
            echo -e "${YELLOW}Restarting all services...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart
            ;;
        2)
            echo -e "${YELLOW}Restarting Odoo...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart garfenter-erp
            ;;
        3)
            echo -e "${YELLOW}Restarting PostgreSQL...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart garfenter-postgres
            ;;
        4)
            echo -e "${YELLOW}Restarting Nginx...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart garfenter-nginx
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            return
            ;;
    esac

    echo -e "${GREEN}✓ Services restarted${NC}"
}

update_odoo() {
    echo -e "\n${BOLD}${BLUE}Update Odoo${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "${RED}WARNING: This will rebuild Odoo container${NC}"
    echo -e "${YELLOW}Continue? (yes/no)${NC}"
    read -r confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Update cancelled${NC}"
        return
    fi

    echo -e "${YELLOW}Stopping services...${NC}"
    docker-compose -f "$COMPOSE_FILE" down

    echo -e "${YELLOW}Rebuilding Odoo image...${NC}"
    docker-compose -f "$COMPOSE_FILE" build --no-cache garfenter-erp

    echo -e "${YELLOW}Starting services...${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d

    echo -e "${GREEN}✓ Update complete${NC}"
}

clean_docker() {
    echo -e "\n${BOLD}${BLUE}Clean Docker Resources${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "${YELLOW}This will remove:${NC}"
    echo -e "  - Unused containers"
    echo -e "  - Unused images"
    echo -e "  - Unused networks"
    echo -e "  - Build cache"
    echo -e "${GREEN}This will NOT remove Garfenter volumes${NC}"
    echo -e "${YELLOW}Continue? (yes/no)${NC}"
    read -r confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Clean cancelled${NC}"
        return
    fi

    echo -e "${YELLOW}Cleaning Docker resources...${NC}"
    docker system prune -af --volumes --filter "label!=com.garfenter.volume"

    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

check_status() {
    echo -e "\n${BOLD}${BLUE}Service Status${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    docker-compose -f "$COMPOSE_FILE" ps

    echo -e "\n${BOLD}${BLUE}Volume Status${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    docker volume ls | grep garfenter

    echo -e "\n${BOLD}${BLUE}Network Status${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    docker network ls | grep garfenter
}

postgres_shell() {
    echo -e "\n${BOLD}${BLUE}PostgreSQL Shell${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "${YELLOW}Connecting to PostgreSQL...${NC}"
    docker-compose -f "$COMPOSE_FILE" exec garfenter-postgres psql -U odoo garfenter_erp
}

odoo_shell() {
    echo -e "\n${BOLD}${BLUE}Odoo Shell${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo -e "${YELLOW}Connecting to Odoo shell...${NC}"
    docker-compose -f "$COMPOSE_FILE" exec garfenter-erp \
        /opt/odoo/odoo-bin shell -c /etc/odoo/odoo.conf -d garfenter_erp
}

export_logs() {
    echo -e "\n${BOLD}${BLUE}Export Logs${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"

    LOG_DIR="./logs"
    mkdir -p "$LOG_DIR"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/garfenter_logs_$TIMESTAMP.log"

    echo -e "${YELLOW}Exporting logs...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs --no-color > "$LOG_FILE"

    if [ -f "$LOG_FILE" ]; then
        echo -e "${GREEN}✓ Logs exported to:${NC} $LOG_FILE"
        echo -e "${CYAN}Size:${NC} $(du -h "$LOG_FILE" | cut -f1)"
    else
        echo -e "${RED}✗ Export failed${NC}"
    fi
}

system_resources() {
    echo -e "\n${BOLD}${BLUE}System Resources${NC}"
    echo -e "${CYAN}──────────────────────────────────────${NC}"

    echo -e "\n${BOLD}Container Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
        $(docker-compose -f "$COMPOSE_FILE" ps -q)

    echo -e "\n${BOLD}Disk Usage:${NC}"
    docker system df
}

# Main menu loop
main() {
    cd "$(dirname "$0")"

    while true; do
        print_header
        print_menu
        echo -e "\n${YELLOW}Select option:${NC} "
        read -r choice

        case $choice in
            1) backup_database ;;
            2) restore_database ;;
            3) view_logs ;;
            4) restart_services ;;
            5) update_odoo ;;
            6) clean_docker ;;
            7) check_status ;;
            8) postgres_shell ;;
            9) odoo_shell ;;
            10) export_logs ;;
            11) system_resources ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac

        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r
    done
}

main
