#!/bin/bash

helm delete data polling hosts alerts dash --purge
kubectl delete ns tick