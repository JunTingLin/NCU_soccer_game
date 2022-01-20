;    Assembler specific instructions for 32 bit ASM code

    .486                   ; minimum processor needed for 32 bit    ;指定微處理器模式 .8086、.186、.286、.386、.486
    .model flat, stdcall   ; FLAT memory model & STDCALL calling    ;定義記憶體模式
    option casemap :none   ; set code to case sensitive
    
    include soccer_game.inc

    WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD

    szText MACRO Name, Text:VARARG
    LOCAL lbl
        jmp lbl
            Name db Text,0
        lbl:
    ENDM

.const
    background equ 100
    menu equ 101
    victor_1 equ 103
    victor_2 equ 104
    p1 equ 1001
    p2 equ 1002
    ball_image equ 102
    CREF_TRANSPARENT  EQU 0FF00FFh
  	CREF_TRANSPARENT2 EQU 0FF0000h
    PLAYER_SPEED  EQU  6 ;可以控制左右移動的速度
    JUMP_SPEED EQU 20   ;;可以控制上下移動的速度

.data

    szDisplayName db "NCU Soccer",0     ;DD:Define Double Word，要用DWORD也可
    AppName db "NCU Soccer", 0
    CommandLine   dd 0      ;WinMain函式的參數之一，該參數設null也可
    buffer        db 256 dup(?)

    hBmp          dd    0
    menuBmp       dd    0
    vitoria1Bmp       dd    0
    vitoria2Bmp       dd    0
    p1_spritesheet    dd 0  ;spritesheet載入圖片，灰色方框，資料壓縮
    p2_spritesheet    dd 0
    ballBmp          dd 0
    paintstruct   PAINTSTRUCT <>    ;內有ballObj、sizePoint
    GAMESTATE             BYTE 1
    ultimate_player1 BYTE 0
    
    ;遊戲狀態
        ; 1 - 菜單
        ; 2 - 遊戲
        ; 3 - 玩家 1 勝利畫面
        ; 4 - 玩家 2 勝利畫面

    ; 音樂
    ponte      db "sounds/ponte.mp3",0
    gol      db "sounds/gol.mp3",0

    ; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
		open_dwCallback     dd ?
		open_wDeviceID     dd ?
		open_lpstrDeviceType  dd ?
		open_lpstrElementName  dd ?
		open_lpstrAlias     dd ?

		; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
		generic_dwCallback   dd ?

		; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
		play_dwCallback     dd ?
		play_dwFrom       dd ?
		play_dwTo        dd ?    

;無初始值之資料段與常數資料段
.data?
    hInstance HINSTANCE ?

    hWnd HWND ?
    thread1ID DWORD ?
    thread2ID DWORD ?
    
; _______________________________________________CODE______________________________________________
.code
start:

    invoke GetModuleHandle, NULL ; provides the instance handle
    mov    hInstance, eax

    ;加載BMP圖像 _________________________
    invoke LoadBitmap, hInstance, background    ;args:handle,bitmap resource
    mov    hBmp, eax

    invoke LoadBitmap, hInstance, menu
    mov    menuBmp, eax

    invoke LoadBitmap, hInstance, victor_1
    mov    vitoria1Bmp, eax

    invoke LoadBitmap, hInstance, victor_2
    mov    vitoria2Bmp, eax

    invoke LoadBitmap, hInstance, p1
    mov     p1_spritesheet, eax

    invoke LoadBitmap, hInstance, p2
    mov     p2_spritesheet, eax

    invoke LoadBitmap, hInstance, ball_image
    mov     ballBmp, eax

    ;WinMain 函數是用戶為基於 Microsoft Windows 的應用程序提供的入口點的常規名稱_____________________________________________

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT    
    invoke ExitProcess,eax     

    ; PROCEDURES________________________________

    isStopped proc addrPlayer:dword
        assume edx:ptr player
        mov edx, addrPlayer

        .if [edx].playerObj.speed.x == 0  && [edx].playerObj.speed.y == 0
            mov [edx].stopped, 1
        .endif

        ret
    isStopped endp
