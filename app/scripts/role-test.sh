#!/bin/bash

echo "Role : dev-admin"
kubectl auth can-i create deployments --as Jules -n dev
kubectl auth can-i delete services --as Vadim -n dev

echo "Role : dev-pod-reader"
kubectl auth can-i list pods --as Alice -n dev
kubectl auth can-i delete pods --as Eleonore -n dev

echo "Role : dev-service-manager"
kubectl auth can-i create services --as Michel -n dev
kubectl auth can-i list pods --as Arthur -n dev

echo "Role : dev-configmap-manager"
kubectl auth can-i create configmaps --as Celia -n dev
kubectl auth can-i delete deployments --as Celia -n dev

