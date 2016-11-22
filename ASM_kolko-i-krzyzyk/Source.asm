.686
.model flat

extern _ExitProcess@4 : PROC
extern __write : PROC
extern __read : PROC

public _main

.data
	tekst_prosba_o_input			db 10, 'Prosze podac wolne pole z przedzialu 1 - 9 ( jak na Num Lock-u ) i zatwierdzic enterem',10
	tekst_prosba_o_input_koniec		db ?
	tekst_niepoprawny_input			db 10, 'Niepoprawny input'
	tekst_niepoprawny_input_koniec	db ?
	tekst_koniec_gry				db 10, 'Nacisnij enter, aby rozpoczac nowa gre...'
	tekst_koniec_gry_koniec			db ?
	tekst_wygrana		db  10, 'GRATULACJE, WYGRAL GRACZ:  ',10
	tekst_wygrana_koniec db ?
	tekst_akt_tura		db	10, 'Aktualna tura gracza:   ',10,10
	tekst_separator		db	'-+-+-',10
	tekst_roboczy		db	'X|X|X',10
	dlugosc_linijki		db	6
	dlugosc_akt_tura	db	27
	bufor_na_input		db	32 dup (?)
	;-------------------------------------------------------------------
	pola db 9 dup (' ')	;tu przechowywane bêd¹ stany pól				; 
						;indeksowane od lewej do prawej z gory na dol	;
						;012											;
						;345											;
						;678											;
						;' ', 'o', 'x'					;
						;------------------------------					;
	tura db 'o'			;znacznik czyja jest obecnie tura				;
						; 'o', 'x'						;
	;-------------------------------------------------------------------
.code

zresetuj_gre PROC
pusha

mov ecx, 9
zg_resetuj_pola:
	mov eax, OFFSET pola
	add eax, ecx
	dec eax
	mov [eax], byte PTR ' '

	loop zg_resetuj_pola

popa
ret
zresetuj_gre ENDP
sprawdz_wygrana PROC
pusha 
;wygrana w al

sw_012:
	mov al, pola+0
	cmp al, ' '
	je sw_345
	mov ah, pola+1
	cmp al, ah
	jne sw_345
	mov ah, pola+2
	cmp al, ah
	je sw_wygrana

sw_345:
	mov al, pola+3
	cmp al, ' '
	je sw_678
	mov ah, pola+4
	cmp al, ah
	jne sw_678
	mov ah, pola+5
	cmp al, ah
	je sw_wygrana

sw_678:
	mov al, pola+6
	cmp al, ' '
	je sw_036
	mov ah, pola+7
	cmp al, ah
	jne sw_036
	mov ah, pola+8
	cmp al, ah
	je sw_wygrana

sw_036:
	mov al, pola+0
	cmp al, ' '
	je sw_147
	mov ah, pola+3
	cmp al, ah
	jne sw_147
	mov ah, pola+6
	cmp al, ah
	je sw_wygrana

sw_147:
	mov al, pola+1
	cmp al, ' '
	je sw_258
	mov ah, pola+4
	cmp al, ah
	jne sw_258
	mov ah, pola+7
	cmp al, ah
	je sw_wygrana

sw_258:
	mov al, pola+2
	cmp al, ' '
	je sw_048
	mov ah, pola+5
	cmp al, ah
	jne sw_048
	mov ah, pola+8
	cmp al, ah
	je sw_wygrana

sw_048:
	mov al, pola+0
	cmp al, ' '
	je sw_246
	mov ah, pola+4
	cmp al, ah
	jne sw_246
	mov ah, pola+8
	cmp al, ah
	je sw_wygrana

sw_246:
	mov al, pola+2
	cmp al, ' '
	je sw_koniec
	mov ah, pola+4
	cmp al, ah
	jne sw_koniec
	mov ah, pola+6
	cmp al, ah
	je sw_wygrana
	jmp sw_koniec
	

