#!/bin/bash
set -e

# define vars
MAGENTO_BIN="php /var/www/dist/bin/magento";
: ${MAGENTO_BASE_URL:="localhost"};

# start mysql
mysql_start;

# set correct base_urls
${MAGENTO_BIN} setup:store-config:set --base-url="http://${MAGENTO_BASE_URL}";
${MAGENTO_BIN} setup:store-config:set --base-url-secure="https://${MAGENTO_BASE_URL}";

# flush cache
${MAGENTO_BIN} cache:flush;

# stop mysql
mysql_stop;

# call CMD
exec "$@"
