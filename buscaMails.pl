#!/usr/bin/perl
##################################################
# Autor: http://otroblogdetecnologias.blogspot.com 
#	 Juan Carlos Miranda juancarlosmiranda81@gmail.com
# Version: 1.0
#
# El autor no se hace responsable de los danos ocasionados por el uso del script
#
# Función del programa:
#======================
# Obtiene los correos dentro de archivos con formato texto
# Puede recibir como entrada archivos con codigo html
#=======================
#ATENCION !!!!
#=======================
# * Antes de correr colocar chmod 755 al script.
#
# * Funcional solamente bajo plataformas del tipo Unix, dado que tiene dependencias 
#   con los siguientes comandos: sort, uniq, rm
##################################################

##################################################
use strict;
use warnings;
use Getopt::Long; #procesamiento de parametros
##################################################


##################################################
#variables donde se guardan el archivo y directorio a procesar
my $directorio;
my $archivo;

##################################################
#para el archivo de reporte final, genera el nombre
#utilizando la fecha y hora del sistema
my $archivoReporte=`date +%Y%m%d%H%M%S`."-correos\.csv";
$archivoReporte=~s/\n//g; #quita los caracteres de nueva linea
##################################################

my $contadorArchivos=0; #cuenta la cantidad de archivos dentro de un directorio
##################################################


# Lee los parámetros en una variable rh_params
my $recibir_parametros = {};
GetOptions($recibir_parametros,
  'd:s',
  'a:s',
  'ayuda',
);
 
# Si se ha especificado el parámetro 'ayuda', imprimir la ayuda y terminar
$recibir_parametros->{ayuda} && imprime_ayuda( 0 );

 
# Los parametros son mutuamente excluyentes
# si ambos estan definidos se corta la ejecucion
if ( defined $recibir_parametros->{d} && defined $recibir_parametros->{a}) {
    imprime_ayuda( 1 );
}

#este modelo acepta solamente uno u otro valor
#si se definio el paramaetro pero el valor viene vacio imprime ayuda
if( defined $recibir_parametros->{d}) {
  if(!($recibir_parametros->{d} eq "")){  	
#####################################################################  	
	$directorio=$recibir_parametros->{d};
	opendir DH,$directorio or die "No se puede abrir el directorio $directorio: $!";
		
	print "===================================================\n";
	print "Procesando en $directorio -->                      \n";
	print "___________________________________________________\n";	

	#si llego hasta aqui es porque el directorio es correcto	
	foreach my $archivoDirectorio (readdir DH){
		print "|--> $archivoDirectorio \n";
		###################################	
		$contadorArchivos=$contadorArchivos+1;
		procesarArchivo($directorio.$archivoDirectorio,$archivoReporte);		
		###################################					
	}#foreach
	closedir DH;
	ordenarArchvoReporte($archivoReporte);
	print "___________________________________________________\n";	
	print "TOTAL DE ARCHIVOS PROCESADOS-> $contadorArchivos \n";
#####################################################################
  }else{
      imprime_ayuda( 1 );
  }
}else 
{
  if( defined $recibir_parametros->{a}) {
    if(!($recibir_parametros->{a} eq "")){
#####################################################################  	
	$archivo=$recibir_parametros->{a};
	#si llego hasta aca es porque el parametro del archivo esta bien
	open AR,$archivo or die "No se puede abrir el archivo: $archivo -> $!";
	#si llego hasta aca es porque el archivo es real
	###################################	
	#le pasa el archivo a verificar y el archivo para reporte final
	#el parametro 1=verdadero, 0=falso para sobreescribir el informe final
	procesarArchivo($archivo,$archivoReporte);
	ordenarArchvoReporte($archivoReporte);
	
	###################################	
	close AR;	
#####################################################################  	      
    }else{
      imprime_ayuda( 1 );
    }
  }else{
    imprime_ayuda( 1 );
  }
}


##################################################
## FIN PRINCIPAL
##################################################


