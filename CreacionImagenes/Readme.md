# Creación de imágenes para OpenStack/OpenMurVDI

Una imagen de una máquina virtual no es más que un simple fichero que representa un disco duro virtual con un sistema operativo instalado.

Un hipervisor es capaz de ejecutar una máquina virtual o sistema huésped proporcionándole una abstracción hardware completa, incluyendo los dispositivos de almacenamiento. A bajo nivel, un dispositivo de almacenamiento como puede ser un disco duro, no es más que un fichero en un determinado formato que representa al medio de almacenamiento.

Para que OpenStack sea capaz de ejecutar máquinas virtuales es necesario proporcionarle un disco duro ya preparado e instalado con un sistema operativo huésped.

Existen una gran multitud de formatos de disco, OpenStack es capaz de soportar varios de ellos dependiendo del hipervisor utilizado, entre los formatos más utilizados destacan:

* **Raw**
    * El formato raw, formato de imagen "en crudo", es uno de los formatos más simples que existen, básicamente representa una copia bloque a bloque de un dispositivo. Una copia a través del comando `dd` genera una imagen de este tipo. Es un formato bastante rápido pero que carece de opciones avanzadas como snapshots de disco o compresión de datos. Como ventaja principal destacan la velocidad, la portabilidad entre hipervisores y que puede gestionarse con herramientas básicas del sistema como `dd`, `parted`, `fdisk/gdisk`, `moount`, `kpartx`, etc.

* **qcow2**
    * El formato qcow2 (QEMU copy-on-write versión 2) es el más usado con KVM, es un formato avanzado con caraecterísticas como expansión dinámica, copy-on-write, snapshots, cifrado, compresión, etc. 

* **VMDK**
    * Es el formato utilizado por VMware en casi todos sus hipervisores: WorkStation, ESX, ...

* **VDI**
    * VDI (Virtual Disk Image) es el formato utilizado por Oracle VirtualBox. Ninguno de los hipervisores que utilizados por OpenStack soporta directamente este formato por lo que siempre será necesaria una conversión previa.

* **VHD/VHDX**
    * VHD y VHDX son los formatos de imágenes de disco utilizado por Hyper-V, el hipervisor de Microsoft. VHDX es el formato más nuevo, introducido en las versiones de Hyper-V de Windows Server 2012.

* **OVF**
    * OVF (Open Virtualization Format) es el formato de empaquetamiento de máquinas virtuales definido por el DMTF (Distributed Management Task Force).  
    Un paquete OVF puede contener varios ficheros destacando el fichero o ficheros con las imágenes de disco así como un fichero XML con metainformación de la máquina virtual.  
    Un paquete OVF se puede distribuir como un conjunto de ficheros o en un solo fichero en tar/gz con la extensión .ova (open virtual appliance/application).  
    OpenStack aún no soporta el uso de este formato directamente.

* **ISO**
    * Una imagen ISO es una imagen de disco de solo lectura formateada con el sistema de ficheros ISO-9660 (también conocido como ECMA-119). El formato ISO es el formato más extendido para las imágenes de CD y DVD.

Lo normal a la hora de crear imágenes de sistemas Linux o Windows para Openstack es que se creen/utilicen imágenes en formato _raw_ o _qcow2_.
    
A la hora de subir imágenes con `glance` hay que especificar también un formato de contenedor, entre los formatos de contenedor que OpenStack soporta destacan:

* **bare**
    - No hay contenedor, el fichero representa una imagen tal cual. Es la opción que utilizaremos siempre.
* **ovf**
    - Formato contenedor OVF.
* **aki/ari/ami**
    - Es el formato de Amazon.

## Creación de imágenes Linux/Ubuntu

Para crear una imagen de un sistema Linux Ubuntu basta seguir los siguientes pasos:

1. Creamos el fichero en formato qcow2 que albergará la imagen de Ubuntu. Por ejemplo, para una imagen llamada `precise.qcow2` con un tamaño de 8 GB el comando sería éste:

	`# qemu-img create -f qcow2 /home/usuario/VMs/libvirt/precise.qcow2 8G`


1. Creamos una máquina KVM con `virt-manager` o con `virt-install` y hacemos una instalación normal, pero teniendo en cuenta:
    * Solo una partición raíz /, formateada en ext4.
    * La partición debe tomar todo el espacio del disco (mínimo 4 GB, recomendables 8 GB).
    * Sin partición swap.
    * Nombre de máquina: _ubuntu_.
    * Nombre de usuario: _openvdi_ con password _openvdi2014_.
	* En el siguiente ejemplo con `virt-install` utilizamos una imagen ISO previamente descargada desde <http://www.ubuntu.com/download/desktop>.

			virt-install --virt-type kvm \
			--name <nombre_maquina> \
			--ram 1024 \
			--cdrom=/home/usuario/ubuntu_desktop_12.04_x64.iso \
			--disk /home/usuario/VMs/libvirt/precise.qcow2,format=qcow2 \
			--network network=default \
			--graphics vnc,listen=0.0.0.0 \
			--noautoconsole \
			--os-type=linux –os-variant=ubuntuprecise

1. Una vez terminada la instalación, reiniciamos la máquina virtual recién creada extrayendo el CD de instalación. No obstante, aunque pulsemos *“Reiniciar”*, lo que realmente sucede es que la máquina virtual se apaga. Una vez apagada, hacemos lo siguiente:
    * Comprobamos el nombre del dispositivo de CD-ROM con la ayuda del siguiente comando:
    
			virsh dumpxml <nombre_maquina>

    * Buscamos la siguiente sección:

				<disk type='block' device='cdrom'> 
				  <driver name='qemu' type='raw'/> 
				  <target dev='hdc' bus='ide'/> 
				  <readonly/> 
				  <address type='drive' controller='0' bus='1' unit='0'/> 
				</disk> 
				<controller type='ide' index='0'> 
				  <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'
			    </controller>

	* Como vemos, en nuestro caso, se trata del dispositivo *hdc*, para extraer el dispositivo, ejecutamos los siguientes comandos:

		* Iniciamos la máquina pausándola.
		
				virsh start <nombre_maquina> --paused

		* Sustituimos el dispositivo existente por ningún dispositivo (“”).4
		
				virsh attach-disk --type cdrom --mode readonly <nombre_maquina> “” hdc

		* Reiniciamos la máquina pausada.
		
				virsh resume <nombre_maquina>

