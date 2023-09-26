;Proyecto de Unidad
;Cesar Alexis Ochoa Tapia 19130952
;Hugo René Guerra Barajas 19130917
;Juego Pong

;---MACROS---
LimpiarPantalla MACRO
    mov ah, 00h                                                 ;Modo de video
    mov al, 13h
    int 10h

    mov ah, 0Bh                                                 ;Color de fondo
    mov bh, 00h
    mov bl, 00h                                                 ;Negro
    int 10h
ENDM

;**** MACRO CON PARµMETROS ****
Imprimir MACRO cadena
        mov ah, 09h
        mov dx, offset cadena
        int 21h
ENDM

;----------------------------------------------------------------------------------------------------------

DibujarPelota MACRO
    mov cx, pelotaX                                             ;Columna inicial (X)
    mov dx, pelotaY                                             ;Fila inicial (Y)

    DibujarPelotaHorizontal:
        mov ah, 0Ch                                             ;Para dibujar un pixel
        mov al, 0Fh                                             ;Color blanco
        mov bh, 00h                                             ;Número de página (Solo hay una)
        int 10h

        inc cx
        mov ax, cx                                              ;cx - pelotaX > pelotaTamano (if(true) avanza fila, else avanza columna)
        sub ax, pelotaX
        cmp ax, pelotaTamano
        jng DibujarPelotaHorizontal                             ;Not greater than

        mov cx, pelotaX                                         ;cx regresa a la columna inicial
        inc dx                                                  ;avanza fila
        mov ax, dx                                              ;dx - pelotaY > pelotaTamano (if(true) sale, else continúa)
        sub ax, pelotaY
        cmp ax, pelotaTamano
        jng DibujarPelotaHorizontal
ENDM

;----------------------------------------------------------------------------------------------------------

TerminarJuego MACRO
    mov ah, 00h
    mov al, 02h
    int 10h

    mov ah, 4Ch
    int 21h
ENDM

.MODEL SMALL
.STACK 20h
.DATA
     ;---CONSTANTES DE LA PANTALLA DE DATOS-------------------------------------------

    marco db '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
        db 0Ah, 0Ah, 0Ah, 0Ah, 0Dh, '$'

    	nombre1 DB 'Cesar Alexis Ochoa Tapia 19130952',0Dh,0Ah,'$'
        nombre2 DB 'Hugo Rene Guerra Barajas 19130917',0Dh,0Ah,'$'
        materia db 'LENGUAJES DE INTERFAZ, Tecnologico de la laguna 11/12/22',0Dh,0Ah,'$'
        profesor DB 'Ing: Armando Ruiz Arrollo',0Dh,0Ah,'$'
         programa db 'PROYECTO U4: JUEGO DEL PONG',0Dh,0Ah,'$'
        desc db  'Proyecto final que nos permite jugar al clasico juego del pong',0Dh,0Ah,'$'
        db 0Ah, 0Ah, 0Ah, 0Dh, '$'

    continuar db 'Presione enter para avanzar...$'

    ;---------------------------------------------------------------------------

    ;Variables pantalla
    anchoPantalla       DW 140h                                 ;320 pixeles
    altoPantalla        DW 0C8h                                 ;200 pixeles
    limitePantalla      DW 6                                    ;Variable para verificar colisiones antes de llegar

    ;Variables de la pelota
    pelotaOrigX         DW 0A0h
    pelotaOrigY         DW 64h
    pelotaX             DW 0A0h                                 ;Posición X de la pelota
    pelotaY             DW 64h                                  ;Posición Y de la pelota
    pelotaTamano        DW 04h                                  ;Tamaño de la pelota (en pixeles)
    pelotaVelocidadX    DW 05h                                  ;Velocidad horizontal de la pelota
    pelotaVelocidadY    DW 02h                                  ;Velocidad vertical de la pelota

    ;Variables de los pad
    padIzquierdoX       DW 0Ah
    padIzquierdoY       DW 55h
    player1Points       DB 0

    padDerechoX         DW 130h
    padDerechoY         DW 55h
    player2Points       DB 0
    controladorIA       DB 0                                    ;Es el pad derecho controlado por IA

    padAncho            DW 05h
    padAlto             DW 1Fh
    padVelocidad        DW 05h

    ;Variables auxiliares para el estado del juego
    tiempoAux           DB 0                                    ;Variable para saber si el tiempo ha cambiado
    juegoActivo         DB 1                                    ;Si es 1 esta activo sino termina
    cerrarJuego         DB 0                                    ;Si es uno empezará el proceso de cerrar juego
    indiceWinner        DB 0                                    ;indica cual es el ganador
    escenaActual        DB 0                                    ;indica en qué parte del juego está

    ;Variables de texto
    textoJugador1       DB '0','$'                              ;Puntos jugador 1
    textoJugador2       DB '0','$'                              ;Puntos jugador2
    textoGameOver       DB 'GAME OVER', '$'
    textoWinner         DB 'Player 0 Won', '$'
    textoReiniciar      DB 'Press R to play again', '$'
    textoMenu           DB 'Press E to exit to main menu', '$'
    textoMenuTitulo     DB 'Main Menu', '$'
    textoMenu1Jugador   DB 'Singleplayer - Press S', '$'
    textoMenuMulti      DB 'Multiplayer - Press M', '$'
    textoMenuSalir      DB 'Exit Game - Press E', '$'