####################################
#procesarArchivo()
#Procesa solamente un archivo
####################################
sub procesarArchivo{
	#$archivoVerificar=nombre de archivo con direcciones de correo en bruto
	#$arFinal=nombre del archivo que contendra el reporte final	
	my ($archivoVerificar,$arFinal)=@_;
	
	#archivos temporales
	my $arTemporal1="temporal.tmp";
	my $arTemporal2="temporal2.tmp";	
	
	############################################
	# abrir archivo segun parametro
	#hace una copia de seguridad del archivo original
	print "COPIANDO ARCHIVO $archivoVerificar --> $arTemporal1 \n";
	copiarArchivo($archivoVerificar,$arTemporal1);

	#elimina simbolos pasandolo a un segundo archivo temporal
	print "ELIMINANDO SIMBOLOS $arTemporal1-> $arTemporal2 -->\n";
	eliminarSimbolos($arTemporal1,$arTemporal2);	


	#abre el archivo temporal dos, el cual contiene las lineas sin simbolos
	open(FH, $arTemporal2    )or die "No se puede abrir el archivo: $arTemporal2 -> $!";
	print "BUSCANDO DIRECCIONES ->\n";
	############################################
	while (<FH>){
		chomp;
		if (/\@/) {
		#obtiene una linea del archivo temporal y escribe en el archivo de reporte final
			procesarLinea($_,$arFinal);
		}		
	}	
	############################################
	#cierra archivo temporal
	close(FH);		
}


##################################################
#Realiza una copia a aun archivo temporal
##################################################
sub copiarArchivo{
		my ($archivo1,$archivo2)=@_;
		#abre archivo1 para lectura
		open(ARCHIVO1,"<",$archivo1) or die "No se puede abrir el archivo: $archivo1 -> $!";
		#abre archivo2 para escritura, borrando todo
		open(ARCHIVO2,">",$archivo2) or die "No se puede abrir el archivo: $archivo2 -> $!";		
		while(<ARCHIVO1>){
			print ARCHIVO2 $_;
		}
		close(ARCHIVO1);
		close(ARCHIVO2);			
}

##################################################
#eliminarSimbolos()
#elimina los simbolos que no son utilizados y suplanta por espacios
##################################################
sub eliminarSimbolos{
	my ($archivo1,$archivo2)=@_;
	my $linea;
	#abre el archivo1 para lectura
	open(ARCHIVO1,"<",$archivo1) or die "No se puede abrir el archivo: $archivo1 -> $!";
	#abre el archivo2 para escritura, borrando todo
	open(ARCHIVO2,">",$archivo2) or die "No se puede abrir el archivo: $archivo2 -> $!";;		
	while(<ARCHIVO1>){
		#expresion que suplanta los simbolos cualquiera sea la ocurrencia
		#dentro de la linea leida			
		s/\[|\]|\?|\(|\)|<|>|'|"|=|\;|\,|\:|\&|\&gt|\&\#10/ /g;
		print ARCHIVO2 $_;
	}
	close(ARCHIVO1);
	close(ARCHIVO2);				
}

##################################################
#procesarLinea()
#lee linea por linea obteniendo los patrones correspondientes a cuentas
#de correo y las agrega al reporte final
#toma el parametro del nombre del archivo desde una instancia superior
##################################################
sub procesarLinea {
	my ($linea,$arFinal)=@_;	
	my @arreglo;
	#suprime los espacios y los tabuladores
	@arreglo= split /[\s|\t]+/, $linea;
	
	#abre el archivo de reporte en modo agregar
	open(FINAL,">>",$arFinal) or die "No se puede abrir el archivo: $arFinal -> $!";		
	#recorre por cada elemento del arreglo, buscando direcciones de correo
	#en una linea puede existir varias direcciones de correo
	foreach my $ar (@arreglo) {
		#es la expresion regular para obtener correos .com
		if($ar=~ /@(.)+\.[com]?/){
		  #escribe en el archivo el reporte final agregando al final
		  #cada direccion que encuentra, en letras minusculas
		  print FINAL "\L$ar\E, \n";			
		}	
	}
	close(FINAL);
}


##################################################
# ordenarArchvoReporte()
## ordenar archivos y eliminar repetidos
##################################################
sub ordenarArchvoReporte {
	my ($arFinal)=@_;
	print "\n Los correos procesados se encuentran en el archivo=>".$arFinal."\n";
	#procesa ordenando y eliminando los correos repetidos
	system ("sort ".$arFinal." > ".$arFinal."2");
	system ("uniq ".$arFinal."2"." > ".$arFinal);	
	#borra archivos temporales
	system ("rm -f ".$arFinal."2");	

}

 
sub imprime_ayuda {
    my $exit_status = shift;
 
    print <<"END"
 
    Uso: $0 [-d ruta directorio_busqueda | -a archivo_con_texto]
 
    Obtiene direcciones de correo desde un directorio con archivos o 
    desde un archivo ingresado por el usuario.
       
    Los parámetros son obligatorios si no se indica lo contrario:
 
          -d     procesa todos los archivos de un directorio
          -a     procesa solamente un archivo especificado          
          -ayuda Imprime esta ayuda
 
          Los parametros -d y -a son excluyentes entre si!!
           
END
;

    exit $exit_status;
}


