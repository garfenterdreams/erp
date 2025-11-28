# Garfenter ERP - Odoo Dockerfile
# Based on Python 3.12 for optimal performance

FROM python:3.12-slim-bookworm

LABEL maintainer="Garfenter Development Team"
LABEL description="Garfenter ERP - Enterprise Resource Planning System powered by Odoo"

# Set environment variables
ENV LANG=es_GT.UTF-8 \
    LC_ALL=es_GT.UTF-8 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base dependencies
    ca-certificates \
    curl \
    dirmngr \
    fonts-noto-cjk \
    gnupg \
    libssl-dev \
    npm \
    python3-magic \
    python3-num2words \
    python3-pdfminer \
    python3-pip \
    python3-phonenumbers \
    python3-pyldap \
    python3-qrcode \
    python3-renderpm \
    python3-setuptools \
    python3-slugify \
    python3-vobject \
    python3-watchdog \
    python3-xlrd \
    python3-xlwt \
    xz-utils \
    # Build dependencies
    build-essential \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    libjpeg-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # wkhtmltopdf for PDF generation
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
    # Install less via npm (avoiding node-uuid apt package issues)
    && npm install -g less less-plugin-clean-css

# Create odoo user
RUN useradd -ms /bin/bash odoo

# Set working directory
WORKDIR /opt/odoo

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy Odoo source code
COPY --chown=odoo:odoo . /opt/odoo

# Create necessary directories and copy config
RUN mkdir -p /var/lib/odoo \
    /etc/odoo \
    /mnt/extra-addons \
    && chown -R odoo:odoo /var/lib/odoo /etc/odoo /mnt/extra-addons

# Copy Odoo config file to the expected location
COPY --chown=odoo:odoo odoo.garfenter.conf /etc/odoo/odoo.conf

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set odoo as the user
USER odoo

# Set the default config file
ENV ODOO_RC=/etc/odoo/odoo.conf

# Start Odoo
CMD ["/opt/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf"]
