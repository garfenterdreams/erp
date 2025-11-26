# GARFENTER PLAN: Garfenter ERP (odoo)

> **⭐ PREFERRED PRODUCT** - Selected as best Full ERP platform for Garfenter Suite (Score: 8/10)

**Product Name:** Garfenter ERP
**Based On:** Odoo (Industry-Leading ERP)
**Category:** Enterprise Resource Planning
**Original Language:** English (with full Spanish support)

---

## Executive Summary

Odoo is a comprehensive ERP with excellent Spanish localization (865 translation files, 8 Spain-specific modules). This plan focuses on containerization, Guatemala customization, and Garfenter branding.

---

## 1. LOCALIZATION PLAN

### Current Status: SPANISH SUPPORTED ✓
- Full Spanish translations (es.po)
- Latin American Spanish (es_419.po)
- Chile variant (es_CL.po)
- 8 Spain localization modules (l10n_es*)
- Weblate integration for translations

### Enhancement Plan

#### Phase 1: Guatemala Localization Module

**Create:** `addons/l10n_gt/` (Guatemala Localization)
```
addons/l10n_gt/
├── __manifest__.py
├── __init__.py
├── data/
│   ├── account_chart_template.xml
│   ├── account_tax_template.xml
│   ├── res_country_state.xml
│   └── l10n_gt_chart_data.xml
├── models/
│   ├── __init__.py
│   ├── account_chart_template.py
│   └── res_partner.py
├── views/
│   └── res_partner_views.xml
├── i18n/
│   └── es_GT.po
└── static/
    └── description/
        └── icon.png
```

**Create:** `addons/l10n_gt/__manifest__.py`
```python
{
    'name': 'Guatemala - Contabilidad (Garfenter)',
    'version': '1.0',
    'category': 'Accounting/Localizations/Account Charts',
    'description': '''
        Plan contable guatemalteco para Garfenter Empresa.

        Incluye:
        - Plan de cuentas según NIIF Guatemala
        - Impuestos (IVA 12%)
        - Departamentos de Guatemala
        - Formato de NIT
        - Factura Electrónica FEL (preparado)
    ''',
    'author': 'Garfenter',
    'website': 'https://garfenter.com',
    'depends': ['account', 'base_address_extended'],
    'data': [
        'data/res_country_state.xml',
        'data/account_chart_template.xml',
        'data/account_tax_template.xml',
        'views/res_partner_views.xml',
    ],
    'license': 'LGPL-3',
}
```

#### Phase 2: Guatemala Tax Configuration

**Create:** `addons/l10n_gt/data/account_tax_template.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- IVA 12% Ventas -->
    <record id="gt_tax_iva_12_sale" model="account.tax.template">
        <field name="name">IVA 12% (Ventas)</field>
        <field name="description">IVA</field>
        <field name="amount">12</field>
        <field name="type_tax_use">sale</field>
        <field name="tax_group_id" ref="account.tax_group_taxes"/>
        <field name="invoice_repartition_line_ids" eval="[
            (0, 0, {'factor_percent': 100, 'repartition_type': 'base'}),
            (0, 0, {'factor_percent': 100, 'repartition_type': 'tax'}),
        ]"/>
    </record>

    <!-- IVA 12% Compras -->
    <record id="gt_tax_iva_12_purchase" model="account.tax.template">
        <field name="name">IVA 12% (Compras)</field>
        <field name="description">IVA</field>
        <field name="amount">12</field>
        <field name="type_tax_use">purchase</field>
        <field name="tax_group_id" ref="account.tax_group_taxes"/>
    </record>

    <!-- Exento de IVA -->
    <record id="gt_tax_exempt" model="account.tax.template">
        <field name="name">Exento de IVA</field>
        <field name="amount">0</field>
        <field name="type_tax_use">sale</field>
    </record>
</odoo>
```

#### Phase 3: Guatemala Departments

**Create:** `addons/l10n_gt/data/res_country_state.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <record id="state_gt_gu" model="res.country.state">
        <field name="name">Guatemala</field>
        <field name="code">GU</field>
        <field name="country_id" ref="base.gt"/>
    </record>
    <record id="state_gt_av" model="res.country.state">
        <field name="name">Alta Verapaz</field>
        <field name="code">AV</field>
        <field name="country_id" ref="base.gt"/>
    </record>
    <!-- ... all 22 departments -->
    <record id="state_gt_qz" model="res.country.state">
        <field name="name">Quetzaltenango</field>
        <field name="code">QZ</field>
        <field name="country_id" ref="base.gt"/>
    </record>
</odoo>
```

---

## 2. CONTAINERIZATION PLAN

### Current Status: NO DOCKER ✗
- Uses Debian packaging
- SystemD service configuration
- No official Docker support

### Implementation Plan

#### Phase 1: Docker Configuration