; _____________________________________________________________________________________________________
    paintBackground proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        LOCAL rect   :RECT      ;RECT 結構定義了矩形左上角和右下角的坐標。
    

        ; paint background image
        .if(GAMESTATE == 1)
            invoke SelectObject, _hMemDC2, menuBmp  ;SelectObject 函數將一個對象選擇到指定的設備內容 (DC) 中。新對象替換相同類型的先前對象。
        .elseif(GAMESTATE == 2)
            invoke SelectObject, _hMemDC2, hBmp
        .elseif(GAMESTATE == 3)
            invoke SelectObject, _hMemDC2, vitoria1Bmp
        .elseif(GAMESTATE == 4)
            invoke SelectObject, _hMemDC2, vitoria2Bmp
        .endif
        

        invoke BitBlt, _hMemDC, 0, 0, 910, 522, _hMemDC2, 0, 0, SRCCOPY     ;BitBlt 函數執行將與像素矩形相對應的顏色數據從指定的源設備內容到目標設備內容的bit-block傳輸。

        .if(GAMESTATE == 2)
        ; paint score
            ;invoke SetBkMode, _hMemDC, TRANSPARENT
            invoke SetTextColor,_hMemDC,00FF8800h
        
            invoke wsprintf, addr buffer, chr$("%d     x     %d"), player1.goals, player2.goals
            mov   rect.left, 360
            mov   rect.top , 10
            mov   rect.right, 490
            mov   rect.bottom, 50  

            invoke DrawText, _hMemDC, addr buffer, -1, \
                addr rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE
            ;invoke ReleaseDC, hWin, _hMemDC
        .endif

        ret

    paintBackground endp
; _____________________________________________________________________________________________________

; _____________________________________________________________________________________________________

    paintPlayers proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
        ; ____________________________________________________________________________________________________
        ; -----------------------------       PLAYER 1      --------------------------------------------------
        ; ____________________________________________________________________________________________________
        invoke SelectObject, _hMemDC2, p1_spritesheet

        movsx eax, player1.direction
        mov ebx, PLAYER_SIZE
        mul ebx
        mov ecx, eax

        invoke isStopped, addr player1

        mov edx, 0

        mov eax, player1.playerObj.pos.x
        mov ebx, player1.playerObj.pos.y
        sub eax, PLAYER_HALF_SIZE
        sub ebx, PLAYER_HALF_SIZE

        invoke TransparentBlt, _hMemDC, eax, ebx,\  ;去背根據pos放置於視窗
            PLAYER_SIZE, PLAYER_SIZE, _hMemDC2,\
            edx, ecx, PLAYER_SIZE, PLAYER_SIZE, 16777215
            ; 函數執行將與像素矩形相對應的顏色數據從指定的源設備內容到目標設備內容的bit-block傳輸

        ; ____________________________________________________________________________________________________
        ; -----------------------------       PLAYER 2      --------------------------------------------------
        ; ____________________________________________________________________________________________________


        invoke SelectObject, _hMemDC2, p2_spritesheet

        movsx eax, player2.direction
        mov ebx, PLAYER_SIZE
        mul ebx
        mov ecx, eax

        invoke isStopped, addr player2

        mov edx, 0

        mov eax, player2.playerObj.pos.x
        mov ebx, player2.playerObj.pos.y
        sub eax, PLAYER_HALF_SIZE
        sub ebx, PLAYER_HALF_SIZE

        invoke TransparentBlt, _hMemDC, eax, ebx,\
            PLAYER_SIZE, PLAYER_SIZE, _hMemDC2,\
            edx, ecx, PLAYER_SIZE, PLAYER_SIZE, 16777215

        ; ____________________________________________________________________________________________________
        ; ----------------------------------       球     --------------------------------------------------
        ; ____________________________________________________________________________________________________

        invoke SelectObject, _hMemDC2, ballBmp

        movsx eax, player2.direction
        mov ebx, BALL_SIZE
        mul ebx
        mov ecx, eax

        mov edx, 0

        mov eax, ball.ballObj.pos.x
        mov ebx, ball.ballObj.pos.y
        sub eax, BALL_HALF_SIZE
        sub ebx, BALL_HALF_SIZE

        invoke TransparentBlt, _hMemDC, eax, ebx,\
            BALL_SIZE, BALL_SIZE, _hMemDC2,\
            edx, ecx, BALL_SIZE, BALL_SIZE, 16777215

        ret
    paintPlayers endp

