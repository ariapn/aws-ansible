# JupyterHub deployment for ACCY 570 & 571

This repository contains an Ansible playbook for launching JupyterHub for
ACCY 570: Data Analytics Foundations for Accountancy and
ACCY 571: Statistical Analyses for Accountancy
classes at the University of Illinois.

See also the [INFO490 setup](https://github.com/EdwardJKim/jupyterhub-info490).

The setup is inspired by [the compmodels class](https://github.com/compmodels/jupyterhub-deploy)
but there are some major differences:

1.  Shibboleth authentication: Jupyterhub runs behind Shibboleth (via Apache).
2.  [Consul](https://www.consul.io/): Consul serves as the back-end discovery service
    for the Swarm cluster.
3.  Instead of creating creating users on the host system and using the
    [systemuser Docker image](https://github.com/jupyter/dockerspawner/tree/master/systemuser),
    we change the ownership of the files on the host system to the `jupyter` user and mount
    the appropriate directory onto the
    [singleuser Docker image](https://github.com/jupyter/dockerspawner/tree/master/singleuser).
4.  CentOS, instead of Ubuntu.

## Overview

When a user accesses the server, the following happens behind the scenes:

1.  First, they go to the main url for the server.
2.  This url actually points to an Apache proxy server which authenticates the TSL connection,
    and proxies the connection to Shibboleth.
3.  After students are autheticated by Shibboleth, they are redirected to the JupyterHub instance
running on the hub server. 
4.  The hub server is both a NFS server (to serve user's home directories) and the JupyterHub server.
    JupyterHub runs in a docker container called `jupyterhub`.
5.  When they access their server, JupyterHub creates a new docker container on one of the node servers
    running an IPython notebook server.
    This docker container is called "jupyter-username", where "username" is the user's username.
6.  As users open IPython notebooks and run them, they are actually communicating
    with one of the node servers.
    The URL still appears the same, because the connection is first being proxied to the hub server
    via the proxy server, and then proxied a second time to the node server via the JupyterHub proxy.
7.  Users have access to their home directory, because each node server is also a NFS client
    with the filesystem mounted at /home.

## Installation

Any management system benefits from being run near the machines being managed.
If you are running Ansible in a cloud, consider running it from a machine inside that cloud.
In most cases this will work better than on the open Internet.
We assume CentOS 7.x in the following.

### Install Docker

```shell
$ sudo yum update
$ sudo yum install docker
$ sudo service docker start
```

### Install Ansible

```shell
$ sudo pip install ansible
```

### Clone Git repository

```shell
$ git clone https://github.com/edwardjkim/jupyterhub-accy-aws
$ cd jupyterhub-accy-aws
```


### Configuration variables

Use the example YAML files to change your server configurations.
```shell
$ cp inventory.example inventory
```
If you want to use the previous configuration, decrypt with `ansible-vault`:
```shell
$ ansible-vault decrypt inventory
```
Edit inventory
```shell
$ vim inventory
```

Similarly, use the example YAML files or decrypt the previous configarution
for `users.yml` and `vars.yml`:
```shell
$ ansible-vault decrypt users.yml
$ vim users.yml
```

```shell
$ ansible-vault decrypt vars.yml
$ vim vars.yml
```

### Generate TLS/SSL certificates

You will need to generate three sets of key and certificate for the web server,
Shibboleth, and Docker sockets.

### SSL certificates for Apache

Get signed SSL certificates from a certificate authority and edit `host_vars`.

```shell
$ cp host_vars/example host_vars/proxy_server
$ vim host_vars/proxy_server
```

You can also generate and use self-signed certificates, but self-signed certificates
may not work with some web browswers (e.g. Safari).

### SSL certificates for Shibboleth

Generate a key and certificate to be used by the Shibboleth service provider (SP).
Note that this is different from the web server certificate.

In the below commands, we will use the `keygen.sh` script provided by Shibboleth.
`your.host.name` is the hostname you chose for your `entityID`.
These commands will create a key and cert pair, `sp-key.pem` and `sp-cert.pem`.

See [Setting up Shibboleth for U of I](https://answers.uillinois.edu/illinois/48459).

```shell
$ ./script/keygen.sh -o certificates -h your.host.name -e https://your.host.name/shibboleth -y 10
```

Use SP's certificate `sp-cert.pem` to register with [iTrust](https://itrust.illinois.edu/federationregistry/).

### TLS certificates for Docker

You'll need to generate SSL/TLS certificates for the hub server and node servers.
To do this, you can use the keymaster docker container.
First, setup the certificates directory, password, and certificate authority:

```shell
$ mkdir certificates

$ touch certificates/password
$ chmod 600 certificates/password
$ cat /dev/urandom | head -c 128 | base64 > certificates/password

$ KEYMASTER="sudo docker run --rm -v $(pwd)/certificates/:/certificates/ cloudpipe/keymaster"

$ ${KEYMASTER} ca
```

Then, to generate a keypair for a server:

```shell
$ ${KEYMASTER} signed-keypair -n server1 -h server1.website.com -p both -s IP:192.168.0.1
```

For example, if you have the following in `inventory`:

```
jupyterhub_host ansible_user=root ansible_host=123.456.78.90 private_ip=123.456.78.90
```

run

```shell
$ ${KEYMASTER} signed-keypair -n jupyterhub_host -h 123.456.78.90 -p both -s IP:123.456.78.90
```

This generate pem files in certificates directory.
Use `ca.pem`, `jupyterhub_host-cert.pem`, and `jupyterhub_host-key.pem` to fill in the `docker_ca_cert`, `docker_tls_cert`, and `docker_tls_key` fields in the `host_vars` files.
You'll need to generate keypairs for the hub server and for each of the node servers.

You'll need to generate keypairs for the hub server and for each of the node servers.
Don't forget to edit the `host_vars` files.

```shell
$ cp host_vars/example host_vars/jupyterhub_host
$ vim host_vars/jupyterhub_host
```

You can also use the `script/assemble_certs` script to automatically copy-paste the generated
certs and keys into `host_vars` files. Open up `script/aseemble_certs` in a text editor, modify
the `name_map` dictionary if necessary, and run `./script/aseemble_certs`.

## Encrypt with ansible-vault

Some files, such as SSL certificates and `vars.yml`, should not be stored in plain text.

```shell
$ ansible-vault encrypt vars.yml
$ ansible-vault encrypt host_vars/proxy_server
$ ansible-vault encrypt host_vars/jupyterhub_host
$ ansible-vault encrypt host_vars/jupyterhub_node1
$ ansible-vault encrypt host_vars/jupyterhub_node2
$ ansible-vault encrypt host_vars/jupyterhub_node3
$ ansible-vault encrypt host_vars/jupyterhub_node4
```

## Deploy

```shell
$ ./script/deploy
```
This shell script will ask for SSH passwords and ansible-vault password.
