#!/bin/bash
# Terminal Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'
coffee=$'\xE2\x98\x95'
coffee3="${coffee} ${coffee} ${coffee}"

CLUSTER_NAME=$1
BX_SPACE=$2
BX_API_KEY=$3
BX_REGION=$4
BX_API_ENDPOINT=""
REGISTRY_NAMESPACE=""

if [[ -z "${BX_REGION// }" ]]; then
	BX_API_ENDPOINT="api.ng.bluemix.net"
	echo "Using DEFAULT endpoint ${grn}${BX_API_ENDPOINT}${end}."

else
	BX_API_ENDPOINT="api.${BX_REGION}.bluemix.net"
	echo "Using endpoint ${grn}${BX_API_ENDPOINT}${end}."
fi

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Running | grep 1/1
}

function print_usage {
	printf "\n\n${yel}Usage:${end}\n"
	printf "\t${cyn}./install_jenkins.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
}

function bluemix_login {
	# Bluemix Login
	if [[ -z "${CLUSTER_NAME// }" ]]; then
		print_usage
		echo "${red}Please provide Cluster Name. Exiting..${end}"
		exit 1

	elif [[ -z "${BX_SPACE// }" ]]; then
		print_usage
		echo "${red}Please provide Bluemix Space. Exiting..${end}"
		exit 1

	elif [[ -z "${BX_API_KEY// }" ]]; then
		print_usage
		echo "${red}Please provide Bluemix API Key. Exiting..${end}"
		exit 1
	fi

	printf "${grn}Login into Bluemix${end}\n"

	export BLUEMIX_API_KEY=${BX_API_KEY}
	bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}

	status=$?

	if [ $status -ne 0 ]; then
		printf "\n\n${red}Bluemix Login Error... Exiting.${end}\n"
		exit 1
	fi
}

function create_registry_namespace {	
	printf "\n\n${grn}Login into Container Registry Service${end}\n\n"
	bx cr login
	REGISTRY_NAMESPACE="jenkins$(cat ~/.bluemix/config.json | jq .Account.GUID | sed 's/"//g' | tail -c 7)"
	printf "\nCreating namespace \"${REGISTRY_NAMESPACE}\"...\n"
	bx cr namespace-add ${REGISTRY_NAMESPACE} &> /dev/null
	echo "Done"
}

function set_cluster_context {
	printf "\n\n${grn}Login into Container Service${end}\n\n"
	bx cs init

	# Getting Cluster Configuration
	unset KUBECONFIG
	printf "\n${grn}Setting terminal context to \"${CLUSTER_NAME}\"...${end}\n"
	eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
	echo "KUBECONFIG is set to = $KUBECONFIG"

	if [[ -z "${KUBECONFIG// }" ]]; then
		echo "KUBECONFIG was not properly set. Exiting"
		exit 1
	fi
}

function initialize_helm {
	printf "\n\n${grn}Initializing Helm.${end}\n"
	helm init --upgrade
	echo "Waiting for Tiller (Helm's server component) to be ready..."

	TILLER_DEPLOYED=$(check_tiller)
	while [[ "${TILLER_DEPLOYED}" == "" ]]; do 
		sleep 1
		TILLER_DEPLOYED=$(check_tiller)
	done
}

function create_jenkins_pvc {
	# Create Jenkins PVC if it does not exist
	printf "\n\n${grn}Checking if PVC already exists...${end}\n"
	PVC_BOUND=$(check_pvc)

	if [[ "${PVC_BOUND}" == "" ]]; then
		printf "\n\n${grn}Creating Persistent Volume Claim (PVC) For Jenkins. This will take a few minutes...${end}\n"
		kubectl create -f storage.yaml
		echo "${yel}Waiting for PVC to be fully bound to cluster...${end} ${coffee3}"

		PVC_BOUND=$(check_pvc)

		# Polling Status
		while [ -z "${PVC_BOUND// }" ]; do
			sleep 1
			PVC_BOUND=$(check_pvc)
		done
		echo "Done!"
	else
		echo "PVC already exists!"
	fi
}

function install_jenkins_chart {
	# Install Jenkins Chart
	JENKINS_EXISTS=$(kubectl get services | grep jenkins)

	if [[ "${JENKINS_EXISTS}" == "" ]]; then
		printf "\n\n${grn}Installing Jenkins Chart...${end} ${coffee3}\n"
		PVC_NAME=$(yaml read storage.yaml metadata.name)

		helm install --name jenkins --set Persistence.ExistingClaim=${PVC_NAME} \
		--set Master.ImageTag=2.61 stable/jenkins --timeout 600

		status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing Jenkins... Exiting.${end}\n"
			exit 1
		fi

		echo "${grn}Success!${end}"
	else
		printf "\n\n${grn}Jenkins Chart is already Installed!${end}\n"
	fi
}