; _____________________________________________________________________________________________________

    screenUpdate proc
        LOCAL hMemDC:HDC
        LOCAL hMemDC2:HDC
        LOCAL hBitmap:HDC
        LOCAL hDC:HDC

        invoke BeginPaint, hWnd, ADDR paintstruct   ;BeginPaint函數為繪畫準備指定的窗口，並用有關繪畫的信息填充 PAINTSTRUCT 結構。
        mov hDC, eax
        invoke CreateCompatibleDC, hDC  ;CreateCompatibleDC函數創建與指定設備兼容的內存設備內容 (DC)
        mov hMemDC, eax
        invoke CreateCompatibleDC, hDC ; for double buffering
        mov hMemDC2, eax
        invoke CreateCompatibleBitmap, hDC, 910, 522
        mov hBitmap, eax

        invoke SelectObject, hMemDC, hBitmap

        invoke paintBackground, hDC, hMemDC, hMemDC2
        .if(GAMESTATE == 2)
            invoke paintPlayers, hDC, hMemDC, hMemDC2
        .endif
        invoke BitBlt, hDC, 0, 0, 910, 522, hMemDC, 0, 0, SRCCOPY

        invoke DeleteDC, hMemDC     ;DeleteDC 函數刪除指定的設備內容 (DC)。
        invoke DeleteDC, hMemDC2
        invoke DeleteObject, hBitmap
        invoke EndPaint, hWnd, ADDR paintstruct ;EndPaint 函數標記指定窗口中的繪製結束。每次調用 BeginPaint 函數時都需要此函數，但僅在繪製完成後才需要
        ret
    screenUpdate endp

; _____________________________________________________________________________________________________

    paintThread proc p:DWORD
        .WHILE GAMESTATE != 5
            invoke Sleep, 17 ; 60 FPS
            invoke InvalidateRect, hWnd, NULL, FALSE ;InvalidateRect函數將一個橢圓添加到指定窗口的更新區域。更新區域代表了必須重新繪製的窗口區域的部分。
        .endw
        ret
    paintThread endp   

; _____________________________________________________________________________________________________

    changePlayerSpeed proc uses eax addrPlayer : DWORD, direction : BYTE, keydown : BYTE
        assume eax: ptr player
        mov eax, addrPlayer

        .if keydown == FALSE
            .if direction == 1 ;a
                .if [eax].playerObj.speed.x > 7fh
                    mov [eax].playerObj.speed.x, 0 
                .endif
            .elseif direction == 3 ;d
                .if [eax].playerObj.speed.x < 80h
                    mov [eax].playerObj.speed.x, 0 
                .endif
            .endif
        .else
            .if direction == 0 ; w
                .if [eax].jumping == 0  ;如果玩家沒有跳躍
                    mov [eax].jumping, 1
                    mov [eax].playerObj.speed.y, -JUMP_SPEED ;我們將玩家速度設置為跳躍
                    mov [eax].stopped, 0                      
                .endif
            .elseif direction == 2 ; a
                mov [eax].playerObj.speed.x, -PLAYER_SPEED
                mov [eax].stopped, 0
            .elseif direction == 3 ; d
                mov [eax].playerObj.speed.x, PLAYER_SPEED
                mov [eax].stopped, 0
            .endif
        .endif

        assume ecx: nothing
        ret
    changePlayerSpeed endp

