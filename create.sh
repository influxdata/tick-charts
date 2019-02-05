#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"

	echo "Services:" ${SERVICES[@]:-all}
	echo "Action:" $ACTION

	if [[ $PROVIDER == 'aws-eks' ]]; then
		echo "Provider:" $PROVIDER
		#chart_execution $ACTION $PROVIDER $SERVICE
		scripts/aws-eks.sh $ACTION ${SERVICES[@]}

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
        -p provider: Valid option is aws-eks
        -a action: Valid options are create and destroy
        -s services: The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf or all
    Examples:
        ./create.sh -s influxdb -a create -p aws-eks
        ./create.sh -s influxdb -a destroy -p aws-eks

        ./create.sh -s all -a create -p aws-eks
        ./create.sh -s all -a delete -p aws-eks
EOF
}

function initScript
{
	PROVIDER=""
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