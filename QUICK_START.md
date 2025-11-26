# Garfenter ERP - Quick Start Guide

## One Command Deployment

```bash
./garfenter-start.sh
```

That's it! Your Garfenter ERP will be running at: **http://localhost:8069**

---

## Essential Commands

### Start Services
```bash
./garfenter-start.sh
# OR
docker-compose -f docker-compose.garfenter.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose.garfenter.yml down
```

### View Logs
```bash
docker-compose -f docker-compose.garfenter.yml logs -f
```

### Restart Services
```bash
docker-compose -f docker-compose.garfenter.yml restart
```

### Check Status
```bash
docker-compose -f docker-compose.garfenter.yml ps
```

---

## First Time Setup

1. Open http://localhost:8069
2. Create database (or it may be auto-created)
3. Master password: `garfenter_admin_2024` (CHANGE THIS!)
4. Select language: `Spanish (GT) / Español (GT)`
5. Choose your modules and start using Garfenter ERP

---

## Default Configuration

- **URL**: http://localhost:8069
- **Language**: Spanish (Guatemala)
- **Country**: Guatemala
- **Database**: garfenter_erp
- **DB User**: odoo
- **DB Password**: odoo (change in production!)

---

## With Nginx (Optional)

```bash
docker-compose -f docker-compose.garfenter.yml --profile with-nginx up -d
```

Access via: http://localhost:80

---

## Need Help?

See detailed guide: [DEPLOYMENT.md](DEPLOYMENT.md)

---

**Garfenter ERP** - Enterprise Resource Planning for Guatemala
