export PATH := $(PATH):$(PWD)/.docker
SHELL := /bin/bash

docker-login:
	if [ ! $$(which docker-credential-gcr) ]; then mkdir -p .docker; cd .docker; curl https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v1.4.2/docker-credential-gcr_darwin_amd64-1.4.2.zip -o docker-credential-gcr_darwin_amd64-1.4.2.zip -L; unzip -a docker-credential-gcr_darwin_amd64-1.4.2.zip; cd -; fi;
	docker-credential-gcr configure-docker
	docker-credential-gcr gcr-login
	@echo docker login https://us.gcr.io
	@docker login -u _json_key -p '{  "type": "service_account",  "project_id": "devops-test-project-194020",  "private_key_id": "48a3920b99b6364a338ebd267bed7b749b82e591",  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDHItLt00mY6RFa\nEUsmWRiHudi2f/f+/yNEfbznCEsbaP4VJ2AqH+AR4UdlrvJ/FP6Zhnl9aFcu3Z5U\nL3wJrrTb3345vtm+0R2Wos43Jbp6vQYw8NUfm4QvmKItN8ZREEXSPC2TAXb7ZBUv\nVQ1HuJQbcikeOwO5YOaW6AjZrGr0mdw2LVxI5ZXjFtGzTN9BSki5Wj3LNfrjniRk\nIX1+Tw2mLkQRb8ELZPndXa+IEH7jX+oca3oy2IS+b3/LWkUmv+N3E1VeqtEILpB6\naeNARsZxlUaJzbhnlLrJdHkWWnxXqmUKGW9z0bmkXXt5dwrHh6IAhH7xsu0pGG86\nUEPVkUyZAgMBAAECggEATBmVzAcjqAjhda8ILgZ8ZlnyZIPw7QTpoGIAz7WOplHw\nT3s1t8NoqMyTsVszFreaOGd4hCFct+8/c2KWH0khmqkFHuI9ajuV+BwNfGuxoPgd\nppRSjfqrgFjvGSKoahAy7o3KyNQVeSqdIfJ52b/C8d4lsoTQ/oX2eRMBVtYaJZD+\nBC+kjiEkwn+p9L/x9XXeRYuuQRMZ4oHuTuMoWNbPo3866n44Ax7kG1uo+3e/vTDp\ndamtvCkExhui3eQ9XwUeFQWpWYPh+EDdyOlgeVvBMLvdonu/Lj2aaXtYd40z4XjJ\nZRhuKNfaZvrdrEzKs0aU2D8+yaZDV9sY6Jk8x4EPNQKBgQDvkXC22ziglosTQdD8\nVHRvf0hGJdHCJ9E90G12TCbtq67CsvTRa2rp8JyEreC/xEPknC5Rvrs5TowboJVD\nA3CDjFbgjyPBNKzUoSSB9AqMQDE7uHVcMolFDtDThCCIBJ3b6Hw6U4cpxaPbPZ56\neyZkdGza+sK/siYU1L0w5HrVMwKBgQDUy3B6O/iWxfbFCDE12+uc8iGMEPMj9QM4\nXKJ8RjCAcmN5Nw3bLaD1S4V64Drv5k0mazjMr4j9ecIUT36j4cOft/+uEfxud3Pk\nsk37kztvRMpy3r3lEHldt7flcnDJ8vBLdJMLbe81g0UKuID8J+/cdtc5Pe/Zv54m\nZHLaBTH/AwKBgC4AF0yFO5JaVcoU0TQiY1klb5NIn8ZQLvVXmC0m4jKwzJXGFww/\nPAA/m04+tPEdlovHEX3QydJvKqgDZaXAe1JHGEd2NL9chfMuHfx2B7B2gv2cpaxW\nZ9VCywZSUIzNliIrue7ZKxLySExIwK10CCMx19UUYWC9rGJDlzBULuHRAoGBALi8\nEN6dN7e1DwGIlig6zzZGYmdVw69AotYIXatjx/GK3N67s9TGrQim0q+VALWKCwpC\nZWIVNelQDfRR+xBNC+aZ92boCGziWQN+5AJ2lE+JufO1ecfl4GdC+mxASLiZppDr\nGEkA3H1pg8PF33yJM0wDA9+W7KXuG18bLzYk8n1/AoGBAO3dFeCyU4fD++OVQj9v\nkn8IzIX5DpHnG+IKd4KVi8iJlbrGClkCRSHtXOIozta6llAt6MM5yKTkQESjnZTH\nG9sTrJbcdr8DYLJhgy89NUV9+qzqTP7hmBe6O6UuyQk9FqU+omt0upPnFt1RDoO3\nGpgBmiuMZ+noV0mi9g+ZdF1Q\n-----END PRIVATE KEY-----\n",  "client_email": "docker-login@devops-test-project-194020.iam.gserviceaccount.com",  "client_id": "105644226512744987533",  "auth_uri": "https://accounts.google.com/o/oauth2/auth",  "token_uri": "https://accounts.google.com/o/oauth2/token",  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/docker-login%40devops-test-project-194020.iam.gserviceaccount.com" }' https://us.gcr.io

build:
	docker build . -t bandiera

up:
	docker-compose up -d db
	docker-compose run app bundle exec rake db:migrate
	docker-compose up app