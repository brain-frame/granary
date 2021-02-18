FROM python:3.9.1-alpine3.12
ARG folder=granary
USER root
RUN adduser -S amanitore

RUN apk update && apk upgrade && apk add bash

USER amanitore

WORKDIR /${folder}
