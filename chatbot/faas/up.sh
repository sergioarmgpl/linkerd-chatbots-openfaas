#!/bin/bash
export gateway="http://openfaas.curzona.net"
#rm -R build
docker login -u admin -p Harbor456 https://hub.cloudsociety.dev
faas-cli login -u admin -p kubeconeu123 --gateway $gateway
#faas-cli up --label "com.openfaas.scale.zero=true" --gateway $gateway
faas-cli up --gateway $gateway
faas-cli logout --gateway $gateway
docker logout https://hub.cloudsociety.dev
