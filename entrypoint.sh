#!/usr/bin/env sh

# Make sure all environment variables are set correctly for cron
printenv | grep -v "no_proxy" >> /etc/environment

# Start php-fpm and nginx services
php-fpm -RD

# Start caddy
caddy run --config /Caddyfile

# Nice way of keeping container alive while also providing logs to docker
#touch /project/storage/logs/laravel.log
#touch /var/log/cron.log
#touch /var/log/php81/error.log

# Start cron service
#crond

#supervisord -c /supervisord.ini