sw_wygrana:

	call wyswietl_stan_gry
	mov ebx, (OFFSET tekst_wygrana_koniec) - (OFFSET tekst_wygrana)
	push ebx
	mov ebx, OFFSET tekst_wygrana_koniec
	dec ebx
	mov [ebx], byte PTR al
	push OFFSET tekst_wygrana
	push 1
	call __write
	add esp,12

	mov ebx, (OFFSET tekst_koniec_gry_koniec) - (OFFSET tekst_koniec_gry)
	push ebx
	push OFFSET tekst_koniec_gry
	push 1 
	call __write
	add esp, 12
	push 4
	push OFFSET bufor_na_input
	push 0
	call __read
	add esp,12

	call zresetuj_gre

sw_koniec:
popa
ret
sprawdz_wygrana ENDP

mapuj_EAX PROC
				;pamiêæ | klawiatura
				;0 1 2	| 7 8 9	
				;3 4 5	| 4 5 6
				;6 7 8	| 1 2 3
	cmp eax, 3
	jbe mE_123
	cmp eax, 6
	jbe me_456

	mE_789:
		sub eax, 7
		jmp mE_koniec
	mE_123:
		add eax, 5
		jmp mE_koniec
	me_456:
		dec eax

	mE_koniec:	
	ret
mapuj_EAX ENDP



wczytaj_input PROC
pusha
wi_poczatek:

;---wyswietlenie komunikatu prosby o input
mov eax, (OFFSET tekst_prosba_o_input_koniec) - (tekst_prosba_o_input)
push  eax
push OFFSET tekst_prosba_o_input
push 1
call __write
add esp, 12

;---pobierz input
push 32						; chcemy tylko jeden bajt
push OFFSET bufor_na_input	; miejsce na wczytany bajt
push 0						; klawiatura
call __read
add esp, 12					; usuniecie 3 arg ze stosu

;---sprawdz poprawnosc
	xor eax, eax
mov al, bufor_na_input		; przeslanie wczytanego bajtu do al
				; odjêcie kodu znaku 0
cmp al, 39H					; chcê akceptowaæ tylko cyfry od 0 do 8
jg wi_niepoprawny_input		; wiêc jeœli wiêksze, do skok do obs³ugi 
cmp al, 31H
jb wi_niepoprawny_input
	sub al, 30H	
	

	call mapuj_EAX ; zmapowanie inputu na pamiec komputera

	xor ebx, ebx
	mov bl, al
	
	push eax
	
	call wez_stan_pola_do_al
	add esp,4
	cmp al, ' ' ; czy pole jest puste
	jne wi_niepoprawny_input

	call wez_ture_do_al
	;w al mamy obecnego gracza, w bl indeks wybranego pola
	mov ecx, dword PTR OFFSET pola
	add ecx,  ebx
	cmp al, 'o'
	jne wi_krzyzyk
	mov [ecx], byte ptr 'o'
	jmp wi_koniec
	wi_krzyzyk:
	mov [ecx], byte ptr 'x'



jmp wi_koniec				; zakoñcz procedurê

wi_niepoprawny_input:
	;---wyswietlenie komunikatu o niepoprawnym inpucie
	mov eax, (OFFSET tekst_niepoprawny_input_koniec) - (tekst_niepoprawny_input)
	push  eax
	push OFFSET tekst_niepoprawny_input
	push 1
	call __write
	add esp, 12

	jmp wi_poczatek			; jesli niepoprawny, to wczytaj sprobuj wczytac jeszcze raz

wi_koniec:
popa
ret
wczytaj_input ENDP


wez_ture_do_al PROC
	push 9
	call wez_stan_pola_do_al
	add esp, 4

ret
wez_ture_do_al ENDP

zmien_ture PROC
pusha
	mov al, tura
	cmp al, 'o'	; jesli tak, to jest tura gracza 1
	jne zt_tura_gracza_2
	mov al, 'x'		;
	jmp zt_koniec
	zt_tura_gracza_2:
		mov al, 'o' ;
	zt_koniec:
	mov ebx, dword PTR OFFSET tura
	mov [ebx], byte PTR al
