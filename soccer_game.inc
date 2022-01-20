include C:\masm32\include\masm32rt.inc

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\Masm32\Lib\msimg32.lib
includelib C:\Masm32\lib\winmm.lib
includelib C:\Masm32\Lib\masm32.lib

include C:\Masm32\include\winmm.inc 
include C:\Masm32\Include\msimg32.inc



point struct 
    x dd 0      
    y dd 0
point ends

gameObject struct
    pos      point <>
    speed    point <> ; 水平和垂直速度
gameObject ends

player struct
    playerObj             gameObject <>
    sizePoint             point <>
    stopped               BYTE 0
    jumping               BYTE 0
    direction             BYTE 0
    goals                 dd   0
player ends

ballStruct struct
    ballObj               gameObject <>
    sizePoint             point <>
ballStruct ends

golStruct struct
    top point <>
;    bottom point <>
golStruct ends


.const
    PLAYER_SIZE      EQU 85
    PLAYER_HALF_SIZE EQU PLAYER_SIZE / 2

    BALL_SIZE      EQU 45
    BALL_HALF_SIZE EQU BALL_SIZE / 2


    ;BALL_SPEED_Y EQU -17

    D_RIGHT       EQU 0 
    D_TOP         EQU 1  
    D_LEFT        EQU 2     
    D_DOWN        EQU 3
    D_DOWN_RIGHT  EQU 4
    D_DOWN_LEFT   EQU 5
    D_TOP_LEFT    EQU 6
    D_TOP_RIGHT   EQU 7
    MAX_GOALS EQU 3
.data
    player1 player <<<100,420>,  <0,0>>, <PLAYER_HALF_SIZE, PLAYER_HALF_SIZE>, 0, D_RIGHT, 0 >
    player2 player <<<780,420>,  <0,0>>, <PLAYER_HALF_SIZE, PLAYER_HALF_SIZE>, 0, D_LEFT, 0 >
    ball ballStruct <<<420,100>,  <0,0>>>
    gol1 golStruct <<30, 240>>
    gol2 golStruct <<850, 240>>
    auxiliar_point point <0, 0>
    