FROM python:3.9.1-alpine3.12
USER root
RUN adduser -S amanitore

RUN apk update && apk upgrade && apk add bash

USER amanitore

WORKDIR /granary
