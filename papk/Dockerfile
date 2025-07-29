ARG ORG="ky-rafaels.example.com"

FROM cgr.dev/${ORG}/python:latest-dev

USER root
ARG ORG
RUN echo "https://apk.cgr.dev/${ORG}" > /etc/apk/repositories

RUN --mount=type=secret,id=cgr-token sh -c "export HTTP_AUTH=basic:apk.cgr.dev:user:\$(cat /run/secrets/cgr-token) apk update && apk add --no-cache jq yq helm curl"

USER 65532
