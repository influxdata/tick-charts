#!/bin/bash
## in case your custom PATH (to helm) is defined in .rc files
# source ~/.bashrc
# source ~/.zshrc

function main
{
	initScript "$@"

	echo "Services:" ${SERVICES[@]:-all}
	echo "Action:" $ACTION

	if [[ $PROVIDER == 'aws-eks' ]]; then
		echo "Provider:" $PROVIDER
		#chart_execution $ACTION $PROVIDER $SERVICE
		scripts/aws-eks.sh $ACTION ${SERVICES[@]}

	elif [[ $PROVIDER == 'minikube' ]]; then
	    echo "Provider:" $PROVIDER
		#chart_execution $ACTION $PROVIDER $SERVICE
		scripts/minikube.sh $ACTION ${SERVICES[@]}

	elif [[ $PROVIDER == '' ]]; then
		echo "Provider name is empty"
	else
		echo "Provider name is not valid !!!"
	fi
}

function usage
{
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

function initScript
{
	PROVIDER="minikube"
	ACTION="create"
	SERVICES=""
	while getopts h:a:p:s: opt
		do
			case "$opt" in
				h) usage "";exit 1;;
				p) PROVIDER=$OPTARG;;
				a) ACTION=$OPTARG;;
				s) SERVICES+=($OPTARG);;
				\?) usage "";exit 1;;
			esac
		done

}
main "$@"