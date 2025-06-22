# 1) Usa la variante slim de Debian bookworm, parcheada:
FROM php:8.3-cli

# 2) Obligamos a que todos los paquetes del OS queden a la última:
RUN apt-get update \
 && apt-get dist-upgrade -y \  
 # 3) Instalamos sólo las dependencias necesarias
 && apt-get install -y --no-install-recommends \
    libpq-dev \
    libzip-dev \
    unzip \
    git \
 && docker-php-ext-configure zip \
 && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_pgsql \
    zip \
 # 4) Limpiamos caches de apt para reducir la superficie
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# 5) Traemos Composer desde su imagen oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./

# Permite que Composer ejecute plugins (Symfony Flex) aun siendo root
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-scripts

# 3) Copiamos el resto del proyecto
COPY . .

# 4) Ahora sí podemos limpiar y precalentar caché
# RUN php bin/console cache:clear --no-warmup --env=prod \
# && php bin/console cache:warmup --env=prod

EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
