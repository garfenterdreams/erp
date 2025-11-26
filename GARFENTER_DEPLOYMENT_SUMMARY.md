# Garfenter ERP - One-Click Deployment Summary

## Overview

A complete Docker-based deployment solution for Garfenter ERP (Odoo) with Spanish (Guatemala) localization, automated setup, and comprehensive management tools.

## Files Created

### Core Deployment Files

1. **Dockerfile** (2.0 KB)
   - Based on Python 3.12 slim-bookworm
   - Includes all Odoo dependencies
   - Pre-configured for Guatemala localization
   - Optimized multi-stage build
   - wkhtmltopdf for PDF generation

2. **docker-compose.garfenter.yml** (2.8 KB)
   - PostgreSQL 15 database service
   - Odoo ERP service (port 8069)
   - Optional Nginx reverse proxy
   - Named volumes for data persistence
   - Health checks for all services
   - Network isolation

3. **odoo.garfenter.conf** (1.2 KB)
   - Odoo configuration file
   - Database connection settings
   - Worker configuration (2 workers)
   - Memory limits (2GB soft, 2.5GB hard)
   - Spanish (Guatemala) language default
   - Security settings

### Environment & Configuration

4. **.env.example** (883 B)
   - Environment variable templates
   - Database credentials
   - Port configurations
   - Localization settings (es_GT, GT)
   - SMTP configuration placeholders
   - Security settings

5. **.dockerignore** (576 B)
   - Optimizes Docker build context
   - Excludes unnecessary files
   - Reduces image size
   - Faster builds

### Scripts

6. **garfenter-start.sh** (11 KB) [Executable]
   - One-click deployment script
   - Beautiful branded interface
   - Automatic dependency checking
   - Environment setup
   - Service orchestration
   - Database initialization
   - Status reporting
   - Interactive log viewing

7. **garfenter-maintenance.sh** (11 KB) [Executable]
   - Interactive maintenance menu
   - Database backup/restore
   - Log management
   - Service control
   - Update management
   - Resource monitoring
   - Shell access (PostgreSQL & Odoo)
   - System cleanup

### Documentation

8. **DEPLOYMENT.md** (6.8 KB)
   - Complete deployment guide
   - Configuration details
   - Service architecture
   - Volume management
   - Common operations
   - Security best practices
   - Troubleshooting guide
   - Resource requirements

9. **QUICK_START.md** (1.4 KB)
   - Quick reference card
   - Essential commands
   - One-command deployment
   - First-time setup guide
   - Common operations

10. **.gitignore** (Updated)
    - Added deployment file exclusions
    - Protects sensitive data (.env)
    - Excludes backups and logs
    - SSL certificate protection

## Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│                Garfenter ERP Stack              │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐      ┌─────────────────┐    │
│  │   Nginx      │      │   Garfenter     │    │
│  │   Reverse    │─────▶│   ERP (Odoo)    │    │
│  │   Proxy      │      │   Port: 8069    │    │
│  │   (Optional) │      │   Workers: 2    │    │
│  └──────────────┘      └─────────────────┘    │
│    Port: 80/443               │                │
│                               │                │
│                               ▼                │
│                     ┌──────────────────┐       │
│                     │   PostgreSQL 15  │       │
│                     │   Database       │       │
│                     │   Port: 5432     │       │
│                     └──────────────────┘       │
│                                                 │
└─────────────────────────────────────────────────┘

Persistent Volumes:
  - garfenter-db-data (PostgreSQL data)
  - garfenter-odoo-data (Odoo filestore)
  - garfenter-extra-addons (Custom modules)
  - garfenter-nginx-logs (Nginx logs)
```

## Key Features

### Localization
- **Language**: Spanish (Guatemala) - es_GT
- **Country**: Guatemala (GT)
- **Timezone**: America/Guatemala
- **Currency**: GTQ (Guatemalan Quetzal)

### Security
- Isolated Docker network
- Environment variable management
- Configurable admin password
- Proxy mode support
- Optional SSL/TLS with Nginx

### Performance
- Multi-worker support (configurable)
- Memory limits per worker
- Connection pooling
- Health checks
- Resource monitoring

### Management
- One-click deployment
- Automated backups
- Easy restoration
- Log management
- Service control
- Update mechanism

## Quick Start

### 1. Deploy (One Command)
```bash
./garfenter-start.sh
```

### 2. Access
Open browser: http://localhost:8069

### 3. Initial Setup
- Master password: `garfenter_admin_2024`
- Language: Spanish (GT)
- Country: Guatemala

### 4. Manage
```bash
./garfenter-maintenance.sh
```

## Common Commands

### Service Control
```bash
# Start
docker-compose -f docker-compose.garfenter.yml up -d

# Stop
docker-compose -f docker-compose.garfenter.yml down

# Restart
docker-compose -f docker-compose.garfenter.yml restart