**Create:** `Dockerfile`
```dockerfile
# Garfenter Empresa - Odoo Docker Image
FROM python:3.12-slim-bookworm

LABEL maintainer="Garfenter <soporte@garfenter.com>"
LABEL description="Garfenter Empresa - ERP para Latinoamérica"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libldap2-dev \
    libpng-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxslt1-dev \
    node-less \
    npm \
    postgresql-client \
    python3-dev \
    wkhtmltopdf \
    xfonts-75dpi \
    xfonts-base \
    && rm -rf /var/lib/apt/lists/*

# Install RTL CSS support
RUN npm install -g rtlcss

# Create odoo user
RUN useradd -m -s /bin/bash odoo

# Set working directory
WORKDIR /opt/odoo

# Copy Odoo source
COPY --chown=odoo:odoo . /opt/odoo

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy Garfenter addons
COPY --chown=odoo:odoo addons/l10n_gt /opt/odoo/addons/l10n_gt

# Copy Garfenter configuration
COPY --chown=odoo:odoo odoo.garfenter.conf /etc/odoo/odoo.conf

# Set permissions
RUN chown -R odoo:odoo /opt/odoo

USER odoo

EXPOSE 8069 8072

# Garfenter environment defaults
ENV GARFENTER_LANG=es_GT
ENV GARFENTER_COUNTRY=GT
ENV GARFENTER_CURRENCY=GTQ
ENV GARFENTER_TIMEZONE=America/Guatemala

CMD ["python", "odoo-bin", "-c", "/etc/odoo/odoo.conf"]
```

**Create:** `docker-compose.garfenter.yml`
```yaml
version: '3.8'

services:
  garfenter-empresa:
    build:
      context: .
      dockerfile: Dockerfile
    image: garfenter/empresa:latest
    container_name: garfenter-empresa
    ports:
      - "8069:8069"
      - "8072:8072"
    environment:
      - HOST=garfenter-postgres
      - USER=garfenter
      - PASSWORD=${DB_PASSWORD:-garfenter123}
      - GARFENTER_LANG=es_GT
      - GARFENTER_COUNTRY=GT
    volumes:
      - odoo-data:/var/lib/odoo
      - odoo-addons:/opt/odoo/custom-addons
    depends_on:
      - garfenter-postgres
    networks:
      - garfenter-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  garfenter-postgres:
    image: postgres:15-alpine
    container_name: garfenter-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=garfenter
      - POSTGRES_PASSWORD=${DB_PASSWORD:-garfenter123}
      - POSTGRES_DB=postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - garfenter-network
    restart: unless-stopped

  garfenter-nginx:
    image: nginx:alpine
    container_name: garfenter-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/odoo.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - garfenter-empresa
    networks:
      - garfenter-network
    restart: unless-stopped

networks:
  garfenter-network:
    driver: bridge

volumes:
  odoo-data:
  odoo-addons:
  postgres-data:
```

**Create:** `odoo.garfenter.conf`
```ini
[options]
; Garfenter Empresa Configuration

; Database
db_host = garfenter-postgres
db_port = 5432
db_user = garfenter
db_password = garfenter123
db_name = garfenter_empresa

; Paths
addons_path = /opt/odoo/addons,/opt/odoo/custom-addons
data_dir = /var/lib/odoo

; Server
http_port = 8069
longpolling_port = 8072
proxy_mode = True

; Logging
log_level = info
logfile = /var/log/odoo/odoo.log

; Workers (production)
workers = 4
max_cron_threads = 2

; Limits
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

; Garfenter Defaults
default_language = es_GT
default_country = GT
```

#### Phase 2: One-Click Start Script

**Create:** `garfenter-start.sh`
```bash
#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║      GARFENTER EMPRESA - ERP Suite       ║"
echo "║      Iniciando servicios...              ║"
echo "╚══════════════════════════════════════════╝"

# Create .env if needed
if [ ! -f .env ]; then
    cat > .env << EOF
DB_PASSWORD=$(openssl rand -hex 16)
ADMIN_PASSWORD=$(openssl rand -hex 16)
EOF
    echo "✓ Archivo .env creado"
    echo "  Contraseña admin: $(grep ADMIN_PASSWORD .env | cut -d= -f2)"
fi

source .env

# Build and start
docker-compose -f docker-compose.garfenter.yml up -d --build

# Wait for database
echo "Esperando base de datos..."
sleep 15

# Initialize database with Guatemala localization
docker-compose -f docker-compose.garfenter.yml exec -T garfenter-empresa \
    python odoo-bin -c /etc/odoo/odoo.conf \
    -d garfenter_empresa \
    -i l10n_gt,base,web \
    --load-language=es_GT \
    --stop-after-init

echo ""
echo "✓ Garfenter Empresa iniciado correctamente!"
echo ""
echo "Accesos:"
echo "  - Odoo:          http://localhost:8069"
echo "  - Base de datos: garfenter_empresa"
echo ""
echo "Primer inicio de sesión:"
echo "  - Usuario: admin"
echo "  - Contraseña: admin (cambiar después)"
echo ""
```

---

## 3. PERSONALIZATION/BRANDING PLAN

### Current Status
- Odoo branding with configurable company settings
- Logo, colors, fonts stored in res.company

### Implementation Plan

#### Phase 1: Garfenter Web Module