; _____________________________________________________________________________________________________

    movePlayer proc uses eax addrPlayer:dword
        assume edx:ptr player
        mov edx, addrPlayer

        assume ecx:ptr gameObject
        mov ecx, addrPlayer



        .if [edx].jumping == TRUE  ;如果玩家在跳躍(減速)
            mov ebx, [ecx].speed.y
            inc ebx
            mov [ecx].speed.y, ebx
        .endif



        ; X AXIS ______________
        mov eax, [ecx].pos.x
        mov ebx, [ecx].speed.x
        add eax, ebx
        

        ;  如果玩家在屏幕範圍內，我們才改變它的位置
        .if eax > 0 && eax < 890
            mov [ecx].pos.x, eax
        .endif

        ; Y AXIS ______________
        mov eax, [ecx].pos.y
        mov ebx, [ecx].speed.y
        add ax, bx

        ; 如果玩家向上跳，它會“下降”到地面
        .if eax >= 420
            mov [edx].jumping, FALSE ;我們警告你他不能再跳躍
            mov eax, 420         ;我們把他放在地上
        .endif

        mov [ecx].pos.y, eax

        assume ecx:nothing
        ret
    movePlayer endp

; _____________________________________________________________________________________________________

    moveBall proc uses eax addrBall:dword
        assume ebx:ptr ballStruct
        mov ebx, addrBall

        ; Y AXIS ______________

        .if [ebx].ballObj.pos.y < 443       ;如果球在空中，我們拉它（重力）
            mov ecx, [ebx].ballObj.speed.y
            inc ecx
            mov [ebx].ballObj.speed.y, ecx
        .endif

        .if [ebx].ballObj.pos.y >= 443                      ; 如果球碰到地面，讓我們讓它反彈    
            ;mov edx, 0
            ;mov eax, [ebx].ballObj.speed.y
            ;mov ecx, 2
            ;div ecx
            ;neg eax

            mov eax, [ebx].ballObj.speed.y              ;我們反轉球的速度
            dec eax                                     ; 使它上升
            dec eax
            dec eax
            neg eax

            mov [ebx].ballObj.speed.y, eax     
        .endif

    
        ;我們增加速度 y;eax 上的速度增量
        mov eax, [ebx].ballObj.pos.y
        mov ecx, [ebx].ballObj.speed.y
        add ax, cx

        .if eax > 443
            mov eax, 443
        .endif

        ; X AXIS ______________
        mov edx, [ebx].ballObj.pos.x
        mov ecx, [ebx].ballObj.speed.x
        add dx, cx

        ;如果球在屏幕邊緣，我們移動它
        .if edx > 10 && edx < 885       ;正常範圍
            mov [ebx].ballObj.pos.x, edx
        .else                               ;如果球撞到牆，我們就擊中它     ;屏幕邊緣
            mov ecx, ball.ballObj.speed.x
            dec ecx
            dec ecx
            neg ecx
            mov [ebx].ballObj.speed.x, ecx 
        .endif

        mov [ebx].ballObj.pos.y, eax        ; 我們移動 y
        
        assume ecx:nothing
        ret 
    moveBall endp

; _____________________________________________________________________________________________________

    collide proc obj1Pos:point, obj2Pos:point, obj1Size:point, obj2Size:point
        
        mov eax, obj1Pos.x
        add eax, obj1Size.x                    ; pos1 + 大小
        ;eax:玩家的右邊界
        mov ebx, obj2Pos.x
        sub ebx, obj2Size.x                    ; pos2 - 大小
        ;ebx:球的左邊界
        .if eax > ebx
            mov eax, obj1Pos.x
            sub eax, obj1Size.x                    ; pos1 - 大小

            mov ebx, obj2Pos.x
            add ebx, obj2Size.x                    ; pos2 + 大小
            .if eax < ebx
                mov edx, TRUE
            .else
                mov edx, FALSE
            .endif
        .else
            mov edx, FALSE
        .endif

        mov eax, obj1Pos.y
        add eax, obj1Size.y                    ; pos1 + 大小
        ;eax:玩家的下邊界
        mov ebx, obj2Pos.y
        sub ebx, obj2Size.y                    ; pos2 - 大小
        ;ebx:球的上邊界
        .if eax > ebx
            mov eax, obj1Pos.y
            sub eax, obj1Size.y                    ; pos1 - 大小

            mov ebx, obj2Pos.y
            add ebx, obj2Size.y                    ; pos2 + 大小
            .if eax < ebx
                mov ecx, TRUE
            .else
                mov ecx, FALSE
            .endif
        .else
            mov ecx, FALSE
        .endif

        pop ebx
        pop eax

        ret
    collide endp