# View logs
docker-compose -f docker-compose.garfenter.yml logs -f

# Check status
docker-compose -f docker-compose.garfenter.yml ps
```

### With Nginx
```bash
docker-compose -f docker-compose.garfenter.yml --profile with-nginx up -d
```

### Backup & Restore
```bash
# Backup
./garfenter-maintenance.sh  # Select option 1

# Restore
./garfenter-maintenance.sh  # Select option 2
```

## Directory Structure

```
erp-crm/odoo/
├── Dockerfile                          # Odoo container image
├── docker-compose.garfenter.yml        # Service orchestration
├── odoo.garfenter.conf                 # Odoo configuration
├── .env.example                        # Environment template
├── .dockerignore                       # Build optimization
├── garfenter-start.sh                  # Deployment script
├── garfenter-maintenance.sh            # Maintenance tools
├── DEPLOYMENT.md                       # Full documentation
├── QUICK_START.md                      # Quick reference
├── GARFENTER_DEPLOYMENT_SUMMARY.md     # This file
├── nginx/                              # Nginx config (created on first run)
│   ├── nginx.conf                      # Reverse proxy config
│   └── ssl/                            # SSL certificates
├── backups/                            # Database backups (created on backup)
└── logs/                               # Exported logs (created on export)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| POSTGRES_DB | garfenter_erp | Database name |
| POSTGRES_USER | odoo | Database user |
| POSTGRES_PASSWORD | odoo | Database password |
| ODOO_PORT | 8069 | Odoo web port |
| ODOO_LONGPOLLING_PORT | 8072 | WebSocket port |
| GARFENTER_LANG | es_GT | Default language |
| GARFENTER_COUNTRY | GT | Default country |
| TZ | America/Guatemala | Timezone |
| NGINX_HTTP_PORT | 80 | HTTP port |
| NGINX_HTTPS_PORT | 443 | HTTPS port |

## Resource Requirements

### Minimum (Development)
- CPU: 2 cores
- RAM: 4GB
- Disk: 10GB
- Network: Basic internet

### Recommended (Production)
- CPU: 4+ cores
- RAM: 8GB+
- Disk: 50GB SSD
- Network: Stable connection

### Enterprise (High Load)
- CPU: 8+ cores
- RAM: 16GB+
- Disk: 100GB+ NVMe SSD
- Network: High bandwidth
- Separate DB server recommended

## Security Checklist

Before production deployment:

- [ ] Change POSTGRES_PASSWORD in .env
- [ ] Change admin_passwd in odoo.garfenter.conf
- [ ] Set list_db = False in odoo.garfenter.conf
- [ ] Configure SSL certificates
- [ ] Set up firewall rules
- [ ] Configure automated backups
- [ ] Review and update SMTP settings
- [ ] Enable monitoring
- [ ] Set up log rotation
- [ ] Configure fail2ban (if applicable)

## Backup Strategy

### Automated Backups
1. Database dumps (daily recommended)
2. Filestore backups (weekly recommended)
3. Configuration backups (after changes)
4. Off-site storage (essential)

### Using Maintenance Script
```bash
./garfenter-maintenance.sh
# Select: 1) Backup Database
```

Backups are stored in: `./backups/`
Format: `garfenter_erp_YYYYMMDD_HHMMSS.sql.gz`

## Troubleshooting

### Services Won't Start
```bash
# Check logs
docker-compose -f docker-compose.garfenter.yml logs

# Verify Docker
docker --version
docker-compose --version

# Check ports
lsof -i :8069
```

### Database Connection Failed
```bash
# Check PostgreSQL
docker-compose -f docker-compose.garfenter.yml ps
docker-compose -f docker-compose.garfenter.yml logs garfenter-postgres

# Verify connectivity
docker-compose -f docker-compose.garfenter.yml exec garfenter-postgres \
  psql -U odoo -d garfenter_erp -c "SELECT version();"
```

### Performance Issues
1. Adjust workers in odoo.garfenter.conf
2. Increase memory limits
3. Check system resources
4. Review database performance

## Support & Documentation

### Internal Documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [QUICK_START.md](QUICK_START.md) - Quick reference

### External Resources
- Odoo Documentation: https://www.odoo.com/documentation
- Docker Documentation: https://docs.docker.com/
- PostgreSQL Documentation: https://www.postgresql.org/docs/

### Garfenter Support
Contact your Garfenter system administrator or support team for assistance.

## Version Information

- **Odoo**: Latest (from repository)
- **PostgreSQL**: 15-alpine
- **Python**: 3.12-slim-bookworm
- **Nginx**: alpine (latest)

## License

This deployment configuration is part of the Garfenter ERP system.
- Odoo: LGPL-3.0
- PostgreSQL: PostgreSQL License
- Nginx: 2-clause BSD License

---

**Garfenter ERP Deployment**
Version 1.0 - November 2025
Localized for Guatemala
