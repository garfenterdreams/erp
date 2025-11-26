# Garfenter ERP - Deployment Guide

## Quick Start (One-Click Deployment)

The easiest way to deploy Garfenter ERP is using the one-click deployment script:

```bash
./garfenter-start.sh
```

This script will:
- Check Docker installation
- Create environment configuration
- Build Docker images
- Start all services (PostgreSQL + Odoo)
- Initialize the database with Spanish (Guatemala) localization
- Display access URLs and helpful information

## Prerequisites

- Docker 20.10 or later
- Docker Compose 2.0 or later (or docker-compose 1.29+)
- At least 4GB RAM available
- 10GB free disk space

## Manual Deployment

If you prefer manual control:

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your preferred settings
```

### 2. Build and Start Services

```bash
# Build the Odoo image
docker-compose -f docker-compose.garfenter.yml build

# Start services
docker-compose -f docker-compose.garfenter.yml up -d
```

### 3. Access Garfenter ERP

Open your browser and navigate to:
- **Main URL**: http://localhost:8069

## Configuration

### Environment Variables

Key environment variables in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_DB` | garfenter_erp | Database name |
| `POSTGRES_USER` | odoo | Database user |
| `POSTGRES_PASSWORD` | odoo | Database password |
| `ODOO_PORT` | 8069 | Odoo web interface port |
| `GARFENTER_LANG` | es_GT | Default language |
| `GARFENTER_COUNTRY` | GT | Default country (Guatemala) |

### Odoo Configuration

Main configuration file: `odoo.garfenter.conf`

Key settings:
- **Workers**: 2 (adjust based on CPU cores)
- **Memory limits**: 2GB soft, 2.5GB hard per worker
- **Database**: Configured for PostgreSQL container
- **Localization**: Spanish (Guatemala) by default

## Using Nginx Reverse Proxy

To enable the Nginx reverse proxy:

```bash
docker-compose -f docker-compose.garfenter.yml --profile with-nginx up -d
```

This provides:
- HTTP/HTTPS termination
- Load balancing
- WebSocket support for long-polling
- Static file serving

Access through:
- **HTTP**: http://localhost:80
- **HTTPS**: https://localhost:443 (configure SSL certificates first)

## Docker Services

### garfenter-postgres
- Image: postgres:15-alpine
- Port: 5432 (internal only)
- Volume: garfenter-db-data
- Health check enabled

### garfenter-erp
- Image: Built from Dockerfile (Python 3.12 + Odoo)
- Ports: 8069 (web), 8072 (longpolling)
- Volumes:
  - garfenter-odoo-data (Odoo data directory)
  - garfenter-extra-addons (custom addons)
  - odoo.garfenter.conf (configuration file)

### garfenter-nginx (optional)
- Image: nginx:alpine
- Ports: 80, 443
- Requires: nginx/nginx.conf
- Profile: with-nginx

## Volume Management

Persistent data is stored in Docker volumes:

```bash
# List volumes
docker volume ls | grep garfenter

# Backup database
docker-compose -f docker-compose.garfenter.yml exec -T garfenter-postgres \
  pg_dump -U odoo garfenter_erp > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose -f docker-compose.garfenter.yml exec -T garfenter-postgres \
  psql -U odoo garfenter_erp < backup_20241125.sql
```

## Common Operations

### View Logs

```bash
# All services
docker-compose -f docker-compose.garfenter.yml logs -f

# Specific service
docker-compose -f docker-compose.garfenter.yml logs -f garfenter-erp
```

### Restart Services

```bash
# Restart all
docker-compose -f docker-compose.garfenter.yml restart

# Restart specific service
docker-compose -f docker-compose.garfenter.yml restart garfenter-erp
```

### Stop Services

```bash
# Stop (keeps volumes)
docker-compose -f docker-compose.garfenter.yml down

# Stop and remove volumes (CAUTION: deletes all data)
docker-compose -f docker-compose.garfenter.yml down -v
```

### Update Odoo

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose -f docker-compose.garfenter.yml build --no-cache
docker-compose -f docker-compose.garfenter.yml up -d
```

### Access Database

```bash
# PostgreSQL shell
docker-compose -f docker-compose.garfenter.yml exec garfenter-postgres \
  psql -U odoo garfenter_erp
```

### Access Odoo Shell

```bash
# Odoo shell
docker-compose -f docker-compose.garfenter.yml exec garfenter-erp \
  /opt/odoo/odoo-bin shell -c /etc/odoo/odoo.conf -d garfenter_erp
```

## Custom Addons

To add custom addons:

1. Place addon directories in a local folder
2. Mount the folder in docker-compose.garfenter.yml:

```yaml
volumes:
  - ./custom_addons:/mnt/extra-addons
```

3. Restart services:

```bash
docker-compose -f docker-compose.garfenter.yml restart garfenter-erp
```

4. Update the module list in Odoo settings

## Localization

Garfenter ERP is pre-configured for Guatemala:

- **Language**: Spanish (Guatemala) - es_GT
- **Country**: Guatemala (GT)
- **Timezone**: America/Guatemala
- **Currency**: GTQ (Guatemalan Quetzal)

To change localization, update `.env`:

```bash
GARFENTER_LANG=es_GT
GARFENTER_COUNTRY=GT
TZ=America/Guatemala
```

## Security Considerations

### Production Deployment

Before deploying to production:

1. **Change default passwords**:
   - Update `POSTGRES_PASSWORD` in `.env`
   - Update `admin_passwd` in `odoo.garfenter.conf`

2. **Disable database listing**:
   - Set `list_db = False` in `odoo.garfenter.conf`

3. **Enable SSL**:
   - Configure SSL certificates in nginx
   - Use HTTPS only

4. **Firewall**:
   - Only expose port 80/443 to public
   - Keep PostgreSQL (5432) internal only

5. **Backup**:
   - Set up automated database backups
   - Store backups off-site

## Troubleshooting

### Port Already in Use

If port 8069 is already in use:

1. Change `ODOO_PORT` in `.env`
2. Restart services

### Database Connection Failed

Check PostgreSQL is running:

```bash
docker-compose -f docker-compose.garfenter.yml ps
docker-compose -f docker-compose.garfenter.yml logs garfenter-postgres
```

### Odoo Won't Start

Check logs for errors:

```bash
docker-compose -f docker-compose.garfenter.yml logs garfenter-erp
```

Common issues:
- Missing dependencies: Rebuild image
- Configuration errors: Check odoo.garfenter.conf
- Database migration: May need manual intervention

### Performance Issues

Adjust worker settings in `odoo.garfenter.conf`:

```ini
workers = 4  # Number of CPU cores
limit_memory_soft = 2147483648  # 2GB
limit_memory_hard = 2684354560  # 2.5GB
```

## Resource Requirements

### Minimum
- 2 CPU cores
- 4GB RAM
- 10GB disk space

### Recommended
- 4 CPU cores
- 8GB RAM
- 50GB disk space (SSD preferred)

### Production
- 8+ CPU cores
- 16GB+ RAM
- 100GB+ disk space (SSD)
- Separate database server

## Support

For issues and questions:
1. Check logs: `docker-compose -f docker-compose.garfenter.yml logs`
2. Review Odoo documentation: https://www.odoo.com/documentation
3. Contact Garfenter support team

## License

This deployment configuration is part of Garfenter ERP system.
Odoo is licensed under LGPL-3.0.
