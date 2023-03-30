# PHP Docker Setup

This project offers a Docker configuration for building a foundational image to utilize in your PHP projects. By implementing this, you can streamline your pipeline and save valuable time.

## Using this like an image base to develop mode
You can add `xdebug` to your develop container as follow:

1. Create your `.docker/services/webservice/php/extensions/xdebug.ini` file:
```ini
[xdebug]
zend_extension=xdebug
xdebug.mode=debug
xdebug.client_port=9003
xdebug.remote_port=9003
xdebug.discover_client_host=true
xdebug.remote_host=host.docker.internal
xdebug.idekey=VSCODE
xdebug.log=/dev/stdout
xdebug.remote_enable=on
xdebug.remote_autostart=on
xdebug.start_with_request=trigger
xdebug.coverage_enable=on
xdebug.coverage_enable_trigger=on
xdebug.remote_handler=dbgp
xdebug.connect_timeout_ms=2000
xdebug.start_upon_error=yes
xdebug.var_display_max_depth=10
xdebug.var_display_max_children=-1
xdebug.var_display_max_data=-1
xdebug.cli_color=1
xdebug.log_level=0
error_reporting=E_ALL
```

2. You need provide correct `PHP_VALUE` to Nginx in `/etc/nginx/conf.d/default.conf`. For that use this:
```bash
sed -i 's/.*PHP_VALUE.*/fastcgi_param PHP_VALUE "xdebug.mode=debug xdebug.start_with_request=trigger xdebug.client_port=9003 xdebug.discover_client_host=true";/' /etc/nginx/conf.d/default.conf
```

3. Install `php-xdebug` in your develop image. Add follow code in your development `Dockerfile`:
```Dockerfile
# example with php8.2-xdebug
RUN apt-get update && apt-get -f -y install php8.2-xdebug \
  && apt-get clean \
  && rm -Rrf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && phpdismod xdebug

COPY .docker/services/webservice/php/extensions/xdebug.ini /etc/php/${PHP_VERSION}/mods-available/xdebug.ini

RUN phpenmod xdebug
```