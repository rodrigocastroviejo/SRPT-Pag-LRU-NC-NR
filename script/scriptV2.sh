#!/bin/bash -

# ███████████████████████████████
# █                             █
# █     FUNCIONES GENERALES     █
# █                             █
# ███████████████████████████████

# ------------FUNCIONES DE INTRODUCCIÓN DE DATOS-------------

# DES: Lee la variable dada en raw. Se usa para que el input solo se interprete como texto
# RET: devuelve 0
# USO: leer var
leer() {
    read -r $1   # La opcion -r no perimite utilizar secuencias de escape con la contrabarra
    return 0
}

leer_numero() {

    # Variable temporal en la que se guarda el valor leido
    local val
    # Leer input del usuario
    leer val

    # Eliminar 0s del principio, porque dan problemas
    # Mientras val sea más largo que 1 y el primer caracter sea 0
    while [[ "${#val}" -gt "1" && "${val:0:1}" == "0" ]];do
        # Eliminar el primer caracter
        val="${val:1}"
    done

    # Asignar el valor a $1
    eval "$1=$val"

    # Si no se ha introducido nada
    if [ ${#val} -eq 0 ];then
        return 2
    # Si se introducen valores no numéricos. Incluyendo "-"
    elif [[ ! "${val}" =~ ^[0-9]+$ ]];then
        return 1
    # Si el número es demasiado grande
    # 9223372036854775807 es el valor máximo de entero que soporta BASH. Si es sobrepasado se
    # entra a valores negativos por overflow por lo que limitando la longitud y comprobando que
    # no se han entrado a valores negativos se asegura que el valor introducido no hace overflow.
    elif [[ "${#val}" -gt 19 || "$val" -lt 0 ]] || [ "$val" -gt "$numeroMaximo" ];then
        return 3
    fi

    return 0
}

leer_numero_entre() {

    # Se establece el mínimo y el máximo
    local min=$2
    local max
    # Si se da máximo y si no.
    [ $# -eq 3 ] && max=$3 || max=$numeroMaximo

    # Leer número 
    leer_numero $1
    # Dependiendo del valor devuelto por la función inmediatamente anterior
    case $? in
        
        # Valor válido
        #0 )
            # No se hace nada porque hay que compararlo más adelante   
        #;;
        # Valor no número natural
        1 )
            return 1
        ;;
        # No se ha introducido nada
        2 )
            return 2
        ;;
	# El valor es demasiado grande y crearia overflow(explicado en la anterior funcion)
        3 )
            return 3
        ;;
    esac

    # Si el número introducido se pasa del mínimo
    if [ ${!1} -lt $min ];then
        return 4
    # Si el número introducido se pasa del máximo
    elif [ ${!1} -gt $max ];then
        return 3
    fi

    return 0

}

