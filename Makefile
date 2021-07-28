.PHONY: all

DOCKER_USERNAME := ntnxdemo

## Getting local git repository details prior
#GIT_COMMIT_ID     := $(shell git rev-parse --short HEAD)
GIT_COMMIT_ID     := 0.1.0
GIT_BRANCH_NAME   := $(shell git rev-parse --abbrev-ref HEAD | cut -d/ -f2 | head -c14)

all: build tag push pull

build:
	docker build . -t phpfpm-app

tag:
	docker tag phpfpm-app ${DOCKER_USERNAME}/phpfpm-app:${GIT_COMMIT_ID}
	docker tag phpfpm-app ${DOCKER_USERNAME}/phpfpm-app:latest

compose:
	docker-compose -f app-code/docker-compose.yml up

push: tag
	docker push ${DOCKER_USERNAME}/phpfpm-app:${GIT_COMMIT_ID}
	docker push ${DOCKER_USERNAME}/phpfpm-app:latest

pull:
	docker image rm ${DOCKER_USERNAME}/phpfpm-app:${GIT_COMMIT_ID}
	docker image rm ${DOCKER_USERNAME}/phpfpm-app:latest
	docker pull ${DOCKER_USERNAME}/phpfpm-app:${GIT_COMMIT_ID}
	docker pull ${DOCKER_USERNAME}/phpfpm-app:latest

validate:
	docker images | grep -E 'fpm|mariadb|nginx'

helm-deploy:
	helm upgrade --install phpfpm helm-chart/ --set mariadb.mariadbRootPassword=mini,mariadb.mariadbUser=mini,mariadb.mariadbPassword=mini,mariadb.mariadbDatabase=mini

set-dockerhub-pull-secrets:
	kubectl get ns -o name | cut -d / -f2 | xargs -I {} kubectl create secret docker-registry myregistrykey --docker-username=ntnxdemo --docker-password='Nutanix@123' -n {}
	kubectl get serviceaccount --no-headers --all-namespaces | grep default | awk '{print $1,$2}' | xargs -n2 sh -c 'kubectl patch serviceaccount $2 -p "{\"imagePullSecrets\": [{\"name\": \"myregistrykey\"}]}" -n $1' sh