function create_config_map {
	printf "\n\n${grn}Creating CI/CD Config Map...${end}\n"
	ORG=$(cat ~/.bluemix/.cf/config.json | jq .OrganizationFields.Name | sed 's/"//g')
	REGION=$1

	NAME=""
	API_ENDPOINT=""
	REGISTRY=""

	# Installing Config Map
	# Replace Config Map name
	# Replace API Endpoint
	# Replace Registry

	if [[ "$REGION" != "" ]]; then
		NAME="bluemix-target-${REGION}"
		API_ENDPOINT="api.${REGION}.bluemix.net"
		REGISTRY="registry.${REGION}.bluemix.net"

	else
		NAME="bluemix-target"
		API_ENDPOINT=$BX_API_ENDPOINT
		REGISTRY="registry.${BX_REGION}.bluemix.net"
	fi

	cat config.yaml | \
		yaml w - metadata.name $NAME | \
		yaml w - data.bluemix-api-endpoint $API_ENDPOINT | \
		yaml w - data.bluemix-registry $REGISTRY | \
		yaml w - data.bluemix-org $ORG | \
		yaml w - data.bluemix-space $BX_SPACE | \
		yaml w - data.bluemix-registry-namespace $REGISTRY_NAMESPACE | \
		yaml w - data.kube-cluster-name $CLUSTER_NAME > \
	        config_new.yaml

	mv config_new.yaml config.yaml

	config=$(kubectl get configmaps | grep ${NAME} | awk '{print $1}' | head -1)

	if [[ -z "${config// }" ]]; then
	    echo "Creating configmap"
		kubectl create -f config.yaml
	else
	    echo "Updating configmap"
		kubectl apply -f config.yaml
	fi
}

function create_registry-secret {
	printf "\n\n${grn}Creating Registry Token Secret...${end}\n"
	secret_name="registry-token"

	token_id=$(bx cr token-list | grep $CLUSTER_NAME | awk '{print $1}')
	#echo "token_id = ${token_id}"
	
	token=$(bx cr token-get ${token_id} | grep Token | tail -1 | awk '{print $2}')
	#echo "token = ${token}"

	# Email is required to create secret, but it won't be used to pull images
	registry="registry.${BX_REGION}.bluemix.net"
	user="token"
	email="user@test.com"

	secret=$(kubectl get secrets | grep ${secret_name} | awk '{print $1}' | head -1)

	if [[ "${secret}" != "" ]]; then
	    kubectl delete secrets ${secret_name}
	fi

    echo "Creating secret"
	kubectl --namespace default create secret docker-registry ${secret_name} \
	--docker-server=$registry \
	--docker-username=$user \
	--docker-password=$token \
	--docker-email=$email
}

function create_secret {
	# Replace API Key
	printf "\n\n${grn}Creating API KEY Secret...${end}\n"
	# Creating for API KEY
	if [[ -z "${BX_API_KEY// }" ]]; then
		printf "${grn}Creating API KEY...${end}\n"
		BX_API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
		echo "${yel}API key 'kubekey' was created.${end}"
		echo "${mag}Please preserve the API key! It cannot be retrieved after it's created.${end}"
		echo "${cyn}Name${end}	kubekey"
		echo "${cyn}API Key${end}	${BX_API_KEY}"
	fi

	string_to_replace=$(yaml read secret.yaml data.api-key)
	sed -i.bak s%${string_to_replace}%$(echo $BX_API_KEY | base64)%g secret.yaml

	secret=$(kubectl get secrets | grep bluemix-api-key | awk '{print $1}' | head -1)

	if [[ -z "${secret// }" ]]; then
	    echo "Creating secret"
		kubectl create -f secret.yaml
	else
	    echo "Updating secret"
		kubectl apply -f secret.yaml
	fi
}

function get_jenkins_ip {
	kubectl get service jenkins-jenkins -o json | jq .status.loadBalancer.ingress[0].ip -r
}

function get_web_port {
	kubectl get service jenkins-jenkins -o json | jq .spec.ports[0].port -r
}

function check_pvc {
	kubectl get pvc jenkins-home | grep Bound
}

# Setup Stuff
bluemix_login
create_registry_namespace
set_cluster_context
initialize_helm

# Create CICD Configuration
create_config_map
create_config_map ng
create_config_map eu-de

create_registry-secret
create_secret

# Create Jenkins Resources
create_jenkins_pvc
install_jenkins_chart

# Getting web port
port=$(get_web_port)

while [[ "${port}" == "" ]]; do
	sleep 1
	port=$(get_web_port)
done

# Getting ip
ip=$(get_jenkins_ip)

while [[ "${ip}" == "" ]]; do
	sleep 1
	ip=$(get_jenkins_ip)
done

password=$(printf $(kubectl get secret --namespace default jenkins-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo)

printf "\nTo see the Jenkins Web UI, please copy and paste the following URL into a new browser window:\n"
echo "${cyn}http://${ip}:${port}${end}"

printf "\nUse these credentials to login:"
printf "\n${cyn}username:${end} admin"
printf "\n${cyn}password:${end} ${password}\n"

printf "\n${yel}Note:${end} It may take a few minutes for Jenkins to fully initialize before you see anything on the browser."