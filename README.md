# `tick-charts`

This is a collection of [Helm](https://github.com/kubernetes/helm) [Charts](https://github.com/kubernetes/charts) for the [InfluxData](https://influxdata.com/time-series-platform) TICK stack. This repo contains the following charts:

- [influxdb](/influxdb/README.md)
- [chronograf](/chronograf/README.md)
- [kapacitor](/kapacitor/README.md)
- [telegraf-s](/telegraf-s/README.md)
- [telegraf-ds](/telegraf-ds/README.md)

### Manual deploy of the whole stack

- Have your `kubectl` tool configured for the cluster where you would like to deploy the stack.
- Have `helm` and `tiller` installed and configured
  - Download and configure the `helm` cli
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md)
  - Run `helm init` to install `tiller` in your cluster
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md#installing-tiller)
- Install the charts:
```bash
$ cd tick-charts
$ helm install --name data --namespace tick ./influxdb/
$ helm install --name polling --namespace tick ./telegraf-s/
$ helm install --name hosts --namespace tick ./telegraf-ds/
$ helm install --name alerts --namespace tick ./kapacitor/
$ helm install --name dash --namespace tick ./chronograf/
```
- Wait for the IP for chronograf to appear:
```bash
$ kubectl get svc -w --namespace tick -l app=dash-chronograf
```
- Open chronograf in your browser and configure it
  - InfluxDB URL: `http://data-influxdb.tick:8086`
  - Kapacitor URL: `http://alerts-kapacitor.tick:9092`
  

#### AWS EKS:

EKS requires external Loadbalancers to expose your service. Corresponding script changes service type to `LoadBalancer` 
together with helm init and tiller deployment.
As a result the EKS Control Plane creates external LoadBalancer(s) in public subnet and additional costs 
to your account may be incurred.

##### Requirements:
 - helm binary already installed in path
 - EKS cluster with available workers
 - kubectl tool in path with working configuration

##### Usage:
just run `./create.sh` and let the shell script do it for you! 

- ./create.sh -s $services -a $action -p $provider
  - Options:   
    -s services:  The name of the component. 
    Valid options are `influxdb`, `kapacitor`, `telegraf-s`, `telegraf-ds`, `chronograf` and `all`   
    -a action: Valid options are `create` and `destroy`   
    -p provider: Valid options is `aws-eks`
    
##### Examples:
 - To execute all components from `single command`:

    	./create.sh -s all -a create -p aws-eks
    	./create.sh -s all -a destroy -p aws-eks
        
 - To execute `individual command`:
 
        ./create.sh -s influxdb -s kapacitor -s ... -a create -p aws-eks
        ./create.sh -s influxdb -s kapacitor -s ... -a destroy -p aws-eks
      
### Usage

To package any of the charts for deployment:

```bash
$ helm package /path/to/chart
```

This will create a file named `{{ .Chart.Name }}-{{ .Chart.Version }}.tgz` that is the chart file to be deployed. The default configurations are listed in the `values.yaml` file in the root of each repo. To deploy the chart with some default values create your custom `values.yaml` file to change the default configuration or modify the `values.yaml` file at the root of the chart before packaging it:

```bash
$ helm install telegraf-0.1.0.tgz --name {{ .Release.Name }} --namespace {{ .Release.Namespace }} --values /path/to/my_values.yaml
```

#### Using InfluxData's Helm repo

All the charts are also available in InfluxData's Helm repository. You can use it as so:

```
$ helm repo add influx http://influx-charts.storage.googleapis.com
$ helm install influx/telegraf-ds
```

### Contributing

If you are interested in contributing to this effort, we ask that you review and sign the [Contributor License Agreement](https://www.influxdata.com/legal/).  
There is an individual and corporate level agreement.  Please review which is right based on your situation.