2.  Instalamos los siguientes paquetes y/o servicios:
    * Servidor SSH
    * Instalamos un kernel más moderno, al menos el de la versión _raring_.
    
    		apt-get install openssh-server linux-generic-lts-raring

2.  Nos aseguramos de que se utilicen los repositorios de Ubuntu locales que se tengan en la red, o al menos unos más rápidos como los repositorios franceses o alemanes, para ello editamos el fichero `/etc/apt/sources.list` cambiando todas las ocurrencias de la expresión _es.archive_ por _de.archive_ o _fr.archive_.

2.  Actualizamos la máquina y reiniciamos:

        root@ubuntu:~# apt-get update
        root@ubuntu:~# apt-get upgrade
        root@ubuntu:~# apt-get dist-upgrade
        root@ubuntu:~# reboot

2.  Tras el reinicio, activamos todos los repositorios y volvemos a ejecutar el comando  un `apt-get update`. Si aparece un error indicando que la clave _16126D3A3E5C1192_ no se encuentra, ejecutamos el comando:

        root@ubuntu:~# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 16126D3A3E5C1192
        ...
        root@ubuntu:~# apt-get update
        root@ubuntu:~# apt-get upgrade

7.  Instalamos cualquier otro software que nos interese, desinstalamos paquetes que no vamos a utilizar.

    * A instalar:
        - `xrdp` (Ubuntu Desktop)
    * A desinstalar:
        - Todos los kernels antiguos:
            + `dpkg --list | grep linux-image`
            + `dpkg --list | grep linux-headers`

