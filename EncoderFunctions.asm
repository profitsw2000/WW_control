/*
Основные функции для работы микроконтроллера с энкодером.
1. Главная процедура обработки сигналов энкодера. Считывается состояние энкодера. Если нажата кнопка (на линии низкий уровень - 0) как минимум
в течение 8 циклов захода в процедуру, счетчик времени нажатия увеличивается на 1 (счетчик находится в памяти ОЗУ). При отжатии кнопки (на линии
высокий уровень - 1) в течении 8 циклов захода в процедуру проверяется значение счетчик времени нажатия. Если значение равно 0, значит нажатия кнопки
уже зафиксировано или отсутствовало. Если значение менее 500 (кнопка была нажата менее 2 секунд), то запускается процедура короткого нажатия кнопки, а
счетчик обнуляется. Если значение счетчика более 500 запускается процедура длительного (более 2 секунд) нажатия кнопки, счетчик также обнуляется.
После проверки нажатия кнопки проверяется наличие вращения энкодера и направление вращения. При завершении очередного шага энкодера(т.е. возвращение
входных линий в исходное состояние - высокий уровень на обоих линиях), определяется направление вращение и запускается процедура обработки события.
Определение направления вращения энкодера и момент завершения шага вращения определяется по состоянию входов контроллера и состоянию регистра
enc_state (логическое состояние энкодера).
2. Процедура обработки короткого нажатия кнопки. 
3. Процедура обработки длительного нажатия кнопки. 
4. Процедура изменения параметра при вращении кнопки энкодера.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Encoder_proc:
	sbrs	enc_state,T2IF
	jmp		exit_enc_proc

	mov		templ,enc_state						;в enc_state содержится состояние входов порта, подключенного к энкодеру и логическое состояние энкодера 
	andi	enc_state,3							;в enc_state оставить только логическое состояние энкодера, в templ - состояние кнопки энкодера 
	andi	templ,0x1C							;в temph - состояние линий А и В энкодера
	lsr		templ
	lsr		templ
	mov		temph,templ
	lsr		temph
	andi	templ,1

	ldi		XL,LOW(BUTTON_STATE)				;записать состояние кнопки в память предварительно сдвинув регистр состояния кнопки на 1 бит
	ldi		XH,HIGH(BUTTON_STATE)
	ld		temp_2,X
	lsl		temp_2
	or		templ,temp_2
	st		X,templ

	ldi		YL,LOW(BUTTON_COUNT)				;в регистр Х записать значение регистров счетчика времени нажатия
	ldi		YH,HIGH(BUTTON_COUNT)
	ld		XL,Y+
	ld		XH,Y

	cpi		templ,0								;счетчик времени нажатия увеличить на 1 если кнопка нажата более 8 циклов (регистр памяти состояния кнопки  = 0)
	brne	check_button_state_unpress			;если кнока отжата более 8 циклов, проверить счетчик времени нажатия
	adiw	XL,1								;нулевое значение означает, что нажатие уже зафиксировано и обработано или его вовсе не было
	ldi		YL,LOW(BUTTON_COUNT)				;если значение менее 512(старший байт 2-х байтового счетчика меньше 2) произошло короткое нажатие кнопки - вызывается процедура короткого нажатия кнопки	
	ldi		YH,HIGH(BUTTON_COUNT)				;если более 512, то произошло длительное нажатие - вызывается процедура длительного нажатия кнопки
	st		Y+,XL
	st		Y,XH
	jmp		check_encoder_state

check_button_state_unpress:
	cpi		templ,0xFF
	brne	check_encoder_state
	cpi		XL,0
	brne	check_non_zero_counter
	cpi		XH,0
	brne	check_non_zero_counter
	jmp		check_encoder_state

check_non_zero_counter:
	cpi		XH,2
	brge	button_counter_more_than_512
	call	Button_short_press
	jmp		clear_button_counter

button_counter_more_than_512:	
	call	Button_long_press

clear_button_counter:
	clr		XL
	clr		XH
	ldi		YL,LOW(BUTTON_COUNT)				
	ldi		YH,HIGH(BUTTON_COUNT)
	st		Y+,XL
	st		Y,XH

check_encoder_state:									;проверка состояния входов, подключенных к энкодеру и логического состояния энкодера 
	cpi		temph,3										;признаком завершения шага вращения энкодера является наличие на линиях А и В высокого уровня
	brne	enc_A_B_not_3								;при этом логическое состояние энкодера enc_state = 1 или 3 в зависимости от направления вращения
	cpi		enc_state,0
	breq	exit_enc_proc

	cpi		enc_state,1
	brne	check_enc_state_3
	cbr		enc_state,(1<<EMPF)
	call	Change_parameter
	jmp		clear_logical_encoder_state

check_enc_state_3:
	cpi		enc_state,3
	brne	exit_enc_proc
	sbr		enc_state,(1<<EMPF)
	call	Change_parameter


clear_logical_encoder_state:
	clr		enc_state		
	jmp		exit_enc_proc							

enc_A_B_not_3:											;в зависимости от состояния линий А и В поменять значение логического состояния энкодера
	cpi		temph,1
	brne	enc_A_B_not_1
	ldi		enc_state,3
	jmp		exit_enc_proc

enc_A_B_not_1:
	cpi		temph,2
	brne	enc_A_B_not_2
	ldi		enc_state,1
	jmp		exit_enc_proc

enc_A_B_not_2:	
	ldi		enc_state,2

exit_enc_proc:
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	2
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Button_short_press:
	//сюда надо записать процедуру обнуления счетчика времени установки времени и запись его в регистр SET_MODE_COUNTER
	push	templ
	clr		templ
	ldi		XL,LOW(SET_MODE_COUNTER)				
	ldi		XH,HIGH(SET_MODE_COUNTER)
	st		X,templ
	pop		templ
///////////////////////////////////////////////////////////////////////////
	sbrc	state_flag,WWVM
	jmp		bsp_timer_mode
	sbrs	state_flag,WWSM
	jmp		exit_bsp_proc							;в режиме установки часов при коротком нажатии изменить номер устанавливаемого сегмента
	ldi		temp_2,3
	cp		set_segm,temp_2
	brsh	bsp_clock_segment_4_5_0					;изменение номера устанавливаемого сегмента идет по порядку, кроме сегментов 4 и 5
	inc		set_segm
	jmp		exit_bsp_proc
bsp_clock_segment_4_5_0:
	ldi		temp_2,5
	cp		set_segm,temp_2
	brne	bsp_clock_segment_4_0
	ldi		temp_2,4
	mov		set_segm,temp_2
	jmp		exit_bsp_proc
bsp_clock_segment_4_0:
	ldi		temp_2,4
	cp		set_segm,temp_2
	breq	bsp_clock_segment_4
	ldi		temp_2,5
	mov		set_segm,temp_2
	jmp		exit_bsp_proc
bsp_clock_segment_4:
	clr		set_segm
	cbr		state_flag,(1<<WWSM)
	sbi		PORTB,0												;выключить 12 вольт
	jmp		exit_bsp_proc

//////////////////////////////////////////////////////////////////////////
bsp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		bsp_timer_mode_check_bt_on				;в режиме установки таймера при коротком нажатии изменить номер устанавливаемого сегмента
	inc		set_segm
	ldi		temp_2,6
	cp		set_segm,temp_2
	brsh	bsp_timer_mode_clear_segm
	ldi		temp_2,3
	cp		set_segm,temp_2
	brne	exit_bsp_proc
	inc		set_segm
	jmp		exit_bsp_proc

bsp_timer_mode_clear_segm:
	clr		set_segm
	cbr		state_flag,(1<<WWSM)
	jmp		exit_bsp_proc

bsp_timer_mode_check_bt_on:
	sbrc	state_flag,BTON
	jmp		bsp_chek_pause_on
	sbr		state_flag,(1<<BTON)								;запуск таймера	
	sbrs	state_flag,BTPS
	call	Sound_1000Hz_ON
	cbr		state_flag,(1<<BTRT) | (1<<BTPS)
	clr		seconds
	clr		minutes
	clr		round
	inc		round
	jmp		exit_bsp_proc

bsp_chek_pause_on:
	sbrs	state_flag,BTPS										;постановка на паузу или снятие с паузы
	jmp		bsp_pause_is_off
	cbr		state_flag,(1<<BTPS)
	jmp		exit_bsp_proc

bsp_pause_is_off:
	sbr		state_flag,(1<<BTPS)

exit_bsp_proc:
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	3
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Button_long_press:
	//сюда надо записать процедуру обнуления счетчика времени установки времени и запись его в регистр SET_MODE_COUNTER
	push	templ
	clr		templ
	ldi		XL,LOW(SET_MODE_COUNTER)				
	ldi		XH,HIGH(SET_MODE_COUNTER)
	st		X,templ
	pop		templ
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	sbrc	state_flag,WWVM
	jmp		blp_timer_mode
	sbrc	state_flag,WWSM
	jmp		blp_clock_mode_set
	sbr		state_flag,(1<<WWSM)				;перевод в режим установки времени
	clr		set_segm							
	cbi		PORTB,0								;включить 12 вольт
	jmp		exit_blp_proc
	
blp_clock_mode_set:								;перевод в режим таймера + выключить 12 вольт
	ldi		templ,(1<<COM21) | (1<<COM20) | (1<<WGM21) | (1<<WGM20) | PRESCALER_2_BT							;также изменить частоту таймера 2
	out		TCCR2,templ	
	sbr		state_flag,(1<<WWVM)
	cbr		state_flag,(1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS) 
	sbi		PORTB,0
	jmp		exit_blp_proc

blp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		blp_timer_not_set_mode	
	ldi		templ,(1<<COM21) | (1<<COM20) | (1<<WGM21) | (1<<WGM20) | PRESCALER_2_CLK							;также изменить частоту таймера 2
	out		TCCR2,templ			
	cbr		state_flag,(1<<WWVM) | (1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS) 								;перевод в режим времени и даты
	jmp		exit_blp_proc

blp_timer_not_set_mode:
	sbrc	state_flag,BTON
	jmp		blp_timer_is_on
	sbr		state_flag,(1<<WWSM)											;перевод в режим установки параметров таймера
	cbr		state_flag,(1<<BTON) | (1<<BTRT) | (1<<BTPS)
	clr		set_segm
	jmp		exit_blp_proc

blp_timer_is_on:
	cbr		state_flag,(1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS)		;перевод в режим остановленного таймера
	clr		seconds
	clr		minutes
	clr		round
	inc		round

exit_blp_proc:
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	4
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Change_parameter:
	//сюда надо записать процедуру обнуления счетчика времени установки времени и запись его в регистр SET_MODE_COUNTER
	push	templ
	clr		templ
	ldi		XL,LOW(SET_MODE_COUNTER)				
	ldi		XH,HIGH(SET_MODE_COUNTER)
	st		X,templ
	pop		templ
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	sbrc	state_flag,WWVM		
	jmp		cp_timer_mode
	sbrs	state_flag,WWSM
	jmp		exit_cp_proc

	clr		templ
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	add		XL,set_segm
	adc		XH,templ
	ld		temph,X

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////в режиме установки времени и даты
	cp		set_segm,templ							
	brne	cp_clock_mode_segm_1
	clr		temph												;обнулить секунды		
	clr		byte_address
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_1:
	ldi		templ,1												
	cp		set_segm,templ										;изменить минуты
	brne	cp_clock_mode_segm_2
	call	BCD_TO_HEX
	sbrc	enc_state,EMPF
	jmp		blp_segm_1_enc_plus
	cpi		temph,0
	brne	blp_segm_1_dec_min
	ldi		temph,59
	jmp		blp_segm_1_write_byte

blp_segm_1_dec_min:
	dec		temph
	jmp		blp_segm_1_write_byte

blp_segm_1_enc_plus:
	inc		temph
	cpi		temph,60
	brlo	blp_segm_1_write_byte
	clr		temph	

blp_segm_1_write_byte:
	call	HEX_TO_BCD
	ldi		templ,1
	mov		byte_address,templ
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_2:
	ldi		templ,2											
	cp		set_segm,templ	
	brne	cp_clock_mode_segm_3
	call	BCD_TO_HEX												;изменить часы
	sbrc	enc_state,EMPF
	jmp		blp_segm_2_enc_plus
	cpi		temph,0
	brne	blp_segm_2_dec_hour
	ldi		temph,23
	jmp		blp_segm_2_write_byte
	
blp_segm_2_dec_hour:
	dec		temph
	jmp		blp_segm_2_write_byte

blp_segm_2_enc_plus:
	inc		temph
	cpi		temph,24
	brlo	blp_segm_2_write_byte
	clr		temph

blp_segm_2_write_byte:
	call	HEX_TO_BCD
	ldi		templ,2
	mov		byte_address,templ
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc
	
////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_3:
	ldi		templ,3										
	cp		set_segm,templ	
	brne	cp_clock_mode_segm_5											;изменить день недели
	sbrc	enc_state,EMPF
	jmp		blp_segm_3_enc_plus
	cpi		temph,1
	brne	blp_segm_3_dec_day
	ldi		temph,7
	jmp		blp_segm_3_write_byte

blp_segm_3_dec_day:
	dec		temph
	jmp		blp_segm_3_write_byte

blp_segm_3_enc_plus:	
	inc		temph
	cpi		temph,8
	brlo	blp_segm_3_write_byte
	ldi		temph,1

blp_segm_3_write_byte:
	ldi		templ,3
	mov		byte_address,templ
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc	

////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_5:
	ldi		templ,4									
	cp		set_segm,templ	
	breq	cp_clock_mode_segm_5_intermed
	jmp		cp_clock_mode_segm_4
cp_clock_mode_segm_5_intermed:													;изменить число	
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	adiw	XL,4
	ld		temph,X+
	ld		temp_2,X+
	ld		temp_3,X
	call	BCD_TO_HEX	


	cpi		temp_2,1
	breq	month_31
	cpi		temp_2,3
	breq	month_31
	cpi		temp_2,5
	breq	month_31
	cpi		temp_2,7
	breq	month_31
	cpi		temp_2,8
	breq	month_31
	cpi		temp_2,0x10
	breq	month_31
	cpi		temp_2,0x12
	breq	month_2	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;если в месяце 31 день
month_31:
	sbrc	enc_state,EMPF
	jmp		blp_segm_5_month_31_plus
	cpi		temph,1
	brne	blp_segm_5_month_31_dec
	ldi		temph,31
	jmp		blp_segm_5_write_byte
	
blp_segm_5_month_31_dec:
	dec		temph
	jmp		blp_segm_5_write_byte

blp_segm_5_month_31_plus:
	inc		temph
	cpi		temph,32
	brlo	blp_segm_5_write_byte
	ldi		temph,1
	jmp		blp_segm_5_write_byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;для февраля месяца определить високосность года
month_2:
	cpi		temp_2,2
	brne	month_30
	sbrc	enc_state,EMPF
	jmp		blp_segm_5_month_2_plus
	cpi		temph,1
	brne	blp_segm_5_month_2_dec
	andi	temp_3,3
	cpi		temp_3,0
	brne	blp_segm_5_month_2_29
	ldi		temph,28
	jmp		blp_segm_5_write_byte

blp_segm_5_month_2_29:
	ldi		temph,29
	jmp		blp_segm_5_write_byte

blp_segm_5_month_2_dec:
	dec		temph
	jmp		blp_segm_5_write_byte

blp_segm_5_month_2_plus:
	inc		temph
	andi	temp_3,3
	cpi		temp_3,0
	brne	blp_segm_5_month_2_29_plus
	cpi		temph,29
	brlo	blp_segm_5_write_byte
	ldi		temph,1
	jmp		blp_segm_5_write_byte

blp_segm_5_month_2_29_plus:
	cpi		temph,30
	brlo	blp_segm_5_write_byte
	ldi		temph,1
	jmp		blp_segm_5_write_byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;если в месяце 30 дней
month_30:
	sbrc	enc_state,EMPF
	jmp		blp_segm_5_month_30_plus
	cpi		temph,1
	brne	blp_segm_5_month_30_dec
	ldi		temph,30
	jmp		blp_segm_5_write_byte

blp_segm_5_month_30_dec:
	dec		temph
	jmp		blp_segm_5_write_byte

blp_segm_5_month_30_plus:
	inc		temph
	cpi		temph,31
	brlo	blp_segm_5_write_byte
	ldi		temph,1

blp_segm_5_write_byte:
	call	HEX_TO_BCD
	ldi		templ,4
	mov		byte_address,templ
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_4:
	ldi		templ,5									
	cp		set_segm,templ	
	breq	cp_clock_mode_segm_4_intermed
	jmp		exit_cp_proc	
cp_clock_mode_segm_4_intermed:													;изменить месяц	
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	adiw	XL,5
	ld		temph,X
	call	BCD_TO_HEX
	sbrc	enc_state,EMPF
	jmp		cp_clock_mode_segm_4_enc_plus
	cpi		temph,1
	brne	cp_clock_mode_segm_4_dec
	ldi		temph,12
	jmp		blp_segm_4_write_byte

cp_clock_mode_segm_4_dec:
	dec		temph
	jmp		blp_segm_4_write_byte

cp_clock_mode_segm_4_enc_plus:
	inc		temph
	cpi		temph,13
	brlo	blp_segm_4_write_byte
	ldi		temph,1

blp_segm_4_write_byte:
	call	HEX_TO_BCD
	ldi		templ,5
	mov		byte_address,templ
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc	

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////в режиме установки параметров таймера
cp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
	ldi		templ,0
	cp		set_segm,templ
	brne	cp_timer_mode_segm_1
	sbrc	enc_state,EMPF											;изменить секунды работы бокс. таймера
	jmp		cp_timer_mode_segm_0_plus
	ldi		templ,10
	cp		sec_work,templ
	brsh	cp_timer_mode_segm_0_10
	ldi		templ,50
	mov		sec_work,templ
	jmp		exit_cp_proc

cp_timer_mode_segm_0_10:
	sub		sec_work,templ
	jmp		exit_cp_proc

cp_timer_mode_segm_0_plus:
	ldi		templ,10
	add		sec_work,templ
	ldi		templ,60
	cp		sec_work,templ
	brsh	cp_timer_mode_segm_0_plus_60
	jmp		exit_cp_proc

cp_timer_mode_segm_0_plus_60:
	clr		sec_work
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_timer_mode_segm_1:
	ldi		templ,1
	cp		set_segm,templ
	brne	cp_timer_mode_segm_2
	sbrc	enc_state,EMPF											;изменить минуты работы бокс. таймера
	jmp		cp_timer_mode_segm_1_plus
	tst		min_work
	brne	cp_timer_mode_segm_1_not_zero
	ldi		templ,99
	mov		min_work,templ
	jmp		exit_cp_proc
	
cp_timer_mode_segm_1_not_zero:
	dec		min_work
	jmp		exit_cp_proc

cp_timer_mode_segm_1_plus:	
	inc		min_work
	ldi		templ,100
	cp		min_work,templ
	brsh	cp_timer_mode_segm_1_plus_100
	jmp		exit_cp_proc

cp_timer_mode_segm_1_plus_100:
	clr		min_work
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_timer_mode_segm_2:
	ldi		templ,2
	cp		set_segm,templ
	brne	cp_timer_mode_segm_4
	sbrc	enc_state,EMPF											;изменить раунды работы бокс. таймера
	jmp		cp_timer_mode_segm_2_plus
	ldi		templ,1
	cp		round_work,templ
	brne	cp_timer_mode_segm_2_dec
	ldi		templ,99
	mov		round_work,templ
	jmp		exit_cp_proc

cp_timer_mode_segm_2_dec:
	dec		round_work
	jmp		exit_cp_proc

cp_timer_mode_segm_2_plus:
	inc		round_work
	ldi		templ,100
	cp		round_work,templ
	brsh	cp_timer_mode_segm_2_plus_100
	jmp		exit_cp_proc

cp_timer_mode_segm_2_plus_100:
	ldi		templ,1
	mov		round_work,templ
	jmp		exit_cp_proc
	
////////////////////////////////////////////////////////////////////
cp_timer_mode_segm_4:
	ldi		templ,4
	cp		set_segm,templ
	brne	cp_timer_mode_segm_5
	sbrc	enc_state,EMPF											;изменить секунды отдыха бокс. таймера
	jmp		cp_timer_mode_segm_4_plus
	ldi		templ,10
	cp		sec_rest,templ
	brsh	cp_timer_mode_segm_4_10
	ldi		templ,50
	mov		sec_rest,templ
	jmp		exit_cp_proc

cp_timer_mode_segm_4_10:
	sub		sec_rest,templ
	jmp		exit_cp_proc

cp_timer_mode_segm_4_plus:
	ldi		templ,10
	add		sec_rest,templ
	ldi		templ,60
	cp		sec_rest,templ
	brsh	cp_timer_mode_segm_4_plus_60
	jmp		exit_cp_proc

cp_timer_mode_segm_4_plus_60:
	clr		sec_rest
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_timer_mode_segm_5:
	ldi		templ,5
	cp		set_segm,templ
	brne	exit_cp_proc
	sbrc	enc_state,EMPF											;изменить минуты отдыха бокс. таймера
	jmp		cp_timer_mode_segm_5_plus
	tst		min_rest
	brne	cp_timer_mode_segm_5_not_zero
	ldi		templ,99
	mov		min_rest,templ
	jmp		exit_cp_proc
	
cp_timer_mode_segm_5_not_zero:
	dec		min_rest
	jmp		exit_cp_proc

cp_timer_mode_segm_5_plus:	
	inc		min_rest
	ldi		templ,100
	cp		min_rest,templ
	brsh	cp_timer_mode_segm_5_plus_100
	jmp		exit_cp_proc

cp_timer_mode_segm_5_plus_100:
	clr		min_rest
		
exit_cp_proc:
ret



.dseg

BUTTON_STATE:		.byte	1

BUTTON_COUNT:		.byte	2

SET_MODE_COUNTER:	.byte	1

.cseg
