Login to deploy-server

$ vi ~/.ssh/id_rsa

$ chmod 600 ~/.ssh/id_rsa

$ sudo apt-get update

$ sudo apt-get upgrade

$ sudo apt-get install python3-pip

$ sudo pip3 install --upgrade pip

$ sudo -H pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H pip3 install -U

$ sudo pip3 install ansible

$ pip3 install --upgrade pip

$ pip3 install ansible

