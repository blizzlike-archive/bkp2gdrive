TAG?=master

docker:
	docker build -t blizzlike/bkp2gdrive:${TAG} --no-cache -f Dockerfile .

keys:
	ssh-keygen -t rsa -b 4096 -f rsa.key
	openssl rsa -in rsa.key -pubout > rsa.key.pub
