#!/usr/bin/env bash

if [ ${USERID} -gt 0 ]; then
    usermod -u "${USERID}" "${USERNAME}"
fi

if [ ${#} -gt 0 ]; then
    exec gosu "${USERID}" "${@}"
else
    chmod a+x /usr/bin/before-start
    /usr/bin/before-start 2>/dev/null
    service $PHP_SERVICE_NAME start \
    && nginx -g "daemon off;"
fi
