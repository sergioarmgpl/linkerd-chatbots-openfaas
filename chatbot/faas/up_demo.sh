#!/bin/bash
export gateway="http://openfaas.curzona.net"
#rm -R build
docker login -u admin -p Harbor456 https://hub.cloudsociety.dev
faas-cli login -u admin -p kubeconeu123 --gateway $gateway
faas-cli build -f ./stack.yml
faas-cli push -f ./stack.yml
#faas-cli up --label "com.openfaas.scale.zero=true" --gateway $gateway

#faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-green
#faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-blue
#faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-root
#faas-cli up --gateway $gateway
#faas-cli logout --gateway $gateway
docker logout https://hub.cloudsociety.dev
