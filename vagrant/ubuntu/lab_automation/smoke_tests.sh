#!/bin/bash
HOSTNAME=$(hostname -s)

# Run this only on worker-2.
if [ "$HOSTNAME" != "worker-2" ]
then
  echo "This is not worker-2. Exiting."
  exit 0
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "Starting SMOKE TESTS of your k8s cluster ...."

# Test DNS
echo ""
echo "Run busybox container"
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

echo ""
echo "Waiting for the running busybox container (timeout 120s)..."
kubectl wait --for=jsonpath='{.status.phase}'=Running pod -l run=busybox --timeout=120s

echo
kubectl get pods -l run=busybox

echo
echo "Execute nslookup command inside the pod"
kubectl exec -i busybox -- nslookup kubernetes

# Test Deployment and Services
echo ""
echo "Create deployment"
kubectl create deployment nginx --image=nginx

echo ""
echo "Waiting for the nginx deployment to be available (timeout 120s) ..."
kubectl wait --for=condition=Available deployment -l app=nginx --timeout=120s

echo
kubectl get pods -l app=nginx

# Expose pod port 80 to the VirtualBox host-only network
echo
echo "Create a service by exposing pod port"
kubectl expose deploy nginx --type=NodePort --port 80
echo

# get the internal port number
PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
echo "Port number = ${PORT_NUMBER}"

# micro delay to wait for port to be exposed on both worker nodes
echo "sleep 5"
sleep 5

# test running nginx
echo
curl http://worker-1:$PORT_NUMBER | grep "Welcome"
echo
curl http://worker-2:$PORT_NUMBER | grep "Welcome"
echo

# get the pod name
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
echo "Pod name = ${POD_NAME}"

# get pod logs
# check if previous tests (running ngnix) was logged
kubectl logs $POD_NAME | grep "curl"

# clean up
echo ""
echo "Deleting created objects..."
kubectl delete svc nginx
kubectl delete deployment nginx
kubectl delete pod busybox

echo ""
echo "SMOKE TESTS completed!"
echo "Please review the log above. It should not contain any error messages."
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++"


