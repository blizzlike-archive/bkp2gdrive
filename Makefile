keys:
	ssh-keygen -t rsa -b 4096 -f rsa.key
	openssl rsa -in rsa.key -pubout > rsa.key.pub