popa
ret
zmien_ture ENDP


wypisz_separator PROC
pusha
	xor eax, eax
	mov al,  dlugosc_linijki
	push eax
	push dword PTR OFFSET tekst_separator
	push dword PTR 1
	call __write
	add esp, 12
popa
ret
wypisz_separator ENDP



wypisz_roboczy PROC
pusha
	xor eax, eax
	mov al,  dlugosc_linijki
	push eax
	push dword PTR OFFSET tekst_roboczy
	push dword PTR 1
	call __write
	add esp, 12
popa
ret
wypisz_roboczy ENDP


wez_stan_pola_do_al PROC ; w parametrze podac ktorego
	
	push ebx
	push ecx
	xor ecx, ecx
	xor ebx, ebx
	mov ebx, [esp+12];trzymam tu argument
	mov ecx, dword PTR OFFSET pola
	add ecx, ebx
	mov eax, [ecx];tu jest to co pod danym polem

	cmp al, ' ' ;		testuje 0wy bajt, jesli ustawiony na 1, to pole puste
	je wspda_puste
	cmp al, 'o'  ;		testuje 1wy bajt, jesli ustawiony na 1, to pole zajete przez 1 gracza
	je wspda_pierwszy_gracz
	cmp al, 'x'  ;		testuje 2wy bajt, jesli ustawiony na 1, to pole zajete przez 2 gracza
	je wspda_drugi_gracz

	wspda_error: 
	
		mov al, byte PTR '.'
		jmp wspda_koniec 

	wspda_puste:
		mov al, byte PTR ' '
		jmp wspda_koniec 
	wspda_pierwszy_gracz:
		mov al, byte PTR 'o'
		jmp wspda_koniec 
	wspda_drugi_gracz:
		mov al, byte PTR 'x'
		jmp wspda_koniec 

	wspda_koniec:
	pop ecx
	pop ebx
	ret
wez_stan_pola_do_al ENDP
wyswietl_stan_gry PROC
	pusha
	call wez_ture_do_al
	mov bl, al



	;wypisanie aktualnego gracza
	wsg_wypisz_akt:
		mov eax, dword PTR OFFSET tekst_akt_tura
		add eax, 23;indeks miejsca w ktorym dorobic znaczek
		mov [eax], bl
	 
		xor eax,eax					;
		mov al, dlugosc_akt_tura	; liczba znakow	
		push eax					;

		push dword PTR OFFSET tekst_akt_tura ; tekst
		push dword PTR 1
		call __write
		add esp,12

	;wypisanie planszy

	mov edx, 0								; licznik indeksu pola
	mov ecx,5								; zewnetrzna petla	
	mov ebx, dword PTR OFFSET tekst_roboczy ; wskaznik do tekstu
	wsg_zew_wypis:
		dec ecx

		cmp ecx,1
		jne wsg_nie_1
		call wypisz_separator
		jmp wsg_zew_wypis

		wsg_nie_1:
			cmp ecx,3
			jne wsg_nie_3
			call wypisz_separator
			jmp wsg_zew_wypis
		wsg_nie_3:

			push edx
			call wez_stan_pola_do_al
			add esp, 4
			inc edx
			mov [ebx+0], al

			push edx
			call wez_stan_pola_do_al
			add esp, 4
			inc edx
			mov [ebx+2], al

			push edx
			call wez_stan_pola_do_al
			add esp, 4
			inc edx
			mov [ebx+4], al

			call wypisz_roboczy


		or ecx, ecx;sterowanie petla
		jnz wsg_zew_wypis

	popa
	ret
wyswietl_stan_gry ENDP
_main:
startuj:
	call wyswietl_stan_gry
	
	call wczytaj_input
	
	call sprawdz_wygrana
	

	call zmien_ture

	jmp startuj



	push 0
	call _ExitProcess@4
END