.CODE
    inicio:
        push DS                                                 ;push a la pila
        sub ax, ax                                              ;Limpiar el registro
        push ax                                                 ;push a la pila

        mov ax, @DATA                                           ;Guardar en ax el contenido del segmento de datos
        mov ds, ax                                              ;Guardar en ds el contenido de ax
        pop ax                                                  ;Libera el primer elemento de la pila
        pop ax

        call bienvenida                                         ; -cartel de bienvenida--------------------------

            LimpiarPantalla

            verificarT:
                cmp cerrarJuego, 01h                            ;Si se quiere cerrar el juego
                je procesoSalida
                cmp escenaActual, 00h                           ;Si se está en el menú
                je mostrarMenu
                cmp juegoActivo, 00h                            ;Si ya no se está jugando
                je MostrarGameOver

                mov ah, 2Ch                                     ;Obtener el tiempo del sistema
                int 21h                                         ;ch = hora / cl = minuto / dh = segundo / dl = 1/100 segundos

                cmp dl, tiempoAux                               ;El tiempo actual es equivalente al anterior(tiempoAux)?
                je verificarT                                   ;Si es el mismo, volverá a verificar
                                                                ;Si es diferente dibujará
                mov tiempoAux, dl                               ;Actualiza el tiempo
                LimpiarPantalla
                call MoverPelota
                DibujarPelota

                call MoverPads
                call DibujarPads

                call DibujarUI                                  ;dibuja la interfaz del juego

                jmp verificarT                                  ;Vuelve a verificar

                mostrarGameOver:
                    call dibujarGameOverMenu
                    jmp verificarT

                mostrarMenu:
                    call dibujarMenu
                    jmp verificarT

                procesoSalida:
                    TerminarJuego

    ;---PROCEDIMIENTOS--------------------------------------------------------------

    MoverPelota PROC NEAR
    mov ax, pelotaVelocidadX
    add pelotaX, ax                                             ;Mover la pelota horizontalmente

    mov ax, limitePantalla
    cmp pelotaX, ax                                             ;Si es menor, punto para el jugador
    jl puntoJugador2                                            ;2 y reinicia la posición de la pelota

    mov ax, anchoPantalla
    sub ax, pelotaTamano
    sub ax, limitePantalla
    cmp pelotaX, ax                                             ;pelotaX > anchoPantalla - pelotaTamano (if(true) colisiona)
    jg puntoJugador1                                            ;jump if greater /
    jmp moverPelotaVertical

        puntoJugador1:
            inc player1Points
            call ResetPosicionBall
            call actualizarTextoP1                              ;actualiza el marcador del jugador1

            cmp player1Points, 05h                              ;checa qe este jugador llege a 5 puntos
            jge gameOver                                        ; si tiene 5 puntos o mas termina
            ret

        puntoJugador2:
            inc player2Points
            call ResetPosicionBall
            call actualizarTextoP2                              ;actualiza el marcador del jugador2

            cmp player2Points, 05h                              ;checa qe este jugador llege a 5 puntos
            jge gameOver                                        ; si tiene 5 puntos o mas termina
            ret

        gameOver:                                               ;cuando llegen a 5 puntos termina el juego
            cmp player1Points, 05h                              ;checa cual jugador tiene mas de 5 puntos
            jnl WinnerJugador1                                  ; si el jugadpr 1 no pasa de 5 puntos
            jnp WinnerJugador2                                  ; si el jugadpr 2 no pasa de 5 puntos

            WinnerJugador1:
                mov indiceWinner, 01h                           ;actualiza el indice del ganador con el indice del jugador
                jmp continuarGameOver

            WinnerJugador2:
                mov indiceWinner, 02h                           ;actualiza el indice del ganador con el indice del jugador
                jmp continuarGameOver

        continuarGameOver:
            mov player1Points, 00h                              ;reinicia los puntos a 0
            mov player2Points,00h
            call actualizarTextoP1
            call actualizarTextoP2
            mov juegoActivo, 00h                                ;detiene el juego
            ret

        ;mueve la pelota vertical
        moverPelotaVertical:
            mov ax, pelotaVelocidadY
            add pelotaY, ax                                     ;Mover la pelota verticalmente

    mov ax, limitePantalla
    cmp pelotaY, ax
    jl negVelocidadY

    mov ax, altoPantalla
    sub ax, pelotaTamano
    sub ax, limitePantalla
    cmp pelotaY, ax                                             ;pelotaY > altoPantalla - pelotaTamano (if(true) colisiona)
    jg negVelocidadY

    ;checar si la bola colisiona con el pad derecho
    ;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny1 && miny1 <maxy2
    ;pelotaX + tamañoPelota > padDerechoX && PelotaX < padDerechoX + padAncho
    ;&& pelotaY + tamañoPelota > padDerechoY && pelotaY < padDerechoy + padAltura

    mov ax, pelotaX
    add ax, pelotaTamano
    cmp ax, padDerechoX
    jng checkColisionPadIzquierdo                               ;si no hay colision checa con el panel izquierdo si hay colisiones

    mov ax, padDerechoX
    add ax, padAncho
    cmp pelotaX, ax
    jnl checkColisionPadIzquierdo;

    mov ax, pelotaY
    add ax, pelotaTamano
    cmp ax, padDerechoY
    jng checkColisionPadIzquierdo                               ;si no hay colision checa con el panel izquierdo si hay colisiones

    mov ax, padDerechoY
    add ax, padAlto
    cmp pelotaY, ax
    jnl checkColisionPadIzquierdo;

    ;si en este punto, la bola colisiona con el pad derecho
    jmp negVelocidadX

    ;checar si la bola colisiona con el pad izquierdo
    checkColisionPadIzquierdo:

    ;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny1 && miny1 <maxy2
    ;pelotaX + tamañoPelota > padIzquierdoX && PelotaX < padIzquierdoX + padAncho
    ;&& pelotaY + tamañoPelota > padIzquierdoY && pelotaY < padIzquierdoy + padAltura

    mov ax, pelotaX
    add ax, pelotaTamano
    cmp ax, padIzquierdoX
    jng exitCheck                                               ;si no hay colision sale

    mov ax, padIzquierdoX
    add ax, padAncho
    cmp pelotaX, ax
    jnl exitCheck;

    mov ax, pelotaY
    add ax, pelotaTamano
    cmp ax, padIzquierdoY
    jng exitCheck                                               ;si no hay colision sale

    mov ax, padIzquierdoY
    add ax, padAlto
    cmp pelotaY, ax
    jnl exitCheck;

    ;si en este punto, la bola colisiona con el pad izquierdo
    jmp negVelocidadX

    negVelocidadY:
        neg pelotaVelocidadY
        ret

    negVelocidadX:
        neg pelotaVelocidadX                                    ;revierte la velocidad de la bola horizontal
        ret

    exitCheck:
        ret