7. En Ubuntu Desktop, si hemos instalado `xrdp`:

    * Configuramos el sistema para fijar el idioma español como lenguaje por defecto al iniciar sesión. Modificamos el fichero `/etc/default/locale` con el siguiente contenido: LANG="es_ES.UTF-8"
	* Por defecto la sesión gráfica está basada en _Unity_, se puede configurar _Gnome Classic_ como sesión por defecto para `xrdp`. Para ello editamos el fichero `/etc/xrdp/startwm.sh` reflejando los siguientes cambios:
	
			#!/bin/sh

			if [ -r /etc/default/locale ]; then
				. /etc/default/locale
	  			export LANG LANGUAGE
			fi

			# By default (Unity)
			#. /etc/X11/Xsession

			# gnome-classic
			echo "gnome-session --session=gnome-classic" > ~/.xsession
			. /etc/X11/Xsession

    * Editamos el contenido del fichero `/etc/xrdp/km-0409.ini` para que la configuración del teclado sea en español al conectarnos a la máquina a través de RDP. Hacemos una copia del fichero original a través del comando `# cp /etc/xrdp/km-0409.ini /etc/xrdp/km-0409.ini.original` y sustituímos su contenido con:

			[noshift]
			Key8=65406:0
			Key9=65307:27
			Key10=49:49
			Key11=50:50
			Key12=51:51
			Key13=52:52
			Key14=53:53
			Key15=54:54
			Key16=55:55
			Key17=56:56
			Key18=57:57
			Key19=48:48
			Key20=39:39
			Key21=161:161
			Key22=65288:8
			Key23=65289:9
			Key24=113:113
			Key25=119:119
			Key26=101:101
			Key27=114:114
			Key28=116:116
			Key29=121:121
			Key30=117:117
			Key31=105:105
			Key32=111:111
			Key33=112:112
			Key34=65104:96
			Key35=43:43
			Key36=65293:13
			Key37=65507:0
			Key38=97:97
			Key39=115:115
			Key40=100:100
			Key41=102:102
			Key42=103:103
			Key43=104:104
			Key44=106:106
			Key45=107:107
			Key46=108:108
			Key47=241:241
			Key48=65105:180
			Key49=186:186
			Key50=65505:0
			Key51=231:231
			Key52=122:122
			Key53=120:120
			Key54=99:99
			Key55=118:118
			Key56=98:98
			Key57=110:110
			Key58=109:109
			Key59=44:44
			Key60=46:46
			Key61=45:45
			Key62=65506:0
			Key63=65450:42
			Key64=65513:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65407:0
			Key78=65300:0
			Key79=65429:0
			Key80=65431:0
			Key81=65434:0
			Key82=65453:45
			Key83=65430:0
			Key84=65437:0
			Key85=65432:0
			Key86=65451:43
			Key87=65436:0
			Key88=65433:0
			Key89=65435:0
			Key90=65438:0
			Key91=65439:0
			Key92=0:0
			Key93=0:0
			Key94=60:60
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65508:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65516:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=0:0
			Key126=65469:61
			Key127=0:0
			Key128=0:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[shift]
			Key8=65406:0
			Key9=65307:27
			Key10=33:33
			Key11=34:34
			Key12=183:183
			Key13=36:36
			Key14=37:37
			Key15=38:38
			Key16=47:47
			Key17=40:40
			Key18=41:41
			Key19=61:61
			Key20=63:63
			Key21=191:191
			Key22=65288:8
			Key23=65056:0
			Key24=81:81
			Key25=87:87
			Key26=69:69
			Key27=82:82
			Key28=84:84
			Key29=89:89
			Key30=85:85
			Key31=73:73
			Key32=79:79
			Key33=80:80
			Key34=65106:94
			Key35=42:42
			Key36=65293:13
			Key37=65507:0
			Key38=65:65
			Key39=83:83
			Key40=68:68
			Key41=70:70
			Key42=71:71
			Key43=72:72
			Key44=74:74
			Key45=75:75
			Key46=76:76
			Key47=209:209
			Key48=65111:168
			Key49=170:170
			Key50=65505:0
			Key51=199:199
			Key52=90:90
			Key53=88:88
			Key54=67:67
			Key55=86:86
			Key56=66:66
			Key57=78:78
			Key58=77:77
			Key59=59:59
			Key60=58:58
			Key61=95:95
			Key62=65506:0
			Key63=65450:42
			Key64=65511:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65273:0
			Key78=65300:0
			Key79=65463:55
			Key80=65464:56
			Key81=65465:57
			Key82=65453:45
			Key83=65460:52
			Key84=65461:53
			Key85=65462:54
			Key86=65451:43
			Key87=65457:49
			Key88=65458:50
			Key89=65459:51
			Key90=65456:48
			Key91=65454:46
			Key92=0:0
			Key93=0:0
			Key94=62:62
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65312:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65312:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=65513:0
			Key126=65469:61
			Key127=65515:0
			Key128=65517:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key10=124:124
			Key11=64:64
			Key12=35:35
			Key13=126:126
			Key14=189:189
			Key15=172:172
			Key16=123:123
			Key17=91:91
			Key18=93:93
			Key19=125:125
			Key20=92:92
			Key21=126:126
			Key22=65288:8
			Key23=65289:9
			Key24=64:64
			Key25=435:322
			Key26=8364:8364
			Key27=182:182
			Key28=956:359
			Key29=2299:8592
			Key30=2302:8595
			Key31=2301:8594
			Key32=248:248
			Key33=254:254
			Key34=91:91
			Key35=93:93
			Key36=65293:13
			Key37=65507:0
			Key38=230:230
			Key39=223:223
			Key40=240:240
			Key41=496:273
			Key42=959:331
			Key43=689:295
			Key44=106:106
			Key45=930:312
			Key46=435:322
			Key47=126:126
			Key48=123:123
			Key49=92:92
			Key50=65505:0
			Key51=125:125
			Key52=171:171
			Key53=187:187
			Key54=162:162
			Key55=2770:8220
			Key56=2771:8221
			Key57=110:110
			Key58=181:181
			Key59=2211:0
			Key60=183:183
			Key61=65120:0
			Key62=65506:0
			Key63=65450:42
			Key64=65513:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65407:0
			Key78=65300:0
			Key79=65429:0
			Key80=65431:0
			Key81=65434:0
			Key82=65453:45
			Key83=65430:0
			Key84=65437:0
			Key85=65432:0
			Key86=65451:43
			Key87=65436:0
			Key88=65433:0
			Key89=65435:0
			Key90=65438:0
			Key91=65439:0
			Key92=0:0
			Key93=0:0
			Key94=124:124
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65508:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65516:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=0:0
			Key126=65469:61
			Key127=0:0
			Key128=0:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[capslock]
			Key8=65406:0
			Key9=65307:27
			Key10=49:49
			Key11=50:50
			Key12=51:51
			Key13=52:52
			Key14=53:53
			Key15=54:54
			Key16=55:55
			Key17=56:56
			Key18=57:57
			Key19=48:48
			Key20=39:39
			Key21=161:161
			Key22=65288:8
			Key23=65289:9
			Key24=81:81
			Key25=87:87
			Key26=69:69
			Key27=82:82
			Key28=84:84
			Key29=89:89
			Key30=85:85
			Key31=73:73
			Key32=79:79
			Key33=80:80
			Key34=65104:96
			Key35=43:43
			Key36=65293:13
			Key37=65507:0
			Key38=65:65
			Key39=83:83
			Key40=68:68
			Key41=70:70
			Key42=71:71
			Key43=72:72
			Key44=74:74
			Key45=75:75
			Key46=76:76
			Key47=209:209
			Key48=65105:180
			Key49=186:186
			Key50=65505:0
			Key51=199:199
			Key52=90:90
			Key53=88:88
			Key54=67:67
			Key55=86:86
			Key56=66:66
			Key57=78:78
			Key58=77:77
			Key59=44:44
			Key60=46:46
			Key61=45:45
			Key62=65506:0
			Key63=65450:42
			Key64=65513:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65407:0
			Key78=65300:0
			Key79=65429:0
			Key80=65431:0
			Key81=65434:0
			Key82=65453:45
			Key83=65430:0
			Key84=65437:0
			Key85=65432:0
			Key86=65451:43
			Key87=65436:0
			Key88=65433:0
			Key89=65435:0
			Key90=65438:0
			Key91=65439:0
			Key92=0:0
			Key93=0:0
			Key94=60:60
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65508:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65516:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=0:0
			Key126=65469:61
			Key127=0:0
			Key128=0:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[shiftcapslock]
			Key8=65406:0
			Key9=65307:27
			Key10=33:33
			Key11=34:34
			Key12=183:183
			Key13=36:36
			Key14=37:37
			Key15=38:38
			Key16=47:47
			Key17=40:40
			Key18=41:41
			Key19=61:61
			Key20=63:63
			Key21=191:191
			Key22=65288:8
			Key23=65056:0
			Key24=113:113
			Key25=119:119
			Key26=101:101
			Key27=114:114
			Key28=116:116
			Key29=121:121
			Key30=117:117
			Key31=105:105
			Key32=111:111
			Key33=112:112
			Key34=65106:94
			Key35=42:42
			Key36=65293:13
			Key37=65507:0
			Key38=97:97
			Key39=115:115
			Key40=100:100
			Key41=102:102
			Key42=103:103
			Key43=104:104
			Key44=106:106
			Key45=107:107
			Key46=108:108
			Key47=241:241
			Key48=65111:168
			Key49=170:170
			Key50=65505:0
			Key51=231:231
			Key52=122:122
			Key53=120:120
			Key54=99:99
			Key55=118:118
			Key56=98:98
			Key57=110:110
			Key58=109:109
			Key59=59:59
			Key60=58:58
			Key61=95:95
			Key62=65506:0
			Key63=65450:42
			Key64=65511:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65273:0
			Key78=65300:0
			Key79=65463:55
			Key80=65464:56
			Key81=65465:57
			Key82=65453:45
			Key83=65460:52
			Key84=65461:53
			Key85=65462:54
			Key86=65451:43
			Key87=65457:49
			Key88=65458:50
			Key89=65459:51
			Key90=65456:48
			Key91=65454:46
			Key92=0:0
			Key93=0:0
			Key94=62:62
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65312:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65312:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=65513:0
			Key126=65469:61
			Key127=65515:0
			Key128=65517:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[altgr]
			Key8=65406:0
			Key9=65307:27
			Key10=124:124
			Key11=64:64
			Key12=35:35
			Key13=126:126
			Key14=189:189
			Key15=172:172
			Key16=123:123
			Key17=91:91
			Key18=93:93
			Key19=125:125
			Key20=92:92
			Key21=126:126
			Key22=65288:8
			Key23=65289:9
			Key24=64:64
			Key25=435:322
			Key26=8364:8364
			Key27=182:182
			Key28=956:359
			Key29=2299:8592
			Key30=2302:8595
			Key31=2301:8594
			Key32=248:248
			Key33=254:254
			Key34=91:91
			Key35=93:93
			Key36=65293:13
			Key37=65507:0
			Key38=230:230
			Key39=223:223
			Key40=240:240
			Key41=496:273
			Key42=959:331
			Key43=689:295
			Key44=106:106
			Key45=930:312
			Key46=435:322
			Key47=126:126
			Key48=123:123
			Key49=92:92
			Key50=65505:0
			Key51=125:125
			Key52=171:171
			Key53=187:187
			Key54=162:162
			Key55=2770:8220
			Key56=2771:8221
			Key57=110:110
			Key58=181:181
			Key59=2211:0
			Key60=183:183
			Key61=65120:0
			Key62=65506:0
			Key63=65450:42
			Key64=65513:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65407:0
			Key78=65300:0
			Key79=65429:0
			Key80=65431:0
			Key81=65434:0
			Key82=65453:45
			Key83=65430:0
			Key84=65437:0
			Key85=65432:0
			Key86=65451:43
			Key87=65436:0
			Key88=65433:0
			Key89=65435:0
			Key90=65438:0
			Key91=65439:0
			Key92=0:0
			Key93=0:0
			Key94=124:124
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65508:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65516:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=0:0
			Key126=65469:61
			Key127=0:0
			Key128=0:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[capslock]
			Key8=65406:0
			Key9=65307:27
			Key10=49:49
			Key11=50:50
			Key12=51:51
			Key13=52:52
			Key14=53:53
			Key15=54:54
			Key16=55:55
			Key17=56:56
			Key18=57:57
			Key19=48:48
			Key20=39:39
			Key21=161:161
			Key22=65288:8
			Key23=65289:9
			Key24=81:81
			Key25=87:87
			Key26=69:69
			Key27=82:82
			Key28=84:84
			Key29=89:89
			Key30=85:85
			Key31=73:73
			Key32=79:79
			Key33=80:80
			Key34=65104:96
			Key35=43:43
			Key36=65293:13
			Key37=65507:0
			Key38=65:65
			Key39=83:83
			Key40=68:68
			Key41=70:70
			Key42=71:71
			Key43=72:72
			Key44=74:74
			Key45=75:75
			Key46=76:76
			Key47=209:209
			Key48=65105:180
			Key49=186:186
			Key50=65505:0
			Key51=199:199
			Key52=90:90
			Key53=88:88
			Key54=67:67
			Key55=86:86
			Key56=66:66
			Key57=78:78
			Key58=77:77
			Key59=44:44
			Key60=46:46
			Key61=45:45
			Key62=65506:0
			Key63=65450:42
			Key64=65513:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65407:0
			Key78=65300:0
			Key79=65429:0
			Key80=65431:0
			Key81=65434:0
			Key82=65453:45
			Key83=65430:0
			Key84=65437:0
			Key85=65432:0
			Key86=65451:43
			Key87=65436:0
			Key88=65433:0
			Key89=65435:0
			Key90=65438:0
			Key91=65439:0
			Key92=0:0
			Key93=0:0
			Key94=60:60
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65508:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65516:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=0:0
			Key126=65469:61
			Key127=0:0
			Key128=0:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0
			[shiftcapslock]
			Key8=65406:0
			Key9=65307:27
			Key10=33:33
			Key11=34:34
			Key12=183:183
			Key13=36:36
			Key14=37:37
			Key15=38:38
			Key16=47:47
			Key17=40:40
			Key18=41:41
			Key19=61:61
			Key20=63:63
			Key21=191:191
			Key22=65288:8
			Key23=65056:0
			Key24=113:113
			Key25=119:119
			Key26=101:101
			Key27=114:114
			Key28=116:116
			Key29=121:121
			Key30=117:117
			Key31=105:105
			Key32=111:111
			Key33=112:112
			Key34=65106:94
			Key35=42:42
			Key36=65293:13
			Key37=65507:0
			Key38=97:97
			Key39=115:115
			Key40=100:100
			Key41=102:102
			Key42=103:103
			Key43=104:104
			Key44=106:106
			Key45=107:107
			Key46=108:108
			Key47=241:241
			Key48=65111:168
			Key49=170:170
			Key50=65505:0
			Key51=231:231
			Key52=122:122
			Key53=120:120
			Key54=99:99
			Key55=118:118
			Key56=98:98
			Key57=110:110
			Key58=109:109
			Key59=59:59
			Key60=58:58
			Key61=95:95
			Key62=65506:0
			Key63=65450:42
			Key64=65511:0
			Key65=32:32
			Key66=65509:0
			Key67=65470:0
			Key68=65471:0
			Key69=65472:0
			Key70=65473:0
			Key71=65474:0
			Key72=65475:0
			Key73=65476:0
			Key74=65477:0
			Key75=65478:0
			Key76=65479:0
			Key77=65273:0
			Key78=65300:0
			Key79=65463:55
			Key80=65464:56
			Key81=65465:57
			Key82=65453:45
			Key83=65460:52
			Key84=65461:53
			Key85=65462:54
			Key86=65451:43
			Key87=65457:49
			Key88=65458:50
			Key89=65459:51
			Key90=65456:48
			Key91=65454:46
			Key92=0:0
			Key93=0:0
			Key94=62:62
			Key95=65480:0
			Key96=65481:0
			Key97=65360:0
			Key98=65362:0
			Key99=65365:0
			Key100=65361:0
			Key101=0:0
			Key102=65363:0
			Key103=65367:0
			Key104=65364:0
			Key105=65366:0
			Key106=65379:0
			Key107=65535:127
			Key108=65421:13
			Key109=65312:0
			Key110=65299:0
			Key111=65377:0
			Key112=65455:47
			Key113=65027:0
			Key114=0:0
			Key115=65515:0
			Key116=65312:0
			Key117=65383:0
			Key118=0:0
			Key119=0:0
			Key120=0:0
			Key121=0:0
			Key122=0:0
			Key123=0:0
			Key124=65027:0
			Key125=65513:0
			Key126=65469:61
			Key127=65515:0
			Key128=65517:0
			Key129=0:0
			Key130=0:0
			Key131=0:0
			Key132=0:0
			Key133=0:0
			Key134=0:0
			Key135=0:0
			Key136=0:0
			Key137=0:0


	* Reiniciamos el servicio *xrdp* para recargar la configuración:
	
			service xrdp restart