; _____________________________________________________________________________________________________

    ballColliding proc
    
        invoke collide, player1.playerObj.pos, ball.ballObj.pos, player1.sizePoint, ball.sizePoint
        .if edx == TRUE  && ecx == TRUE                      ; 相撞
            mov eax, player1.playerObj.speed.x

            .if eax == 0                                    ; 如果玩家是靜止的
                mov eax, ball.ballObj.speed.x               ; 只是被球擊中->對方速度的反向射回去
                .if ultimate_player1 == 1
                    add eax, 50
                    mov ultimate_player1, 0
                .endif
                dec eax
                dec eax
                neg eax
            .else                                           ; 如果玩家在移動
                add eax, player1.playerObj.speed.x          ; 我們根據你的速度踢(根據玩家x的水平速度)
                .if ultimate_player1 == 1
                    add eax, 50
                    mov ultimate_player1, 0
                .endif
                dec eax
                dec eax
                dec eax

            .endif

            mov ball.ballObj.speed.y, -20
            mov ball.ballObj.speed.x, eax       
        .endif

        invoke collide, player2.playerObj.pos, ball.ballObj.pos, player2.sizePoint, ball.sizePoint
        .if edx == TRUE  && ecx == TRUE                      ; 相撞 
            mov eax, player2.playerObj.speed.x

            .if eax == 0
                mov eax, ball.ballObj.speed.x
                dec eax
                dec eax
                neg eax
            .else
                add eax, player2.playerObj.speed.x
                dec eax
                dec eax
                dec eax

            .endif

            mov ball.ballObj.speed.y, -15
            mov ball.ballObj.speed.x, eax          
        .endif     

        ret
    ballColliding endp

; _____________________________________________________________________________________________________

    resetBall proc
        mov ball.ballObj.speed.x, 0
        mov ball.ballObj.speed.y, 0
        mov ball.ballObj.pos.x, 420
        mov ball.ballObj.pos.y, 100
        ret
    resetBall endp

; _____________________________________________________________________________________________________

    resetPositions proc
        mov player1.playerObj.pos.x, 100
        mov player1.playerObj.pos.y, 420

        mov player2.playerObj.pos.x, 780
        mov player2.playerObj.pos.y, 420

        invoke resetBall

        ret
    resetPositions endp
; _____________________________________________________________________________________________________

    verifyGoal proc uses eax addrBall:dword
        assume ebx:ptr ballStruct
        mov ebx, addrBall
        
        mov eax, [ebx].ballObj.pos.x   ; 我們保存球的位置
        mov ecx, [ebx].ballObj.pos.y 

        mov edx, 0
        .if eax > gol2.top.x && ecx > gol2.top.y    ; 右邊的守門點
            add player1.goals, 1
            invoke resetPositions
            mov edx, 1
        .elseif eax < gol1.top.x && ecx > gol1.top.y ; 左邊的守門點
            add player2.goals, 1
            invoke resetPositions
            mov edx, 1
        .endif
        
        .if edx == 1
             ; 音樂
            mov   open_lpstrDeviceType, 0h         ; fill MCI_OPEN_PARMS structure
            mov   open_lpstrElementName,OFFSET gol
            invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
            ; cmp   edx,0h                 	
            ; je    next		
            ; next:	
                invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback	
        .endif

        assume ecx:nothing
        ret 
    verifyGoal endp

