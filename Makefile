include .env

repo_dir		:= ${REPO_DIR}
home_zimbra		:= ${HOME_ZIMBRA}
git_email		:= ${GITEMAIL}
git_name		:= ${GITNAME}
solr_mode		:= ${SOLR_MODE}
solr_memory		:= ${SOLR_MEMORY}

#MAKE 			:= ${MAKE} repo_dir="${repo_dir}" home_zimbra="${home_zimbra}" git_email="${git_email}" git_name="${git_name}" solr_mode="${solr_mode}" solr_memory="${solr_memory}"
#endif


all: .env build

build:
	docker-compose build

clean: down
	rm -rf .env

down:
	@docker stack rm zcs
	rm -f .up.lock

up: .up.lock

.up.lock:
	REPO_DIR=${repo_dir} \
	HOME_ZIMBRA=${home_zimbra} \
	GITEMAIL=${git_email} \
	GITNAME=${git_name} \
	SOLR_MODE=${solr_mode} \
	SOLR_MEMORY=${solr_memory} \
	docker stack deploy -c docker-compose.yml zcs
	touch .up.lock

.env:
	touch .env
	echo "HOME_ZIMBRA=." >> .env
	echo "GITEMAIL=\"<git-email-address>\"" >> .env
	echo "GITNAME=\"<firstname> <lastname>\"" >> .env
	echo "SOLR_MODE=cloud" >> .env
	echo "SOLR_MEMORY=2g"  >> .env
	echo "HOME_ZIMBRA=." >> .env
    echo "REPO_DIR=./home-zimbra" >> .env
