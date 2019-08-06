#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

temp_ref     db  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,21,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,87,89,90,91,92,93,94,95,96,97,98,99,100
            
ADC_out      db  00h,02h,05h,08h,0ah,0dh,0fh,12h,14h,17h,1ah,1ch,1fh,21h,24h,26h,29h,2bh,2eh,30h,33h,36h,38h,3bh,3dh,40h,42h,45h,47h,4ah,4dh,4fh,52h,54h,57h,59h,5ch,5eh,61h,63h,66h,69h,6bh,6eh,70h,73h,75h,78h,7ah,7dh,7fh,82h,85h,87h,8ah,8ch,8fh,91h,94h,96h,99h,9ch,9eh,0a1h,0a3h,0a6h,0a8h,0abh,0adh,0b0h,0b2h,0b5h,0b8h,0bah,0bdh,0bfh,0c2h,0c4h,0c7h,0c9h,0cch,0cfh,0d1h,0d4h,0d6h,0d9h,0dbh,0deh,0e0h,0e3h,0e5h,0e8h,0ebh,0edh,0f0h,0f2h,0f5h,0f7h,0fah,0fch,0ffh
            
temp_t      db  ?                            ;current temperature
temp_h      db  ?                            ;current humidity
cmp_t       db  ?                            ;voltage for current temperature
neg_flag    db  00h                          ;check sign of temperature
origin      db  50                           ;voltage for 0 degree temperature

jmp     strt 
         db     1024 dup(0)


	strt:      cli 
		
	;intialize ds, es,ss to start of RAM
          mov       ax,0000h
          mov       ds,ax
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH
	
    ; initializing 8255
	sti	  	
	
	
	mov al,88h	; control word for 8255(for LCD)
	out 06h,al
	
	mov al,89h  ; control word for 8255(for ADC)
	out 0Eh,al    
	

	mov al,00h 	;default low output for PC0  
	out 0ch,al                                      
	
	
	
	 ;initializing LCD
	
	call dly_minor 
	mov al,04h      
	out 02h,al
	call dly_minor
	
	mov al,04h      ; to make rs=0 and r/w=0
	out 02h,al
	
	mov al,38h      ;function set
	out 00h,al
	
	mov al,04h      
	out 02h,al
	call dly_minor
	mov al,00h      ;to make rs=0 and r/w=0
	out 02h,al
	call dly_minor
	mov al,0Ch      ; display on
	out 00h,al
	mov al,04h
	out 02h,al
	call dly_minor
	mov al,00h     
	out 02h,al
	
	mov al,06h      ; set entry mode
	out 00h,al
	call dly_minor
	mov al,04h
	out 02h,al
	call dly_minor
	mov al,00h      
	out 02h,al
	mov al,4ch
	out 00h,al  
	call dly_minor  
	
	
	
		
start:	call    idle
        call    clear_LCD	
	    call    hello_world
	    call    dly_std


seq:  call    getHmd
        call    getTemp 
        call    clear_LCD
        call    dly_std
        call    display_lcd
        mov     al,cmp_t
        mov     bl,temp_h
        cmp     al,bl
        ja      inc_hum
        jb      dec_hum
        call    idle
        jmp     repeat
        
inc_hum:    call    inc_hmd
            jmp     repeat
            
dec_hum:    call    dec_hmd
            jmp     repeat
            
repeat:    call    dly_major
            jmp     seq
       




       	
dly_minor proc	near

	    mov    	cl,30
	aa:
		dec 	cl
		jnz 	aa
	ret
dly_minor endp


dly_major proc	near
	
	mov	cx,0ffffh
	bb:	
		dec 	cx
		jnz 	bb
	ret
dly_major endp 



dly_std proc	near
	
	mov	cx,5555h
	st:	
		dec 	cx
		jnz 	st
	ret
dly_std endp 



                                        
getTemp    PROC    NEAR                 ;get temperature through ADC
       
        
        mov     al,00h
        out     0eh,al    ; PC0=0
                       
        call    dly_major
       
        mov     al,82h
        out     0eh,al
        in      AL,0AH
        lea     si,ADC_out
        lea     di,temp_ref
        dec     si
        
cc:     inc     si
        
        cmp     al,[si]
        jnz     cc
        sub     si,offset ADC_out        
        add     di,si
       
        mov     al,[di]
        mov     cmp_t,al
        
        cmp     [di],50
        jge     pos 
        mov     neg_flag,01h       ;for negative temperature
        mov     al,[di]
        mov     origin,50
        sub     origin,al
        mov     al,origin
        mov     temp_t,al
        jmp     con
                
pos:    mov     neg_flag,00h       ;for positive temperature
        mov     al,[di]
        sub     al,50
        mov     temp_t,al
        
        
