#!/bin/sh

# Go to project root
cd $DOCKER_CONTAINER_SRC

# Run tests or run server
if [ "$1" = "test" ]
then
    pip install -r requirements/test.txt
    python manage.py migrate --noinput
    exec pytest --cov=. --cov-report term-missing
elif [ "$1" = "lint" ]
then
    pip install -r requirements/test.txt
    exec flake8 .
elif [ "$1" = "shell" ]
then
    exec ash
elif [ "$1" = "shelltest" ]
then
    pip install -r requirements/test.txt
    python manage.py migrate --noinput
    exec ash
elif [ "$1" = "worker" ]
then
    python manage.py compilemessages
    exec celery -A coraline worker -l info
elif [ "$1" = "devserver" ]
then
    python manage.py migrate --noinput
    exec python manage.py runserver 0.0.0.0:80
else
    service nginx start
    cd $DOCKER_CONTAINER_SRC/apps/agent/saml/certs && python download_certs.py
    cd $DOCKER_CONTAINER_SRC
    python manage.py migrate --noinput
    python manage.py collectstatic --clear --no-input
    python manage.py compilemessages
    exec gunicorn -b 0.0.0.0:8000 -w $WORKERNUM -t 300 \
              --access-logfile - \
              --error-logfile - \
              coraline.wsgi:application
fi
