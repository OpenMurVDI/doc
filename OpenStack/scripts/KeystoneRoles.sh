#!/bin/bash

# Alejandro Roca Alhama
# Script para la creación inicial de usuarios, proyectos y roles.
# Versión 2.0.
# Última modificación: 3/enero/2014.

# Solo hay que modificar estos parámetros
PASSWORD='oscloud20!!p'
EMAIL=alex@iescierva.net
PUBLIC_IP=172.20.253.190
PRIVATE_IP=172.20.253.190
ADMIN_IP=172.20.253.190

# Creación de tenants, usuarios y roles

keystone tenant-create --name admin --description "Admin Tenant"
keystone tenant-create --name service --description "Service Tenant"

keystone user-create --name admin --pass $PASSWORD --email $EMAIL
keystone user-create --name nova --pass $PASSWORD --email $EMAIL
keystone user-create --name glance --pass $PASSWORD --email $EMAIL
#keystone user-create --name swift --pass $PASSWORD --email $EMAIL

keystone role-create --name admin
#keystone role-create --name Member

#ADMIN_TENANT=`keystone tenant-list | grep admin | tr -d " " | awk -F \| ' { print $2 }'`
#SERVICE_TENANT=`keystone tenant-list | grep service | tr -d " " | awk -F \| ' { print $2 }'`

#ADMIN_ROLE=`keystone role-list | grep admin | tr -d " " | awk -F \| ' { print $2 }'`
#MEMBER_ROLE=`keystone role-list | grep Member | tr -d " " | awk -F \| ' { print $2 }'`

#ADMIN_USER=`keystone user-list | grep admin | tr -d " " | awk -F \| ' { print $2 }'`

# Añadimos el rol admin al usuario admin en el tenant admin
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=glance --tenant=service --role=admin
keystone user-role-add --user=nova --tenant=service --role=admin
#keystone user-role-add --user=admin --tenant=admin –role=Member

# Creamos los servicios
keystone service-create --name keystone --type identity --description "Keystone Identity Service"
keystone service-create --name nova --type compute --description "Nova Compute Service"
#keystone service-create --name volume --type volume --description "OpenStack Volume Service"
keystone service-create --name glance --type image --description "Glance Image Service"
#keystone service-create --name swift --type object-store --description "OpenStack Storage Service"

#keystone service-create --name ec2 --type ec2 --description "OpenStack EC2 Service"

# Creamos los endpoints
#for service in nova volume glance swift keystone ec2
for service in nova keystone glance
do
    ID=`keystone service-list | grep $service | tr -d " " | awk -F \| ' { print $2 } '`
    case $service in
    "nova"     ) keystone endpoint-create --service-id $ID \
                 --publicurl   "http://$PUBLIC_IP"':8774/v2/%(tenant_id)s' \
                 --adminurl    "http://$ADMIN_IP"':8774/v2/%(tenant_id)s' \
                 --internalurl "http://$PRIVATE_IP"':8774/v2/%(tenant_id)s'
    ;;
    "volume"   ) keystone endpoint-create --service_id $ID \
                 --publicurl   "http://$PUBLIC_IP"':8776/v1/$(tenant_id)s' \
                 --adminurl    "http://$ADMIN_IP"':8776/v1/$(tenant_id)s' \
                 --internalurl "http://$PRIVATE_IP"':8776/v1/$(tenant_id)s'            
    ;;
    "glance"   ) keystone endpoint-create --service-id $ID \
                 --publicurl   "http://$PUBLIC_IP"':9292' \
                 --adminurl    "http://$ADMIN_IP"':9292' \
                 --internalurl "http://$PRIVATE_IP"':9292'
    ;;
    "swift"    ) keystone endpoint-create --service_id $ID \
                 --publicurl   "http://$PUBLIC_IP"':8080/v1/AUTH_$(tenant_id)s' \
                 --adminurl    "http://$ADMIN_IP"':8080/v1' \
                 --internalurl "http://$PRIVATE_IP"':8080/v1/AUTH_$(tenant_id)s'
    ;;
    "keystone" ) keystone endpoint-create --service_id $ID \
                 --publicurl   "http://$PUBLIC_IP"':5000/v2.0' \
                 --adminurl    "http://$ADMIN_IP"':35357/v2.0' \
                 --internalurl "http://$PRIVATE_IP"':5000/v2.0'
    ;;
    "ec2"      ) keystone endpoint-create --service_id $ID \
                 --publicurl   "http://$PUBLIC_IP"':8773/services/Cloud' \
                 --adminurl    "http://$ADMIN_IP"':8773/services/Admin' \
                 --internalurl "http://$PRIVATE_IP"':8773/services/Cloud'
    ;;
    esac
done