con:    call    CONVBCD
        ret
        
getTemp    ENDP


getHmd     PROC    NEAR                    ;get humidity through ADC
       
        mov     al,01h
        out     0eh,al    ; PC0=1
        
        call    dly_major
      
        mov     al,82h
        out     0eh,al
        in      al,0aH
       
        lea     si,ADC_out
        lea     di,temp_ref
        dec     si
        
dd:     inc     si
        
        mov     bl,[si]
        cmp     al,bl
        jnz     dd
        sub     si,offset ADC_out        
        add     di,si
        mov     al,[di]
        mov     temp_h,al
     
        call    CONVBCD
        mov     dx,bx
        ret
        
getHmd     ENDP   

;increase humidity
inc_hmd   proc    near  
    
                mov     al,0eh
                out     0eh,al    ;reset decrease humidity signal 
                
                mov     al,0dh
                out     0eh,al    ;set increase humidity signal
                
                ret
inc_hmd   endp

;decrease humidity
dec_hmd   proc    near  
    
                mov     al,0ch
                out     0eh,al    ;reset increase humidity signal
                
                mov     al,0fh
                out     0eh,al    ;set decrease humidity signal
                
                ret
dec_hmd   endp

;idle humidifier when temperature and humidity are equal
idle       proc    near  
    
                mov     al,0eh
                out     0eh,al    
                
                mov     al,0ch
                out     0eh,al    
                
                ret
idle       endp


clear_LCD proc	near
	mov al,00h
	out 02h,al
	call dly_minor
	mov al,01h			;Clear LCD display
	out 00h,al
	call dly_minor
	mov al,04h
	out 02h,al
	call dly_minor
	mov al,00h
	out 02h,al  
RET
clear_LCD endp


hello_world proc	near
	
	mov al,0A0h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints Space 
	
	mov al,0A0h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints Space
	
	mov al,0A0h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints Space
	
	mov al,48h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints H
	
	mov al,65h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints e
	
	mov al,6ch
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints l
		
	mov al,6ch
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints l
	
	mov al,6fh
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints o
	                	         
	mov al,0A0h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints Space         
	                 
	mov al,57h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints W
	
	mov al,6fh
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints o  
	
	mov al,72h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints r
	
	mov al,6ch
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints l
	
	mov al,64h
	out 00h,al
	call dly_minor
	mov al,05h
	out 02h,al
	call dly_minor
	mov al,01h
	out 02h,al  ;prints d

ret
hello_world endp


display_lcd   PROC    NEAR   ;Display temperature and humidity on LCD
        
	    
	
    	
    	mov al,54h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'T'
    	
    	mov al,65h 
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'e'
    	
    	mov al,6dh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'm'
    	
    	mov al,70h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'p'
    	
    	mov al,65h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'e'
    	
    	mov al,72h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'r'
    	
    	mov al,61h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'a'
    	
    	mov al,74h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 't'
    	
    	
    	mov al,75h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'u'
    	
    	mov al,72h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'r'
    	
    	mov al,65h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'e'

    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
    	
    	cmp neg_flag,00h
    	jz  hh
    	
    	mov al,2dh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints '-'
    	jmp nn
    	
    	
hh:     mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	

nn:    	mov al,bh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints number stored in bh
    	
    	mov al,bl
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints number store in bl
    	
    	mov al,0DFh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'DEG'
    	
    	mov al,43h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'C'
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
        mov al,0c0h
    	out 00h,al
    	mov al,04h
    	out 02h,al
    	call dly_minor
    	mov al,00h
    	out 02h,al
   	    call dly_minor     
        
        
    	mov al,48h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'H'
    	
    	mov al,75h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'u'
    	
    	mov al,6dh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'm'
    	
    	mov al,69h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'i'
    	
    	mov al,64h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'd'
    	
    	mov al,69h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'i'
    	
    	mov al,74h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 't'
    	
    	mov al,79h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints 'y'
    	
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
    	
    	mov al,0A0h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints Space	
    	
    	mov al,dh
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints character in dh
    	
    	mov al,dl
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints character in dl
    	
    	mov al,25h
    	out 00h,al
    	call dly_minor
    	mov al,05h
    	out 02h,al
    	call dly_minor
    	mov al,01h
    	out 02h,al  ;prints '%'
    	ret
display_lcd    endp
	


CONVBCD PROC 	NEAR                    ;convert binary to bcd
        mov     bh,0ffH

BACK1:  INC     BH
        SUB     AL,0AH
        JNC     BACK1
        ADD     AL,0AH
        MOV     BL,30H
        ADD     BH,BL
        ADD     BL,AL
        RET
CONVBCD ENDP