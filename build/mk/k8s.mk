k8s-kubectl-install:		## Install kubectl
	sudo apt-get update && sudo apt-get install -y apt-transport-https
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl
	kubectl version

k8s-minikube-install:		## Install minikube
	curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	chmod +x minikube
	sudo cp minikube /usr/local/bin && rm minikube
	minikube version

k8s-minikube-start:			## Start minikube
	minikube start --cpus 8 --memory 20480 --disk-size=80GB
	kubectl proxy --address='0.0.0.0' --disable-filter=true &

k8s-prepare:	k8s-minikube-install k8s-kubectl-install k8s-minikube-start ## Install minikube, kubectl and start a cluster

k8s-deploy-saferwall:	k8s-deploy-nfs-server k8s-deploy-minio k8s-deploy-cb k8s-deploy-nsq k8s-deploy-backend k8s-deploy-consumer k8s-deploy-multiav ## Deploy all stack in k8s

k8s-deploy-nfs-server:	## Deploy NFS server in a newly created k8s cluster
	cd  $(ROOT_DIR)/build/k8s \
	&& kubectl apply -f nfs-server.yaml \
	&& kubectl apply -f samples-pv.yaml \
	&& kubectl apply -f samples-pvc.yaml

k8s-deploy-cb:	## Deploy couchbase in kubernetes cluster
	cd  $(ROOT_DIR)/build/k8s ; \
	kubectl create -f couchbase-sc.yaml ; \
	kubectl create -f couchbase-pv.yaml ; \
	kubectl create -f couchbase-pvc.yaml ; \
	kubectl create -f crd.yaml ; \
	kubectl create -f operator-role.yaml ; \
	kubectl create serviceaccount couchbase-operator --namespace default ; \
	kubectl create rolebinding couchbase-operator --role couchbase-operator --serviceaccount default:couchbase-operator ; \
	kubectl create -f admission.yaml ; \
	kubectl create -f secret.yaml ; \
	kubectl create -f operator-deployment.yaml ; \
	kubectl apply -f couchbase-cluster.yaml  

k8s-deploy-nsq:			## Deploy NSQ in a newly created k8s cluster
	cd  $(ROOT_DIR)/build/k8s \
	&& kubectl apply -f nsqlookupd.yaml \
	&& kubectl apply -f nsqd.yaml \
	&& kubectl apply -f nsqadmin.yaml
	
k8s-deploy-minio:		## Deploy minio
	cd  $(ROOT_DIR)/build/k8s ; \
	kubectl apply -f minio-standalone-pvc.yaml ; \
	kubectl apply -f minio-standalone-deployment.yaml ; \
	kubectl apply -f minio-standalone-service.yaml

k8s-deploy-multiav:		## Deploy multiav in a newly created k8s cluster
	cd  $(ROOT_DIR)/build/k8s \
	&& kubectl apply -f multiav-clamav.yaml \
	&& kubectl apply -f multiav-avira.yaml \
	&& kubectl apply -f multiav-eset.yaml \
	&& kubectl apply -f multiav-kaspersky.yaml \
	&& kubectl apply -f multiav-comodo.yaml \
	&& kubectl apply -f multiav-fsecure.yaml \
	&& kubectl apply -f multiav-bitdefender.yaml \
	&& kubectl apply -f multiav-avast.yaml \
	&& kubectl apply -f multiav-symantec.yaml \
	&& kubectl apply -f multiav-sophos.yaml \
	&& kubectl apply -f multiav-mcafee.yaml \
	&& kubectl apply -f seccomp-profile.yaml \
	&& kubectl apply -f seccomp-installer.yaml \
	&& kubectl apply -f multiav-windefender.yaml

k8s-deploy-backend:		## Deploy backend in kubernetes cluster
	cd  $(ROOT_DIR)/build/k8s ; \
	kubectl delete deployments backend ;\
	kubectl apply -f backend.yaml

k8s-deploy-consumer:		## Deploy consumer in kubernetes cluster
	cd  $(ROOT_DIR)/build/k8s ; \
	kubectl apply -f consumer.yaml

k8s-delete-nsq:
	cd  $(ROOT_DIR)/build/k8s ; \
	kubectl delete svc nsqd nsqadmin nsqlookupd
	kubectl delete deployments nsqadmin 
	kubectl delete deployments nsqadmin

k8s-delete-cb:		## Delete all couchbase related objects from k8s
	kubectl delete cbc cb-saferwall ; \
	kubectl delete deployment couchbase-operator-admission ; \
	kubectl delete deployment couchbase-operator  ; \
	kubectl delete crd couchbaseclusters.couchbase.com  ; \
	kubectl delete secret cb-saferwall-auth ; \
	kubectl delete pvc couchbase-pvc ; \
	kubectl delete pv couchbase-pv ; \
	kubectl delete sc couchbase-sc

k8s-delete-multiav:		## Delete all multiav related objects from k8s
	cd  $(ROOT_DIR)/build/k8s ; \
		kubectl delete deployments avast ; kubectl apply -f multiav-avast.yaml ; \
		kubectl delete deployments avira ; kubectl apply -f multiav-avira.yaml ; \
		kubectl delete deployments bitdefender ; kubectl apply -f multiav-bitdefender.yaml ; \
		kubectl delete deployments comodo ; kubectl apply -f multiav-comodo.yaml ; \
		kubectl delete deployments eset ; kubectl apply -f multiav-eset.yaml ; \
		kubectl delete deployments fsecure ; kubectl apply -f multiav-fsecure.yaml ; \
		kubectl delete deployments symantec ; kubectl apply -f multiav-symantec.yaml ; \
		kubectl delete deployments kaspersky ; kubectl apply -f multiav-kaspersky.yaml ; \
		kubectl delete deployments windefender ; kubectl apply -f multiav-windefender.yaml

k8s-delete:			## delete all
	kubectl delete deployments,service backend -l app=web
	kubectl delete service backend
	kubectl delete service consumer
	kubectl delete deployments consumer ; kubectl apply -f consumer.yaml

	kubectl delete cbc cb-saferwall ; kubectl create -f couchbase-cluster.yaml
	kubectl delete deployments backend ; kubectl apply -f backend.yaml

KEY_FILE =  tls.key
CERT_FILE =  tls.crt
k8s-create-tls-secrets:
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
	kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}


k8s-pf:
	kubectl port-forward --namespace default v1-couchbase-cluster-0000 8091:8091
