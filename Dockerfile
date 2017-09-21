# base image
FROM techdivision/dnmp-debian

# define labels
LABEL maintainer="j.zelger@techdivision.com"

# define composer magento repo credentials args
ARG MAGENTO_REPO_USERNAME=""
ARG MAGENTO_REPO_PASSWORD=""

# define magento install args
ARG MAGENTO_INSTALL_ADMIN_EMAIL="admin@magento.com"
ARG MAGENTO_INSTALL_ADMIN_USER="admin"
ARG MAGENTO_INSTALL_ADMIN_PASSWORD="admin123"
ARG MAGENTO_INSTALL_ADMIN_FIRSTNAME="Magento"
ARG MAGENTO_INSTALL_ADMIN_LASTNAME="Admin"
ARG MAGENTO_INSTALL_ADMIN_USE_SECURITY=1
ARG MAGENTO_INSTALL_BASE_URL="http://localhost/"
ARG MAGENTO_INSTALL_BASE_URL_SECURE="https://localhost/"
ARG MAGENTO_INSTALL_BACKEND_FRONTNAME="admin"
ARG MAGENTO_INSTALL_DB_HOST="localhost"
ARG MAGENTO_INSTALL_DB_NAME="magento"
ARG MAGENTO_INSTALL_DB_USER="magento"
ARG MAGENTO_INSTALL_DB_PASSWORD="magento"
ARG MAGENTO_INSTALL_LANGUAGE="de_DE"
ARG MAGENTO_INSTALL_CURRENCY="EUR"
ARG MAGENTO_INSTALL_TIMEZONE="Europe/Berlin"
ARG MAGENTO_INSTALL_USE_REWRITES=1
ARG MAGENTO_INSTALL_USE_SECURE=1
ARG MAGENTO_INSTALL_USE_SECURE_ADMIN=1
ARG MAGENTO_INSTALL_SAMPLEDATA=0
ARG MAGENTO_INSTALL_EDITION="community"
ARG MAGENTO_INSTALL_VERSION="2.1.8"
ARG MAGENTO_INSTALL_STABILITY="stable"

# define envs
ENV COMPOSER_AUTH="{\"http-basic\": {\"repo.magento.com\": {\"username\": \"$MAGENTO_REPO_USERNAME\", \"password\": \"$MAGENTO_REPO_PASSWORD\"}}}"
ENV COMPOSER_NO_INTERACTION=1
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV MAGENTO_BIN="php -dmemory_limit=1024M /var/www/dist/bin/magento"

# copy fs
COPY fs /tmp/fs

# start install routine
RUN \
    # prepare filesystem
    mkdir /var/www && \

    # install prerequisites
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require hirak/prestissimo && \

    # create magento
    composer create-project --repository-url=https://repo.magento.com/ magento/project-$MAGENTO_INSTALL_EDITION-edition=$MAGENTO_INSTALL_VERSION --stability $MAGENTO_INSTALL_STABILITY /var/www/dist && \

    # setup magento database
    mysql_start && \
    echo "GRANT ALL PRIVILEGES ON *.* TO 'magento'@'localhost' IDENTIFIED BY 'magento' WITH GRANT OPTION;"  | mysql --protocol=socket -uroot && \
    echo "CREATE DATABASE magento DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" | mysql --protocol=socket -uroot && \

    # install magento
    php /var/www/dist/bin/magento setup:install \
        --admin-firstname="$MAGENTO_INSTALL_ADMIN_FIRSTNAME" \
        --admin-lastname="$MAGENTO_INSTALL_ADMIN_LASTNAME" \
        --admin-email="$MAGENTO_INSTALL_ADMIN_EMAIL" \
        --admin-user="$MAGENTO_INSTALL_ADMIN_USER" \
        --admin-password="$MAGENTO_INSTALL_ADMIN_PASSWORD" \
        --admin-use-security-key="$MAGENTO_INSTALL_ADMIN_USE_SECURITY" \
        --backend-frontname="$MAGENTO_INSTALL_BACKEND_FRONTNAME" \
        --base-url="$MAGENTO_INSTALL_BASE_URL" \
        --base-url-secure="$MAGENTO_INSTALL_BASE_URL_SECURE" \
        --db-host="$MAGENTO_INSTALL_DB_HOST" \
        --db-name="$MAGENTO_INSTALL_DB_NAME" \
        --db-user="$MAGENTO_INSTALL_DB_USER" \
        --db-password="$MAGENTO_INSTALL_DB_PASSWORD" \
        --language="$MAGENTO_INSTALL_LANGUAGE" \
        --currency="$MAGENTO_INSTALL_CURRENCY" \
        --timezone="$MAGENTO_INSTALL_TIMEZONE" \
        --use-rewrites="$MAGENTO_INSTALL_USE_REWRITES" \
        --use-secure="$MAGENTO_INSTALL_USE_SECURE" \
        --use-secure-admin="$MAGENTO_INSTALL_USE_SECURE_ADMIN" && \

    # check if sampledata should be deployed
    if [ "$MAGENTO_INSTALL_SAMPLEDATA" = 1 ]; then \
        $MAGENTO_BIN sampledata:deploy && $MAGENTO_BIN setup:upgrade; \
    fi && \

    # tear down
    mysql_stop && \

    # rollout fs
    cp -r /tmp/fs/. / && \

    # cleanup
    rm -rf /tmp/* && \
    rm -rf /etc/nginx/conf.d/default.conf

# define entrypoing
ENTRYPOINT ["/entrypoint.sh"]

# expose available ports
EXPOSE 80 81 443 3306 5671 5672 6379 9200 9300

# define default cmd
CMD ["/usr/local/bin/supervisord", "--nodaemon", "-c", "/etc/supervisord.conf"]