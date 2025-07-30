# Building images with Chainguard Custom Assembly vs Private APK

# Create a plugin using custom-assembly

First, ensure that you have the packages necessary for the argocd-plugin available in your private apk repo as well as the chainguard-base image. 

```bash
cat << EOF >> argocd-plugin.yaml
contents:
  packages:
    - jq
    - yq 
    - helm 
    - bash-binsh
    - curl
EOF
```

Then generate a package file and create the image we will use as our argocd plugin. We will use this plugin help the argocd repo server to authenticate with the chainguard registry to read charts.

```bash
ORG=ky-rafaels.example.com
REPO=custom-base
chainctl image repo build apply -f custom-assembly/argo-plugin-apks.yaml --parent $ORG --repo $REPO

# You can then check active and historical builds

chainctl image repo build list --parent $ORG --repo $REPO

# If you want to check build logs 
chainctl image repo build logs --parent $ORG --repo $REPO
```

# Use the private APK repo

Run an image and check what apk repo is already configured

```bash
# Because CA is enabled globally you will find only private APK repo
docker run -it --user root --rm --name py-test-1 --entrypoint /bin/sh cgr.dev/ky-rafaels.example.com/python:latest-dev

/# cat /etc/apk/repositories
https://virtualapk.cgr.dev/b25cd7fccd73dc9a14b3ec891625c5f172624a75/sha256:be64f1bf7ef7e49053e10b10595d8be404358fe8693b24739971e051b5a70c34/chainguard
https://virtualapk.cgr.dev/b25cd7fccd73dc9a14b3ec891625c5f172624a75/sha256:be64f1bf7ef7e49053e10b10595d8be404358fe8693b24739971e051b5a70c34/extra-packages
```

# Authenticating to Private APK 

If you do not have Custom-Assembly enabled in your registry for an image, you can setup authentication to your Private APK repo like so

```bash
cat << EOF > Dockerfile
FROM cgr.dev/chainguard/python:latest-dev

ARG PAPK_ORG="ky-rafaels.example.com"

USER root
RUN echo "https://apk.cgr.dev/\$PAPK_ORG" > /etc/apk/repositories 

RUN --mount=type=secret,id=cgr-token \
  sh -c "export HTTP_AUTH=basic:apk.cgr.dev:user:$(chainctl auth token --audience apk.cgr.dev) \
  apk update && apk add --no-cache curl jq yq helm curl"

USER 65532
EOF

docker build -t py-papk-build:v1 .
```

We can then also validate which repo a particular apk package was installed from

```bash
docker run -it --user root -e "HTTP_AUTH=basic:apk.cgr.dev:user:$(chainctl auth token --audience apk.cgr.dev)" --rm --entrypoint /bin/sh py-papk-build:v1

/# apk policy curl --no-cache
# ----OUTPUT----
fetch https://apk.cgr.dev/ky-rafaels.example.com/aarch64/APKINDEX.tar.gz
curl policy:
  8.15.0-r1:
    lib/apk/db/installed
```

### If you'd like to install a package from wolfi os package repo

```bash
cat << EOF > Dockerfile
ARG ORG="ky-rafaels.example.com"

FROM cgr.dev/${ORG}/python:latest-dev

USER root
RUN echo 'https://packages.wolfi.dev/os' >  /etc/apk/repositories && \
    wget -O /etc/apk/keys/wolfi-signing.rsa.pub https://packages.wolfi.dev/os/wolfi-signing.rsa.pub

RUN apk update && apk add --no-cache jq yq helm curl 

USER 65532
EOF

docker build -t py-wolfi-build:v1 .
```
