#!/usr/bin/env bash

W_DIR='/var/www'

find ${W_DIR} -type f -exec chmod 664 {} \;
find ${W_DIR} -type d -exec chmod 775 {} \;

chgrp -R $(id ${NGINX_PHP_USER} -u) ${W_DIR}
chmod -R ug+rwx ${W_DIR}/storage ${W_DIR}/bootstrap/cache
chmod +x ${W_DIR}/vendor/bin/* 2>/dev/null