MoverPelota ENDP

;----------------------------------------------------------------------------------------------------------

ResetPosicionBall PROC NEAR                                     ;Reinicia la posición de la pelota
    mov ax, PelotaOrigX
    mov Pelotax, ax

    mov ax, PelotaOrigY
    mov PelotaY, ax
    ret
ResetPosicionBall ENDP

;----------------------------------------------------------------------------------------------------------

DibujarPads PROC NEAR
    mov cx, padIzquierdoX                                       ;Columna inicial (X)
    mov dx, padIzquierdoY                                       ;Fila inicial (Y)

    DibujarPadHorizontal:
        mov ah, 0Ch                                             ;Para dibujar un pixel
        mov al, 0Fh                                             ;Color blanco
        mov bh, 00h                                             ;Número de página (Solo hay una)
        int 10h

        inc cx
        mov ax, cx                                              ;cx - padizquierdox > padderecho (if(true) avanza fila, else avanza columna)
        sub ax, padIzquierdoX
        cmp ax, padAncho
        jng DibujarPadHorizontal                                ;Not greater than

        mov cx, padIzquierdoX                                   ;cx regresa a la columna inicial
        inc dx                                                  ;avanza fila

        mov ax, dx                                              ;dx - padIzquierdoX  > padIzquierdoY (if(true) sale, else continúa)
        sub ax, padIzquierdoY
        cmp ax, padAlto
        jng DibujarPadHorizontal

        mov cx, padDerechoX                                     ;Columna inicial (X)
        mov dx, padDerechoY                                     ;Fila inicial (Y)

    DibujarPadDerechoHorizontal:
        mov ah, 0Ch                                             ;Para dibujar un pixel
        mov al, 0Fh                                             ;Color blanco
        mov bh, 00h                                             ;Número de página (Solo hay una)
        int 10h

        inc cx
        mov ax, cx                                              ;cx - padizquierdox > padderecho (if(true) avanza fila, else avanza columna)
        sub ax, padDerechoX
        cmp ax, padAncho
        jng DibujarPadDerechoHorizontal                         ;Not greater than

        mov cx, padDerechoX                                     ;cx regresa a la columna inicial
        inc dx                                                  ;avanza fila

        mov ax, dx                                              ;dx - padIzquierdoX  > padIzquierdoY (if(true) sale, else continúa)
        sub ax, padDerechoY
        cmp ax, padAlto
        jng DibujarPadDerechoHorizontal
    ret