7. Eliminamos el gestor de red Network Manager para evitar posibles interferencias con la configuración de red de OpenStack:

		# apt-get remove --purge network-manager

	... y editamos el fichero `/etc/network/interfaces` añadiendo la siguiente configuración:

		auto eth0
		iface eth0 inet dhcp

	Reiniciamos el servicio de red:

		# service networking restart`
  
9.  Comprobamos que el cortafuegos esté deshabilitado.

10. Pasamos el parámetro `console` al kernel en el inicio, de esta forma nos aseguramos que los logs del kernel se mostrarán en la consola de OpenStack.  
    Editamos el fichero `/etc/default/grub` modificando la línea:

    	#GRUB_CMDLINE_LINUX_DEFAULT=""
    por esta otra:

    	GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0"
    ... y ejecutamos el comando:

    	root@ubuntu:~# update-grub

11. Eliminamos cosas innecesarias a través de los comandos:

		root@ubuntu:~# apt-get autoremove
		root@ubuntu:~# apt-get clean
		root@ubuntu:~# rm /root/.bash_history
		root@ubuntu:~# rm /home/usuario/.bash_history
		root@ubuntu:~# rm /var/log/auth.log
		root@ubuntu:~# export HISTSIZE=0

12. Iniciamos sesión gráfica e iniciamos los siguientes programas, de esta forma la creación de configuraciones locales se queda hecha acelerando el inicio de los programas la primera vez:

	* Iniciamos sesión con _Unity_.
  	* Iniciamos sesión con _Gnome Classic_.
  	* iniciamos Firefox.
  	* Iniciamos LibreOffice.
  	* Iniciamos Eclipse.
  	* Iniciamos Chrome.

