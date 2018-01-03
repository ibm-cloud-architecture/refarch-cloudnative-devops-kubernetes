# Checking if bx is installed
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'
coffee=$'\xE2\x98\x95'
coffee3="${coffee} ${coffee} ${coffee}"

BLUEMIX_API_ENDPOINT="api.ng.bluemix.net"
CLUSTER_NAME=$1
SPACE=$2
API_KEY=$3

REGISTRY_NAMESPACE=""

function check_pvc {
	kubectl get pvc jenkins-home | grep Bound
}

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Runnin
}

function bluemix_login {
	# Bluemix Login
	printf "${grn}Login into Bluemix${end}\n"
	if [[ -z "${API_KEY// }" && -z "${SPACE// }" ]]; then
		echo "${yel}API Key & SPACE NOT provided.${end}"
		bx login -a ${BLUEMIX_API_ENDPOINT}

	elif [[ -z "${SPACE// }" ]]; then
		echo "${yel}API Key provided but SPACE was NOT provided.${end}"
		export BLUEMIX_API_KEY=${API_KEY}
		bx login -a ${BLUEMIX_API_ENDPOINT}

	elif [[ -z "${API_KEY// }" ]]; then
		echo "${yel}API Key NOT provided but SPACE was provided.${end}"
		bx login -a ${BLUEMIX_API_ENDPOINT} -s ${SPACE}

	else
		echo "${yel}API Key and SPACE provided.${end}"
		export BLUEMIX_API_KEY=${API_KEY}
		bx login -a ${BLUEMIX_API_ENDPOINT} -s ${SPACE}
	fi

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

function get_cluster_name {
	printf "\n\n${grn}Login into Container Service${end}\n\n"
	bx cs init

	if [[ -z "${CLUSTER_NAME// }" ]]; then
		echo "${yel}No cluster name provided. Will try to get an existing cluster...${end}"
		CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

		if [[ "$CLUSTER_NAME" == "Name" ]]; then
			echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
			exit 1
		fi
	fi
}

function set_cluster_context {
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
		--set Master.ImageTag=2.61 stable/jenkins --wait --timeout 600

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
	SPACE=$(cat ~/.bluemix/.cf/config.json | jq .SpaceFields.Name | sed 's/"//g')

	# Installing Config Map
	# Replace Bluemix Org
	string_to_replace=$(yaml read config.yaml data.bluemix-org)
	sed -i.bak s%${string_to_replace}%${ORG}%g config.yaml

	# Replace Bluemix Space
	string_to_replace=$(yaml read config.yaml data.bluemix-space)
	sed -i.bak s%${string_to_replace}%${SPACE}%g config.yaml

	# Replace Registry Namespace
	string_to_replace=$(yaml read config.yaml data.bluemix-registry-namespace)
	sed -i.bak s%${string_to_replace}%${REGISTRY_NAMESPACE}%g config.yaml

	# Replace Kubernetes Cluster Name
	string_to_replace=$(yaml read config.yaml data.kube-cluster-name)
	sed -i.bak s%${string_to_replace}%${CLUSTER_NAME}%g config.yaml

	config=$(kubectl get configmaps | grep bluemix-target | awk '{print $1}' | head -1)

	if [[ -z "${config// }" ]]; then
	    echo "Creating configmap"
		kubectl create -f config.yaml
	else
	    echo "Updating configmap"
		kubectl apply -f config.yaml
	fi
}

function create_secret {
	# Replace API Key
	printf "\n\n${grn}Creating API KEY Secret...${end}\n"
	# Creating for API KEY
	if [[ -z "${API_KEY// }" ]]; then
		printf "${grn}Creating API KEY...${end}\n"
		API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
		echo "${yel}API key 'kubekey' was created.${end}"
		echo "${mag}Please preserve the API key! It cannot be retrieved after it's created.${end}"
		echo "${cyn}Name${end}	kubekey"
		echo "${cyn}API Key${end}	${API_KEY}"
	fi

	string_to_replace=$(yaml read secret.yaml data.api-key)
	sed -i.bak s%${string_to_replace}%$(echo $API_KEY | base64)%g secret.yaml

	secret=$(kubectl get secrets | grep bluemix-api-key | awk '{print $1}' | head -1)

	if [[ -z "${secret// }" ]]; then
	    echo "Creating secret"
		kubectl create -f secret.yaml
	else
	    echo "Updating secret"
		kubectl apply -f secret.yaml
	fi
}

# Setup Stuff
bluemix_login
create_registry_namespace
get_cluster_name
set_cluster_context
initialize_helm

# Create CICD Configuration
create_config_map
create_secret

# Create Jenkins Resources
create_jenkins_pvc
install_jenkins_chart

# Completion Messages
printf "\n\nTo see Kubernetes Dashboard, paste the following in your terminal:\n"
echo "${cyn}export KUBECONFIG=${KUBECONFIG}${end}"

printf "\nThen run this command to connect to Kubernetes Dashboard:\n"
echo "${cyn}kubectl proxy${end}"

printf "\n$To see Jenkins service and its web URL, open a browser window and enter the following URL:\n"
echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service/default/jenkins-jenkins?namespace=default${end}"

printf "\nNote that it may take a few minutes for the LoadBalancer IP to be available. You can watch the status of it by running:\n"
echo "${cyn}kubectl get svc --namespace default -w jenkins-jenkins${end}"

printf "\nFinally, run the following command to get the password for \"admin\" user:\n"
printf "${cyn}printf \$(kubectl get secret --namespace default jenkins-jenkins -o jsonpath=\"{.data.jenkins-admin-password}\" | base64 --decode);echo${end}\n"