DibujarPads ENDP

;----------------------------------------------------------------------------------------------------------

MoverPads PROC NEAR
    ;pad izquierdo movimiento
    ;Checa si no hay una tecla presionada(si no, checar otro pad)
    mov ah, 01h
    int 16h
    jz checarPadDerecho                                         ;ZF = 1, JZ -> jump Zero

    ;checar cual tecla esta presionada(AL = ASCII CARACTER)
    mov ah, 00h
    int 16h

    ;si es 'w' o 'W' movemos arriba
    cmp al, 77h; 'w'
    je moverPadIzquierdoUp
    cmp al, 57h; 'W'
    je moverPadIzquierdoUp

    ;si es 's' o 'S' movemos abajo
    cmp al, 73h; 's'
    je moverPadIzquierdoDown
    cmp al, 53h; 'S'
    je moverPadIzquierdoDown
    jmp checarPadDerecho

    moverPadIzquierdoUp:
        mov ax, padVelocidad
        sub padIzquierdoY, ax

        mov ax, limitePantalla
        cmp padIzquierdoY, ax
        jl  fixPadIzquierdoTopPosition
        jmp checarPadDerecho

        fixPadIzquierdoTopPosition:
            mov ax, limitePantalla
            mov padIzquierdoY, ax
            jmp checarPadDerecho

    moverPadIzquierdoDown:
        mov ax, padVelocidad
        add padIzquierdoY, ax
        mov ax, altoPantalla
        sub ax, limitePantalla
        sub ax, padAlto
        cmp padIzquierdoY, ax
        jg  fixPadIzquierdoBottomPosition
        jmp checarPadDerecho

            fixPadIzquierdoBottomPosition:
                mov padIzquierdoY, ax
                jmp checarPadDerecho

    ;pad derecho movimiento
    checarPadDerecho:
        cmp controladorIA, 01h
        je controladoPorIA

        ;Cuando el pad es controlado por un usuario
        checarTeclas:
            ;si es 'o' u 'O' movemos arriba
            cmp al, 6Fh; 'o'
            je moverPadDerechoUp
            cmp al, 4Fh; 'O'
            je moverPadDerechoUp

            ;si es 'l' o 'L'movemos abajo
            cmp al, 6Ch; 'l'
            je moverPadDerechoDown
            cmp al, 4Ch; 'L'
            je moverPadDerechoDown
            jmp exitPad

        ;Cuando el pad es controlado por IA
        controladoPorIA:
            ;Verificar si la pelota está arriba del pad (pelotaY + tamanoPelota < padDerechoY)
            ;Si lo está se moverá el pad hacia arriba
            mov ax, pelotaY
            add ax, pelotaTamano
            cmp ax, padDerechoY
            jl moverPadDerechoUp

            ;Verificar si la pelota está debajo del pad (pelotaY > padDerechoY + padAlto)
            ;Si lo está se moverá hacia abajo
            mov ax, padDerechoY
            add ax, padAlto
            cmp ax, pelotaY
            jl moverPadDerechoDown

            ;Si no es ninguna, no se moverá
            jmp exitPad

        moverPadDerechoUp:
            mov ax, padVelocidad
            sub padDerechoY, ax

            mov ax, limitePantalla
            cmp padDerechoY, ax
            jl  fixPadDerechoTopPosition
            jmp exitPad

            fixPadDerechoTopPosition:
                mov ax, limitePantalla
                mov padDerechoY, ax
                jmp exitPad

        moverPadDerechoDown:
            mov ax, padVelocidad
            add padDerechoY, ax
            mov ax, altoPantalla
            sub ax, limitePantalla
            sub ax, padAlto
            cmp padDerechoY, ax
            jg  fixPadDerechoBottomPosition
            jmp exitPad

        fixPadDerechoBottomPosition:
            mov padDerechoY, ax
            jmp exitPad

    exitPad:
        ret