12. Instalamos el paquete cloud-init:

		root@ubuntu:~# apt-get install cloud-init cloud-utils

	... y realizamos las siguientes modificaciones al principio del fichero `/etc/cloud/cloud.cfg`:

		user: openvdi
		locale: es_ES.UTF-8

	... siendo `openvdi` el usuario del sistema creado durante la instalación y que utilizará para que el servidor _metadata_ de OpenStack inyecte la clave pública en la cuenta.
	Para que cloud-init sea capaz de ajustar el tamaño del sistema de ficheros raíz en el inicio de la máquina virtual hay que instalar además el paquete `cloud-initramfs-growroot` a través del comando:

		apt-get install cloud-initramfs-growroot

	... en caso contrario el disco reflejará el tamaño del _flavour_ escogido, pero la partición raíz no se redimensionará en el inicio.
 
9. Una vez instalado, reconfiguramos el paquete *cloud-init* para que utilice como fuente de metadatos el servicio EC2 de Amazon para el cual ha sido configurado OpenStack.

		# dpkg-reconfigure cloud-init
![](dpkg-reconfigure_cloud-init.png)

8.  Eliminamos el contenido, solo el contenido, de los ficheros que regulan las reglas `udev` encargadas de registrar las MAC de las interfaces de red:
    * `/etc/udev/rules.d/70-persistent-net.rules`
    * `/etc/udev/rules.d/75-persistent-net-generator.rules`

	Como alternativa, podemos ejecutar el comando `virt-sysprep`:

		# virt-sysprep -d <nombre_maquina>

13. Apagamos la máquina a través del comando `# shutdown -h now` y la subimos al nuestro cloud a través del servicio Glance:

		glance image-create --name="Ubuntu Server 12.04.4 64 bits" --is-public=true --container-format=bare --disk-format=qcow2 < imagen.qcow2

14. Borrar la máquina virtual creada y el volumen asociado:

		virsh undefine <nombre_maquina>
		vol-list --pool default
		vol-delete <nombre_volumen> --pool default


## Creación de imágenes Windows 7

1. Creamos el fichero que albergará la imagen en formato `qcow2` de Windows 7. Si vamos a instalar el Service Pack 1 así como el resto de actualizaciones existentes, además de algún navegador adicional o software antivirus, nuestra imagen crecerá considerablemente desde los 7 GB que puede ocupar una instalación limpia. Es por ello que se recomienda darle un tamaño de, al menos, unos 20 GB:

		qemu-img create -f qcow2 /home/jose/VMs/libvirt/Windows7.qcow2 20G

2. Descargamos la última versión de los driver VirtIO para el correcto funcionamiento de sistemas Windows sobre KVM desde la direccion <http://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers>.

3. Lanzamos la instalación de la máquina virtual Windows desde `virt-manager` o con el comando `virt-install`. En este último caso, el comando sería muy similar a:

		virt-install --virt-type=kvm \
		--name windows7  \
		--ram 1024 \
		--vcpus=1 \
		--disk path=/home/usuario/VMs/libvirt/Windows7.qcow2,size=20,bus=virtio \
		--cdrom /home/usuario/Windows7.iso \
		--disk path=/var/lib/libvirt/images/virtio-win-0.1-65.iso,device=cdrom \
		--os-type windows \
		--os-variant=win2k8 \
		--graphics vnc,keymap=es \
		--noautoconsole \
		--network network=default,model=virtio \
		--description "Windows 7"

	De toda esta secuencia de comandos conviene remarcar tres detalles importantes:

	* La imagen de almacenamiento usará los drivers VirtIO (`--disk …,bus=virtio`). Recurriremos a ellos durante el proceso de instalación para que Windows identifique dicha imagen como una unidad de disco.
	* Windows 7 identificará estos drivers (`virtio-win-0.1-65.iso`) durante la instalación como si estuvieran almacenados en un CD-ROM (`device=cdrom`) y allí es donde tendremos que buscarlos.
	* La configuración de red se hará igualmente utilizando los drivers VirtIO (`--network …,model=virtio`). De hecho, cuando finalice la instalación tendremos que configurar el controlador de dispositivos de red de nuestro Windows recurriendo a los drivers VirtIO correspondientes.
	* En el caso de instalar la versión 64 bits de Windows 7 hay que presentar las dos versiones de los drivers, la de 32 y la de 64 bits.

4. Durante la instalación no es necesario hacer nada fuera de lo normal, salvo indicarle al sistema operativo que busque los drivers para la controladora de disco en el CD-ROM que configuramos en el comando de instalación. Utilizaremos una única partición para el sistema (aunque, por defecto, Windows crea una partición de 100 MB al principio del disco para el arranque).

