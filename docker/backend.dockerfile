FROM python:3.7-alpine

# Set env variables used in this Dockerfile
# Host directory with project source
ENV DOCKER_HOST_SRC=.
# Directory in container for source
ENV DOCKER_CONTAINER_SRC=/coraline

# Install psycopg2 prereqs
RUN apk update && apk add postgresql-dev gcc musl-dev

# Change workdir
WORKDIR $DOCKER_CONTAINER_SRC

# We copy just requirements files and run pip install
# prior to copying all the code so we can have a cached checkpoint here
# and not install requirements everytime we build container after
# our code changes

# Install Python dependencies
COPY $DOCKER_HOST_SRC/requirements ./requirements
RUN pip install -r requirements/base.txt

# Copy source
COPY $DOCKER_HOST_SRC .

# Prepare nginx config
# RUN rm /etc/nginx/sites-enabled/* && \
#     cp ./docker/nginx.conf /etc/nginx/sites-enabled/stepup.conf

# Prepare entrypoint
RUN mv docker/backend.entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Port to expose
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
