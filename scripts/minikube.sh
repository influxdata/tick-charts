#!/bin/bash

function main
{
	initScript "$@"
	dir="$(dirname "$(readlink -f "$0")")"
	root_dir="${dir%/scripts}"
	action="$1"
	shift
	user_services=(${@/all/})
	services=(${user_services[@]:-influxdb telegraf-s telegraf-ds kapacitor chronograf})
	namespace='tick'

	if [[ "$action" == 'create' ]]; then

		# create kube state metrics
		kubectl create namespace "$namespace"
		kubectl apply -f "$dir"/resources/eks-default.yaml
		kubectl config set-context $(kubectl config current-context) --namespace="$namespace"
		# Initialize the helm in the cluster
		helm init --wait --service-account tiller --kube-context $(kubectl config current-context)
		# create charts
        for s in ${services[@]}
        do
            create_chart "$s"
        done

	elif [[ "$action" == 'destroy' ]]; then

		# destroy charts
        for s in ${services[@]}
        do
            echo "$s"
            destroy_chart "$s"
        done

    elif [[ "$action" == 'prune_resources' ]]; then

        helm reset --kube-context $(kubectl config current-context)
        kubectl delete -f "$dir"/resources/eks-default.yaml
        kubectl delete namespaces tick
        kubectl config set-context $(kubectl config current-context) --namespace=kube-system

	else
		echo "Action is not valid !!!"
	fi
}

function create_chart
{
	service="$1"
    MINIKUBE_IP=$(minikube ip)

    echo "Creating chart for" "$service"
	if [[ "$service" == 'influxdb' ]]; then

		# Deploying influxdb service
		echo "Deploying $service ....."

		# replace ClusterIP to NodePort
		sed -i "s/\(type:\s\)\(.*\)/\1NodePort/" "$root_dir/$service/values.yaml"

		deploy_service data "$root_dir/$service"
		sleep 120;
		INFLUX_PORT+=($(kubectl describe svc data-influxdb | grep "NodePort:" | awk '{print $3}' | tr -d /TCP))

        printf "\n\n=======================================================================\n"
        for port in ${INFLUX_PORT[@]}; do
            echo "Influxdb Endpoint URL:" $MINIKUBE_IP:$port
        done
        printf "\n\n=======================================================================\n"

	elif [[ "$service" == 'kapacitor' ]]; then

		# Deploying kapacitor service
        echo "Deploying $service ....."

        # replace ClusterIP to NodePort
		sed -i "s/\(type:\s\)\(.*\)/\1NodePort/" "$root_dir/$service/values.yaml"

		deploy_service alerts "$root_dir/$service"
		sleep 120;
		KAPACITOR_PORT=$(kubectl describe svc alerts-kapacitor | grep "NodePort:" | awk '{print $3}' | tr -d /TCP)

		printf "\n\n=======================================================================\n"
		echo "Kapacitor Endpoint URL:" $MINIKUBE_IP:$KAPACITOR_PORT
		printf "\n\n=======================================================================\n"


	elif [[ "$service" == 'chronograf' ]]; then

		# Deploying chronograf service
		echo "Deploying Chronograf ....."

		# replace ClusterIP to NodePort
		sed -i "s/\(type:\s\)\(.*\)/\1NodePort/" "$root_dir/$service/values.yaml"

		deploy_service dash "$root_dir/$service"
		sleep 120;

		CHRONOGRAF_PORT=$(kubectl describe svc dash-chronograf | grep "NodePort:" | awk '{print $3}' | tr -d /TCP)

		printf "\n\n=======================================================================\n"
		echo "Chronograf Endpoint URL:" $MINIKUBE_IP:$CHRONOGRAF_PORT
		printf "\n=======================================================================\n"

	elif [[ "$service" == 'telegraf-s' ]]; then

		# Deploying telegraf-ds service
		deploy_service polling "$root_dir/$service"

	elif [[ "$service" == 'telegraf-ds' ]]; then

		# Deploying telegraf-ds service
		deploy_service hosts "$root_dir/$service"
	fi
}

function deploy_service
{
	service_alias="$1"
	service="$2"
	helm install --name "$service_alias" --namespace "$namespace" "$service"
}

function destroy_chart
{
	service="$1"
	echo "Destroying chart of" "$service"
	if [ "$service" == "influxdb" ]; then
		helm delete data --purge
	elif [ $service == "kapacitor" ]; then
		helm delete alerts --purge
	elif [ $service == "chronograf" ]; then
		helm delete dash --purge
	elif [ $service == "telegraf-s" ]; then
		helm delete polling --purge
	elif [ $service == "telegraf-ds" ]; then
		helm delete hosts --purge
	fi
	sleep 60;
}

function initScript
{
	echo "Tick Charts for Minikube"
}
main "$@"
