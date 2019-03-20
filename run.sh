#!/bin/bash
## in case your custom PATH (to helm) is defined in .rc files
# source ~/.bashrc
# source ~/.zshrc

function usage {
	cat <<EOF

    Usage:
        -p provider: Valid options are minikube, aws-eks
        -a action: Valid options are create, destroy, prune_resources
        -s services: The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf or all
    Examples:
        ./run.sh [-a create -s all -p minikube]
        ./run.sh -s influxdb -a create [-p minikube]
        ./run.sh -s influxdb -a destroy [-p minikube]
        ./run.sh -a prune_resources [-p minikube]
        ./run.sh -s all -a create -p aws-eks
        ./run.sh -s all -a destroy -p aws-eks
EOF
}

function initScript {
	PROVIDER="minikube"
	ACTION="create"
	NAMESPACE="tick"
	DIR="$(dirname "$(readlink -f "$0")")"

	while getopts ha:p:s: opt; do
        case "$opt" in
            p) PROVIDER=$OPTARG
                ;;
            a) ACTION=$OPTARG
                ;;
            s) USER_SERVICES+=($OPTARG)
                ;;
            h|*)
                usage
                exit 1
                ;;
        esac
    done

    USER_SERVICES=(${USER_SERVICES[@]/all/})
	SERVICES=(${USER_SERVICES[@]:-influxdb telegraf-s telegraf-ds kapacitor chronograf})
}

function main {
    initScript "$@"

	echo "Services:" ${SERVICES[@]}
	echo "Action:" ${ACTION}

    case ${PROVIDER} in
        minikube)
            SERVICE_TYPE="NodePort"
            ;;
        aws-eks)
            SERVICE_TYPE="LoadBalancer"
            ;;
        *)
            echo "Provider ${PROVIDER} is not valid !!!"
            exit 1
            ;;
    esac

	case ${ACTION} in
        create)
            # create kube state metrics
            kubectl create namespace "${NAMESPACE}"
            kubectl apply -f "${DIR}/scripts/resources/default.yaml"
            kubectl config set-context $(kubectl config current-context) --namespace="${NAMESPACE}"
            # Initialize the helm in the cluster
            helm init --wait --service-account tiller --kube-context $(kubectl config current-context)
            # create charts
            for s in ${SERVICES[@]}; do
                create_chart ${s}
            done
            ;;
        destroy)
            # destroy charts
            for s in ${SERVICES[@]}; do
                destroy_chart ${s}
            done
            ;;
        prune_resources)
            helm reset --kube-context $(kubectl config current-context)
            kubectl delete -f "${DIR}/scripts/resources/default.yaml"
            kubectl delete namespaces "${NAMESPACE}"
            kubectl config set-context $(kubectl config current-context) --namespace=kube-system
            ;;
        *)
            echo "Action ${ACTION} is not valid !!!"
            exit 1
            ;;
    esac

}

function print_service_url {
        local service=$1
        local service_alias=$2
        local service_ports=()
        local service_ip=""
        local service_urls=()

        case ${PROVIDER} in
            minikube)
                service_ports+=($(kubectl describe svc ${service_alias}-${service} | grep "NodePort:" | awk '{print $3}' | tr -d /TCP))
                service_ip=$(sudo minikube ip)
                for port in ${service_ports[@]}; do
                    service_urls+=("${service_ip}:${port}")
                done
                ;;
            aws-eks)
                service_urls+=($(kubectl describe svc ${service_alias}-${service} | grep "Ingress" | awk '{print $3}'))
                ;;
        esac

        printf "\n\n=======================================================================\n"
        for url in ${service_urls[@]}; do
            echo "${service} Endpoint URL:" ${url}
        done
        printf "=======================================================================\n\n"
}

function replace_service_type {
    local service=$1

    sed -i "s/\(type:\s\)\(.*\)/\1${SERVICE_TYPE}/" "${DIR}/${service}/values.yaml"
}

function create_chart {
    local service="$1"
	local service_alias=""

	echo "Creating chart for" "${service}"
	case ${service} in
        influxdb)
            service_alias="data"
	        replace_service_type ${service}
		    deploy_service ${service_alias} ${service}
		    sleep 120;
	        print_service_url ${service} ${service_alias}
            ;;
        kapacitor)
            service_alias="alerts"
	        replace_service_type ${service}
		    deploy_service ${service_alias} ${service}
		    sleep 120;
	        print_service_url ${service} ${service_alias}
            ;;
        chronograf)
            service_alias="dash"
	        replace_service_type ${service}
		    deploy_service ${service_alias} ${service}
		    sleep 120;
	        print_service_url ${service} ${service_alias}
            ;;
        telegraf-s)
            service_alias="polling"
		    deploy_service ${service_alias} ${service}
            ;;
        telegraf-ds)
            service_alias="hosts"
		    deploy_service ${service_alias} ${service}
            ;;
        *)
            echo "Service ${service} is not valid !!!"
            exit 1
            ;;
    esac
}

function deploy_service {
	local service_alias="$1"
	local service="$2"

	echo "Deploying ${service} ....."
	helm install --name "${service_alias}" --namespace "${NAMESPACE}" "${DIR}/${service}"
}

function destroy_chart {
    local service="$1"
	local service_alias=""

	echo "Destroying chart of" "${service}"
	case ${service} in
        influxdb)
            service_alias="data"
		    helm delete ${service_alias} --purge
            ;;
        kapacitor)
            service_alias="alerts"
	        helm delete ${service_alias} --purge
            ;;
        chronograf)
            service_alias="dash"
	        helm delete ${service_alias} --purge
            ;;
        telegraf-s)
            service_alias="polling"
		    helm delete ${service_alias} --purge
            ;;
        telegraf-ds)
            service_alias="hosts"
		    helm delete ${service_alias} --purge
            ;;
        *)
            echo "Service ${service} is not valid !!!"
            exit 1
            ;;
    esac
    sleep 60;
}

main "$@"