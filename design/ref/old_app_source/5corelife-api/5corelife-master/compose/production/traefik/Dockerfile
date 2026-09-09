FROM traefik:v2.0

ARG WEB_DOMAIN
ENV WEB_DOMAIN $WEB_DOMAIN
ARG FLOWER_DOMAIN
ENV FLOWER_DOMAIN $FLOWER_DOMAIN
RUN mkdir -p /etc/traefik/acme
RUN touch /etc/traefik/acme/acme.json
RUN chmod 600 /etc/traefik/acme/acme.json
#COPY traefik.yml /etc/traefik
COPY ./compose/production/traefik/traefik.yml /etc/traefik
RUN sed -i "s/FLOWER_DOMAIN/$FLOWER_DOMAIN/g" /etc/traefik/traefik.yml
RUN sed -i "s/WEB_DOMAIN/$WEB_DOMAIN/g" /etc/traefik/traefik.yml
