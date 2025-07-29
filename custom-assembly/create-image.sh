#!/bin/zsh

ORG=ky-rafaels.example.com

chainctl image repo build apply -f argo-plugin-apks.yaml \
    --parent ky-rafaels.example.com \
    --repo custom-base