5. Una vez terminada la instalación, realizamos todas las actualizaciones necesarias desde Windows Update. Al tener que repetir el proceso varias veces, la actualización completa del sistema puede durar varias horas.

5. Instalamos el siguiente software:

	**Firefox**
	:	<http://www.mozilla.org/es-ES/>

	**Google Chrome**
	:	<https://www.google.com/intl/es/chrome/>

	**Java**
	:	<https://www.java.com/es/>

	**Plugin Flash**
	:	<http://get.adobe.com/es/flashplayer/>

	**Evince** (lector PDF)
	:	<https://wiki.gnome.org/Apps/Evince>

	**CutePDF**(impresora PDF)
	:	<http://www.cutepdf.com/>

	**LibreOffice**
	:	<http://www.libreoffice.org/download>

	**Microsoft Office**
	:	<http://office.microsoft.com/es-es/>

	**GIMP**
	:	<http://www.gimp.org/downloads/>

	**Inkscape**
	:	<http://www.inkscape.org/es/>

	**Filezilla**
	:	<https://filezilla-project.org/>

	**VLC**
	:	<http://www.videolan.org/vlc/index.html>

	**Audacity**
	:	<http://audacity.sourceforge.net/download/windows>

	**Notepad++**
	:	<http://notepad-plus-plus.org/>

	**Putty**
	:	<http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html>

	**Eclipse**
	:	<http://www.eclipse.org/>.  
		Para Eclipse instalamos los plugins para Java, Python, C/C++ y PHP.

6. Desactivamos:
	* Desde las "Propiedades de Conexión de área local":
		- "Protocolo de internet versión6 (TCP/IPv6)".
		- "Compartir impresoras y archivos para redes Microsoft".
	* Actualizaciones automáticas.
	* El cortafuegos.
	* El antivirus y cualquier aviso relativo a él.
	* Localización de red por defecto (_Network Location_):
		- Windows 7 tiene dos localizaciones: pública y privada. Es altamente recomendable que Windows no pregunte por la localización si aparece una red nueva. Para ello elegimos 'pública' como localización por defecto para todas las redes nuevas.
		- Se pueden modificar ciertos parámetros a través del programa `"gpedit.msc" -> Computer Configuration –> Windows Settings –> Security Settings –> Network list manager`.
	* Mensajes de Windows (desde la "banderita" que aparece en el panel de indicadores de la barra de tareas).
	* Efectos gráficos.
		- Desde el panel de control, buscamos la palabra "rendimiento".
		- Ajustamos los efectos visuales.

6. Como configuración del usuario administrador podemos configurar:
	* Equipo -> Menú -> Herramientas -> Opciones de carpeta -> Ver -> Desactivar "Ocultar las extensiones de archivo..."

6. Después de actualizar el equipo, puede resultar conveniente optimizar el tamaño de los archivos del mismo. El propio Windows nos proporciona dos herramientas que nos pueden hacer ahorrar varios GB:
	* Reducimos el tamaño asignado a la "Papelera de Reciclaje".
	* Opcionalmete, podemos reducir el tamaño asignado al fichero de paginación (Memoria Virtual).
	* Borramos el contenido de la carpeta `C:\Windows\Temp`.
	* Con el “Liberador de espacio de disco” podremos eliminar algunos ficheros creados durante el proceso de actualización y que ya no necesitamos. Para abrirlo, basta con pulsar `Win+R` y escribir en la barra de texto el comando `cleanmgr`.
	* Eliminar el backup del Service Pack 1. Para ello, ejecutamos desde un cmd y con permisos de Administrador el siguiente comando:
`DISM /online /cleanup-image /spsuperseded`		
	Este proceso puede tardar varios minutos.
	* Hay una forma alternativa de eliminar el espacio ocupado por las actualizaciones de Windows, para borrar la carpeta `C:\Windows\SoftwareDistribution\` ejecutamos como administradores (opción _Ejecutar como..._) los siguientes comandos:
	
			cd C:\Windows
			net stop wuauserv
            ren SoftwareDistribution SoftwareDistributionOLD
            net start wuauserv
            rd /s /q SoftwareDistributionOLD

8. Habilitamos el acceso a Windows 7 a través del servicio de Escritorio Remoto. Para ello vamos a *Inicio → (Botón Derecho) + Propiedades → Configuración de Acceso remoto*. Y activamos la casilla *“Permitir las conexiones desde equipos que ejecuten cualquier versión de Escritorio remoto”*.  
En esta misma sección podemos seleccionar qué usuarios podrán conectarse a la máquina a través de Escritorio remoto (los miembros del grupo *Administradores* tienen acceso por defecto).

9. Instalamos _Cloud-Init for Windows_ de _Cloudbase Solutions_. La instalación y parcheo de cloud-init se detalla en el siguiente apartado.

7. Sin embargo, aunque se reduzca el espacio efectivo ocupado en el disco de nuestra máquina virtual, el fichero `qcow2` seguirá ocupando el mismo tamaño que antes de la eliminación de datos.
Esto se produce porque todo aquel espacio de disco que ha sido utilizado primero y luego borrado del disco no se elimina físicamente, es decir, no vuelve a cero, sino que sigue manteniendo el contenido previo. El sistema de ficheros sólo quita la referencia en el índice del sistema de ficheros al conjunto de clusters del disco que tiene el contenido real del archivo. No "vemos" los archivos eliminados porque el índice de archivos existentes no los tiene, pero físicamente los archivos siguen estando.
No obstante, al convertir entre formatos de disco, `qemu-img` sí reconoce como espacio vacío los bytes a cero. Por tanto, para ajustar el tamaño de nuestro fichero `qcow2` al espacio efectivamente empleado en el disco tenemos que seguir los siguientes pasos:
	* Convertimos el fichero `qcow2` original a formato `raw`. Obteniendo dos ficheros, en nuestro caso,`Windows7.qcow2` y `Windows7.raw`.		
`# qemu-img convert Windows7.qcow2 Windows7.raw`
	* Mapeamos el archivo `Windows7.raw` como un dispositivo de bloques con `kpartx` (`apt-get install kpartx`).		
`# kpartx -a Windows7.raw`
	* Esto nos creará un dispositivo de `loop` en `/dev/mapper` por cada una de las particiones existentes en la imagen. En nuestro caso dos: `loop0p1` y `loop02`.		
		```
		# ls /dev/mapper
		control  loop0p1  loop0p2
		```
	* Montamos el dispositivo con la partición de Windows (`loop0p2`) en un punto de montaje (`/mnt`).		
