.PHONY: all init plan apply deploy-images deploy-frontend deploy-backend deployall test destroy clean

all: deploy-images apply

deployall: deploy-images apply test

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

deploy-frontend:
	./deploy-frontend.sh

deploy-backend:
	./deploy-backend.sh

deploy-images: deploy-frontend deploy-backend

test:
	./test-deployment.sh

destroy:
	terraform destroy

clean:
	docker system prune -f
