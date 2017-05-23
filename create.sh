#!/bin/bash

helm install --name data --namespace tick ./influxdb/
helm install --name polling --namespace tick ./telegraf-s/
helm install --name hosts --namespace tick ./telegraf-ds/
helm install --name alerts --namespace tick ./kapacitor/
helm install --name dash --namespace tick ./chronograf/
kubectl get svc -w --namespace tick -l app=dash-chronograf
