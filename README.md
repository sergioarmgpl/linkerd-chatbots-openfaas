# Service Mesh and Serverless Chatbots with Linkerd, K8s and OpenFaaS - Lab

## Kubernetes Cluster Creation
1. Create a Digital Ocean k8s cluster
2. Instalar Kubectl
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

# Installing OpenFaaS
## Helm Installation and configuration
Download and install helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
Adding some useful charts to helm
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```
Adding OpenFaaS Helm Chart
```
helm repo add openfaas https://openfaas.github.io/faas-netes/
```
Some useful OpenFaaS documentation:
- Source: https://docs.openfaas.com/deployment/kubernetes/
Chart
- Readme: https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md
- Helm readme: https://github.com/openfaas/faas-netes/blob/master/HELM.md
- Detail: https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md
Creating OpenFaaS Namespace:
```
kubectl create ns openfaas 
```
Installing nginx-ingress to give public access to openfaas
```
helm install nginx-ingress --namespace openfaas stable/nginx-ingress
```
Creating default user and password login
```
kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-password=kubeconeu123 --from-literal=basic-auth-user=admin
```
## Create values.yaml file
```
async: "false"
basic_auth: "false"
faasIdler: 
  dryRun: "false"
  inactivityDuration: "1m"
gateway: 
  readTimeout: "900s"
  replicas: "2"
  upstreamTimeout: "800s"
  writeTimeout: "900s"
queueWorker: 
  replicas: "2"    
functionNamespace: "openfaas"
```
# Suggested installation
```
helm install openfaas --namespace openfaas openfaas/openfaas -f values.yaml
```

## test just dry-run(optional)
```
helm install openfaas --namespace openfaas openfaas/openfaas -f values.yaml --dry-run    
```
## Check deployment
```
kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"
```
## Create ingress rule with nginx-ingress to expose OpenFaaS
```
kubectl create -f public-openfaas.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: public-openfaas
  namespace: openfaas
spec:
  rules:
    - host: openfaas.curzona.net
      http:
        paths:
          - backend:
              serviceName: gateway
              servicePort: 8080
            path: /
  # Optional section if you are using TLS
  tls:
      - hosts:
          - openfaas.curzona.net
        secretName: openfaas-cert
```

## Installing faas cli
```
curl -sSL https://cli.openfaas.com | sudo sh
```
## login to OpenFaaS via CLI
```
faas-cli login --username admin --password kubeconeu123 --gateway openfaas.curzona.net 
```
## OpenFaaS Logout
```
faas-cli logout
```
Note: use the option --tls-no-verify for self signed certifies

# Linkerd installation
Steps
```
curl -sL https://run.linkerd.io/install | sh
```
```
export PATH=$PATH:$HOME/.linkerd2/bin
```
```
linkerd version
```
```
linkerd check --pre
```
```
linkerd install | kubectl apply -f -
```
```
linkerd check
```
```
kubectl -n linkerd get deploy
```
```
linkerd dashboard
```
## Securing the Linkerd dashboard
```
htpasswd -c auth admin    [Enter password for admin, stored in the auth file]
```
```
kubectl -n linkerd create secret generic basic-auth --from-file auth 
```

  annotations:
    # type of authentiation 
    nginx.ingress.kubernetes.io/auth-type: basic
    # secret reference that contins the credential detals
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;

kubectl -n linkerd create -f public-linkerd.yaml

Tutorial Bot
https://github.com/slackapi/python-slackclient/blob/master/tutorial/03-responding-to-slack-events.md
https://readthedocs.org/projects/python-slackclient/downloads/pdf/latest/
apt-get install python3-dev
apt-get install python3-pip

FaaS
apt-get install docker.io
mkdir faas
cd faas
faas template pull https://github.com/openfaas-incubator/python-flask-template
faas new --lang python3-flask chatbot


## Crear Bot
1. Create a Slack app(https://api.slack.com/apps/new) (if you don't already have one).
2. Add a Bot User and configure your bot user with some basic info (display name, default username and its online presence).
3. Once you've completed these fields, click Add Bot User.
4. Next, give your bot access to the Events API.
5. Finally, add your bot to your workspace.

## Se inyecta linkerd
```
kubectl -n openfaas get deploy gateway -o yaml | linkerd inject --skip-outbound-ports=4222 - | kubectl apply -f -
kubectl -n openfaas get deploy/basic-auth-plugin -o yaml | linkerd inject - | kubectl apply -f -
kubectl -n openfaas get deploy/faas-idler -o yaml | linkerd inject - | kubectl apply -f -
kubectl -n openfaas get deploy/queue-worker -o yaml | linkerd inject  --skip-outbound-ports=4222 - | kubectl apply -f -
```
```
kubectl annotate namespace openfaas linkerd.io/inject=enabled
```
Inject ingress controller
```
kubectl -n openfaas get deploy/nginx-ingress-controller -o yaml | linkerd inject - | kubectl apply -f -
```
Add the following in the annotations block
```
kubectl -n openfaas edit deployment nginx-ingress-controller
nginx.ingress.kubernetes.io/configuration-snippet: |
  proxy_set_header l5d-dst-override gateway.openfaas.svc.cluster.local:8080;
  proxy_hide_header l5d-remote-ip;
  proxy_hide_header l5d-server-id;
```
Deploy 3 services echo chatbot-root is a dummy service
```
faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-green
faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-blue
faas-cli deploy --gateway=http://openfaas.curzona.net --image hub.cloudsociety.dev/openfaas/chatbot:latest --name chatbot-root
```
Test the access to the services
```
curl http://openfaas.curzona.net/function/echo-green.openfaas
curl http://openfaas.curzona.net/function/echo-blue.openfaas
curl http://openfaas.curzona.net/function/echo.openfaas
```
## Inject the green and blue chatbots
```
kubectl get -n openfaas deployment chatbot-root -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```
```
kubectl get -n openfaas deployment chatbot-green -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```
```
kubectl get -n openfaas deployment chatbot-blue -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```
## Apply the traffic splitting rule
```
kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: function-split
  namespace: openfaas
spec:
  # The root service that clients use to connect to the destination application.
  service: chatbot-root
  # Services inside the namespace with their own selectors, endpoints and configuration.
  backends:
  - service: chatbot-blue
    weight: 500m
  - service: chatbot-green
    weight: 500m
```
## Sending traffic with a loop
```
for i in {0..10}; do  curl http://openfaas.curzona.net/function/echo.openfaas; done    
```
## Removing the traffic splitting
```
kubectl delete -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: function-split
  namespace: openfaas
spec:
  # The root service that clients use to connect to the destination application.
  service: echo
  # Services inside the namespace with their own selectors, endpoints and configuration.
  backends:
  - service: echo-blue
    weight: 100m
  - service: echo-green
    weight: 900m
```
# Resourses
[install linkerd2 with observability in OpenFaaS] (https://github.com/openfaas-incubator/openfaas-linkerd2)