`# mount -t ntfs -o loop /dev/mapper/loop0p2 /mnt`	
	* Creamos un fichero lleno de ceros que ocupará el espacio restante en el fichero con el comando `dd`.		
`# dd if=/dev/zero of=/mnt/borrame.000 bs=4096`
	* Eliminamos el fichero con los ceros.		
`# rm /mnt/borrame.000`
	* Desmontamos el dispositivo `loop` del punto de montaje.		
`# umount /mnt`
	* Eliminamos el mapeo de las particiones del fichero `Windows7.raw` en nuestra lista de dispositivos de bloque.		
		```
		# kpartx -d Windows7.raw
		loop deleted : /dev/loop0
		```
	* Convertimos el fichero `raw` resultante a `qcow2`.		
`# qemu-img convert -f raw -O qcow2 Windows7.raw Windows7-optimizado.qcow2` 
	* Refrescamos la lista de imágenes disponibles en nuestro pool de imágenes de disco, que en nuestro caso se llama `VMs`.		
`# virsh pool-refresh VMs`
	* Comprobamos como el nuevo fichero `qcow2` es sensiblemente más pequeño.

			# ls -lh /home/usuario/VMs/libvirt
			...
			-rw-r--r-- 1 root         root  19G abr 29 09:22 Windows7.qcow2 
			-rw-r--r-- 1 root         root  20G abr 29 09:55 Windows7.raw 
			-rw-r--r-- 1 root         root  15G abr 29 10:11 Windows7-optimizado.qcow2
			...

7. Hay una forma alternativa de comprimir el espacio que ocupa la imagen QCOW2:

	* Desfragmentamos el disco duro desde el propio Windows.
	* Escribimos con ceros todos los bloques libres del sistema de ficheros NTFS de la unidad C:, se puede hacer con la utilidad _sdelete_ que Microsoft pone a disposición desde la URL <http://technet.microsoft.com/en-us/sysinternals/bb897443.aspx>, basta con descargarla y guardarla en `C:\Windows\System32`. La ejecutamos a través del comando:
	
			sdelete -z

	* Apagamos la máquina virtual.
	* Utilizamos el comando `qemu-img` para convertir la imagen pero manteniendo el mismo formato, después borramos la imagen original. Podemos añadir al comando la opción -c si queremos, además, comprimir la imagen:
	
			qemu-img convert -c -O qcow2 original.qcow2 compress.qcow2
			mv compress.qcow2 original.qcow2



10. Ejecutamos la herramienta `sysprep` en el cliente Windows 7 que se encuentra en la siguiente ruta.(POR CONFIRMAR: parece que `cloudbase-init` ya ejecuta `sysprep`).
`c:\windows\system32\sysprep\sysprep.exe`
![](Creacionsysprep.png)

11. Apagamos la máquina y subimos la imagen a Glance:
`# glance image-create --name="Windows 7" --is-public=true --container-format=bare --disk-format=qcow2 < Windows7-optimizado.qcow2`

12. Borramos la máquina virtual creada y el volumen asociado:
	`# virsh undefine <nombre_maquina>`
	`# vol-delete <nombre_volumen> --pool <nombre_pool>`

### Instalación de cloud-init

El software _cloud-init for Windows instaces_ de Cloudbase Solutions intenta aportar toda la funcionalidad que se consigue a través del paquete cloud-init en entornos GNU/Linux. Cuenta con una gran funcionalidad pero aún no implementan todo lo que permite el sofware para Linux, concretamente no soporta el paso de parámetros de configuración (etiquetados como `#cloud-config`) a través del campo _userdata_.

Para la instalación, configuración y parcheo de cloud-init seguimos los siguientes pasos:

1. Nos descargamos el paquete MSI desde la URL: <http://www.cloudbase.it/cloud-init-for-windows-instances/>, el paquete se llama _CloudbaseInitSetup_Beta.msi_.
2. Para que la instalación del paquete funcione correctamente es necesario renombrar el grupo local *Administradores* a su nombre original *Administrators*, aunque el asistente permite configurar este parámetros, es algo que en las versiones actuales no funciona. por lo que dejamos en Windows el nombre del grupo en inglés.
3. Lanzamos el asistente prestando especial atención al siguiente paso:

![](cloud-init.step1.png)  
4. En el último paso se realiza la configuración de _SysPrep_, marcamos la primera opción y dejamos libre la segunda:

![](cloud-init.step2.png)  
5. Desde el propio proyecto hemos desarrollado un _pequeño_ plugin que permite recoger la contraseña desde el campo _userdata_ que proporciona el servicio _metadata_ de OpenStack, para ello hay que copiar el plugin en un determinado directorio y parchear la lista de plugins activos:

  * Guardamos el siguiente código en el fichero `userdataadminpassword.py`, dentro del directorio `C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\Python27\Lib\site-packages\cloudbaseinit\plugins\windows\`:
   
```python
# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2012 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import re

from oslo.config import cfg
from cloudbaseinit.metadata.services import base as metadata_services_base
from cloudbaseinit.openstack.common import log as logging
from cloudbaseinit.osutils import factory as osutils_factory
from cloudbaseinit.plugins import base
from cloudbaseinit.plugins.windows import userdatautils
from cloudbaseinit.plugins.windows.userdataplugins import factory

opts = [
    cfg.StrOpt('username', default='Admin', help='User to be added to the '
               'system or updated if already existing'),
    cfg.ListOpt('groups', default=['Administrators'], help='List of local '
                'groups to which the user specified in \'username\' will '
                'be added'),
]

CONF = cfg.CONF
CONF.register_opts(opts)

LOG = logging.getLogger(__name__)


