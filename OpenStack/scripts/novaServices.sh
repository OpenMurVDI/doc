#!/bin/bash
SERVICIOS="nova-api nova-cert nova-consoleauth nova-scheduler nova-conductor nova-novncproxy"
# A falta de añadir: "libvirt-bin"

function iniciarServiciosNova()
{
	service rabbitmq-server start
	for servicio in $SERVICIOS
	do
		service $servicio start
	done
}

function pararServiciosNova()
{
	for servicio in $SERVICIOS
	do
		service $servicio stop
	done
	/etc/init.d/rabbitmq-server stop
}

case $1 in
	start)
		echo "Iniciando todos los servicios nova"
		iniciarServiciosNova
	;;

	stop)
		echo "Parando todos los servicios nova"
		pararServiciosNova
	;;

	restart)
		/etc/init.d/rabbitmq-server restart
		for servicio in $SERVICIOS
		do
			service $servicio restart
		done
	;;

	*) echo "Opción desconocida, uso $0 start|stop|restart"
	;;
esac