; _____________________________________________________________________________________________________

    gameManager proc p:dword
        LOCAL area:RECT

        game:
            .while GAMESTATE == 2
                invoke Sleep, 30               
                invoke movePlayer, addr player1
                invoke movePlayer, addr player2
                invoke ballColliding
                invoke moveBall, addr ball
                invoke verifyGoal, addr ball

                .if (player1.goals == MAX_GOALS)
                    mov GAMESTATE, 3
                .elseif (player2.goals == MAX_GOALS)
                    mov GAMESTATE, 4
                .endif
            .endw

        jmp game

        ret
    gameManager endp
        
    ;______________________________________________________________________________

    ; 把 WinMain 程序放在這裡來創建窗口本身

    WinMain proc hInst     :DWORD,
                hPrevInst :DWORD,
                CmdLine   :DWORD,
                CmdShow   :DWORD

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG     ;MSG結構包含來自Thread的消息隊列的信息

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Windowclass1"
        
        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                            or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc       ;本視窗的訊息處裡函式
        mov wc.cbClsExtra,     NULL                 ;附加引數
        mov wc.cbWndExtra,     NULL                 ;附加引數
        m2m wc.hInstance,      hInst                ;當前應用程式的例向控制代碼
        mov wc.hbrBackground,  COLOR_BTNFACE+1      ;視窗背景色
        mov wc.lpszMenuName,   NULL                 ;視窗選單
        mov wc.lpszClassName,  offset szClassName   ;視窗結構體的名稱 ;給視窗結構體命名，CreateWindow函式將根據視窗結構體名稱來建立視窗
        ; RC 文件中的圖標 ID
        invoke LoadIcon,hInst, IDI_APPLICATION      ;視窗圖式
        mov wc.hIcon,          eax
        invoke LoadCursor,NULL,IDC_ARROW            ;視窗游標
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc             ;註冊視窗


        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW, \
                            ADDR szClassName, \
                            ADDR szDisplayName,\
                            WS_OVERLAPPEDWINDOW,\
                            ;Wtx,Wty,Wwd,Wht,
                            CW_USEDEFAULT,CW_USEDEFAULT, 910, 552, \      ;窗口大小
                            NULL,NULL,\
                            hInst,NULL


        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

        ;===================================
        ; Loop until PostQuitMessage is sent
        ;===================================

        StartLoop:
        invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
        cmp eax, 0                                  ; exit if GetMessage()
        je ExitLoop                                 ; returns zero
        invoke TranslateMessage, ADDR msg           ; translate it
        invoke DispatchMessage,  ADDR msg           ; send it to message proc
        jmp StartLoop
        ExitLoop:

        return msg.wParam   ;wParam:指定有關消息的附加信息。確切含義取決於消息成員的值

    WinMain endp

    WndProc proc hWin  :DWORD,
                uMsg   :DWORD,
                wParam :DWORD,
                lParam :DWORD

        LOCAL hDC    :DWORD
        LOCAL memDC  :DWORD
        LOCAL memDCp1 : DWORD
        LOCAL hOld   :DWORD
        LOCAL hWin2  :DWORD
        LOCAL direction : BYTE
        LOCAL keydown   : BYTE
        mov direction, -1
        mov keydown, -1

    
        ; 當它創建
        .if uMsg == WM_CREATE  ;當應用程序通過調用 CreateWindowEx 或 CreateWindow 函數請求創建窗口時，將發送 WM_CREATE 消息
            mov eax, offset gameManager 
            invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1ID 
            invoke CloseHandle, eax 

            mov eax, offset paintThread 
            invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2ID 
            invoke CloseHandle, eax 

            ; 音樂
            mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
            mov   open_lpstrElementName,OFFSET ponte
            invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
            cmp   eax,0h                 	
            je    next		
            next:	
                invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback			

        .elseif uMsg == WM_PAINT    ;當系統或其他應用程序請求繪製應用程序窗口的一部分時，會發送 WM_PAINT 消息
            invoke screenUpdate

        .elseif uMsg == WM_DESTROY                                        ; if the user closes our window 
            invoke PostQuitMessage,NULL                                   ; quit our application 

        ; game manager
        .elseif uMsg == WM_CHAR
            .if (wParam == 13) ; [ENTER]
                .if GAMESTATE == 1
                    mov GAMESTATE, 2
                .elseif GAMESTATE == 2
                    mov GAMESTATE, 1
                .elseif GAMESTATE == 3 || GAMESTATE == 4
                    invoke resetPositions
                    invoke resetBall
                    mov player1.goals, 0
                    mov player2.goals, 0
                    mov GAMESTATE, 2
                .endif                
            .endif

        ; 當釋放非系統鍵時
        .elseif uMsg == WM_KEYUP

            ; ____________________________________________________________________________________________________
            ; -----------------------------       PLAYER 1         -----------------------------------------------
            ; ____________________________________________________________________________________________________
            .if ( wParam == 57h || wParam == 20h) ;W/space
                mov keydown, FALSE
                mov direction, 0                

            .elseif (wParam == 41h) ;A
                mov keydown, FALSE
                mov direction, 1

            .elseif (wParam == 44h) ;D
                mov keydown, FALSE
                mov direction, 3

            .elseif (wParam == 45h) ;E
                mov ultimate_player1, 1

            .endif


            .if direction != -1
                invoke changePlayerSpeed, ADDR player1, direction, keydown
                mov direction, -1
                mov keydown, -1
            .endif


            ; ____________________________________________________________________________________________________
            ; -----------------------------       PLAYER 2         -----------------------------------------------
            ; ____________________________________________________________________________________________________

            .if (wParam == VK_UP) ;上
                mov keydown, FALSE
                mov direction, 0                

            .elseif (wParam == VK_LEFT) ;左
                mov keydown, FALSE
                mov direction, 1

            .elseif (wParam == VK_RIGHT) ;右
                mov keydown, FALSE
                mov direction, 3
            .endif

            .if direction != -1
                invoke changePlayerSpeed, ADDR player2, direction, keydown
                mov direction, -1
                mov keydown, -1
            .endif            
           
        ;當按下非系統鍵時
        .elseif uMsg == WM_KEYDOWN
            ; ____________________________________________________________________________________________________
            ; -----------------------------       PLAYER 1         -----------------------------------------------
            ; ____________________________________________________________________________________________________

            .if (wParam == 57h || wParam == 20h) ; W/space
                mov keydown, TRUE
                mov direction, 0

            .elseif (wParam == 41h) ; A
                mov keydown, TRUE
                mov direction, 2

            .elseif (wParam == 44h) ; D
                mov keydown, TRUE
                mov direction, 3

            .elseif (wParam == 51h) ;Q:可以讓球再次彈起
                mov ball.ballObj.speed.x, 0
                mov ball.ballObj.speed.y, 0
                mov ball.ballObj.pos.x, 420
                mov ball.ballObj.pos.y, 100

            .elseif (wParam == 45h) ;E
                mov ultimate_player1, 1

            .endif

            

            .if direction != -1
                invoke changePlayerSpeed, ADDR player1, direction, keydown
                mov direction, -1
                mov keydown, -1
            .endif



            ; ____________________________________________________________________________________________________
            ; -----------------------------       PLAYER 2         -----------------------------------------------
            ; ____________________________________________________________________________________________________


            .if (wParam == VK_UP) ; 上
                mov keydown, TRUE
                mov direction, 0

            .elseif (wParam == VK_LEFT) ; 左
                mov keydown, TRUE
                mov direction, 2

            .elseif (wParam == VK_RIGHT) ; 右
                mov keydown, TRUE
                mov direction, 3
            .endif

            .if direction != -1
                invoke changePlayerSpeed, ADDR player2, direction, keydown
                mov direction, -1
                mov keydown, -1
            .endif

        .else
            invoke DefWindowProc,hWin,uMsg,wParam,lParam ;DefWindowProc 函數調用默認窗口過程來為應用程序不處理的任何窗口消息提供默認處理
        .endif
        ret

    WndProc endp

end start