class UserDataAdminPasswordPlugin(base.BasePlugin):
    #_PART_HANDLER_CONTENT_TYPE = "text/part-handler"
    #_GZIP_MAGIC_NUMBER = '\x1f\x8b'

    def execute(self, service, shared_data):
        LOG.debug('OpenMurVDI: executing UserDataAdminPassword Plugin from OpenMurVDI Project')
        try:
            user_data = service.get_user_data()
        except metadata_services_base.NotExistingMetadataException:
            LOG.info("OpenMurVDI: can't connect to Metadata service")
            return (base.PLUGIN_EXECUTION_DONE, False)

        if not user_data:
            LOG.info("OpenMurVDI: user_data doesn't exist")
            return (base.PLUGIN_EXECUTION_DONE, False)

        #user_data = self._check_gzip_compression(user_data)

        # We have to check the file structure and the password
        lines = user_data.split('\n')
        regex = re.compile("password: (.+)$")

        password = ''
        for line in lines:
            mo = regex.match(line)
            if mo:
                password = mo.group(1)
                break
        # Password contains the password in user_data
        user_name = CONF.username
        #LOG.debug("OpenMurVDI: setting password '" + password + "' to user '" + user_name + "'")
        LOG.debug("OpenMurVDI: setting password from user_data to user '" + user_name + "'")

        osutils = osutils_factory.get_os_utils()
        osutils.set_user_password(user_name, password)

        return (base.PLUGIN_EXECUTION_DONE, False)
```
  * En el directorio `C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\Python27\Lib\site-packages\cloudbaseinit\plugins\`, después de la siguiente línea (línea 35) del fichero `factory.py`:

			'SetUserPasswordPlugin', 			
  	... añadimos la carga de nuestro plugin, dejando el contenido así:
			
			'SetUserPasswordPlugin',
			'cloudbaseinit.plugins.windows.userdataadminpassword.UserDataAdminPasswordPlugin',

  * De ese mismo directorio borramos el fichero `factory.pyc`.

6. Configuramos el servicio para que arranque de forma automática.
7. Apagamos la máquina.

# Gestión de imágenes QCOW2
Una vez creada la imagen QCOW2 puede resultar muy útil trabajar directamente con el fichero QCOW2 en el caso de que fuese necesario tomar algún fichero de la imagen o realizar pequeños cambios.

* Podemos acceder directamente a una imagen QCOW2 ejecutando los siguientes comandos:
		root@jupiter:~# guestfish --ro -a cirros-0.3.1-x86_64-disk.img 

		Welcome to guestfish, the libguestfs filesystem interactive shell for
		editing virtual machine filesystems.

		Type: 'help' for help on commands
		      'man' to read the manual
		      'quit' to quit the shell

		><fs> run
		◓ 25% ⟦▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓═════════════════════════════════════════════════⟧ --:--
		 100% ⟦▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓⟧ 00:00
		><fs> list-filesystems 
		/dev/vda1: ext3
		><fs> mount /dev/vda1 /
		><fs> ll /
		total 42
		drwxr-xr-x 21 0 0  1024 Feb  8  2013 .
		drwxr-xr-x 21 0 0  4096 Jun 11 10:34 ..
		drwxrwxr-x  2 0 0  3072 Feb  8  2013 bin
		drwxr-xr-x  3 0 0  1024 Feb  8  2013 boot
		drwxr-xr-x  3 0 0  1024 Feb  8  2013 dev
		drwxrwxr-x 11 0 0  1024 Feb  8  2013 etc
		drwxrwxr-x  4 0 0  1024 Feb  8  2013 home
		-rwxr-xr-x  1 0 0  2616 Feb  8  2013 init
		lrwxrwxrwx  1 0 0    32 Feb  8  2013 initrd.img -> boot/initrd.img-3.2.0-37-virtual
		drwxrwxr-x  4 0 0  1024 Feb  8  2013 lib
		lrwxrwxrwx  1 0 0    11 Feb  8  2013 linuxrc -> bin/busybox
		drwx------  2 0 0 12288 Feb  8  2013 lost+found
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 media
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 mnt
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 old-root
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 opt
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 proc
		drwx------  2 0 0  1024 Feb  8  2013 root
		drwxr-xr-x  2 0 0  1024 Feb  8  2013 run
		drwxrwxr-x  2 0 0  3072 Feb  8  2013 sbin
		drwxrwxr-x  2 0 0  1024 Feb  8  2013 sys
		drwxrwxrwt  3 0 0  1024 Feb  8  2013 tmp
		drwxrwxr-x  6 0 0  1024 Feb  8  2013 usr
		drwxrwxr-x  8 0 0  1024 Feb  8  2013 var
		lrwxrwxrwx  1 0 0    29 Feb  8  2013 vmlinuz -> boot/vmlinuz-3.2.0-37-virtual

		><fs> umount /
		><fs> exit

		root@jupiter:~#
  * Contamos además con otros comandos como: `ls`, `ll`, `cat`, `more`, `download`, `tar-out`, `edit`, `vi`, `emacs`, `write`, `mkdir`, `upload`, `tar-in`, `mkfs`, `part-add`, `lvcreate`, `lvresize`, etc.

* Podemos montar una imagen QCOW2 en el sistema siguiendo los siguientes pasos:
Para montar una imagen QCOW2 seguimos los siguientes pasos:
	
	1. Cargamos el módulo _nbd_:

			modprobe nbd max_part=63

	2. Asignamos un dispositivo NBD a la imagen que queremos utilizar:
			
	    	qemu-nbd -c /dev/nbd0 Windows7.img

	3. Trabajamos con los ficheros de la imagen:  
	    Ver tabla de particiones:

	    	fdisk /dev/nbd0

	    Montar la segunda partición (ya sea de Windows o Linux):

	        mount -o ro /dev/nbd0p2 /mnt/

	    Desmontamos:

	    	umount /mnt     

	4. Desconectamos el dispositivo NBD y descargamos el módulo:

	        qemu-nbd -d /dev/nbd0
	        rmmod nbd

* Para ampliar el tamaño de una imagen QCOW2, por ejemplo en 2 GB, ejecutamos el comando:

		qemu-img resize Windows7Cloud.qcow2 +2G

	Hay que tener en cuenta dos cosas:
	
	  * La imagen no se puede redimensionar si tiene snapshots.
	  * Hay que redimensionar además, los sistemas de ficheros subyacentes.

* Para mostrar y eliminar snapshots podemos ejecutar los comandos:
	
		qemu-img snapshot -l Ubuntu.12.04.Desktop.Cloud.qcow2
		qemu-img snapshot -d <ID> Ubuntu.12.04.Desktop.Cloud.qcow2

* Podemos compactar una imagen QCOW2 a través del comando:

		qemu-img convert -O qcow2 Windows7Cloud.qcow2 shrunk.qcow2
