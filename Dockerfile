# PHP Dependencies
FROM composer:2.5.0 as vendor

WORKDIR /app
COPY ./src/composer.json /app/composer.json
COPY ./src/composer.lock /app/composer.lock
RUN composer config --global gitlab-token.nexus.nmscreative.com sW4wJiED4Ke7V1vSGesB
RUN composer install --ignore-platform-reqs --no-interaction --no-plugins --no-scripts --prefer-dist

# Application
FROM public.ecr.aws/h1y8m9v5/nmsph-php8.2
ENV HTTP_LOCAL_CONF nms.templates.backend.local.conf
ARG HTTP_LIVE_CONF live.backend.com.conf
ARG HTTP_STAGING_CONF staging.backend.com.conf

# Install Composer
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app

# Apache, Supervisord Configuration
COPY ./playbook/conf/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./playbook/conf/httpd_conf/$HTTP_LOCAL_CONF /etc/apache2/sites-available/
COPY ./playbook/conf/httpd_conf/$HTTP_LIVE_CONF /etc/apache2/sites-available/
COPY ./playbook/conf/httpd_conf/$HTTP_STAGING_CONF /etc/apache2/sites-available/
RUN a2enmod rewrite headers && service apache2 restart
RUN a2dissite 000-default.conf && a2ensite $HTTP_LOCAL_CONF

# Deploy Site
COPY --chown=www-data:www-data ./src /app
COPY --from=vendor /app/vendor/ /app/vendor/

# Exposed Ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]