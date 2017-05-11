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

API="api.ng.bluemix.net"
CLUSTER_NAME=$1

function check_pvc {
	kubectl get pvc jenkins-home | grep Bound
}

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Runnin
}

# Bluemix Login
printf "${grn}Login into Bluemix${end}\n"
bx login -a ${API}

status=$?

if [ $status -ne 0 ]; then
	printf "\n\n${red}Bluemix Login Error... Exiting.${end}\n"
	exit 1
fi

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

# Getting Cluster Configuration
unset KUBECONFIG
echo "${grn}Getting configuration for cluster ${CLUSTER_NAME}...${end}"
eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
echo "KUBECONFIG is set to = $KUBECONFIG"

if [[ -z "${KUBECONFIG// }" ]]; then
	echo "KUBECONFIG was not properly set. Exiting"
	exit 1
fi

printf "\n\n${grn}Initializing Helm.${end}\n"
helm init --upgrade
echo "Waiting for Tiller (Helm's server component) to be ready..."

TILLER_DEPLOYED=$(check_tiller)
while [[ "${TILLER_DEPLOYED}" == "" ]]; do 
	sleep 1
	TILLER_DEPLOYED=$(check_tiller)
done

# Create Jenkins PVC if it does not exist
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
fi

# Install Jenkins Chart
JENKINS_EXISTS=$(kubectl get services | grep jenkins)

if [[ "${JENKINS_EXISTS}" == "" ]]; then
	printf "\n\n${grn}Installing Jenkins Chart...${end} ${coffee3}\n"
	helm install --name jenkins --set Persistence.ExistingClaim=jenkins-home stable/jenkins --wait &> /dev/null
else
	printf "\n\n${grn}Jenkins Chart is already Installed!${end}\n"
fi

printf "\n\n${grn}To see Kubernetes Dashboard, paste the following in your terminal:${end}\n"
echo "${cyn}export KUBECONFIG=${KUBECONFIG}${end}"

printf "\n${grn}Then run this command to connect to Kubernetes Dashboard:${end}\n"
echo "${cyn}kubectl proxy${end}"

printf "\n${grn}To see Jenkins service and its web URL, open a browser window and enter the following URL:${end}\n"
echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service/default/jenkins-jenkins?namespace=default${end}"

printf "\nNote that it may take a few minutes for the LoadBalancer IP to be available. You can watch the status of it by running:\n"
echo "${cyn}kubectl get svc --namespace default -w jenkins-jenkins${end}"

printf "\n${grn}Finally, run the following command to get the password for \"admin\" user:${end}\n"
printf "${cyn}printf \$(kubectl get secret --namespace default jenkins-jenkins -o jsonpath=\"{.data.jenkins-admin-password}\" | base64 --decode);echo${end}\n"