MoverPads ENDP

;----------------------------------------------------------------------------------------------------------

DibujarUI PROC NEAR
; dibuja los puntos del jugador izquierdo
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 04h                                                 ;muestra el renglon
    mov dl, 06h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, TextoJugador1                                       ;es como el offset
    int 21h

; dibuja los puntos del jugador derecho
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 04h                                                 ;muestra el renglon
    mov dl, 1Fh                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, TextoJugador2                                       ;es como el offset
    int 21h
ret
DibujarUI ENDP

;----------------------------------------------------------------------------------------------------------

actualizarTextoP1 PROC NEAR
    xor ax, ax
    mov al, player1Points                                       ;cambia el valor del texto del juagdor1

    ;antes de pintar la pantalla, se cambia de decimal a valor ascii
    add al,30h
    mov [textoJugador1], al
ret
actualizarTextoP1 ENDP

;----------------------------------------------------------------------------------------------------------

actualizarTextoP2 PROC NEAR
    xor ax, ax
    mov al, player2Points                                       ;cambia el valor del texto del juagdor1

    ;antes de pintar la pantalla, se cambia de decimal a valor ascii
    add al,30h
    mov [textoJugador2], al
ret
actualizarTextoP2 ENDP

;----------------------------------------------------------------------------------------------------------

dibujarGameOverMenu PROC NEAR
    LimpiarPantalla

    ;muestra el titulo del menu
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 04h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, TextoGameOver                                       ;es como el offset
    int 21h

    ;muestra el ganador
    ;muestra el titulo del menu
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 06h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    call actualizarGameOverGanador

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, TextoWinner                                         ;es como el offset
    int 21h

    ;espera para una tecla
    mov ah, 00h
    int 16h

    ;muestra el mensaje de reiniciar juego
    ;muestra el titulo del menu
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 08h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoReiniciar                                      ;es como el offset
    int 21h

    ;espera para una tecla
    mov ah, 00h
    int 16h

    ;muestra el mensaje de volver al menu
    ;muestra el titulo del menu
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 0Ah                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoMenu                                           ;es como el offset
    int 21h

    ;espera para una tecla
    mov ah, 00h
    int 16h

    ;Si la tecla es 'R' o 'r', reinicia el juego
    cmp al, 'R'
    je reiniciar
    cmp al, 'r'
    je reiniciar
    ;Si la tecla es 'E' o 'e', volver al menú
    cmp al, 'E'
    je salirMenu
    cmp al, 'e'
    je salirMenu
    ret

    reiniciar:
        mov juegoActivo, 01h
        ret

    salirMenu:
        mov juegoActivo, 00h
        mov escenaActual, 00h
    ret
 dibujarGameOverMenu ENDP