**Create:** `addons/garfenter_branding/`
```
addons/garfenter_branding/
├── __manifest__.py
├── __init__.py
├── static/
│   ├── src/
│   │   ├── css/
│   │   │   └── garfenter_theme.css
│   │   └── img/
│   │       ├── garfenter-logo.png
│   │       ├── garfenter-logo-white.png
│   │       └── garfenter-favicon.ico
│   └── description/
│       └── icon.png
├── views/
│   └── webclient_templates.xml
└── data/
    └── res_company_data.xml
```

**Create:** `addons/garfenter_branding/__manifest__.py`
```python
{
    'name': 'Garfenter Branding',
    'version': '1.0',
    'category': 'Hidden/Tools',
    'summary': 'Garfenter visual branding for Odoo',
    'description': '''
        Personalización visual de Garfenter Empresa:
        - Logo Garfenter
        - Colores corporativos
        - Favicon personalizado
        - Textos en español
    ''',
    'author': 'Garfenter',
    'website': 'https://garfenter.com',
    'depends': ['web', 'base'],
    'data': [
        'views/webclient_templates.xml',
        'data/res_company_data.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'garfenter_branding/static/src/css/garfenter_theme.css',
        ],
    },
    'auto_install': True,
    'license': 'LGPL-3',
}
```

#### Phase 2: Theme CSS

**Create:** `addons/garfenter_branding/static/src/css/garfenter_theme.css`
```css
/* Garfenter Empresa Theme */

:root {
    --garfenter-primary: #1E3A8A;
    --garfenter-accent: #F59E0B;
    --garfenter-success: #059669;
    --garfenter-text: #374151;
}

/* Navbar */
.o_main_navbar {
    background-color: var(--garfenter-primary) !important;
}

/* Buttons */
.btn-primary {
    background-color: var(--garfenter-primary) !important;
    border-color: var(--garfenter-primary) !important;
}

.btn-primary:hover {
    background-color: #1E40AF !important;
    border-color: #1E40AF !important;
}

/* Links */
a {
    color: var(--garfenter-primary);
}

/* Login page */
.o_login_auth {
    background-color: var(--garfenter-primary);
}

/* Sidebar */
.o_web_client .o_action_manager .o_kanban_view .o_kanban_record {
    border-left: 3px solid var(--garfenter-accent);
}
```

#### Phase 3: Default Company Data

**Create:** `addons/garfenter_branding/data/res_company_data.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Update main company -->
    <record id="base.main_company" model="res.company">
        <field name="name">Garfenter Empresa</field>
        <field name="logo" type="base64" file="garfenter_branding/static/src/img/garfenter-logo.png"/>
        <field name="primary_color">#1E3A8A</field>
        <field name="secondary_color">#F59E0B</field>
        <field name="font">Inter</field>
        <field name="report_header">Garfenter - Tecnología para Latinoamérica</field>
        <field name="report_footer">www.garfenter.com | soporte@garfenter.com</field>
        <field name="country_id" ref="base.gt"/>
        <field name="currency_id" ref="base.GTQ"/>
    </record>
</odoo>
```

---

## 4. GUATEMALA-SPECIFIC FEATURES

### Electronic Invoicing (FEL)
```python
# Future: addons/l10n_gt_edi_fel/
# Integration with SAT Guatemala's FEL system
# Providers: Infile, G4S, Digifact
```

### NIT Validation
```python
# addons/l10n_gt/models/res_partner.py
def validate_nit_gt(nit):
    """Validate Guatemala NIT format"""
    # Remove hyphens and spaces
    nit = nit.replace('-', '').replace(' ', '')

    if len(nit) < 8 or len(nit) > 9:
        return False

    # Calculate check digit
    # ... NIT algorithm
    return True
```

---

## 5. IMPLEMENTATION TIMELINE

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 1 | Docker configuration | 3 days | HIGH |
| 2 | l10n_gt module | 5 days | HIGH |
| 3 | Garfenter branding module | 2 days | MEDIUM |
| 4 | One-click script | 1 day | HIGH |
| 5 | Testing | 3 days | HIGH |
| 6 | Documentation ES | 2 days | MEDIUM |

**Total Estimated Time:** 2-3 weeks

---

## 6. FILES TO CREATE/MODIFY

### New Files
- [ ] `Dockerfile`
- [ ] `docker-compose.garfenter.yml`
- [ ] `odoo.garfenter.conf`
- [ ] `garfenter-start.sh`
- [ ] `.env.example`
- [ ] `addons/l10n_gt/` (complete module)
- [ ] `addons/garfenter_branding/` (complete module)
- [ ] `nginx/odoo.conf`

### Files to Modify
- [ ] `requirements.txt` - Add any missing deps

---

## 7. SUCCESS METRICS

- [ ] Single command deployment working
- [ ] Spanish (Guatemala) as default
- [ ] GTQ currency configured
- [ ] 12% IVA taxes working
- [ ] Guatemala departments available
- [ ] Garfenter logo/colors visible
- [ ] All Odoo apps functional

---

*Plan Version: 1.0*
*Created for: Garfenter Product Suite*
*Target Market: Guatemala & Central America*
