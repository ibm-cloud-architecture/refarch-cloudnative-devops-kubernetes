# Load Jenkins with existing job configurations
To avoid manually creating and configuring Jenkins jobs for each project, you can copy the contents of the `jobs` folder into the `jobs` folder inside the `JENKINS_HOME` folder. To do so, use the command below:

```bash
kubectl cp jobs ${NAMESPACE}/${JENKINS_POD_NAME}:/var/jenkins_home
```

Where:
* `${JENKINS_POD_NAME}` is the name of the Jenkins Pod.
* `${NAMESPACE}` is the namespace where the Jenkins pod is deployed.
* `/var/jenkins_home` is the default path to the Jenkins Home folder.

To see the jobs you can restart Jenkins or click `Manage Jenkins -> Reload Configuration from Disk`.

If using NFS as the Persistent Volume, you could also simply copy and paste the `jobs` folder to the NFS volume before deploying the Jenkins chart.