# DES: Lee un nombre de archivo válido
# USO: leer_nombre_archivo var
leer_nombre_archivo() {
    # Variable donde se guarda el valor dado mientras se procesa.
    local temp

    # Va leyendo la variable hasta que se salga del loop.
    while leer temp;do

        # Si la cadena está vacía.
        if [ ${#temp} -eq 0 ];then
            echo -e -n "${ft[0]}${cl[$av]}AVISO${rstf}. Debes introducir algo: ${rstf}"
        
        # Si se han introducido más de los caracteres permitidos. Ext4 soporta un máximo de 256 bytes
        elif [ "$(echo "$temp" | wc -c)" -gt 256 ];then
            echo -e -n "${ft[0]}${cl[$av]}AVISO${rstf}. Nombre demasiado largo: ${rstf}"

        # Si se han introducido caracteres no permitidos
        elif [[ "$temp" =~ [\/\|\<\>:\&\\] ]];then
            echo -e -n "${ft[0]}${cl[$av]}AVISO${rstf}. No uses los caracteres '${ft[0]}${cl[$re]}/${rstf}', '${ft[0]}${cl[$re]}\\"
            echo -e -n "${rstf}', '${ft[0]}${cl[$re]}<${rstf}', '${ft[0]}${cl[$re]}>${rstf}', '${ft[0]}${cl[$re]}|${rstf}', '${ft[0]}${cl[$re]}&${rstf}' o '${ft[0]}${cl[$re]}:${rstf}': ${rstf}"
        
        # Si pasa las condiciones, salir del loop.
        else
            break
        fi

    done

    # Tras salir del loop se guarda el valor en la variable dada.
    eval "$1=$temp"
}

# DES: Muestra una pantalla de pregunta genérica con los parámetros dados
# USO: preguntar "Cabecera" \
#                "Pregunta" \
#                variable   \
#                "Opción 1" \ # Var=1
#                "Opción 2" \ # Var=2
#                   ....
#                "Opción n"   # Var=n
preguntar() {

    local titulo=$1
    local pregunta=$2

    # Elimina los caracteres especiales para guardarla en el informe a color.
    local preguntaPlano="$(echo -e "${pregunta}" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"

    # Vector donde se almacenan todas las opciones
    local opciones=()
    local numOpciones=$(( $# - 3 ))

    # Loop sobre los parámetros restantes para ir guardandolos en opciones
    for (( i=4; i <= $#; i++ ));do
        opciones+=("${!i}")
    done

    # Salida por pantalla
    cabecera "$titulo"
    echo -e "$pregunta"
    echo

    # Por cada índice se muestra la opción correspondiente
    for i in ${!opciones[*]};do
        echo -e "    ${cl[$re]}${ft[0]}[$(( $i + 1 ))]$rstf <- ${opciones[i]}"
    done

    echo

    local temp
    local encontrado
    echo -n "Selección: "
    while leer temp;do
        # Va comprobando si el valor dado es válido
        for (( i=1; i <= $numOpciones; i++ ));do
            if [[ "$i" == "$temp" ]];then
                
                encontrado=1
                break
            fi
        done
        
        # si se ha dado una opción válida salir
        [ $encontrado ] && break

        # Si no se ha encontrado valor válido volver a preguntar.
        echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce "

        # Crea un aviso con tantas opciones como se han dado.
        for i in ${!opciones[*]};do
            if [[ "$i" == 0 ]];then
                echo -n -e "${cl[$re]}${ft[0]}$(( $i + 1 ))${rstf}"
            elif [[ "$i" == $((${#opciones[*]} - 1)) ]];then
                echo -n -e " o ${cl[$re]}${ft[0]}$(( $i + 1 ))${rstf}: "
            else
                echo -n -e ", ${cl[$re]}${ft[0]}$(( $i + 1 ))${rstf}"
            fi
        done
    done

    # Muestra la pantalla tras seleccionar una respuesta valida y genera los informes
    cabecera $titulo
    echo -e $pregunta
    informar_color "$pregunta"
    informar_plano "$preguntaPlano"
    echo

    # Muestra las opciones, con la seleccionada resaltada
    for i in ${!opciones[*]};do
        if [ $(( $i + 1 )) -eq $temp ];then
            echo -e "    ${cl[1]}${ft[0]}${cf[2]}[$(( $i + 1 ))] <- ${opciones[i]}$rstf"
            informar_color "    ${cl[1]}${ft[0]}${cf[2]}[$(( $i + 1 ))] <- ${opciones[i]}$rstf"
            informar_plano "--->[$(( $i + 1 ))] <- ${opciones[i]}"
        else
            echo -e "    ${cl[$re]}${ft[0]}[$(( $i + 1 ))]$rstf <- ${opciones[i]}"
            informar_color "    ${cl[$re]}${ft[0]}[$(( $i + 1 ))]$rstf <- ${opciones[i]}"
            informar_plano "    [$(( $i + 1 ))] <- ${opciones[i]}"
        fi
    done

    echo
    informar_color ""
    informar_plano ""
    # Asigna el valor a la variable
    eval "$3=$temp"
    sleep 0.5

}

# DES: Pregunta de respuesta sí o no. No se guarda en informes
# RET: 0=Sí 1=No
# USO: preguntar_si_no pregunta
preguntar_si_no() {
    local pregunta=$1
    local temp
    echo -n -e "${pregunta} [S/n] "
    while leer temp;do
        case $temp in
            # Si se ha introducido S o s
            S | s )
                return 0
            ;;
            # Si se ha introducido N o n
            N | n )
                return 1
            ;;
            # Valor inválido
            * )
                echo -e -n "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce ${cl[$re]}${ft[0]}S${rstf} o ${cl[$re]}${ft[0]}n${rstf}: "
            ;;
        esac
    done
}

# ------------FUNCIONES DE INFORME-------------

# DES: Añade cadena a la cadena de informe plano. Se usa como si de un printf se tratara.
# USO: informar_plano "Palabrejas %s" $variable
informar_plano() {
    local temp
    printf -v temp -- "$@"
    cadenaInformePlano+="$temp\n"
}

# DES: Añade cadena a la cadena de informe plano. Se usa como si de un printf se tratara.
# USO: informar_color "Palabrejas %s" $variable
informar_color() {
    local temp
    printf -v temp -- "$@"
    cadenaInformeColor+="$temp\n"
}

# Guarda las cadenas de informe a sus archivos respectivos y las vacía.
guardar_informes() {

    echo -e -n "${cadenaInformePlano}" >> "${archivoInformePlano}"

    echo -e -n "${cadenaInformeColor}" >> "${archivoInformeColor}"

    # Vacia las variables de informe
    cadenaInformePlano=""
    cadenaInformeColor=""

}

# ------------MISC-------------

# DES: Muestra una cabecera general
# USO: cabecera "Texto a mostrar"
cabecera() {
    clear
    echo -e                "${cf[$ac]}                                                 ${rstf}"
    echo -e                 "${cf[10]}                                                 ${rstf}"

    # Imprime el nombre del algoritmo en la cabecera
    echo -e "${cf[10]}${cl[1]}${ft[0]}  SRPT - Pag - LRU - NC - NR                     ${rstf}"

    printf          "${cf[10]}${cl[1]}  %s%*s${rstf}\n" "${1}" $((47-${#1})) "" # Mantiene el ancho de la cabecera
    echo -e                 "${cf[10]}                                                 ${rstf}"
    echo -e                "${cf[$ac]}                                                 ${rstf}"
    echo
}

# DES: Crea un número pseudoaleatorio y lo asigna a la variable.
# USO: aleatorio_entre var min max
aleatorio_entre() {
    eval "${1}=$( shuf -i ${2}-${3} -n 1 )"
}

# DES: Espera a que se pulse una tecla para continuar el programa
pausa_tecla() {
    echo -e "Pulsa ${ft[0]}${cl[$re]}ENTER${rstf} para continuar."
    read -r
}

# DES: Muestra una barra tan ancha como la terminal con la proporción $1 / $2
# USO: barra_loading actual total
barra_loading() {
    
    local ancho=$(( $(tput cols) - 4 ))
    local anchoCompleto=$(( $ancho * $1 / $2 ))
    local anchoRestante=$(( $ancho - $anchoCompleto ))
    local porcentaje=$(( 100 * $1 / $2 ))

    printf "\r${cf[ac]}%${anchoCompleto}s${cf[2]}%${anchoRestante}s${rstf}%4s" "" "" "${porcentaje}%"

}


# ███████████████████████████████
# █                             █
# █            INIT             █
# █                             █
# ███████████████████████████████

# Establece las variable globales.
init_globales() {

    # Directorio donde se encuentra el script. Por si se ejecuta desde otro lugar
    readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    # Variables que se pueden cambiar
    readonly maximoProcesos=99                                                # Número máximo de procesos que acepta el script. (El primer proceso el el 1)
    readonly archivoAyuda="$DIR/ayuda.txt"                                    # Fichero de ayuda.
    readonly carpetaInformes="$DIR/informes"                                  # Carpeta donde se guardan los informes
    archivoInformePlano="informeBN.txt"                      	              # Archivo de informes sin color por defecto
    archivoInformeColor="informeCOLOR.txt"                   		      # Archivo de informes con color por defecto
    readonly carpetaDatos="$DIR/procesos"                                     # Carpeta donde se guardan los datos de las ejecuciones
    readonly archivoUltimaEjecucion="$carpetaDatos/datos.txt"                 # Archivo con los datos de la última ejecución. Siempre se guarda
    readonly archivoUltimaEjecucionRangos="$carpetaDatos/datosrangos.txt"     # Archivo con los rangos de la ultima ejecuion por alguna entrada de datos por aleatoriedad. 
    readonly anchoInformePlano=95                                             # Ancho del infome en texto plano

    readonly anchoNumeroProceso=${#maximoProcesos}                            # Se usa para nombrar a los procesos y rellenar el nombre con 0s ej P01

    readonly numeroMaximo=$(( 9223372036854775807 / (1 + $maximoProcesos) ))
                                                    # El número máximo que soporta Bash es 9223372036854775807
                                                    # Esta variable calcula el número máximo soportado por el script despejando NM de la ecuación:
                                                    # NM      + P                  * NM                  = 9223372036854775807
                                                    # TLegada + Número de procesos * Tiempo de ejecución = 9223372036854775807
                                                    # Así nunca se va a producir overflow. Da igual lo grandes que se intenten hacer los números.
                                                    # Aunque probablemente nadie intente meter números tan grandes -_-
    
    

    # VARIABLES DE INFORME
    cadenaInformePlano=""                           # Variables de informe donde se van guardando las lineas de informe para luego
    cadenaInformeColor=""                           # guardarlas a archivo
    
    # VARIABLES DE ARCHIVO DE DATOS
    archivoDatos=""                                 # Archivo en el que se guardarán los datos de la ejecución (dado por el usuario)
    						    #utiliza en la funcion guardarDatos
    
    archivoRangos=""                                # Archivo en el que se gurdran los rangos de la ejecucion si el usuario da un archivo perso. para guardarlos
    						    #utiliza en la funcion guardarDatos

    # Algoritmo que se va a usar [1=SRPT]
    algo=1

    # CARACTERÍSTICAS DE LA MEMORIA
    numeroMarcos=""                                 # Número de marcos de la memoria 
    tamanoMarco=""                                  # Tamaño de los marcos de pagina
    tamanoMemoria=""                                # Número de direcciones de la memoria (calculado mediante: numeroMarcos * tamaño Marcos)

    # DATOS DE LOS PROCESOS
    procesos=()                                     # Contiene el número de cada proceso.
    nombreProceso=()                                # Nombre del proceso (ej. proceso 0 -> P01)
    nombreProcesoColor=()                           # Nombre del proceso incluyendo variable de color
    listaLlegada=()                                 # Contiene los procesos ordenados segun llegada
    colorProceso=()                                 # Contiene los colores de cada proceso
    tiempoLlegada=()                                # Vector con todos los tiempos de llegada
    tiempoEjecucion=()                              # Vector con todos los tiempos de ejecución. Se calcula dependiendo del número de direcciones
    minimoEstructural=()                            # Mínimo estructural de todos los procesos
    declare -A -g procesoDireccion                  # Vector asociativo con todas las direcciones
    declare -A -g procesoPagina                     # Vector asociativo con todas las páginas del proceso
    numeroDireccionesProceso=""                     # Contiene el numero de direccines del proceso, uso en calcular_num_direcciones_proceso()


    # ANCHO DE COLUMNAS DE TABLA
    anchoNombreProceso=$(( ${anchoNumeroProceso} + 1 )) # Nombre de los procesos ej. P01
    anchoColRef=$(( ${anchoNombreProceso} + 1 ))    # Ancho de la columna Ref de la tabla
    anchoColTll=4                                   # Ancho de la columna Tll de la tabla
    anchoColTej=4                                   # Ancho de la columna Tej de la tabla
    anchoColNm=5                                    # Ancho de la columna Nm de la tabla

    anchoGen=$anchoNombreProceso                   # Ancho general que se usa el las barras de memoria y tiempo pequeñas.
                                                    # Puede cambiar si las direcciones de página son muy grandes o la memoria
                                                    # es muy grande o se alcanza un tiempo muy grande

}

# Establece las variables de color.
init_colores() {
    
    # Color de la letra
    readonly cl=(
        "\e[39m"  #   Default  0
        "\e[30m"  #     Negro  1
        "\e[97m"  #    Blanco  2
        "\e[90m"  #     GrisO  3
        "\e[31m"  #      Rojo  4
        "\e[32m"  #     Verde  5
        "\e[33m"  #  Amarillo  6
        "\e[34m"  #      Azul  7
        "\e[35m"  #   Magenta  8
        "\e[36m"  #      Cian  9
        "\e[37m"  #     GrisC 10
        "\e[91m"  #     RojoC 11
        "\e[92m"  #    VerdeC 12
        "\e[93m"  # AmarilloC 13
        "\e[94m"  #     AzulC 14
        "\e[95m"  #  MagentaC 15
        "\e[96m"  #     CianC 16
    )
    
    # color del background, es decir, el subrayado
    readonly cf=(
        "\e[49m"  #   Default  0
        "\e[40m"  #     Negro  1
        "\e[107m" #    Blanco  2
        "\e[100m" #     GrisO  3
        "\e[41m"  #      Rojo  4
        "\e[42m"  #     Verde  5
        "\e[43m"  #  Amarillo  6
        "\e[44m"  #      Azul  7
        "\e[45m"  #   Magenta  8
        "\e[46m"  #      Cian  9
        "\e[47m"  #     GrisC 10
        "\e[101m" #     RojoC 11
        "\e[102m" #    VerdeC 12
        "\e[103m" # AmarilloC 13
        "\e[104m" #     AzulC 14
        "\e[105m" #  MagentaC 15
        "\e[106m" #     CianC 16
    )

    readonly ft=(
        "\e[1m"   #   Negrita 0
        "\e[22m"  # NoNegrita 1
        "\e[4m"   # Subrayado 2
        "\e[24m"  # NoSubraya 3
    )

    readonly coloresClaros=(
        2
        10
        12
        13
        14
        15
        16
    )

    # Index del color de acento, aviso y resalto
    readonly ac=7
    readonly av=4
    readonly re=13

    # Reset de formato
    readonly rstf="\e[0m"

}

# Se inicializan variables globales
init() {
    init_globales
    init_colores
}

# ███████████████████████████████
# █                             █
# █           INTRO             █
# █                             █
# ███████████████████████████████

# Muestra la cabecera con datos relevantes
intro_cabecera_inicio() {

    # Cabecera que se muestra por pantalla
    clear
    echo -e         "${cf[ac]}                                                 ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Algoritmo de procesos  :  SRPT                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Tipo de algoritmo      :  PAGINACIÓN           ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Algoritmo de memoria   :  LRU                  ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Memoria continua       :  NO                   ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Memoria reublicable    :  NO                   ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Autor: Castroviejo Ausucua, Rodrigo            ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Autores anteriores:                            ${rstf}"
    echo -e "${cf[10]}${cl[1]}  RR-Pag-NRU-C-FI: Diego García Muñoz            ${rstf}"
    echo -e "${cf[10]}${cl[1]}  PriMayor-SN-NC-R: Iván Cortés                  ${rstf}"
    echo -e "${cf[10]}${cl[1]}  R-R-Pag-Reloj-C-FI: Ismael Franco Hernando     ${rstf}"
    echo -e "${cf[10]}${cl[1]}  FCFS-SJF-Pag-Reloj-NC-R: Cacuci Catalin Andrei ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Asignatura: Sistemas Operativos                ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Profesor: Jose Manuel Saiz Diez                ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Este script se creó usando la versión          ${rstf}"
    echo -e "${cf[10]}${cl[1]}  5.1.16(1) de Bash si no se ejecuta con esta    ${rstf}"
    echo -e "${cf[10]}${cl[1]}  versión pueden surgir problemas.               ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  © Creative Commons                             ${rstf}"
    echo -e "${cf[10]}${cl[1]}  BY - Atribución (BY)                           ${rstf}"
    echo -e "${cf[10]}${cl[1]}  NC - No uso Comercial (NC)                     ${rstf}"
    echo -e "${cf[10]}${cl[1]}  SA - Compartir Igual (SA)                      ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e         "${cf[ac]}                                                 ${rstf}"

    # Informe texto plano
    informar_plano "#################################################"
    informar_plano "#                                               #"
    informar_plano "#  Algoritmo de procesos  :  SRPT               #"
    informar_plano "#  Tipo de algoritmo      :  PAGINACIÓN         #"
    informar_plano "#  Algoritmo de memoria   :  LRU                #"
    informar_plano "#  Memoria continua       :  NO                 #"
    informar_plano "#  Memoria reublicable    :  NO                 #"
    informar_plano "#                                               #"
    informar_plano "#  Autor: Castroviejo Ausucua, Rodrigo          #"
    informar_plano "#                                               #"
    informar_plano "#  Autores anteriores:                          #"
    informar_plano "#  RR-Pag-NRU-C-FI: Diego García Muñoz          #"
    informar_color "#  PriMayor-SN-NC-R: Iván Cortés                #"
    informar_color "#  R-R-Pag-Reloj-C-FI: Ismael Franco Hernando   #"
    informar_color "#  FCFS-SJF-Pag-Reloj-NC-R: Cacuci Catalin A.   #"
    informar_plano "#                                               #"
    informar_plano "#  Asignatura: Sistemas Operativos              #"
    informar_plano "#  Profesor: Jose Manuel Saiz Diez              #"
    informar_plano "#                                               #"
    informar_plano "#  Este script se creó usando la versión        #"
    informar_plano "#  5.1.16(1) de Bash si no se ejecuta con esta  #"
    informar_plano "#  versión pueden surgir problemas.             #"
    informar_plano "#                                               #"
    informar_plano "#################################################"
    informar_plano "#                                               #"
    informar_plano "#  © Creative Commons                           #"
    informar_plano "#  BY - Atribución (BY)                         #"
    informar_plano "#  NC - No uso Comercial (NC)                   #"
    informar_plano "#  SA - Compartir Igual (SA)                    #"
    informar_plano "#                                               #"
    informar_plano "#################################################"
    informar_plano ""

    # Informe a color.
    informar_color         "${cf[ac]}                                                 ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Algoritmo de procesos  :  SRPT                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Tipo de algoritmo      :  PAGINACIÓN           ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Algoritmo de memoria   :  LRU                  ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Memoria continua       :  NO                   ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Memoria reublicable    :  NO                   ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Autor: Castroviejo Ausucua, Rodrigo            ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Autores anteriores:                            ${rstf}"
    informar_color "${cf[10]}${cl[1]}  RR-Pag-NRU-C-FI: Diego García Muñoz            ${rstf}"
    informar_color "${cf[10]}${cl[1]}  PriMayor-SN-NC-R: Iván Cortés                  ${rstf}"
    informar_color "${cf[10]}${cl[1]}  R-R-Pag-Reloj-C-FI: Ismael Franco Hernando     ${rstf}"
    informar_color "${cf[10]}${cl[1]}  FCFS-SJF-Pag-Reloj-C-NR: Cacuci Catalin A.     ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Asignatura: Sistemas Operativos                ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Profesor: Jose Manuel Saiz Diez                ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Este script se creó usando la versión          ${rstf}"
    informar_color "${cf[10]}${cl[1]}  5.1.16(1) de Bash si no se ejecuta con esta    ${rstf}"
    informar_color "${cf[10]}${cl[1]}  versión pueden surgir problemas.               ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  © Creative Commons                             ${rstf}"
    informar_color "${cf[10]}${cl[1]}  BY - Atribución (BY)                           ${rstf}"
    informar_color "${cf[10]}${cl[1]}  NC - No uso Comercial (NC)                     ${rstf}"
    informar_color "${cf[10]}${cl[1]}  SA - Compartir Igual (SA)                      ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color         "${cf[ac]}                                                 ${rstf}"
    informar_color ""

    pausa_tecla

}

# Muestra la cabecera con aviso sobre el tamaño de la terminal
intro_cabecera_tamano() {

    clear
    echo -e        "${cf[$ac]}                                                 ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}                      AVISO                      ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  Para visualizar correctamenta la información   ${rstf}"
    echo -e "${cf[10]}${cl[1]}  es necesario poner la ventana de terminal en   ${rstf}"
    echo -e "${cf[10]}${cl[1]}  pantalla completa. Si no, hay elementos que    ${rstf}"
    echo -e "${cf[10]}${cl[1]}  no se van a ver correctamente.                 ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e "${cf[10]}${cl[1]}  También es recomendable tener la terminal      ${rstf}"
    echo -e "${cf[10]}${cl[1]}  con un tema oscuro.                            ${rstf}"
    echo -e         "${cf[10]}                                                 ${rstf}"
    echo -e        "${cf[$ac]}                                                 ${rstf}"

    # informe a color
    informar_color        "${cf[$ac]}                                                 ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}                      AVISO                      ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  Para visualizar correctamenta la información   ${rstf}"
    informar_color "${cf[10]}${cl[1]}  es necesario poner la ventana de terminal en   ${rstf}"
    informar_color "${cf[10]}${cl[1]}  pantalla completa. Si no, hay elementos que    ${rstf}"
    informar_color "${cf[10]}${cl[1]}  no se van a ver correctamente.                 ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color "${cf[10]}${cl[1]}  También es recomendable tener la terminal      ${rstf}"
    informar_color "${cf[10]}${cl[1]}  con un tema oscuro.                            ${rstf}"
    informar_color         "${cf[10]}                                                 ${rstf}"
    informar_color        "${cf[$ac]}                                                 ${rstf}"
    informar_color ""

    # informe a color
    informar_plano "#################################################"
    informar_plano "#                                               #"
    informar_plano "#                     AVISO                     #"
    informar_plano "#                                               #"
    informar_plano "# Para visualizar correctamenta la información  #"
    informar_plano "# es necesario poner la ventana de terminal en  #"
    informar_plano "# pantalla completa. Si no, hay elementos que   #"
    informar_plano "# no se van a ver correctamente.                #"
    informar_plano "#                                               #"
    informar_plano "# También es recomendable tener la terminal     #"
    informar_plano "# con un tema oscuro.                           #"
    informar_plano "#                                               #"
    informar_plano "#################################################"
    informar_plano ""
    
    pausa_tecla

}

# Se muestran las cabeceras
intro() {
    intro_cabecera_inicio
    intro_cabecera_tamano
}


# ███████████████████████████████
# █                             █
# █          OPCIONES           █
# █                             █
# ███████████████████████████████

# DES: Da a elegir si se desea cambiar los informes por defecto
opciones_informes() {
    local cambiarInformes
    preguntar "Selección de informes" \
              "Los informes por defecto son ${ft[0]}${cl[re]}${archivoInformePlano}${rstf} y ${ft[0]}${cl[re]}${archivoInformeColor}${rstf}.\n¿Quieres cambiarlos?" \
              cambiarInformes \
              "Sí" \
              "No"

    # Si se ha decidido cambiar los informes
    case $cambiarInformes in
        1 )
            cabecera "Cambio de informes"

            # Pide el nombre del informe plano
            echo -e -n "Introduce el nombre para el ${ft[0]}${cl[re]}informe plano${rstf} con extensión: "
            leer_nombre_archivo archivoInformePlano

            # Pide el nombre del informe color
            echo -e -n "Introduce el nombre para el ${ft[0]}${cl[re]}informe a color${rstf} con extensión: "
            # Se asegura de que no sea igual al nombre del informe plano.
            while leer_nombre_archivo archivoInformeColor;do
                [[ "$archivoInformePlano" == "$archivoInformeColor" ]] \
                && echo -e -n "${ft[0]}${cl[$av]}AVISO${rstf}. El nombre no puede ser el mismo.\nIntroduce otro nombre para el ${ft[0]}${cl[re]}informe a color${rstf}: " \
                || break
            done
        ;;
    esac

    # Hace las variables de informe
    informar_plano "Los informes se guardarán en la carpeta: ${carpetaInformes}"
    informar_plano "Archivo de informe en texto plano: ${archivoInformePlano}"
    informar_plano "Archivo de informe en color: ${archivoInformeColor}"
    informar_plano ""

    informar_color "Los informes se guardarán en la carpeta: ${ft[0]}${cl[re]}${carpetaInformes}${rstf}"
    informar_color "Archivo de informe en texto plano: ${ft[0]}${cl[re]}${archivoInformePlano}${rstf}"
    informar_color "Archivo de informe en color: ${ft[0]}${cl[re]}${archivoInformeColor}${rstf}"
    informar_color ""

    # Si la carpeta informes no existe crearla
    [ ! -d "${carpetaInformes}" ] \
        && mkdir "${carpetaInformes}"

    # Pasa las variables a ruta absoluta
    archivoInformePlano="${carpetaInformes}/${archivoInformePlano}"
    archivoInformeColor="${carpetaInformes}/${archivoInformeColor}"

    # Crea o vacía los archivos de informe
    > $archivoInformePlano
    > $archivoInformeColor
}

# DES: Muestra la ayuda del fichero de ayuda si este existe
opciones_menu_ayuda() {
    clear
    cat "$archivoAyuda"
    informar_color "$( cat $archivoAyuda )"
    informar_plano "$( cat $archivoAyuda )"
    guardar_informes
    echo
    echo
    pausa_tecla
    exit
}

# DES: Elige si mostrar la ayuda o ejecutar el algoritmo
opciones_menu() {
    local menu
    preguntar "Menu" \
              "¿Qué quieres hacer?" \
              menu \
              "Ejecutar el programa" \
              "Ver la ayuda"
    
    case $menu in
        2 )
            opciones_menu_ayuda
        ;;
    esac
}

# DES: Función principar de opciones
opciones() {
    opciones_informes
    opciones_menu
}

# ███████████████████████████████
# █                             █
# █          DATOS              █
# █                             █
# ███████████████████████████████

# DES: Pregunta si se desean guardar los procesos
datos_pregunta_guardar() {

    local guardarSeleccionArchivo

	    preguntar "Seleccion de archivo" \
              "¿En que fichero quieres guardar los procesos?" \
              guardarSeleccionArchivo \
	      "En el fichero de datos por defecto (datos.txt)" \
              "En otro fichero"
    
	     # si la opcion seleccionada es 1, los guardara mediante la funcion datos_guardar() en datos.txt (ultima ejecucion)
	     # como eso se realiza en la datos() despues del case de seleccionar la forma de entrada de datos
	    if [ $guardarSeleccionArchivo -eq 1 ]; then
		    archivoDatos="datos.txt"
	    fi

	     # guarda los datos en otro fichero introducido por el usuario
	    if [ $guardarSeleccionArchivo -eq 2 ]; then
		    
           	echo -e -n "Introduce el nombre para el ${ft[0]}${cl[re]}archivo de procesos${rstf}: "
    		while leer_nombre_archivo archivoDatos;do
                
                
   	             # Si el archivo ya existe pregunta si sobreescribir
       		         if [[ -f "${carpetaDatos}/${archivoDatos}" ]] \
               		     && ! preguntar_si_no "${ft[0]}${cl[$av]}AVISO${rstf}. El archivo ya existe. ¿Sobreescribirlo?";then

	                   	 echo -e -n "Introduce otro nombre para el ${ft[0]}${cl[re]}archivo de procesos${rstf}: "
               		 else
              		      break
               		 fi
                done

	    fi

            # Informar donde se guardarán los procesos.
            informar_plano "Carpeta de procesos: ${carpetaDatos}"
            informar_plano "Archivo de procesos: ${archivoDatos}"
            informar_plano ""

            informar_color "Carpeta de procesos: ${ft[0]}${cl[re]}${carpetaDatos}${rstf}"
            informar_color "Archivo de procesos: ${ft[0]}${cl[re]}${archivoDatos}${rstf}"
            informar_color ""

            # Pasa el archivo de procesos a ruta absoluta
            archivoDatos="${carpetaDatos}/${archivoDatos}"
            

}

# DES: Pregunta si se desean guardar los rangos 
rangos_pregunta_guardar() {

    local guardarSeleccionArchivo

	    preguntar "Seleccion de archivo" \
              "¿En que fichero quieres guardar los rangos?" \
              guardarSeleccionArchivo \
	      "En el fichero de rangos por defecto (datosrangos.txt)" \
              "En otro fichero"
    
	     # si la opcion seleccionada es 1, los guardara mediante la funcion rangos_guardar() en datosrangos.txt (rangos ultima ejecucion)
	     #como eso se realiza en las propias funciones de rangos aleatorios, no se realiza nada es esta funcion

	     # guarda los datos en otro fichero introducido por el usuario
	    if [ $guardarSeleccionArchivo -eq 2 ]; then
		    
           	echo -e -n "Introduce el nombre para el ${ft[0]}${cl[re]}archivo de rangos${rstf}: "
    		while leer_nombre_archivo archivoRangos;do
                
                
   	             # Si el archivo ya existe pregunta si sobreescribir
       		         if [[ -f "${carpetaDatos}/${archivoRangos}" ]] \
               		     && ! preguntar_si_no "${ft[0]}${cl[$av]}AVISO${rstf}. El archivo ya existe. ¿Sobreescribirlo?";then

	                   	 echo -e -n "Introduce otro nombre para el ${ft[0]}${cl[re]}archivo de procesos${rstf}: "
               		 else
              		      break
               		 fi
                done

	    fi

            # Informar donde se guardarán los procesos.
            informar_plano "Carpeta de procesos: ${carpetaDatos}"
            informar_plano "Archivo de procesos: ${archivoRangos}"
            informar_plano ""

            informar_color "Carpeta de procesos: ${ft[0]}${cl[re]}${carpetaDatos}${rstf}"
            informar_color "Archivo de procesos: ${ft[0]}${cl[re]}${archivoRangos}${rstf}"
            informar_color ""

            # Pasa el archivo de procesos a ruta absoluta
            archivoRangos="${carpetaDatos}/${archivoRangos}"
            

}

# DES: Guardar los datos a archivo
datos_guardar() {

    # Si la carpeta de datos no existe, crearla
    [ ! -d "${carpetaDatos}" ] \
        && mkdir "${carpetaDatos}"

    # Se crea una cadena que luego se guarda en los archivos respectivos
    local cadena=""

    cadena+="# Numero de marcos de pagina:\n"
    cadena+="${numeroMarcos}\n"
    cadena+="# Numero de direcciones por marco de pagina (tamaño marco de pagina):\n"
    cadena+="${tamanoMarco}\n"
    #no necesita el numero de procesos porque realmente cada proceso sera el numero de lineas del siguiente bucle for
    cadena+="# Tll,Nm,dir1,dir2,dir3,...\n"

    for p in ${procesos[*]};do

        cadena+="${tiempoLlegada[$p]},"
        cadena+="${minimoEstructural[$p]}"

        for (( d=0; d<${tiempoEjecucion[$p]}; d++ ));do
            cadena+=",${procesoDireccion[$p,$d]}"
        done
        cadena+="\n"
    done

    # Guardar los datos en el archivo de última ejecución
    echo -e -n "${cadena}" > "$archivoUltimaEjecucion"

    # Si se ha dado un archivo de datos
    if [[ $archivoDatos ]];then
        echo -e -n "${cadena}" > "$archivoDatos"
    fi

}

# DES: Muestra una tabla con todos los procesos introducidos hasta el momento
datos_tabla_procesos() {

    # Color del proceso que se está imprimiendo
    local color

    local ancho=$(( $anchoColRef + $anchoColTll + $anchoColTej + $anchoColNm ))
    local anchoRestante
    local anchoCadena

    # Mostrar cabecera
    printf "${ft[0]}%-${anchoColRef}s%${anchoColTll}s%${anchoColTej}s%${anchoColNm}s%s${rstf}\n"  " Ref" "Tll" "Tej" "nMar" " Dirección - Página"

    for proc in ${listaLlegada[*]};do

        # Poner la fila con el color del proceso
        color=${colorProceso[$proc]}

        printf "${cl[$color]}${ft[0]}"
        # Ref
        printf "%-${anchoColRef}s" " ${nombreProceso[$proc]}"
        # Tll
        printf "%${anchoColTll}s" "${tiempoLlegada[$proc]}"
        # Tej
        printf "%${anchoColTej}s" "${tiempoEjecucion[$proc]}"
        # Nm
        printf "%${anchoColNm}s" "${minimoEstructural[$proc]}"

        anchoRestante=$(( $anchoTotal - $ancho ))

        # Dirección - Página
        for (( i=0; ; i++ ));do

            anchoCadena=$(( ${#procesoDireccion[$proc,$i]} + ${#procesoPagina[$proc,$i]} + 2 ))

            if [ $anchoRestante -lt $anchoCadena ];then
                printf "\n"
                anchoRestante=$anchoTotal
            fi

            # Si ya no quedan páginas
            [[ -z "${procesoDireccion[$proc,$i]}" ]] \
                && break

            printf " ${ft[1]}${procesoDireccion[$proc,$i]}-${ft[0]}${procesoPagina[$proc,$i]}"

            anchoRestante=$(( $anchoRestante - $anchoCadena ))

        done

        printf "${rstf}\n"
    done

    echo

}

# DES: Ordena los procesos segun llegada en la lista de llegada
datos_ordenar_llegada() {

    # EXPLICACIÓN
    # Se hace echo a cadenas del tipo "tLl.nPr&Pr" ej. "12.02&2"
    # Estas cadenas son ordenadas numericamente por el comando sort -n , que
    # interpreta la primera parte como un número decimal.
    # grep -o "&.*$" coge lo que hay desde el "&" hasta el final ej "&2"
    # tr -d "&" elimina el "&" quedando solo el "2"
    # El output se introduce en la lista de llegada

    listaLlegada=($(
        for pro in ${procesos[*]};do
            printf "${tiempoLlegada[$pro]}.%0${anchoNumeroProceso}d&${pro}\n" "${pro}"
        done | sort -n | grep -o "&.*$" | tr -d "&"
    ))

}


# --------- DATOS MEMORIA -----------

# DES: Muestra una tabla con las características de la memoria según se van dando.
datos_memoria_tabla() {
    clear
    echo -e         "${cf[ac]}                                                                      ${rstf}"
    echo -e         "${cf[10]}                                                                      ${rstf}"
    printf  "${cf[10]}${cl[1]}                   Número marcos : %-33s  ${rstf}\n" "${numeroMarcos}"
    printf  "${cf[10]}${cl[1]}   Tamaño marco (en direcciones) : %-33s  ${rstf}\n" "${tamanoMarco}"
    printf  "${cf[10]}${cl[1]} Tamaño memoria (en direcciones) : %-33s  ${rstf}\n" "${tamanoMemoria}"
    echo -e         "${cf[10]}                                                                      ${rstf}"
    echo -e         "${cf[ac]}                                                                      ${rstf}"
    echo

}

# DES: Introducir el numero de marcos de pagina
datos_memoria_num_marcos() {

    # Para que se muestr un guión en el dato que se introduce
    numeroMarcos="_"

    # Mostrar la tabla
    datos_memoria_tabla

    echo -e -n "Introduce el número de ${ft[0]}${cl[re]}marcos de pagina:${rstf}"
    # Leer el tamaño de la memoria con un mínimo de 1
    while :;do

        leer_numero_entre numeroMarcos 1
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o nada
            1 | 2 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un número natural: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El número de ${ft[0]}${cl[re]}marcos${rstf} debe ser mayor a ${ft[0]}${cl[re]}0${rstf}: "
            ;;

        esac
    done

}

# DES: Introducir tamaño en direcciones de los marcos de pagina
datos_memoria_tamano_marco() {

    # Para que se muestr un guión en el dato que se introduce
    tamanoMarco="_"

    # Mostrar la tabla
    datos_memoria_tabla

    echo -e -n "Introduce el tamaño (en direcciones) de ${ft[0]}${cl[re]}los marcos de página${rstf}: "
    # Leer el número de marcos con un mínimo de 1 y máx del tamaño de la memoria
    while :;do

        leer_numero_entre tamanoMarco 1
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o nada
            1 | 2 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un número natural: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El tamaño de ${ft[0]}${cl[re]}marco${rstf} debe ser mayor a ${ft[0]}${cl[re]}0${rstf}: "
            ;;

        esac
    done

}

# DES: Introducir características de la memoria
datos_memoria() {

    # Introducir número de direcciones de la memoria
    datos_memoria_num_marcos
    # Introducir tamaño de página
    datos_memoria_tamano_marco
    # Calcular tamano de la memoria en direcciones
    tamanoMemoria=$(($numeroMarcos * $tamanoMarco))

    # Mostrar los datos introducidos
    datos_memoria_tabla
    pausa_tecla

}

# ------------------------------------
# --------- DATOS POR TECLADO --------
# ------------------------------------

# DES: Pide el tiempo de llegada del proceso
datos_teclado_llegada() {

    clear
    # Mostrar tabla de procesos
    datos_tabla_procesos

    echo -n -e "Introduce el tiempo de ${ft[0]}${cl[$re]}llegada${rstf} de ${nombreProcesoColor[$p]}: "
    # while true
    while :;do

        leer_numero tiempoLlegada[$p]
        # Dependiendo del valor devuelto por la función anterior
        case $? in

            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural
            1 | 2 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un número natural: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    # Calcular ancho columna tiempo llegada
    [ $(( ${#tiempoLlegada[$p]} + 2 )) -gt ${anchoColTll} ] \
        && anchoColTll=$(( ${#tiempoLlegada[$p]} + 2 ))

}

# DES: Pide el mínimo estructural del proceso
datos_teclado_nm() {
    
    clear
    # Mostrar tabla de procesos
    datos_tabla_procesos

    echo -n -e "Introduce el ${ft[0]}${cl[$re]}mínimo estructural${rstf} de ${nombreProcesoColor[$p]}: "
    # while true
    while :;do

        leer_numero_entre minimoEstructural[$p] 1 ${numeroMarcos}
        # Dependiendo del valor devuelto por la función anterior
        case $? in

            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural
            1 | 2 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un número natural: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El ${ft[0]}${cl[$re]}mínimo estructural${rstf} no puede ser mayor al número de marcos (${ft[0]}${cl[$re]}${numeroMarcos}${rstf}): "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El ${ft[0]}${cl[re]}mínimo estructural${rstf} debe ser mayor a ${ft[0]}${cl[re]}0${rstf}: "
            ;;

        esac
    done

    # Calcular ancho columna minimo estructural
    [ $(( ${#minimoEstructural[$p]} + 2 )) -gt ${anchoColNm} ] \
        && anchoColNm=$(( ${#minimoEstructural[$p]} + 2 ))

}

# DES: Va pidiendo las direcciones del proceso
datos_teclado_direcciones() {

    # dirección introducida se usa como variable de paso para el valor de escape de la introducción
    local direc

    # Empezando con la dirección 0
    for (( d=0; ; d++ ));do

        clear
        # Mostrar tabla de procesos
        datos_tabla_procesos

        echo -n -e "Introduce la dirección número ${ft[0]}${cl[$re]}$(( ${d}+1 ))${rstf} [${ft[0]}${cl[$re]}no${rstf}=no introducir más]: "
        # while true
        while :;do

            leer_numero direc
            # Dependiendo del valor devuelto por la función anterior
            case $? in

                # Valor válido
                0 )
                    # Asignar la dirección
                    procesoDireccion[$p,$d]=$direc


                    # Calcular la página
                    procesoPagina[$p,$d]=$(( $direc / $tamanoMarco ))


                    # Actualizar anchoGen si la dirección de página es muy grande
                    [ ${#procesoPagina[$p,$d]} -gt $anchoGen ] && anchoGen=${#procesoPagina[$p,$d]}

                    break
                ;;
                # Valor no número natural
                1 | 2 )
                    # Si se ha introducido "no"
                    if [ "${direc}" = "no" ];then
                        if [ $d -eq 0 ];then
                            echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Tienes que introducir al menos una dirección: "
                        else
                            # Si el mínimo estructural el menor al número de direcciones introducidas o si se acepta el desperdicio
                            if [ ${minimoEstructural[$p]} -le $d ] || preguntar_si_no "Has introducido menos direcciones que el mínimo estructural del proceso.\nEsto es un desperdicio. ¿Seguro?";then
                                # calcular tiempo de ejecución
                                tiempoEjecucion[$p]=$d
                                # Calcular ancho columna tiempo llegada
                                [ $(( ${#tiempoEjecucion[$p]} + 2 )) -gt ${anchoColTej} ] \
                                    && anchoColTej=$(( ${#tiempoEjecucion[$p]} + 2 ))
                                return 0
                            fi
                            echo -n -e "Introduce la dirección ${ft[0]}${cl[$re]}${d}${rstf}: "
                        fi
                    else
                        echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un número natural: "
                    fi
                ;;
                # Valor demasiado grande
                3 )
                    echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
                ;;

            esac
        done
    done
}


# DES: Crea los nombre de los procesos ej 1 -> P01
generar_nombre_proceso() {

    local color=""

    nombreProceso[$p]=$(
        printf "P%0${anchoNumeroProceso}d" "$p"		
	)						# d indica que el parametro que va a sustituir($p) es decimal  
							# el ancho que va a tener el printf es especificado por anchoNumeroProceso
							# %0 en el printf, rellena los huecos con 0s en vez de espacios si el ancho
						        #especificado por anchoNumeroProceso ocupa mas espacios que la variable a sustituir	

    color=${colorProceso[$p]}

    nombreProcesoColor[$p]=$(
        printf "${cl[$color]}${ft[0]}P%0${anchoNumeroProceso}d${cl[0]}${ft[1]}" "$p"
    )

}


# DES: Introducir los datos por teclado
datos_teclado() {
    
    # Preguntar si guardar a archivo custom
    datos_pregunta_guardar

    # Introducir datos de la memoria
    datos_memoria

    # Introducir datos de los procesos
    # Empezando con el proceso nº1
    for (( p=1; ; p++ ));do

        # Añadir número de proceso a la lista con todos los procesos y de llegada
        procesos+=($p)
        listaLlegada+=($p)

        # Establecer variables a "-"
        tiempoLlegada[$p]="-"
        tiempoEjecucion[$p]="-"
        minimoEstructural[$p]="-"

        # Calcular el color del proceso. Se basa en mis variables de color.
        # Si usas otras no va a funcionar correctamente.
        colorProceso[$p]=$(( (${p} % 12) + 5 ))

        # Se genera la cadena de nombre del proceso ej 1 -> P01
        generar_nombre_proceso

        # Introducir el tiempo de llegada del proceso
        datos_teclado_llegada

        # Introducir el mínimo estructural del proceso
        datos_teclado_nm

        # Introducir las direcciones del proceso y calcular el tiempo de ejecución
        datos_teclado_direcciones

        # Ordenar los procesos según llegada
        datos_ordenar_llegada

        # Mostrar la tabla de procesos
        clear
        datos_tabla_procesos
        
        # Si se alcanza el máximo de procesos
        if [ $p -eq $maximoProcesos ];then
            echo -e "${ft[0]}${cl[$av]}AVISO${rstf}. Se ha llegado al máximo de procesos (${ft[0]}${cl[$re]}${maximoProcesos}${rstf}): "
            pausa_tecla
            break
        fi

        # Pregunta si se quiren añadir más procesos
        if ! preguntar_si_no "¿Seguir añadiendo procesos?";then
            break
        fi

    done

}


# ------------------------------------
# --------- DATOS POR ARCHIVO --------
# ------------------------------------

# DES: Comprueba que la carpeta existe y que hay archivos dentro.
#      Tambien crea la lista con los archivos que hay dentro
datos_archivo_comprobar() {

    # Si no existe la carpeta
    if [ ! -d "${carpetaDatos}" ];then
        mkdir "${carpetaDatos}"
        echo -e "${cl[av]}${ft[0]}AVISO.${rstf} No se ha encontrado ningún archivo en la carpeta ${ft[0]}${cl[re]}${carpetaDatos}${rstf}. Saliendo..."
        exit
    fi

    for arch in "$carpetaDatos"/*;do
        lista+=("${arch##*/}")
    done

    # Si no hay archivos en la carpeta
    if [ "${lista[0]}" == "*" ];then
        echo -e "${cl[av]}${ft[0]}AVISO.${rstf} No se ha encontrado ningún archivo en la carpeta ${ft[0]}${cl[re]}${carpetaDatos}${rstf}. Saliendo..."
        exit
    fi

}

# DES: Muestra una lista con todos los archivos de la que se puede seleccionar el que se quiera
datos_archivo_seleccionar() {
    
    cabecera "Selección archivo de datos"
    echo "¿Que archivo quieres usar?"
    echo
    # Por cada archivo en la carpeta imprime una linea
    for archivo in ${!lista[*]};do
        echo -e "    ${cl[$re]}${ft[0]}[$(( $archivo + 1 ))]${rstf} <- ${lista[$archivo]}"
    done
    echo
    echo -n "Selección: "

    while :;do
        leer_numero_entre seleccion 1 ${#lista[*]}
        # En caso de que el valor devuelto por la función anterior
        case $? in
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural
            * )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf} Introduce un número entre ${ft[0]}${cl[$re]}1${rstf} y ${ft[0]}${cl[$re]}${#lista[*]}${rstf}: "
            ;;
        esac
    done


    ((seleccion--))

    cabecera "Selección archivo de datos"
    echo "¿Que archivo quieres usar?"
    echo
    # Por cada archivo en la carpeta imprime una linea
    for archivo in ${!lista[*]};do
        if [ $archivo -eq $seleccion ];then
            echo -e "    ${cl[1]}${ft[0]}${cf[2]}[$(( $archivo + 1 ))] <- ${lista[$archivo]}${rstf}"
        else
            echo -e "    ${cl[$re]}${ft[0]}[$(( $archivo + 1 ))]${rstf} <- ${lista[$archivo]}"
        fi
    done
    echo

    # Haya nombre del archivo seleccionado
    seleccion=${lista[$seleccion]}

}

# DES: Añade a los informes el archivos que se va a usar
datos_archivo_informes() {
    # Informar el archivo que se usa.
    informar_plano "El archivo de datos usado es: ${seleccion}\n"
    informar_color "El archivo de datos usado es: ${cl[re]}${ft[0]}${seleccion}${rstf}\n"
}

# DES: Leer los datos del archivo seleccionado
datos_archivo_leer() {

    local linea=""
    # número de linea
    local n=0
    # número de proceso
    local p=1
    # número de dirección
    local d=0

    # Datos del proceso que se está leyendo
    local datosProceso=()

    # Hayar path completa del archivo seleccionado
    seleccion="${carpetaDatos}/$seleccion"

    # se va leyendo cada linea del archivo
    while read linea;do
        case $n in
            # Número de marcos de pagina
            1 )
                numeroMarcos=$linea
            ;;
            # Tamaño en direcciones de los marcos de pagina
            3 )
                tamanoMarco=$linea
                tamanoMemoria=$(( $numeroMarcos * $tamanoMarco ))
            ;;
       esac

        if [ $n -ge 5 ];then

            # Se divide la linea con "," como delimitador y la guarda en datosProceso
            IFS=',' read -ra datosProceso <<< "$linea"

            procesos+=($p)
            colorProceso[$p]=$(( (${p} % 12) + 5 ))

            generar_nombre_proceso
            tiempoLlegada[$p]=${datosProceso[0]}
            tiempoEjecucion[$p]=$(( ${#datosProceso[*]} - 2 ))
            minimoEstructural[$p]=${datosProceso[1]}

            # anchos
            # Calcular ancho columna tiempo llegada
            [ $(( ${#tiempoLlegada[$p]} + 2 )) -gt ${anchoColTll} ] \
                && anchoColTll=$(( ${#tiempoLlegada[$p]} + 2 ))
            # Calcular ancho columna minimo estructural
            [ $(( ${#minimoEstructural[$p]} + 2 )) -gt ${anchoColNm} ] \
                && anchoColNm=$(( ${#minimoEstructural[$p]} + 2 ))
            # Calcular ancho columna tiempo llegada
            [ $(( ${#tiempoEjecucion[$p]} + 2 )) -gt ${anchoColTej} ] \
                && anchoColTej=$(( ${#tiempoEjecucion[$p]} + 2 ))


            for (( i=2; i<${#datosProceso[*]};i++ ));do

                d=$(( $i - 2 ))
                procesoDireccion[$p,$d]=${datosProceso[$i]}


                procesoPagina[$p,$d]=$(( ${procesoDireccion[$p,$d]} / $tamanoMarco ))

                # Actualizar anchoGen si la dirección de página es muy grande
                [ ${#procesoPagina[$p,$d]} -gt $anchoGen ] && anchoGen=${#procesoPagina[$p,$d]}

            done

            ((p++))

        fi

        ((n++))
        
    done < "$seleccion"

}

# DES: Introducir los datos mediante archivo
datos_archivo() {

    # Lista con los archivos de la carpeta de datos
    local lista=()
    # Archivo que se ha seleccionado de la lista
    local seleccion=""

    # comprobaciones previas
    datos_archivo_comprobar

    # Seleccionar archivo
    datos_archivo_seleccionar

    # Hacer los informes del archivo seleccionado
    datos_archivo_informes

    # Interpreta los datos que hay en el archivos seleccionado
    # y crea todas las demás variables a partir de ellos
    datos_archivo_leer
    
    # Ordenar los procesos
    datos_ordenar_llegada
    
    # Mostrar la información de la memoria
    datos_memoria_tabla

    pausa_tecla

} 

#---------------------------------------------------------------
#----Introduccion de datos por archivo de ultima ejecucion------
#̣̣̣̣̣̣̣̣---------------------------------------------------------------

datos_archivo_ultima_ejecucion() {

    # Como el archivo que vamos a seleccionar siempre es el mismo (datos.txt (ultima Ejecucion)), no hace falta las funciones
    # de comprobacion y seleccion del archivo del que sacar los datos
    
    local seleccion="datos.txt"

    # Hacer los informes del archivo seleccionado
    datos_archivo_informes

    # Interpreta los datos que hay en el archivo seleccionado
    # y crea todas las demás variables a partir de ellos
    datos_archivo_leer
    
    # Ordenar los procesos
    datos_ordenar_llegada
    
    # Mostrar la información de la memoria
    datos_memoria_tabla

    

    pausa_tecla

}


# ------------------------------------
# --------- DATOS RANDOM -------------
# ------------------------------------

# DES: Muestra los parámetros para la generación
datos_random_tabla() {
    echo -e         "${cf[ac]}                                                                      ${rstf}"
    echo -e         "${cf[10]}                                                                      ${rstf}"
    printf  "${cf[10]}${cl[1]}                   Número marcos : %-13s %-20s ${rstf}\n" "[ ${numeroMarcosMinimo} - $numeroMarcosMaximo ]"  "--> $numeroMarcos" 
    printf  "${cf[10]}${cl[1]}   Tamaño marco (en direcciones) : %-13s %-20s ${rstf}\n" "[ ${tamanoMarcoMinimo} - ${tamanoMarcoMaximo} ]"  "--> $tamanoMarco"
    printf  "${cf[10]}${cl[1]}                  Tamaño memoria : %-13s %-20s ${rstf}\n" "$tamanoMemoria" 
    printf  "${cf[10]}${cl[1]}                 Número procesos : %-13s %-20s ${rstf}\n" "[ ${numeroProcesosMinimo} - ${numeroProcesosMaximo} ]"	"--> $numeroProcesos"
    printf  "${cf[10]}${cl[1]}                  Tiempo llegada : %-13s %-20s ${rstf}\n" "[ ${tiempoLlegadaMinimo} - ${tiempoLlegadaMaximo} ]"
    printf  "${cf[10]}${cl[1]}                Tiempo ejecución : %-13s %-20s ${rstf}\n" "[ ${tiempoEjecucionMinimo} - ${tiempoEjecucionMaximo} ]" 
    printf  "${cf[10]}${cl[1]}              Mínimo estructural : %-13s %-20s ${rstf}\n" "[ ${minimoEstructuralMinimo} - ${minimoEstructuralMaximo} ]" 
    printf  "${cf[10]}${cl[1]} Tamaño proceso (en direcciones) : %-13s %-20s ${rstf}\n" "[ ${direccionMinima} - ${direccionMaxima} ]"
    echo -e         "${cf[10]}                                                                      ${rstf}"
    echo -e         "${cf[ac]}                                                                      ${rstf}"
    echo
}

# DES: Añade la tabla con los parámetros a los informes
datos_random_informes() {
    # Informe color
    informar_color         "${cf[ac]}                                                                      ${rstf}"
    informar_color         "${cf[10]}                                                                      ${rstf}"
    informar_color "${cf[10]}${cl[1]}                   Número marcos : %-13s %-19s  ${rstf}" "[ ${numeroMarcosMinimo} - $numeroMarcosMaximo ]"  "--> $numeroMarcos"
    informar_color "${cf[10]}${cl[1]}  Tamaño marco (en direcciones)  : %-13s %-19s  ${rstf}" "[ ${tamanoMarcoMinimo} - ${tamanoMarcoMaximo} ]"  "--> $tamanoMarco"
    informar_color "${cf[10]}${cl[1]}                  Tamaño memoria : %-13s %-19s  ${rstf}" "${tamanoMemoria}"
    informar_color "${cf[10]}${cl[1]}                 Número procesos : %-13s %-19s  ${rstf}" "[ ${numeroProcesosMinimo} - ${numeroProcesosMaximo} ]" "--> $numeroProcesos"
    informar_color "${cf[10]}${cl[1]}                  Tiempo llegada : %-13s %-19s  ${rstf}" "[ ${tiempoLlegadaMinimo} - ${tiempoLlegadaMaximo} ]"  
    informar_color "${cf[10]}${cl[1]}                Tiempo ejecución : %-13s %-19s  ${rstf}" "[ ${tiempoEjecucionMinimo} - ${tiempoEjecucionMaximo} ]"
    informar_color "${cf[10]}${cl[1]}              Mínimo estructural : %-13s %-19s  ${rstf}" "[ ${minimoEstructuralMinimo} - ${minimoEstructuralMaximo} ]"
    informar_color "${cf[10]}${cl[1]} Tamaño proceso (en direcciones) : %-13s %-19s  ${rstf}" "[ ${direccionMinima} - ${direccionMaxima} ]"
    informar_color         "${cf[10]}                                                                      ${rstf}"
    informar_color         "${cf[ac]}                                                                      ${rstf}"
    informar_color ""

    # Informe plano
    # En este informe no estan hechas las flechitas con el resultado entre el rango
    informar_plano "██████████████████████████████████████████████████████████████████"
    informar_plano "█                                                                █"
    informar_plano "█                  Número marcos : %-29s █" "[ ${numeroMarcosMinimo} - $numeroMarcosMaximo ]"
    informar_plano "█  Tamaño marco (en direcciones) : %-29s █" "[ ${tamanoMarcoMinimo} - ${tamanoMarcoMaximo} ]"
    informar_plano "█                 Tamaño memoria : %-29s █" "${tamanoMemoria}"
    informar_plano "█                Número procesos : %-29s █" "[ ${numeroProcesosMinimo} - ${numeroProcesosMaximo} ]"
    informar_plano "█                 Tiempo llegada : %-29s █" "[ ${tiempoLlegadaMinimo} - ${tiempoLlegadaMaximo} ]"
    informar_plano "█               Tiempo ejecución : %-29s █" "[ ${tiempoEjecucionMinimo} - ${tiempoEjecucionMaximo} ]"
    informar_plano "█             Mínimo estructural : %-29s █" "[ ${minimoEstructuralMinimo} - ${minimoEstructuralMaximo} ]"
    informar_plano "█ Tamaño proceso(en direcciones) : %-29s █" "[ ${direccionMinima} - ${direccionMaxima} ]"
    informar_plano "█                                                                █"
    informar_plano "██████████████████████████████████████████████████████████████████"
    informar_plano ""
}

# DES: Introducir el rango minimo y maximo del numero de marcos de pagina
datos_random_num_marcos_pagina() {

    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango de ${ft[0]}${cl[$re]}marcos de pagina${rstf}: "
    while :;do

        leer_numero numeroMarcosMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango de${ft[0]}${cl[$re]} marcos de pagina${rstf}: "
    while :;do

        leer_numero_entre numeroMarcosMaximo $numeroMarcosMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${tiempoLlegadaMinimo}${rstf}): "
            ;;

        esac
    done

}

# DES: Introducir el tamaño minimo y maximo de los marcos de pagina en direcciones
datos_random_tam_marco() {

    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango del tamaño en direcciones de ${ft[0]}${cl[$re]}los marcos${rstf}: "
    while :;do

        leer_numero tamanoMarcoMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango del tamaño en direcciones de ${ft[0]}${cl[$re]}los marcos${rstf}: "
    while :;do

        leer_numero_entre tamanoMarcoMaximo $tamanoMarcoMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${tiempoLlegadaMinimo}${rstf}): "
            ;;

        esac
    done

}

# DES: Introduce el numero minimo y maximo de marcos
datos_random_num_procesos() {

    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango del numero de ${ft[0]}${cl[$re]}procesos${rstf}: "
    while :;do

        leer_numero numeroProcesosMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango del numero de ${ft[0]}${cl[$re]}procesos${rstf}: "
    while :;do

        leer_numero_entre numeroProcesosMaximo $numeroProcesosMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${tiempoLlegadaMinimo}${rstf}): "
            ;;

        esac
    done

}


# DES: Introducir tiempos de llegada
datos_random_llegada() {

    clear
    datos_random_tabla

    echo -n -e "Introduzca el minimo del rango del tiempo de ${ft[0]}${cl[$re]}llegada${rstf}: "
    while :;do

        leer_numero tiempoLlegadaMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduzca el maximo del rango del tiempo de ${ft[0]}${cl[$re]}llegada${rstf}: "
    while :;do

        leer_numero_entre tiempoLlegadaMaximo $tiempoLlegadaMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${tiempoLlegadaMinimo}${rstf}): "
            ;;

        esac
    done

}

# DES: Introducir tiempos de ejecución
datos_random_ejecucion() {

    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango del tiempo de ${ft[0]}${cl[$re]}ejecución${rstf}: "
    while :;do

        leer_numero_entre tiempoEjecucionMinimo 1
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El tiempo de ejecución mínimo es ${ft[0]}${cl[$re]}1${rstf}: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango del tiempo de ${ft[0]}${cl[$re]}ejecución${rstf}: "
    while :;do

        leer_numero_entre tiempoEjecucionMaximo $tiempoEjecucionMinimo
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${tiempoEjecucionMinimo}${rstf}): "
            ;;

        esac
    done

}

# DES: Introducir mínimos estructurales
datos_random_nm() {
    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango del ${ft[0]}${cl[$re]}tamaño estructural mínimo${rstf}: "
    while :;do

        desperdicios=-1
        leer_numero_entre minimoEstructuralMinimo 1 $numeroMarcos
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                # Casos de desperdicios
                # Si el mínimo estructural mínimo es mayor al tiempo de ejecución máximo
                if [[ ${minimoEstructuralMinimo} -gt ${tiempoEjecucionMaximo} ]];then
                    preguntar_si_no "${ft[0]}${cl[4]}AVISO${rstf}. El mínimo estructural mínimo es mayor al tiempo de ejecución máximo.\nVan a haber desperdicios en todos los procesos. ¿Continuar?" \
                        && desperdicios=1 \
                        || desperdicios=0

                # Si el mínimo estructural mínimo es mayor al tiempo de ejecución mínimo
                elif [[ ${minimoEstructuralMinimo} -gt ${tiempoEjecucionMinimo} ]];then
                    preguntar_si_no "${ft[0]}${cl[4]}AVISO${rstf}. El mínimo estructural mínimo es mayor al tiempo de ejecución mínimo.\nPodrían haber desperdicios. ¿Continuar?" \
                        && desperdicios=1 \
                        || desperdicios=0
                fi

                case ${desperdicios} in
                    0 )
                        # resetear la pregunta
                        minimoEstructuralMinimo="-"
                        clear
                        datos_random_tabla
                        echo -n -e "Introduce el minimo del rango del ${ft[0]}${cl[$re]}tamaño estructural mínimo${rstf}: "
                        ;;
                    * )
                        # salir
                        break
                        ;;
                esac
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El mínimo estructural no puede ser mayor al número de marcos (${ft[0]}${cl[$re]}$numeroMarcos${rstf}): "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El mínimo estructural mínimo es ${ft[0]}${cl[$re]}1${rstf}: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango del ${ft[0]}${cl[$re]}tamaño estructural mínimo${rstf}: "
    while :;do

        leer_numero_entre minimoEstructuralMaximo $minimoEstructuralMinimo $numeroMarcos
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El mínimo estructural no puede ser mayor al número de marcos (${ft[0]}${cl[$re]}$numeroMarcos${rstf}): "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${minimoEstructuralMinimo}${rstf}): "
            ;;

        esac
    done

}

# DES: Introducir rango de direcciones
datos_random_direcciones() {

    clear
    datos_random_tabla

    echo -n -e "Introduce el minimo del rango del ${ft[0]}${cl[$re]}tamaño del proceso (en direcciones)${rstf}: "
    while :;do

        leer_numero direccionMinima
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;

        esac
    done

    clear
    datos_random_tabla

    echo -n -e "Introduce el maximo del rango del ${ft[0]}${cl[$re]}tamaño del proceso (en direcciones)${rstf}: "
    while :;do

        leer_numero_entre direccionMaxima $direccionMinima
        # En caso de que el valor devuelto por la función anterior
        case $? in
            
            # Valor válido
            0 )
                break
            ;;
            # Valor no número natural o No se introduce nada
            1 | 2)
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Introduce un ${ft[0]}${cl[$re]}número natural${rstf}: "
            ;;
            # Valor demasiado grande
            3 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. Valor demasiado grande: "
            ;;
            # Valor demasiado pequeño
            4 )
                echo -n -e "${ft[0]}${cl[$av]}AVISO${rstf}. El máximo no puede ser menor al mínimo (${ft[0]}${cl[$re]}${direccionMinima}${rstf}): "
            ;;

        esac
    done

}

#DES: guarda los rangos de la ultima ejecucion por datos aleatorios
rangos_guardar() {

	#con solo un > elimina el contenido del archivo y pasa a ser ese echo la primera linea
	echo "#Numero marcos min: " > $archivoRangos 
	echo "$numeroMarcosMinimo" >> $archivoRangos 

	echo "#Numero marcos max: " >> $archivoRangos 
	echo "$numeroMarcosMaximo" >> $archivoRangos 

	echo "#Tamaño marco min: " >> $archivoRangos  
  	echo "$tamanoMarcoMinimo" >> $archivoRangos

	echo "#Tamaño marco max: " >> $archivoRangos  
  	echo "$tamanoMarcoMaximo" >> $archivoRangos  
	
	echo "#Numero procesos min: " >> $archivoRangos  
  	echo "$numeroProcesosMinimo" >> $archivoRangos  

	echo "#Numero procesos max: " >> $archivoRangos  
  	echo "$numeroProcesosMaximo" >> $archivoRangos  
	
	echo "#Tiempo de llegada min: " >> $archivoRangos 
  	echo "$numeroProcesosMinimo" >> $archivoRangos 

	echo "#Tiempo de llegada max: " >> $archivoRangos 
  	echo "$tiempoLlegadaMaximo" >> $archivoRangos  

	echo "#Tiempo de ejecucion min: " >> $archivoRangos  
	echo "$tiempoEjecucionMinimo" >> $archivoRangos  

	echo "#Tiempo de ejecucion max: " >> $archivoRangos  
	echo "$tiempoEjecucionMaximo" >> $archivoRangos  

	echo "#Tamaño minimo estructural min: " >> $archivoRangos  
	echo "$minimoEstructuralMinimo" >> $archivoRangos  

	echo "#Tamaño minimo estructural max: " >> $archivoRangos  
	echo "$minimoEstructuralMaximo" >> $archivoRangos  
	
	echo "#Direccion min: " >> $archivoRangos 
	echo "$direccionMinima" >> $archivoRangos  
	
	echo "#Direccion max: " >> $archivoRangos  
	echo "$direccionMaxima" >> $archivoRangos  
}


# DES: Generar los procesos de forma pseudo-aleatoria
datos_random() {

    # Preguntar si guardar rangos a archivo custom
    rangos_pregunta_guardar

    # Preguntar si guardar a archivo custom
    datos_pregunta_guardar

    # Parámetros
    local tamanoMarcoMinimo=""
    local tamanoMarcoMaximo=""

    local numeroMarcosMinimo="" 
    local numeroMarcosMaximo="" 

    local numeroProcesosMinimo=""
    local numeroProcesosMaximo=""

    local tiempoLlegadaMinimo="-"
    local tiempoLlegadaMaximo="-"

    local tiempoEjecucionMinimo="-"
    local tiempoEjecucionMaximo="-"

    # Para saber si da igual que hayan desperdicios
    local desperdicios=""
    local minimoEstructuralMinimo="-"
    local minimoEstructuralMaximo="-"

    local direccionMinima="-"
    local direccionMaxima="-"
    
    # Introducir numero marcos totales, ademas calcula el dato entre el rango(necesario para tabla datos)

    datos_random_num_marcos_pagina
    aleatorio_entre numeroMarcos ${numeroMarcosMinimo} ${numeroMarcosMaximo}
    datos_random_tabla

    # Introducir el tamaño de los marcos, ademas calcula el dato entre el rango(necesario para tabla datos)
 
    datos_random_tam_marco
    aleatorio_entre tamanoMarco ${tamanoMarcoMinimo} ${tamanoMarcoMaximo}
    datos_random_tabla
    
    # Introducir número de procesos a crear, ademas calcula el dato entre el rango(necesario para tabla datos)
    datos_random_num_procesos
    aleatorio_entre numeroProcesos ${numeroProcesosMinimo} ${numeroProcesosMaximo}
    datos_random_tabla
    
    # Calcula el numero de direcciones totoales de la memoria (es decir, su tamaño)
    tamanoMemoria=$(($numeroMarcos * $tamanoMarco))

    # Introducir tiempos de llegada
    datos_random_llegada

    # Introducir tiempos de ejecución
    datos_random_ejecucion

    # Introducir minimos estructurales
    datos_random_nm

    # Introducir rango de direcciones
    datos_random_direcciones

    # guardar en el archivo personalizado si ha sido seleccionado en rangos_pregunta_guardar()
    rangos_guardar

    archivoRangos=$archivoUltimaEjecucionRangos
    # guarda siempre en el archivo de ultimaEjecucion(datosrangos.txt)
    rangos_guardar

    # Mostrar la tabla antes de generar los procesos
    clear
    datos_random_tabla
    # Informar de la tabla
    datos_random_informes
    pausa_tecla


    # GENERAR LOS PROCESOS    
    for (( p=0; p < ${numeroProcesos}; p++ ));do

        clear
        echo "Generando procesos..."
        barra_loading "$(( $p + 1 ))" "${numeroProcesos}"

        # Añadir proceso a lista de procesos
        procesos+=($p)
        # Asignar color al proceso.
        colorProceso[$p]=$(( (${p} % 12) + 5 ))
        # Dar nombre al proceso 1 -> P01
        generar_nombre_proceso
        
	# el numero de procesos y demas es calculado arriba junto a la llamada a la funcion que pide el min max de procesos
        aleatorio_entre tiempoLlegada[$p] ${tiempoLlegadaMinimo} ${tiempoLlegadaMaximo}
        aleatorio_entre tiempoEjecucion[$p] ${tiempoEjecucionMinimo} ${tiempoEjecucionMaximo}
        
        # Si se aceptan desperdicios cambiar como se calcula el mínimo estructural
        if [[ $desperdicios -eq 1 ]];then
            aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
        else
            # tiempo de ejecución es menor al mínimo máximo se escoge como máximo el tiempo de ejecución
            if [[ ${tiempoEjecucion[$p]} -lt ${minimoEstructuralMaximo} ]];then
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${tiempoEjecucion[$p]}
            # Si no se coge el mínimo máximo
            else
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
            fi
        fi

        # calcular las direcciones y páginas
        for (( d=0; d < ${tiempoEjecucion[$p]}; d++ ));do
            aleatorio_entre procesoDireccion[$p,$d] ${direccionMinima} ${direccionMaxima}
            procesoPagina[${p},${d}]=$(( procesoDireccion[${p},${d}] / $tamanoMarco ))

            # Actualizar anchoGen si la dirección de página es muy grande
            [ ${#procesoPagina[$p,$d]} -gt $anchoGen ] && anchoGen=${#procesoPagina[$p,$d]}

        done

        # calcular anchos
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoLlegada[$p]} + 2 )) -gt ${anchoColTll} ] \
            && anchoColTll=$(( ${#tiempoLlegada[$p]} + 2 ))
        # Calcular ancho columna minimo estructural
        [ $(( ${#minimoEstructural[$p]} + 2 )) -gt ${anchoColNm} ] \
            && anchoColNm=$(( ${#minimoEstructural[$p]} + 2 ))
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoEjecucion[$p]} + 2 )) -gt ${anchoColTej} ] \
            && anchoColTej=$(( ${#tiempoEjecucion[$p]} + 2 ))

    done

    datos_ordenar_llegada

}


# DES: Leer los datos de rangos del fichero de ultimos rangos utilizados
rangos_archivo_leer() {

    local linea=""
    # número de linea
    local n=0
    # número de proceso
    local p=1
    # número de dirección
    local d=0

    # Datos del proceso que se está leyendo
    local datosProceso=()

    seleccion="${carpetaDatos}/$seleccion"

    # se va leyendo cada linea del archivo
    while read linea;do
        case $n in
            # Numero de marcos min
            1 )
	         numeroMarcosMinimo=$linea
            ;;
            # Numero de marcos max
            3 )
	    	numeroMarcosMaximo=$linea
            ;;
            # Tamaño de marco min
            5 )
	    	tamanoMarcoMinimo=$linea
            ;;

            # Tamaño de marco max
            7 )
	    	tamanoMarcoMaximo=$linea
            ;;

            # Numero de procesos min
            9 )
	    	numeroProcesosMinimo=$linea
            ;;

            # Numero de procesos min
            11 )
	    	numeroProcesosMaximo=$linea
            ;;

            # Tiempo de llegada min
            13 )
	    	tiempoLlegadaMinimo=$linea
            ;;

	    # Tiempo de llegada max
            15 )
	    	tiempoLlegadaMaximo=$linea
            ;;

            # Tiempo de ejecucion min
            17 )
		tiempoEjecucionMinimo=$linea
            ;;
	   
	    # Tiempo de ejecucion max
            19 )
		tiempoEjecucionMaximo=$linea
            ;;

	    # tme minimo(tamaño minimo estructural)
            21 )
                minimoEstructuralMinimo=$linea
            ;;

	    # tme maximo(tamaño minimo estructural)
            23 )
                minimoEstructuralMaximo=$linea
            ;;

	    #Direccion min
	    25 )
                direccionMinima=$linea
            ;;

	    #Direccion max
	    27 )
                direccionMaxima=$linea
            ;;

        esac

	((n++))

   done < "$seleccion"
}

# DES: Generar los procesos de forma pseudo-aleatoria a partir de los rangos utilizados en la ultima ejecucion aleatoria
rangos_random_ultima_ejecucion() {

    # pregunta si guardar los datos utilizados 
    datos_pregunta_guardar
    
    # guarda el archivo de ultima ejecucion de rangos como archivo a utilizar en la funcion que lee el archivo
    local seleccion="datosrangos.txt"
   
    # Parámetros
    local numeroMarcosMinimo="" 
    local numeroMarcosMaximo="" 
    
    local tamanoMarcoMinimo=""
    local tamanoMarcoMaximo=""

    local numeroProcesosMinimo=""
    local numeroProcesosMaximo=""


    local tiempoLlegadaMinimo="-"
    local tiempoLlegadaMaximo="-"

    local tiempoEjecucionMinimo="-"
    local tiempoEjecucionMaximo="-"

    # Para saber si da igual que hayan desperdicios
    local desperdicios=""
    local minimoEstructuralMinimo="-"
    local minimoEstructuralMaximo="-"

    local direccionMinima="-"
    local direccionMaxima="-"

    # Da los valores a las variables correspondientes de los rangos utilizados en la ultima ejecucion aleatoria
    rangos_archivo_leer

    # Generacion entre el min y max del numero de procesos tamaño de memoria y tamañano de pagina
    # se generan aqui por ser necesarios para el calculo de los marcos de pagina y por que el numero de 
    # procesos es necesario en el apartarado que genera los procesos 
    aleatorio_entre numeroProcesos ${numeroProcesosMinimo} ${numeroProcesosMaximo}
    aleatorio_entre numeroMarcos ${numeroMarcosMinimo} ${numeroMarcosMaximo}
    aleatorio_entre tamanoMarco ${tamanoMarcoMinimo} ${tamanoMarcoMaximo}

    # Calcula el tamano de la memoria en direcciones
    tamanoMemoria=$(($numeroMarcos * $tamanoMarco))


    archivoRangos=$archivoUltimaEjecucionRangos

    # Mostrar la tabla antes de generar los procesos
    clear
    datos_random_tabla
    # Informar de la tabla
    datos_random_informes
    pausa_tecla


    # GENERAR LOS PROCESOS    
    for (( p=0; p < ${numeroProcesos}; p++ ));do

        clear
        echo "Generando procesos..."
        barra_loading "$(( $p + 1 ))" "${numeroProcesos}"

        # Añadir proceso a lista de procesos
        procesos+=($p)
        # Asignar color al proceso.
        colorProceso[$p]=$(( (${p} % 12) + 5 ))
        # Dar nombre al proceso 1 -> P01
        generar_nombre_proceso
        
	# el numero de procesos y demas es calculado arriba junto a la llamada a la funcion que pide el min max de procesos
        aleatorio_entre tiempoLlegada[$p] ${tiempoLlegadaMinimo} ${tiempoLlegadaMaximo}
        aleatorio_entre tiempoEjecucion[$p] ${tiempoEjecucionMinimo} ${tiempoEjecucionMaximo}
        
        # Si se aceptan desperdicios cambiar como se calcula el mínimo estructural
        if [[ $desperdicios -eq 1 ]];then
            aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
        else
            # tiempo de ejecución es menor al mínimo máximo se escoge como máximo el tiempo de ejecución
            if [[ ${tiempoEjecucion[$p]} -lt ${minimoEstructuralMaximo} ]];then
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${tiempoEjecucion[$p]}
            # Si no se coge el mínimo máximo
            else
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
            fi
        fi

        # calcular las direcciones y páginas
        for (( d=0; d < ${tiempoEjecucion[$p]}; d++ ));do
            aleatorio_entre procesoDireccion[$p,$d] ${direccionMinima} ${direccionMaxima}
            procesoPagina[${p},${d}]=$(( procesoDireccion[${p},${d}] / $tamanoMarco ))

            # Actualizar anchoGen si la dirección de página es muy grande
            [ ${#procesoPagina[$p,$d]} -gt $anchoGen ] && anchoGen=${#procesoPagina[$p,$d]}

        done

        # calcular anchos
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoLlegada[$p]} + 2 )) -gt ${anchoColTll} ] \
            && anchoColTll=$(( ${#tiempoLlegada[$p]} + 2 ))
        # Calcular ancho columna minimo estructural
        [ $(( ${#minimoEstructural[$p]} + 2 )) -gt ${anchoColNm} ] \
            && anchoColNm=$(( ${#minimoEstructural[$p]} + 2 ))
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoEjecucion[$p]} + 2 )) -gt ${anchoColTej} ] \
            && anchoColTej=$(( ${#tiempoEjecucion[$p]} + 2 ))

    done

    datos_ordenar_llegada

}

# DES: Generar los procesos de forma pseudo-aleatoria a partir de los rangos suministrados por un fichero de rangos
ejecucion_rangos_archivo() {

    # pregunta si guardar los datos utilizados 
    datos_pregunta_guardar

     # Lista con los archivos de la carpeta de datos
    local lista=()
     # Archivo que se ha seleccionado de la lista
    local seleccion=""

    # comprobaciones previas
    datos_archivo_comprobar

    # Seleccionar archivo
    datos_archivo_seleccionar

    # Hacer los informes
    datos_archivo_informes


    # Parámetros
    local numeroMarcosMinimo="" 
    local numeroMarcosMaximo="" 

    local tamanoMarcoMinimo=""
    local tamanoMarcoMaximo=""

    local numeroProcesosMinimo=""
    local numeroProcesosMaximo=""

    local tiempoLlegadaMinimo="-"
    local tiempoLlegadaMaximo="-"

    local tiempoEjecucionMinimo="-"
    local tiempoEjecucionMaximo="-"

    # Para saber si da igual que hayan desperdicios
    local desperdicios=""
    local minimoEstructuralMinimo="-"
    local minimoEstructuralMaximo="-"

    local direccionMinima="-"
    local direccionMaxima="-"

    # Da los valores a las variables correspondientes de los rangos utilizados en la ultima ejecucion aleatoria
    rangos_archivo_leer

    # Generacion entre el min y max del numero de procesos tamaño de memoria y tamañano de pagina
    # se generan aqui por ser necesarios para el calculo de los marcos de pagina y por que el numero de 
    # procesos es necesario en el apartarado que genera los procesos 
    aleatorio_entre numeroProcesos ${numeroProcesosMinimo} ${numeroProcesosMaximo}
    aleatorio_entre numeroMarcos ${numeroMarcosMinimo} ${numeroMarcosMaximo}
    aleatorio_entre tamanoMarco ${tamanoMarcoMinimo} ${tamanoMarcoMaximo}

    # Calcula el numero de marcos de pagina
    tamanoMemoria=$(($numeroMarcos * $tamanoMarco))

     # Mostrar la tabla antes de generar los procesos
    clear
    datos_random_tabla
    # Informar de la tabla
    datos_random_informes

    pausa_tecla

    # GENERAR LOS PROCESOS    
    for (( p=0; p < ${numeroProcesos}; p++ ));do

        clear
        echo "Generando procesos..."
        barra_loading "$(( $p + 1 ))" "${numeroProcesos}"

        # Añadir proceso a lista de procesos
        procesos+=($p)
        # Asignar color al proceso.
        colorProceso[$p]=$(( (${p} % 12) + 5 ))
        # Dar nombre al proceso 1 -> P01
        generar_nombre_proceso
        
        aleatorio_entre tiempoLlegada[$p] ${tiempoLlegadaMinimo} ${tiempoLlegadaMaximo}
        aleatorio_entre tiempoEjecucion[$p] ${tiempoEjecucionMinimo} ${tiempoEjecucionMaximo}
        
        # Si se aceptan desperdicios cambiar como se calcula el mínimo estructural
        if [[ $desperdicios -eq 1 ]];then
            aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
        else
            # tiempo de ejecución es menor al mínimo máximo se escoge como máximo el tiempo de ejecución
            if [[ ${tiempoEjecucion[$p]} -lt ${minimoEstructuralMaximo} ]];then
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${tiempoEjecucion[$p]}
            # Si no se coge el mínimo máximo
            else
                aleatorio_entre minimoEstructural[$p] ${minimoEstructuralMinimo} ${minimoEstructuralMaximo}
            fi
        fi

        # calcular las direcciones y páginas
        for (( d=0; d < ${tiempoEjecucion[$p]}; d++ ));do
            aleatorio_entre procesoDireccion[$p,$d] ${direccionMinima} ${direccionMaxima}
            procesoPagina[${p},${d}]=$(( procesoDireccion[${p},${d}] / $tamanoMarco ))

            # Actualizar anchoGen si la dirección de página es muy grande
            [ ${#procesoPagina[$p,$d]} -gt $anchoGen ] && anchoGen=${#procesoPagina[$p,$d]}

        done

        # calcular anchos
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoLlegada[$p]} + 2 )) -gt ${anchoColTll} ] \
            && anchoColTll=$(( ${#tiempoLlegada[$p]} + 2 ))
        # Calcular ancho columna minimo estructural
        [ $(( ${#minimoEstructural[$p]} + 2 )) -gt ${anchoColNm} ] \
            && anchoColNm=$(( ${#minimoEstructural[$p]} + 2 ))
        # Calcular ancho columna tiempo llegada
        [ $(( ${#tiempoEjecucion[$p]} + 2 )) -gt ${anchoColTej} ] \
            && anchoColTej=$(( ${#tiempoEjecucion[$p]} + 2 ))

    done

    datos_ordenar_llegada

}



# ------------------------------------
# --------- INFORMES -----------------
# ------------------------------------


# DES: Se introducen datos sobre memoria y procesos
datos() {

    local metodo            

              preguntar "Método de introducción de datos" \
              "¿Cómo quieres introducir los datos?" \
              metodo \
              "Por teclado" \
	      "Fichero de Datos de ultima ejecucion (datos.txt)" \
              "Por otro fichero de datos" \
	      "A traves de RANGOS - manual" \
	      "Fichero de RANGOS aleatorios de ultima ejecucion (datosrangos.txt)" \
              "Por otro fichero de RANGOS"

    anchoTotal=$( tput cols )

    # Dependiendo de la respuesta dada se ejecuta la función correspondiente.
    case $metodo in
        1 )
            # Introducir los datos por teclado
            datos_teclado
        ;;
        2 )
            # Introducir los datos por archivo
       	    datos_archivo_ultima_ejecucion
        ;;
	3 )
            # Introducir los datos por el fichero de datos de la ultima ejecucion
            datos_archivo
        ;;
        4 )
            # Introducir los datos aleatoriamente
            datos_random
        ;;
	5)
	    # Introducir los datos por fichero de RANGOS de ultima ejecucion
	    rangos_random_ultima_ejecucion
	;;
	6 )
	    ejecucion_rangos_archivo
            # Introducir los datos por un fichero de RANGOS
            
        ;;
    esac

    # Si el número de páginas es muy grande, actualizar el anchoGen
    local temp=$(( $numeroMarcos - 1 ))
    [ ${#temp} -gt $anchoGen ] && anchoGen=${#temp}

    # Mostrar la tabla de procesos final
    clear
    datos_tabla_procesos

    # Guardar a archivo custom y datos de última ejecución
    datos_guardar

    pausa_tecla

}


# ███████████████████████████████
# █                             █
# █          EJECUCIÓN          █
# █                             █
# ███████████████████████████████

# ------------------------------------
# --------- EJECUCIÓN ----------------
# ------------------------------------

# DES: Calcular tiempo de espera y de ejecución para los procesos
ej_ejecutar_tesp_tret() {

    # Por cada proceso que está esperando a entrar a memoria o a ser ejecutado
    for p in ${colaMemoria[*]} ${colaEjecucion[*]};do

        # Incrementar su tiempo de espera y de retorno
        ((tEsp[$p]++))
        ((tRet[$p]++))

        # Calcular anchos para la tabla
        [ ${#tEsp[$p]} -gt $(( ${anchoColTEsp} - 2 )) ] \
            && anchoColTEsp=$(( ${#tEsp[$p]} + 2 ))
        [ ${#tRet[$p]} -gt $(( ${anchoColTRet} - 2 )) ] \
            && anchoColTRet=$(( ${#tRet[$p]} + 2 ))
    done

    # Si hay un proceso en ejecución
    if [[ -n "$enEjecucion" ]];then
        # Incrementar su tiempo de retorno
        ((tRet[$enEjecucion]++))

        # Calcular anchos para la tabla
        [ ${#tRet[$enEjecucion]} -gt $(( ${anchoColTRet} - 2 )) ] \
            && anchoColTRet=$(( ${#tRet[$enEjecucion]} + 2 ))
    fi

}

# DES: Finalizar la ejecución del proceso
ej_ejecutar_fin_ejecutar() {

    # Sacar el proceso de la memoria
    for mar in ${marcosActuales[*]};do

        unset memoriaProceso[$mar]
        unset memoriaPagina[$mar]
        unset memoriaNFU[$mar]

        # Actualizar memoria libre y ocupada
        ((memoriaLibre++))
        ((memoriaOcupada--))

    done

    # Resetear el vector procesoMarcos.
    for (( pag=0; pag<${minimoEstructural[$enEjecucion]}; pag++ )) {
        unset procesoMarcos[$enEjecucion,$pag]
    }

    # Poner el tiempo restante de ejecución a - para que no muestre 0
    tREj[$enEjecucion]="-"

    # Actualizar le estado del proceso
    estado[$enEjecucion]=4

    # Resetear los marcos actuales
    marcosActuales=()

    procesoFin[$enEjecucion]=$t

    # Poner el proceso que ha terminado para mostrarlo en pantalla
    fin=$enEjecucion
    # Mostrar la pantalla porque es un evento interesante
    mostrarPantalla=1

    # Liberar procesador
    unset enEjecucion

    ((numProcesosFinalizados++))

    siguienteMarco=""

}

# DES: Atender la llegada de procesos
ej_ejecutar_llegada() {

    # Por cada proceso en la cola de llegada
    for p in ${colaLlegada[*]};do
        # Si su tiempo de llegada es igual al tiempo actual
        if [ ${tiempoLlegada[$p]} -eq $t ];then

            # Quitar proceso de la lista de llegada
            colaLlegada=("${colaLlegada[@]:1}")

            # Añadir proceso a la cola para entrar a memoria
            colaMemoria+=($p)

            # Cambiar el estado del proceso
            estado[$p]=1

            # Establecer el tiempo de espera del proceso a 0
            tEsp[$p]=0

            # Establecer tiempo de retorno a 0
            tRet[$p]=0

            # Añadir proceso a los que han llegada para mostrarlo
            llegada+=($p)
            # Mostrar pantalla porque es un evento importante
            mostrarPantalla=1

        else
            # Como están en orde de llegada, en cuanto nos topemos con un proceso
            # que aún no llega sabemos que no va a llegar ningún otro
            break
        fi
    done

}

# DES: Introducir procesos que han llegado a memoria si se puede
# RET: 0 -> han entrado procesos a memoria 1 -> no han entrado procesos
ej_ejecutar_memoria_proceso() {

    # Contador de cuantos procesos han entrado
    local cont=0

    # Por cada proceso en la cola de memoria
    for p in ${colaMemoria[*]};do

	# descomentar la linea inferior de codigo si desea hacer el agoritmo no continuo y comentar la linea indicada que hace el algoritmo continuo 
	# si hay suficiente memoria libre (Porque es memoria no continua, si fuese continua habria que hacerlo diferente)	    
        if [ ${minimoEstructural[$p]} -le $memoriaLibre ];then
	
	# Esta condicion convierte el agoritmo en Continuo, reemplazar por la de arriba
        #if [ ${#minimoEstructural[$p, $d]} -le $memoriaLibre ];then


            # Quitar proceso del la cola de memoria
            colaMemoria=("${colaMemoria[@]:1}")

            # Añadir proceso a la memoria
            # pag -> Página del proceso por la que va (No es un buen nombre, pero no se me ocurre otra cosa)
            # mar -> Marco de memoria por el que va
            # hasta que se alcance el mínimo estructural
            for (( pag=0,mar=0; pag<${minimoEstructural[$p]}; mar++ ));do
                # Si el marco no está ya asignado
                if [[ -z ${memoriaProceso[$mar]} ]];then

                    # Asignar el marco al proceso
                    memoriaProceso[$mar]=$p
                    procesoMarcos[$p,$pag]=$mar

                    # Pasar a la siguiente página del proceso.
                    ((pag++))

                    # Actualizar memoria libre y ocupada.
                    ((memoriaLibre--))
                    ((memoriaOcupada++))

                fi
            done

            # Añadir proceso a la cola de ejecución
            colaEjecucion+=($p)

            # Cambiar estado del proceso.
            estado[$p]=2

            # Establecer el tiempo restante de ejecución del proceso a su tiempo de ejecución total
            tREj[$p]=${tiempoEjecucion[$p]}

            # Añadir proceso a la lista de procesos que han entrado a memoria para la pantalla
            entrada+=($p)
            # Mostrar la pantalla porque es un evento importante
            mostrarPantalla=1

            # Incrementar contador
            ((cont++))

        else
            # Como la entrada a memoria es FIFO si un proceso no puede entrar, los siguientes
            # tampoco porque la lista está ordenasa según tiempo de llegada
            break
        fi
    done

    # Si no han entrado procesos devolver 1
    if [ $cont -eq 0 ];then
        return 1
    # Si han llegado devolver 0
    else
        return 0
    fi

}

# DES: Ordenar cola de ejecución segun SJF
ej_ejecutar_ordenar_sjf() {

    # Explicación:
    # Se hace print a cadenas del tipo "4.02&01", "3.05&2", "3.12&3"
    # "TiempoEjecucion.Indice&Proceso"
    # Estas cadenas se ordenan de forma numerica. Se usa el índice para
    # que, en caso de coincidir los tiempos de ejecucion, como con "3.05&2" y "3.12&3"
    # se mantenga el orden de llegada. La variable anchosIdx es para que un índice 12
    # no esté antes de un índice 5, como son decimales 3.5 es mayor a 3.12, por lo que
    # hay que pasar 3.5 a 3.05, que es menor que 3.12.

    # El comando sort ordena las cadenas de forma numérica, el grep elimina lo que hay
    # antes del "&" y el tr elimina el "&".

    # Calcular el ancho de los índices
    local anchoIdx=$(( $colaEjecucion -1 ))
    anchoIdx=${#anchoIdx}
    local pro
    colaEjecucion=($(
        for idx in ${!colaEjecucion[*]};do
            pro=${colaEjecucion[$idx]}
            printf "${tiempoEjecucion[$pro]}.%0${anchoIdx}d&${pro}\n" "${idx}"
        done | sort -n | grep -o "&.*$" | tr -d "&"
    ))

}

# DES: Meter proceso al procesador
ej_ejecutar_empezar_ejecucion() {

    # Asignar procesador al proceso
    enEjecucion=${colaEjecucion[0]}

    # Quitar proceso de la cola de ejecución
    colaEjecucion=("${colaEjecucion[@]:1}")

    # Cambiar estado del proceso
    estado[$enEjecucion]=3

    # Hayar los marcos del proceso actual
    for (( i=0; i<${minimoEstructural[$enEjecucion]}; i++ ));do
        marcosActuales+=(${procesoMarcos[$enEjecucion,$i]})
    done

    # Establece el marco siguiente al primer marco del proceso en ejecucución
    siguienteMarco=${marcosActuales[0]}

    # Poner el proceso que se ha inciado para mostrarlo en la pantalla
    inicio=$enEjecucion
    # Mostrar la pantalla porque es un evento importante
    mostrarPantalla=1

    procesoInicio[$enEjecucion]=$t

}

# DES: Introducir siguiente página del proceso a memoria
# RET: 0=No ha habido fallo 1=Ha habido fallo
ej_ejecutar_memoria_pagina() {

    # Página que hay que introducir
    local pagina=${pc[$enEjecucion]}
    pagina=${procesoPagina[$enEjecucion,$pagina]}

    # Añadir proceso y página a la linea de tiempo
    tiempoProceso[$t]=$enEjecucion
    tiempoPagina[$t]=$pagina
    paginaTiempo[$enEjecucion,${pc[$enEjecucion]}]=$t

    # Comprobar cada marco de la memoria si la página ya está metida
    for ind in ${!marcosActuales[*]};do
        mar=${marcosActuales[$ind]}
        # Si se encuentra la página
        if [[ -n "${memoriaPagina[$mar]}" ]] && [ ${memoriaPagina[$mar]} -eq $pagina ];then
            # Incrementar los usos de esa página
            (( ++memoriaNFU[$mar] ))
            marcoFallo+=($ind)
            return 0
        fi
    done

    # Si la página no está en memoria
    # Marco en el que se va a introducir la página.
    local marco=""
    # Menores usos
    local usos=-1

    local marc=""
    # Si la página no está en memoria hay que buscar la página con menos frecuencia.
    for ind in ${!marcosActuales[*]};do
        mar=${marcosActuales[$ind]}
        # Si el marco está vacío se usa siempre
        if [[ -z "${memoriaPagina[$mar]}" ]];then
            marco=$mar
            usos=0
            marc=$ind
            break
        
        # si el marco no está vacío
        elif [[ -z "$marco" ]] || [ ${memoriaNFU[$mar]} -lt $usos ];then
            marco=$mar
            usos=${memoriaNFU[$mar]}
            marc=$ind
        fi

    done

    # Introducir la página en el marco
    memoriaPagina[$marco]=$pagina
    # Poner los usos de la página a 1
    memoriaNFU[$marco]=1
    marcoFallo+=($marc)

    # Incrementar fallos del proceso
    (( numFallos[$enEjecucion]++ ))

    return 1

}

# DES: Encuentra cual va a ser el siguiente marco en utilizar en caso de que se produzca fallo en la siguiente página
ej_calcular_marco_siguiente() {
    # Marco en el que se va a introducir la página.
    local marco=""
    # Menores usos
    local usos=-1
    # Si la página no está en memoria hay que buscar la página con menos frecuencia.
    for ind in ${!marcosActuales[*]};do
        mar=${marcosActuales[$ind]}
        # Si el marco está vacío se usa siempre
        if [[ -z "${memoriaPagina[$mar]}" ]];then
            marco=$mar
            usos=0
            break
        
        # si el marco no está vacío
        elif [[ -z "$marco" ]] || [ ${memoriaNFU[$mar]} -lt $usos ];then
            marco=$mar
            usos=${memoriaNFU[$mar]}
        fi
    done
    siguienteMarco=${marco}
}

# DES: Guardar el estado de la memoria en este momento para luego mostrar el resumen con los fallos
#      No está directamente relacionado con la ejecución. Es solo para la pantalla.
ej_ejecutar_guardar_fallos() {

    local marco=""
    local mom=$(( ${pc[$enEjecucion]} - 1 ))
    for mar in ${!marcosActuales[*]};do
        marco=${marcosActuales[$mar]}
        resumenFallos["$mom,$mar"]="${memoriaPagina[$marco]}"
        resumenNFU["$mom,$mar"]="${memoriaNFU[$marco]}"
    done

}

# DES: Llegada de procesos, ejecución, introducción a memoria...
ej_ejecutar() {

    # Calcular tiempo de espera y de ejecución para los procesos
    ej_ejecutar_tesp_tret

    # Si hay un proceso en ejecución significa que en el instante anterior se
    # ha introducido una página suya y durante el tiempo que ha pasado se ha ejecutado
    # por lo que hay que decrementar su tREj
    if [[ -n "$enEjecucion" ]];then

        # Decrementar tiempo restante de ejecución
        (( --tREj[$enEjecucion] ))
        
        # Guardar el estado de la memoria en este momento para luego mostrar el resumen con los fallos
        ej_ejecutar_guardar_fallos

        # Si el proceso se ha terminado de ejecutar
        if [ ${tREj[$enEjecucion]} -eq 0 ];then

            ej_ejecutar_fin_ejecutar

        fi
    fi

      # Atender la llegada de procesos
    ej_ejecutar_llegada

    # Introducir procesos que han llegado a memoria si se puede
    ej_ejecutar_memoria_proceso
    
    # Si han entrado procesos ordenar la cola de ejecución ( $? es el valor devuelto por la función anterior)
    if [ $? -eq 0 ];then
        # Ordenar la cola de ejecución según FCFS o SJF
        case $algo in
            1 ) #FCFS
                # Nada porque ya está en orden de llegada.
                ;;
            2 ) #SJF
                ej_ejecutar_ordenar_sjf
                ;;
        esac
    fi

    # Si no hay procesos en ejecución y hay procesos esperando a ser ejecutados
    [[ -z "$enEjecucion" ]] && [ ${#colaEjecucion[*]} -gt 0 ] \
        && ej_ejecutar_empezar_ejecucion

    # Si hay un proceso en ejecución, introducir su siguiente página a memoria
    if [[ -n "$enEjecucion" ]];then
        ej_ejecutar_memoria_pagina
        ej_calcular_marco_siguiente

        # Incrementar el contador del proceso
        (( pc[$enEjecucion]++ ))

    fi
    
}


# ------------------------------------
# --------- PANTALLA ----------------
# ------------------------------------

# DES: Mostrar una cabecera con información sobre el algoritmo y sobre la memoria
ej_pantalla_cabecera() {

    # Mostrar el algoritmo usado
    echo -e -n "${ft[0]} Paginación-"
    case $algo in

        1 )
            echo -e -n "FCFS-"
        ;;
        2 )
            echo -e -n "SJF-"
        ;;
    esac
    echo -e -n "RELOJ-C-NR${rstf}\n"

}

# DES: Mostrar el tiempo actual
ej_pantalla_tiempo() {
    printf " ${cl[$re]}${ft[0]}%s${rstf}: %-6s" "T" "${t}"
    printf " ${cl[$re]}${ft[0]}%7s${rstf}: %-6s" "Nº Dirs" "${tamanoMemoria}"
    printf " ${cl[$re]}${ft[0]}%8s${rstf}: %-6s" "Tam Pág" "${tamanoPagina}"
    printf " ${cl[$re]}${ft[0]}%7s${rstf}: %-6s" "Nº Marc" "${numeroMarcos}"
}

# DES: Mostrar información sobre la llegada de procesos
ej_pantalla_llegada() {

    case ${#llegada[*]} in
        # Si no ha llegado ningún proceso no hacer nada
        0 )
        ;;
        # Si ha llegada un proceso
        1 )
            local temp=${llegada[0]}
            echo -e " Ha llegado el proceso ${nombreProcesoColor[$temp]}."
        ;;
        # Si ha llegado más de un proceso
        * )
            echo -e -n " Han llegado los procesos "
            for p in ${!llegada[*]};do
                # Número del proceso
                local temp=${llegada[$p]}

                # Si es el antepenúltimo proceso
                if [ $p -eq $(( ${#llegada[*]} - 2 )) ];then

                    echo -e -n "${nombreProcesoColor[$temp]}"

                # Si es el último proceso
                elif [[ $p -eq $(( ${#llegada[*]} - 1 )) ]];then

                    echo -e " y ${nombreProcesoColor[$temp]}."

                # Si es cualquier otro proceso
                else

                    echo -e -n "${nombreProcesoColor[$temp]}, "

                fi
            done
        ;;
    esac

}

# DES: Mostrar tabla con los procesos y sus datos
ej_pantalla_tabla() {

    # Color del proceso que se está imprimiendo
    local color
    # Estado del proceso
    local est

    local ancho=$(( $anchoColRef + $anchoColTll + $anchoColTej + $anchoColNm + $anchoColTEsp + $anchoColTRet + $anchoColTREj + $anchoEstados ))
    local anchoRestante
    local anchoCadena
    # Mostrar cabecera
    echo ""
    printf "${ft[0]}" # Negrita
    # Nº proceso
    printf "%-${anchoColRef}s" " Ref"
    # 1ª parte
    printf "%${anchoColTll}s" "Tll"
    printf "%${anchoColTej}s" "Tej"
    printf "%${anchoColNm}s" "nMar"
    # 2ª Parte
    printf "%${anchoColTEsp}s" "Tesp"
    printf "%${anchoColTRet}s" "Tret"
    printf "%${anchoColTREj}s" "Trej"
    # Estado
    printf "%-${anchoEstados}s" " Estado"
    # Direcciones
    printf " Dirección - Página"
    printf "${rstf}\n"

    # Mostrar los procesos en orden de llegada
    for proc in ${listaLlegada[*]};do
        
        # Poner la fila con el color del proceso
        color=${colorProceso[$proc]}
        # Hayar el estado
        est=${estado[$proc]}
        est=${cadenaEstado[$est]}

        printf "${cl[$color]}${ft[0]}"
        # Ref
        printf "%-${anchoColRef}s" " ${nombreProceso[$proc]}"
        # 1ª parte
        printf "%${anchoColTll}s" "${tiempoLlegada[$proc]}"
        printf "%${anchoColTej}s" "${tiempoEjecucion[$proc]}"
        printf "%${anchoColNm}s" "${minimoEstructural[$proc]}"
        # 2ª Parte
        [[ -n "${tEsp[$proc]}" ]] \
            && printf "%${anchoColTEsp}s" "${tEsp[$proc]}" \
            || printf "%${anchoColTEsp}s" "-"
        [[ -n "${tRet[$proc]}" ]] \
            && printf "%${anchoColTRet}s" "${tRet[$proc]}" \
            || printf "%${anchoColTRet}s" "-"
        [[ -n "${tREj[$proc]}" ]] \
            && printf "%${anchoColTREj}s" "${tREj[$proc]} " \
            || printf "%${anchoColTREj}s" "-"
        # Estado
        # Para que puedan haber tildes hay que poner el ancho diferente.
        printf "%-s%*s" " ${est}" $(( ${anchoEstados} - ${#est} - 1)) ""

        anchoRestante=$(( $anchoTotal - $ancho ))

        # Direcciones
        for (( i=0; ; i++ ));do
            anchoCadena=$(( ${#procesoDireccion[$proc,$i]} + ${#procesoPagina[$proc,$i]} + 2 ))

            if [ $anchoRestante -lt $anchoCadena ];then
                printf "\n"
                anchoRestante=$anchoTotal
            fi
            printf " "
            if [ $i -lt ${pc[$proc]} ];then
                printf "${ft[2]}"
            fi
            
            # Si ya no quedan páginas
            [[ -z "${procesoDireccion[$proc,$i]}" ]] \
                && break

            printf "${ft[1]}${procesoDireccion[$proc,$i]}-${ft[0]}${procesoPagina[$proc,$i]}"
            
            if [ $i -lt ${pc[$proc]} ];then
                printf "${ft[3]}"
            fi

            anchoRestante=$(( $anchoRestante - $anchoCadena ))

        done

        printf "${rstf}\n"
    done

}

# DES: Mostrar media de Tesp y de Tret
ej_pantalla_media_tiempos() {

    local mediaTesp
    local mediaTret
    local sum=0
    local cont=0

    # CÁLCULOS
    for tiem in ${tEsp[*]};do
        sum=$(( sum + $tiem ))
        (( cont++ ))
    done
    [ $cont -ne 0 ] \
        && mediaTesp="$(bc -l <<<"scale=2;$sum / $cont")"
    sum=0
    cont=0

    for tiem in ${tRet[*]};do
        sum=$(( sum + $tiem ))
        (( cont++ ))
    done
    [ $cont -ne 0 ] \
        && mediaTret="$(bc -l <<<"scale=2;$sum / $cont")"
    
    # IMPRESIÓN
    if [ -n "${mediaTesp}" ];then
        printf " ${cl[$re]}%s${rstf}: %-9s" "Tiempo Espera Medio" "${mediaTesp}"
    else
        printf " ${cl[$re]}%s${rstf}: %-9s" "Tiempo Espera Medio" "0.0"
    fi

    if [ -n "${mediaTret}" ];then
        printf " ${cl[$re]}%s${rstf}: %s\n" "Tiempo Respuesta Medio" "${mediaTret}"
    else
        printf " ${cl[$re]}%s${rstf}: %s\n" "Tiempo Respuesta Medio" "0.0"
    fi

}

# DES: Mostrar un resumen con los fallos de página que han habido durante la ejecución
ej_pantalla_fin_fallos() {

    # El el ancho del número de marco máximo, para mostrarlos en el formato "03"
    local anchoNumMar=$(( ${minimoEstructural[$fin]} - 1 ))
    anchoNumMar=${#anchoNumMar}
    # El +4 es por la M de M03, el espacio a la izquierda y 2 por el ": " de la derecha
    local anchoEtiquetas=$(( ${#anchoNumMar} + 4 ))

    # Ancho de cada momento
    local anchoMomento=$anchoGen
    local anchoBloque=$(( $anchoMomento + 2 ))
    local anchoRestante=$(( $anchoTotal - $anchoEtiquetas ))

    # Número de momentos que se van a mostrar en esta linea
    local numBloquesPorLinea

    # Para saber por que marco se va en cada linea.
    # Son el primer momento y el último momento de cada linea.
    local primerMomento=0
    local ultimoMomento=""

    # Por cada linea.
    for (( l=0; ; l++ ));do

        local numBloquesPorLinea=$(( $anchoRestante / $anchoBloque ))
        ultimoMomento=$(( $primerMomento + $numBloquesPorLinea - 1 ))
        if [ $ultimoMomento -ge ${tiempoEjecucion[$fin]} ];then
            ultimoMomento=$(( ${tiempoEjecucion[$fin]} - 1 ))
        fi
        
        # Etiqueta para el tiempo
        echo -e -n "${cl[$re]}${ft[0]}"
        printf "%${anchoEtiquetas}s" "T: "
        echo -e -n "${rstf}"
        # Imprimir el tiempo para cada momento
        for (( mom=$primerMomento; mom<=$ultimoMomento; mom++ ));do
            printf "(%${anchoGen}s)" "${paginaTiempo[$fin,$mom]}"
        done
        printf "\n"

        # Imprimir la evolución de cada marco
        for (( mar=0; mar<${minimoEstructural[$fin]}; mar++ ));do
            # Etiqueta del marco
            echo -e -n "${cl[$re]}${ft[0]}"
            printf "%${anchoEtiquetas}s" " M$( printf "%0${anchoNumMar}d" "${mar}" ): "
            echo -e -n "${rstf}"
            # Imprimir la página de cada momento del marco
            printf "${ft[0]}"
            for (( mom=$primerMomento; mom<=$ultimoMomento; mom++ ));do
                if [ ${marcoFallo[$mom]} -eq $mar ];then
                    printf "${cf[3]}╔%${anchoGen}s╗${cf[0]}" "${resumenFallos[$mom,$mar]}"
                else
                    printf "┌%${anchoGen}s┐" "${resumenFallos[$mom,$mar]}"
                fi
            done
            printf "${rstf}\n"
            printf "%${anchoEtiquetas}s" ""
            # Imprimir el contador de cada momento del marco
            for (( mom=$primerMomento; mom<=$ultimoMomento; mom++ ));do
                if [ ${marcoFallo[$mom]} -eq $mar ];then
                    printf "${cf[3]}╚%${anchoMomento}s╝${cf[0]}" "${resumenNFU[$mom,$mar]}"
                else
                    printf "└%${anchoMomento}s┘" "${resumenNFU[$mom,$mar]}"
                fi
            done
            printf "\n"
        done

        if [ $ultimoMomento -eq $(( ${tiempoEjecucion[$fin]} - 1 )) ];then
            break;
        fi
        printf "\n"
        primerMomento=$(( $ultimoMomento + 1 ))
        anchoRestante=$(( $anchoTotal - $anchoEtiquetas ))

    done

}

# DES: Mostrar el proceso que ha finalizado su ejecución
ej_pantalla_fin() {

    if [ -n "${fin}" ];then

        echo -e " El proceso ${nombreProcesoColor[$fin]} ha finalizado su ejecución con ${cl[$re]}${numFallos[$fin]}${rstf} fallos de página."

        ej_pantalla_fin_fallos

    fi

}

# DES: Mostrar info sobre la entrada de procesos en memoria
ej_pantalla_entrada() {

    # Por cada proceso que ha entrado a memoria
    for p in ${entrada[*]};do

        echo -e " El proceso ${nombreProcesoColor[$p]} ha entrado a memoria a partir de la posición ${cl[$re]}${procesoMarcos[$p,0]}${rstf}."

    done

}

# DES: Mostrar cola de ejecución
ej_pantalla_cola() {
    if [ ${#colaEjecucion} -eq 0 ];then
        return
    fi

    echo -n -e " Cola(Orden ejecución):"
    for proc in ${colaEjecucion[*]};do
        echo -n -e " ${nombreProcesoColor[$proc]}"
    done
    echo
}

# DES: Mostrar el proceso que ha iniciado su ejecución
ej_pantalla_inicio() {
    if [ -n "$inicio" ];then
        echo -e " El proceso ${nombreProcesoColor[$inicio]} ha iniciado su ejecución."
    fi
}

# DES: Muestra la linea de memoria grande
ej_pantalla_linea_memoria_grande() {
    
    # Ancho del interior del bloque 
    local anchoBloqueIn=$anchoGen
    if [ $anchoBloqueIn -lt 4 ];then
        anchoBloqueIn=4
    fi
    # Ancho del bloque completo con los paréntesis
    local anchoBloqueOut=$(( $anchoBloqueIn + 2 ))
    local anchoEtiquetas=11
    local anchoRestante=$(( $anchoTotal - $anchoEtiquetas - 3))
    local numMaxBloquesPorLinea=$(( $anchoRestante / $anchoBloqueOut ))
    local numLineas=$(( $numeroMarcos / $numMaxBloquesPorLinea ))

    # Para saber por que marco se va en cada linea.
    local primerMarco=0
    local ultimoMarco=""
    local ultimoProceso=-2

    for (( l=0; l<=$numLineas; l++ ));do

        if [ $l -eq $numLineas ];then
            numBloquesPorLinea=$(( $numeroMarcos % $numMaxBloquesPorLinea ))
            if [ $numBloquesPorLinea -eq 0 ];then
                break
            fi

        else
            numBloquesPorLinea=$numMaxBloquesPorLinea
        fi

        ultimoMarco=$(( $primerMarco + $numBloquesPorLinea ))

        printf "%${anchoEtiquetas}s ${cl[3]}██%*s██${rstf}\n" "" $(( $numBloquesPorLinea * $anchoBloqueOut - 2 )) ""


        # PROCESOS
        # Etiqueta
        printf "${ft[0]}${cl[re]}%${anchoEtiquetas}s ${cl[3]}█${rstf}" "Proceso:"
        mar=${primerMarco}

        for (( ; mar<${ultimoMarco}; mar++ ));do

            # Poner el color
            if [ -n "${memoriaProceso[$mar]}" ];then
                temp=${memoriaProceso[$mar]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cl[$temp2]}"
            fi

            local marcoSiguiente=$(( $mar + 1 ))
            # Si el marco está vacío
            if [ -z "${memoriaProceso[$mar]}" ];then

                # Si antes tambien estaba vacío
                if [ $ultimoProceso -eq -1 ];then
                    printf " %${anchoBloqueIn}s"  ""
                else
                    echo -e -n "${cf[0]}${cl[0]}"
                    printf "[%-${anchoBloqueIn}s" "NADA"
                fi
                
                if [ -n "${memoriaProceso[$marcoSiguiente]}" ] || [[ $mar -eq $(( $numeroMarcos - 1 )) ]] ;then
                    printf "]"
                else
                    printf " "
                fi
                ultimoProceso=-1
            
            # Si se cambia de proceso
            elif [ ${ultimoProceso} -ne ${memoriaProceso[$mar]} ];then

                # Poner el color de fondo
            
                temp=${memoriaProceso[$mar]}

                printf "[${ft[0]}%-${anchoBloqueIn}s${ft[1]}" "${nombreProceso[$temp]}"

                if [ -z "${memoriaProceso[$marcoSiguiente]}" ] || [ ${memoriaProceso[$mar]} -ne ${memoriaProceso[$marcoSiguiente]} ];then
                    printf "]"
                else
                    printf " "
                fi

                ultimoProceso=${memoriaProceso[$mar]}

            # Si sigue el mismo proceso
            else
                printf " %${anchoBloqueIn}s"

                if [ -z "${memoriaProceso[$marcoSiguiente]}" ] || [ ${memoriaProceso[$mar]} -ne ${memoriaProceso[$marcoSiguiente]} ];then
                    printf "]"
                else
                    printf " "
                fi
            fi

            echo -e -n "${rstf}"

        done

        printf "${cl[3]}█${rstf}\n"

        # MARCOS
        # Etiqueta
        printf "${ft[0]}${cl[re]} %${anchoEtiquetas}s ${cl[3]}█${rstf}" "Nº Marco:"
        mar=${primerMarco}

        for (( ; mar<${ultimoMarco}; mar++ ));do

            # Poner el color
            if [ -n "${memoriaProceso[$mar]}" ];then
                temp=${memoriaProceso[$mar]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cl[$temp2]}"
            fi

            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf "${ft[0]}("
            else
                printf "["
            fi

            printf "%${anchoBloqueIn}s" "$mar"

            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf ")"
            else
                printf "]"
            fi

            echo -e -n "${rstf}"

        done

        printf "${cl[3]}█${rstf}\n"

        
        # PÁGINA
        # Etiqueta
        printf "${ft[0]}${cl[re]} %${anchoEtiquetas}s ${cl[3]}█${rstf}" "Página:"
        mar=${primerMarco}

        for (( ; mar<${ultimoMarco}; mar++ ));do

            # Poner el color
            if [ -n "${memoriaProceso[$mar]}" ];then
                temp=${memoriaProceso[$mar]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cl[$temp2]}"
            fi

            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf "${ft[0]}("
            else
                printf "["
            fi

            printf "%${anchoBloqueIn}s" "${memoriaPagina[$mar]}"
            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf ")"
            else
                printf "]"
            fi

            echo -e -n "${rstf}"

        done

        printf "${cl[3]}█${rstf}\n"


        # CONTADOR NFU
	# aunque ponga Reloj, es solo estetico, funciona como NFU
        # Etiqueta
        printf "${ft[0]}${cl[re]}%${anchoEtiquetas}s ${cl[3]}█${rstf}" "Cnt.Reloj:"
        mar=${primerMarco}

        for (( ; mar<${ultimoMarco}; mar++ ));do

            # Poner el color
            if [ -n "${memoriaProceso[$mar]}" ];then
                temp=${memoriaProceso[$mar]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cl[$temp2]}"
            fi

            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf "${ft[0]}("
            else
                printf "["
            fi

            if [[ -n "${memoriaPagina[$mar]}" ]];then
                # Número de usos de la página respectiva al marco
                local usos=${memoriaNFU[$mar]}
                printf "%${anchoBloqueIn}s" "${usos}"
            else
                printf "%${anchoBloqueIn}s"
            fi

            if [ -n "${siguienteMarco}" ] && [ $siguienteMarco -eq $mar ];then
                printf ")"
            else
                printf "]"
            fi

            

            echo -e -n "${rstf}"

        done

        printf "${cl[3]}█${rstf}\n"
        printf "%${anchoEtiquetas}s ${cl[3]}██%*s██${rstf}\n" "" $(( $numBloquesPorLinea * $anchoBloqueOut - 2 )) ""


        primerMarco=$ultimoMarco

    done
}

# DES: Muestra la linea de memoria pequeña
ej_pantalla_linea_memoria_pequena() {

    local temp
    local temp2

    local anchoBloque=$anchoGen
    local anchoEtiqueta=5
    local anchoRestante=$(( $anchoTotal - $anchoEtiqueta - 2 ))
    
    local numBloquesPorLinea

    local procesoActual=-2
    local primerMarco=0
    local ultimoMarco=""
    local ultimoProceso=""
    for (( l=0; ; l++ ));do

        # Calcular cuantos marcos se van a imprimir en esta linea
        numBloquesPorLinea=$(( $anchoRestante / $anchoBloque ))
        ultimoMarco=$(( $primerMarco + $numBloquesPorLinea - 1 ))
        if [ $ultimoMarco -ge $numeroMarcos ];then
            ultimoMarco=$(( $numeroMarcos - 1 ))
        fi

        #PROCESOS
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" ""
        printf "|"
        ultimoProceso=-2
        for (( m=$primerMarco; m<=$ultimoMarco; m++ ));do
            # Si el marco está vacío o es el mismo proceso
            if [ -z "${memoriaProceso[$m]}" ] || [ ${ultimoProceso} -eq ${memoriaProceso[$m]} ];then
                printf "%${anchoBloque}s"
                if [ -z "${memoriaProceso[$m]}" ];then
                    ultimoProceso=-1
                fi
            # Si se cambia de proceso
            elif [ ${ultimoProceso} -ne ${memoriaProceso[$m]} ];then
                temp=${memoriaProceso[$m]}
                printf "%s%*s" "${nombreProcesoColor[$temp]}" "$(( ${anchoBloque} - ${#nombreProceso[$temp]} ))" ""
                ultimoProceso=${temp}
            fi
        done
        printf "${rstf}|\n"

        #PÁGINAS
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" " BM: "
        printf "|"
        for (( m=$primerMarco; m<=$ultimoMarco; m++ ));do
            # Poner el color
            if [ -n "${memoriaProceso[$m]}" ];then
                temp=${memoriaProceso[$m]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cf[$temp2]}"
                [[ " ${coloresClaros[@]} " =~ " ${temp2} " ]] \
                    && echo -n -e "${cl[1]}" \
                    || echo -n -e "${cl[2]}"
            else
                printf "${cf[2]}"
                #echo -e -n "\e[7m"
            fi

            temp=${memoriaProceso[$m]}
            temp2=$(( ${pc[$temp]} - 1 ))
            if [ -n "${memoriaPagina[$m]}" ] && [ ${procesoPagina[$temp,$temp2]} -eq ${memoriaPagina[$m]} ];then
                printf "${ft[0]}"
            fi

            if [ -n "${memoriaProceso[$m]}" ] && [ -z "${memoriaPagina[$m]}" ];then
                printf "%${anchoBloque}s" "-"
            else
                printf "%${anchoBloque}s" "${memoriaPagina[$m]}"
            fi

            if [ -n "${memoriaPagina[$m]}" ] && [ ${procesoPagina[$temp,$temp2]} -eq ${memoriaPagina[$m]} ];then
                printf "${ft[1]}"
            fi
        done
        printf "${rstf}| M=$numeroMarcos \n"

        #NÚMERO DE MARCO
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" ""
        printf "|"
        ultimoProceso=-2
        for (( m=$primerMarco; m<=$ultimoMarco; m++ ));do
            if [ -n "${memoriaProceso[$m]}" ];then
                procesoActual="${memoriaProceso[$m]}"
            else
                procesoActual=-1
            fi
            if [ $ultimoProceso -eq $procesoActual ];then
                printf "%${anchoBloque}s" ""
            else
                printf "%${anchoBloque}s" "$m"
                ultimoProceso=$procesoActual
            fi
        done

        printf "${rstf}|\n"
        # Si se ha llegado al último marco
        if [ $ultimoMarco -eq $(( $numeroMarcos - 1 )) ];then
            break;
        fi
        primerMarco=$(( $ultimoMarco + 1 ))
        anchoRestante=$(( $anchoTotal - 2 ))
    done

}

# DES: Mostrar la linea temporal
ej_pantalla_linea_tiempo() {
    local temp
    local temp2

    local anchoBloque=$anchoGen
    local anchoEtiqueta=5
    local anchoRestante=$(( $anchoTotal - $anchoEtiqueta - 2 ))
    
    local primerTiempo=0
    local ultimoTiempo=""
    local ultimoProceso=""
    for (( l=0; ; l++ ));do

        # Calcular cuntos marcos se van a imprimir en esta linea
        local numBloquesPorLinea=$(( $anchoRestante / $anchoBloque ))
        ultimoTiempo=$(( $primerTiempo + $numBloquesPorLinea - 1 ))
        if [ $ultimoTiempo -gt $t ];then
            ultimoTiempo=$(( $t ))
        fi

        #PROCESOS
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" ""
        printf "|"
        ultimoProceso=-2
        for (( m=$primerTiempo; m<=$ultimoTiempo; m++ ));do
            # Si el marco está vacío o es el mismo proceso
            if [ -z "${tiempoProceso[$m]}" ] || [ ${ultimoProceso} -eq ${tiempoProceso[$m]} ];then
                printf "%${anchoBloque}s"
                if [ -z "${tiempoProceso[$m]}" ];then
                    ultimoProceso=-1
                fi
            # Si se cambia de proceso
            elif [ ${ultimoProceso} -ne ${tiempoProceso[$m]} ];then
                temp=${tiempoProceso[$m]}
                printf "%s%*s" "${nombreProcesoColor[$temp]}" "$(( ${anchoBloque} - ${#nombreProceso[$temp]} ))" ""
                ultimoProceso=${temp}
            fi
        done
        printf "${rstf}|\n"

        #PÁGINAS
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" " BT: "
        printf "|"
        for (( m=$primerTiempo; m<=$ultimoTiempo; m++ ));do
            # Poner el color
            if [ $m -gt $t ];then
                printf "${rstf}"
            elif [ -n "${tiempoProceso[$m]}" ];then
                temp=${tiempoProceso[$m]}
                temp2=${colorProceso[$temp]}
                echo -e -n "${cf[$temp2]}"
                [[ " ${coloresClaros[@]} " =~ " ${temp2} " ]] \
                    && echo -n -e "${cl[1]}" \
                    || echo -n -e "${cl[2]}"
            else
                #printf "\e[7m${rstf}"
                printf "${cf[2]}"
            fi
            printf "%${anchoBloque}s" "${tiempoPagina[$m]}"
        done
	printf "${rstf}| T=$t\n"

        #TIEMPO
        # Imprimir la etiqueta si estamos en la primera linea
        [ $l -eq 0 ] && printf "%${anchoEtiqueta}s" ""
        printf "|"
        ultimoProceso=-2
        for (( m=$primerTiempo; m<=$ultimoTiempo; m++ ));do

            if [[ "$ultimoProceso" -eq "-2" || -z "${tiempoProceso[$m]}" && $ultimoProceso -ne -1 || -n "${tiempoProceso[$m]}" && "${ultimoProceso}" -ne "${tiempoProceso[$m]}" ]];then
                printf "%${anchoBloque}s" "$m"
                [ -z "${tiempoProceso[$m]}" ] \
                    && ultimoProceso=-1 \
                    || ultimoProceso=${tiempoProceso[$m]}
            else
                printf "%${anchoBloque}s"
            fi
        done

        printf "${rstf}|\n"
        # Si se ha llegado al último marco
        if [ $ultimoTiempo -eq $t ];then
            break;
        fi
        primerTiempo=$(( $ultimoTiempo + 1 ))
        anchoRestante=$(( $anchoTotal - 2 ))
    done
}

# DES: Muestra la pantalla con la información de los eventos que han ocurrido
ej_pantalla() {

    # Mostrar una cabecera con información sobre el algoritmo y sobre la memoria
    ej_pantalla_cabecera

    # Mostrar el tiempo actual
    ej_pantalla_tiempo

    # Mostrar info sobre la llegada de procesos
    ej_pantalla_llegada

    # Mostrar tabla con los procesos
    ej_pantalla_tabla
    
    # Mostrar media de Tesp y de Tret
    ej_pantalla_media_tiempos

    # Mostrar el proceso que ha finalizado su ejecución junto con un resumen de sus fallos
    ej_pantalla_fin

    # Mostrar info sobre la entrada de procesos en memoria
    ej_pantalla_entrada

    # Mostrar cola de ejecución
    ej_pantalla_cola

    # Mostrar el proceso que ha iniciado su ejecución
    ej_pantalla_inicio

    # Mostrar la linea de memoria grande
    ej_pantalla_linea_memoria_grande

    # Mostrar la linea de memoria más pequeña
    ej_pantalla_linea_memoria_pequena

    # Mostrar la linea temporal
    ej_pantalla_linea_tiempo
}

# DES: resetea las variables de evento para que no se vuelvan a mostrar
ej_limpiar_eventos() {
    # No seguir mostrando la pantalla
    mostrarPantalla=0
    reubicacion=0

    llegada=()
    entrada=()
    inicio=""

    # Si ha finalizado un proceso
    if [[ -n "${fin}" ]];then
        resumenFallos=()
        resumenNFU=()
        # Por si entra un proceso a la vez que sale
        local corte=${tiempoEjecucion[$fin]}
        marcoFallo=(${marcoFallo[@]:$corte})
        fin=""
    fi
}


# DES: Muestra un resumen de lo que ha pasado
ej_resumen() {
    # CABECERA
    echo -e                "${cf[$ac]}                                                 ${rstf}"
    echo -e                 "${cf[10]}                                                 ${rstf}"
    case $algo in
        # FCFS
        1 )
            echo -e "${cf[10]}${cl[1]}${ft[0]}  FCFS - Pag - RELOJ - C - NR                    ${rstf}"
        ;;
        # SJF
        2 )
            echo -e "${cf[10]}${cl[1]}${ft[0]}  SJF - Pag - RELOJ - C - NR                     ${rstf}"
        ;;
    esac
    printf          "${cf[10]}${cl[1]}  %-47s${rstf}\n" "Resumen Final" # Mantiene el ancho de la cabecera
    echo -e                 "${cf[10]}                                                 ${rstf}"
    echo -e                "${cf[$ac]}                                                 ${rstf}"
    echo

    # TABLA PROCESOS
    # Color del proceso que se está imprimiendo
    local color

    if [ $anchoGen -lt 5 ]; then
        local anchoColIni=5 # INICIO EJECUCIÓN
        local anchoColFin=5 # FIN EJECUCIÓN
    else
        local anchoColIni=$anchoGen # INICIO EJECUCIÓN
        local anchoColFin=$anchoGen # FIN EJECUCIÓN
    fi
    if [ $anchoGen -lt 6 ]; then
        local anchoColFal=7 # FALLOS
    else
        local anchoColFal=$anchoGen # FALLOS
    fi

    # Mostrar cabecera
    printf "${ft[0]}" # Negrita
    # Nº proceso
    printf "%-${anchoColRef}s" " Ref"
    # 1ª parte
    printf "%${anchoColTll}s" "Tll "
    printf "%${anchoColTej}s" "Tej "
    # 2ª Parte
    printf "%${anchoColTEsp}s" "Tesp "
    printf "%${anchoColTRet}s" "Tret "
    # Inicio y Fin
    printf "%${anchoColIni}s" "Ini "
    printf "%${anchoColFin}s" "Fin "
    # Fallos
    printf "%${anchoColFal}s" "Fallos "
    printf "${rstf}\n"

    # Mostrar los procesos en orden de llegada
    for proc in ${listaLlegada[*]};do
        
        # Poner la fila con el color del proceso
        color=${colorProceso[$proc]}
        printf "${cl[$color]}${ft[0]}"

        # Ref
        printf "%-${anchoColRef}s" " ${nombreProceso[$proc]}"
        # 1ª parte
        printf "%${anchoColTll}s" "${tiempoLlegada[$proc]} "
        printf "%${anchoColTej}s" "${tiempoEjecucion[$proc]} "
        # 2ª Parte
        printf "%${anchoColTEsp}s" "${tEsp[$proc]} "
        printf "%${anchoColTRet}s" "${tRet[$proc]} "
        # Inicio y Fin
        printf "%${anchoColIni}s" "${procesoInicio[$proc]} "
        printf "%${anchoColFin}s" "${procesoFin[$proc]} "
        # Fallos
        printf "%${anchoColFal}s" "${numFallos[$proc]} "
        printf "${rstf}\n"
    done

    # DATOS VARIOS

    local mediaTesp
    local mediaTret

    local totalFallos=0
    local totalPags=0

    local sum=0
    local cont=0
    for tiem in ${tEsp[*]};do
        sum=$(( sum + $tiem ))
        (( cont++ ))
    done
    [ $cont -ne 0 ] \
        && mediaTesp="$(bc -l <<<"scale=2;$sum / $cont")"
    sum=0
    cont=0

    for tiem in ${tRet[*]};do
        sum=$(( sum + $tiem ))
        (( cont++ ))
    done
    [ $cont -ne 0 ] \
        && mediaTret="$(bc -l <<<"scale=2;$sum / $cont")"


    for p in ${procesos[*]};do
        ((totalFallos+=${numFallos[$p]}))
        ((totalPags+=${tiempoEjecucion[$p]}))
    done

    echo
    echo " Tiempo de espera medio: $mediaTesp"
    echo " Tiempo de retorno medio: $mediaTret"
    echo

}


# DES: Aquí empieza lo difícil. Esto es lo que más vas a tener que cambiar.
ej() {
# Variables locales

    # Elegir cómo se va a mostrar la ejecución
    local metodoEjecucion
    preguntar "Método de ejecución" \
              "¿Cómo quieres ejecutar el algoritmo?" \
              metodoEjecucion \
	      "Por eventos (presionando Enter)" \
	      "Automatica (definiendo el tiempo de espera entre eventos)" \
	      "Completa (sin espera alguna)" \
              "Resumen final"

    # ------------VARIABLES SOLO PARA LA EJECUCIÓN-------------
    # Memoria
    local memoriaProceso=()         # Contiene el proceso que hay en cada marco. El índice respectivo está vacío si no hay nada.
    local memoriaPagina=()          # Contiene la página que hay en cada marco. El índice respectivo está vacío si no hay nada.
    local memoriaLibre=$numeroMarcos # Número de marcos libres. Se empieza con la memoria vacía.
    local memoriaOcupada=0          # Número de marcos ocupados. Empieza en 0.
    local memoriaNFU=()             # Contiene el número de usos que tiene cada página en memoria. El índice está vacío si no hay nada.
    local marcosActuales=()         # Marcos asignados al proceso en ejecución.

    # Procesos
    local pc=()                     # Contador de los procesos. Contiene la siguiente instrucción a ejecutar para cada proceso.
    for p in ${procesos[*]};do pc[$p]=0 ;done # Poner contador a 0 para todos los procesos

    declare -A procesoMarcos        # Contiene los marcos asignados a cada proceso actualmente

    local estado=()                 # Estado de cada proceso
    # [0=fuera del sistema 1=en espera para entrar a memoria 2=en espera para ser ejecutado 3=en ejecución 4=Finalizado]
    local cadenaEstado=()           # Cadenas correspondientes a cada estado. Es lo que se muestra en la tabla.
    cadenaEstado[0]="Fuera de sist."
    cadenaEstado[1]="En espera"
    cadenaEstado[2]="En memoria"
    cadenaEstado[3]="En ejecución"
    cadenaEstado[4]="Finalizado"
    for p in ${procesos[*]};do estado[$p]=0 ;done # Poner todos los procesos en estado 0 (fuera del sistema)

    local siguienteMarco=""         # Puntero al siguiente marco en el que se va a introducir una página si no está ya en memoria.

    # Tiempos de espera, de ejecución y restante de ejecución
    local tEsp=()       # Tiempo de espera de cada proceso
    local tRet=()       # Tiempo de retorno (Desde llegada hasta fin de ejecución)
    local tREj=()       # Tiempo restante de ejecución

    # Colas
    local colaLlegada=("${listaLlegada[@]}") # Procesos que están por llegar. En orden de llegada
    local colaMemoria=()            # Procesos que han llegado pero no caben en la memoria y están esperando
    local colaEjecucion=()          # Procesos en memoria esperando a ser ejecutados. Se ordena según el algorimo dado (FCFS o SJF)
    local enEjecucion               # Proceso en ejecución (Vacío si no se ejecuta nada)

   
    # ------------VARIABLES PARA EL MOSTRADO DE LA INFORMACIÓN-------------
    local mostrarPantalla=1         # [1=Se va a mostrar la pantalla 0=No se muestra porque no ha ocurrido nada interesante]


    # Anchos para la tabla de procesos
    local anchoColTEsp=5
    local anchoColTRet=5
    local anchoColTREj=$(( $anchoColTej + 1 ))
    local anchoEstados=16

    # Datos de los eventos que han ocurrido
    local llegada=()                # Procesos que han llegado en este tiempo
    local entrada=()                # Procesos que han entrado a memoria en este tiempo
    local inicio=""                 # Proceso que ha empezado a ejecutarse
    local fin=""                    # Proceso que ha finalizado su ejecución

    declare -A resumenFallos        # Contiene información de los fallos de página que han habido durante la ejecución del proceso
                                    # se muestra cuando un proceso finaliza su ejecución. resumenFallos[$momento,$marco]
    declare -A resumenNFU           # Contiene el estado del contador para cada marco en cada momento
    declare -A paginaTiempo         # Contiene el tiempo en el que se introduce cada página del proceso [$proc,$pc]
    local marcoFallo=()             # Marco que se usa para cada página
    local numFallos=()              # Número de fallos de cada proceso
    for p in ${procesos[*]};do numFallos[$p]=0 ;done

    # Variables para la linea temporal
    local tiempoProceso=()          # Contien el proceso que está en ejecución en cada tiempo
    local tiempoPagina=()           # Contiene la página que se ha ejecutado en cada tiempo

    local numProcesosFinalizados=0


    # VARIABLES PARA LA PANTALLA DE RESUMEN
    local procesoInicio=()          # Contiene el tiempo de inicio de cada proceso
    local procesoFin=()             # COntiene el tiempo de fin de cada proceso

# Ejecución

     #si la opcion selecionada es la ejecucion automatica, pregunta un tiempo de espera entre
     #eventos y lo guarda en un avariable para despues ejecutar automaticamente
    if [ $metodoEjecucion -eq 2  ]; then
	local tiempoEsperaEntreEventos=""
	read -p "Introduzca el tiempo de espera entre eventos: " tiempoEsperaEntreEventos
    fi

#Ejecución por eventos
    # Cada ciclo se incrementa el tiempo t
    for (( t=0; ; t++ ));do
        # Si el tiempo es más grande que el ancho general
        if [ ${#t} -gt $anchoGen ];then
            anchoGen=${#t}
        fi

        # Llegada de procesos, ejecución, introducción a memoria...
        ej_ejecutar

        # Mostrado de la pantalla con los eventos que ocurren
        if [ $mostrarPantalla -eq 1 ] && [ $metodoEjecucion -eq 1 -o $metodoEjecucion -eq 2 -o $metodoEjecucion -eq 3 ];then
            
	    # En la ejecucion completa no queremos que vacie la pantalla entre eventos, excepto en la primera 
	    #  impresion para quitar el menu de seleccion de metodo de ejec
            echo ""
	    echo "--------------------------------------------------------------------------"
	    echo ""

	    if [ $metodoEjecucion -ne 3  -o $t -eq 0 ]; then 
            clear
	    fi

            # Ancho total respecto al cual se van a imprimir las cosas
            local anchoTotal=$( tput cols )
            # mostrar la pantalla
            ej_pantalla

            # Añadir a los informes
            informar_color "$( ej_pantalla )"
            informar_color "----------------------------------------------------------------"

            # Establecer el ancho para el informe plano
            local anchoTotal=$anchoInformePlano
            informar_plano "$( ej_pantalla | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
            informar_plano "----------------------------------------------------------------"
            
            # limpiar las variables de evento para que no se vuelvan a mostrar
            ej_limpiar_eventos

            # Guardar los informes con la pantalla
            guardar_informes

             #pide la introduccion del enter para pasar de evento si se ha seleccionado la opcion de ejecucion por eventos manual
	    if [ $metodoEjecucion -eq 1 ]; then
            	pausa_tecla
       	    fi

	     #realiza el sleep si la opcion de ejecucion es la automatica
	    if [ $metodoEjecucion -eq 2 ]; then
            	sleep $tiempoEsperaEntreEventos	
       	    fi
	fi
        # Si no hay ningún proceso en cola ni ejecutandose salir del loop.
        if [ ${#colaEjecucion[*]} -eq 0 ] && [ ${#colaLlegada[*]} -eq 0 ] && [ ${#colaMemoria[*]} -eq 0 ] && [ -z "$enEjecucion" ] ;then
            break
        fi

    done
    
    # no vacia la pantalla hasta que se presione enter en la ejecucion completa
    if [ $metodoEjecucion -eq 3 ]; then
   	 pausa_tecla
    fi

    clear

    # Mostrar el resumen de la ejecución
    ej_resumen
    # Hacer los informes
    informar_color "$( ej_resumen )"
    informar_plano "$( ej_resumen | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
    guardar_informes
    pausa_tecla

}

# Función principal
main() {
    init
    intro
    opciones
    datos
    ej
}
main