;----------------------------------------------------------------------------------------------------------

 dibujarMenu PROC NEAR
    LimpiarPantalla

    ;muestra el titulo del menu
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 04h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoMenuTitulo                                     ;es como el offset
    int 21h

    ;muestra el mensaje de un jugador
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 06h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoMenu1Jugador                                   ;es como el offset
    int 21h

    ;muestra el mensaje de multijugador
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 08h                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoMenuMulti                                      ;es como el offset
    int 21h

    ;muestra el mensaje de salida
    mov ah, 02h                                                 ;coloca la posicion al cursor
    mov bh, 00h                                                 ;coloca la pagina dl numero
    mov dh, 0Ah                                                 ;muestra el renglon
    mov dl, 04h                                                 ;muestra la columna
    int 10h

    mov ah, 09h                                                 ;escribe la cadena a la salida estandar
    lea dx, textoMenuSalir                                      ;es como el offset
    int 21h

    ;espera para una tecla
    mov ah, 00h
    int 16h

    menuEspera:
        ;Verifica qué tecla fue presionada
        cmp al, 'S'
        je iniciar1jugador
        cmp al, 's'
        je iniciar1jugador
        cmp al, 'M'
        je iniciarmulti
        cmp al, 'm'
        je iniciarmulti
        cmp al, 'E'
        je salirJuego
        cmp al, 'e'
        je salirJuego
        jmp menuEspera

    iniciar1jugador:
        mov escenaActual, 01h
        mov juegoActivo, 01h
        mov controladorIA, 01h
        ret

    iniciarmulti:
        mov escenaActual, 01h
        mov juegoActivo, 01h
        mov controladorIA, 00h
        ret

    salirJuego:
        mov cerrarJuego, 01h
        ret
dibujarMenu ENDP

;----------------------------------------------------------------------------------------------------------

actualizarGameOverGanador PROC NEAR
    mov al, indiceWinner                                        ;si el ganador del indice es 1 => al,1
    add al, 30h                                                 ;al, 31h  => al, '1'
    mov [textoWinner+7], al                                     ;actualiza el indice con el texto del caracter
    ret
actualizarGameOverGanador ENDP

;----------------------------------------------------------------------------------------------------------

bienvenida PROC NEAR
        mov ah, 00h
        mov al, 03h
        int 10h      ;LIMPIA LA PANTALLA
        mov bh, 4Fh	  ;COLOR ROJO

        mov ah, 06h
        xor al, al
        xor cx, cx
        mov dx, 184Fh
        int 10h	  ;CAMBIA EL COLOR DE LA PANTALLA

        mov dh, 06h       ;POSICION DEL CURSOR: RENGLON
	    mov dl, 10h	  ;POSICION DEL CURSOR: COLUMNA
        mov bh, 00h
        mov ah, 02h
        int 10h
;--------------------------------------CENTRA EL CURSOR-----------------------
        imprimir marco    ;LLAMADA AL MACRO DE IMPRESION DE CADENA

        mov dh, 09h
	    mov dl, 19h
         mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir programa

        mov dh, 0ch
	    mov dl, 17h
         mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir nombre1

	    mov dh, 0dh
	    mov dl, 17h
         mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir nombre2

	    mov dh, 0eh
	    mov dl, 0Bh
         mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir materia

        mov dh, 0fh
	    mov dl, 1Ah
         mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir profesor

	    mov dh, 10h
	    mov dl, 08h
        mov bh, 00h
        mov ah, 02h
        int 10h
        imprimir desc

        mov dh, 13h       ;POSICION DEL CURSOR: RENGLON
	     mov dl, 10h	  ;POSICION DEL CURSOR: COLUMNA
         mov bh, 00h
         mov ah, 02h
         int 10h
         imprimir marco

        imprimir continuar

        mov ah, 01h
        int 21h

	ret
    bienvenida ENDP
    END inicio