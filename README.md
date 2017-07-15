MySQL 5.7 High Avaliable with Keepalived on Oracle Compute Cloud
===================

This terraform configuration creates MySQL 5.7 HA Cluter with Keepalived solutions. 


This configuration will create:

-	3 Compute Instances: `mysql_01`, `mysql_02`, `nat`
-	1 IP Networks: `Private_IPNetwork`
-	1 SSH Key: `mysql-example-key`
-	1 Public IP Reservations: `reservation1`

Usage
-----

### Set account variables

Create a `terraform.tfvars` to set the Oracle Compute Cloud authentication credentials.

### Setup SSH Keys for instance access

First create an ssh key pair to be used access the instances. The following will create `id_rsa` and `id_rsa.pub` in the local directory.

```sh
$ ssh-keygen -f ./id_rsa -N "" -q
```

Alternatively the `ssh_public_key` and `ssh_private_key` variables can be set in `terraform.tfvars` to the file location of an existing ssh key pair.

### Apply the configuration

Review the configuraion terraform will create

```
$ terraform plan
```

Now apply the configuration

```
$ terraform apply
```

Wait for the configuration to complete

### Access the instances and check the configuration

You can ssh directly to Instance_3 and Instance_4. The Public IP Addresses assinged to these instances is output at the end of the `terraform apply`.

e.g. SSH to nat

```
$ ssh opc@129.152.148.130 -i ./id_rsa
```

Once connected to the *nat* instance you can access mysql_01 and mysql_02 using the staically assigned IP addresses 192.168.2.11 and 192.168.2.12 in the IP Networks. And the IP 192.168.2.88 is float IP for MySQL HA Cluster created by Keepalived.

```
[opc@nat ~]$ ping 192.168.2.88
PING 192.168.2.88 (192.168.2.88) 56(84) bytes of data.
64 bytes from 192.168.2.88: icmp_seq=1 ttl=64 time=0.586 ms

[opc@nat ~]$ mysql -u ha -pXXXXXX -h 192.168.2.88

```

### Destroy the configuration

Cleanup all instances and resources created

```
$ terraform destroy
```
