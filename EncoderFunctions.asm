/*
�������� ������� ��� ������ ���������������� � ���������.
1. ������� ��������� ��������� �������� ��������. ����������� ��������� ��������. ���� ������ ������ (�� ����� ������ ������� - 0) ��� �������
� ������� 8 ������ ������ � ���������, ������� ������� ������� ������������� �� 1 (������� ��������� � ������ ���). ��� ������� ������ (�� �����
������� ������� - 1) � ������� 8 ������ ������ � ��������� ����������� �������� ������� ������� �������. ���� �������� ����� 0, ������ ������� ������
��� ������������� ��� �������������. ���� �������� ����� 500 (������ ���� ������ ����� 2 ������), �� ����������� ��������� ��������� ������� ������, �
������� ����������. ���� �������� �������� ����� 500 ����������� ��������� ����������� (����� 2 ������) ������� ������, ������� ����� ����������.
����� �������� ������� ������ ����������� ������� �������� �������� � ����������� ��������. ��� ���������� ���������� ���� ��������(�.�. �����������
������� ����� � �������� ��������� - ������� ������� �� ����� ������), ������������ ����������� �������� � ����������� ��������� ��������� �������.
����������� ����������� �������� �������� � ������ ���������� ���� �������� ������������ �� ��������� ������ ����������� � ��������� ��������
enc_state (���������� ��������� ��������).
2. ��������� ��������� ��������� ������� ������. ��� ������ �� ��������� ��������� ���������� ������� ��������� �������� �������� ������, �������������
��������� ������������ � eeprom. 
3. ��������� ��������� ����������� ������� ������. 
4. ��������� ��������� ��������� ��� �������� ������ ��������.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Encoder_proc:
	sbrs	enc_state,T2IF
	jmp		exit_enc_proc

	mov		templ,enc_state						;� enc_state ���������� ��������� ������ �����, ������������� � �������� � ���������� ��������� �������� 
	andi	enc_state,3							;� enc_state �������� ������ ���������� ��������� ��������, � templ - ��������� ������ �������� 
	andi	templ,0x1C							;� temph - ��������� ����� � � � ��������
	lsr		templ
	lsr		templ
	mov		temph,templ
	lsr		temph
	andi	templ,1

	ldi		XL,LOW(BUTTON_STATE)				;�������� ��������� ������ � ������ �������������� ������� ������� ��������� ������ �� 1 ���
	ldi		XH,HIGH(BUTTON_STATE)
	ld		temp_2,X
	lsl		temp_2
	or		templ,temp_2
	st		X,templ

	ldi		YL,LOW(BUTTON_COUNT)				;� ������� � �������� �������� ��������� �������� ������� �������
	ldi		YH,HIGH(BUTTON_COUNT)
	ld		XL,Y+
	ld		XH,Y

	cpi		templ,0								;������� ������� ������� ��������� �� 1 ���� ������ ������ ����� 8 ������ (������� ������ ��������� ������  = 0)
	brne	check_button_state_unpress			;���� ����� ������ ����� 8 ������, ��������� ������� ������� �������
	adiw	XL,1								;������� �������� ��������, ��� ������� ��� ������������� � ���������� ��� ��� ����� �� ����
	ldi		YL,LOW(BUTTON_COUNT)				;���� �������� ����� 512(������� ���� 2-� ��������� �������� ������ 2) ��������� �������� ������� ������ - ���������� ��������� ��������� ������� ������	
	ldi		YH,HIGH(BUTTON_COUNT)				;���� ����� 512, �� ��������� ���������� ������� - ���������� ��������� ����������� ������� ������
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

check_encoder_state:									;�������� ��������� ������, ������������ � �������� � ����������� ��������� �������� 
	cpi		temph,3										;��������� ���������� ���� �������� �������� �������� ������� �� ������ � � � �������� ������
	brne	enc_A_B_not_3								;��� ���� ���������� ��������� �������� enc_state = 1 ��� 3 � ����������� �� ����������� ��������
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

enc_A_B_not_3:											;� ����������� �� ��������� ����� � � � �������� �������� ����������� ��������� ��������
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
	//���� ���� �������� ��������� ��������� �������� ������� ��������� ������� � ������ ��� � ������� SET_MODE_COUNTER
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
	jmp		exit_bsp_proc							;� ������ ��������� ����� ��� �������� ������� �������� ����� ���������������� ��������
	ldi		temp_2,3
	cp		set_segm,temp_2
	brsh	bsp_clock_segment_4_5_0					;��������� ������ ���������������� �������� ���� �� �������, ����� ��������� 4 � 5
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
	sbi		PORTB,0												;��������� 12 �����
	jmp		exit_bsp_proc

//////////////////////////////////////////////////////////////////////////
bsp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		bsp_timer_mode_check_bt_on				;� ������ ��������� ������� ��� �������� ������� �������� ����� ���������������� ��������
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
	call	Write_timer_parameters_to_eeprom		;�������� ��������� ������� � eeprom
	jmp		exit_bsp_proc

bsp_timer_mode_check_bt_on:
	sbrc	state_flag,BTON
	jmp		bsp_chek_pause_on
	sbr		state_flag,(1<<BTON)								;������ �������	
	sbrs	state_flag,BTPS
	call	Sound_1000Hz_ON
	cbr		state_flag,(1<<BTRT) | (1<<BTPS)
	clr		seconds
	clr		minutes
	clr		round
	inc		round
	jmp		exit_bsp_proc

bsp_chek_pause_on:
	sbrs	state_flag,BTPS										;���������� �� ����� ��� ������ � �����
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
	//���� ���� �������� ��������� ��������� �������� ������� ��������� ������� � ������ ��� � ������� SET_MODE_COUNTER
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
	sbr		state_flag,(1<<WWSM)				;������� � ����� ��������� �������
	clr		set_segm							
	cbi		PORTB,0								;�������� 12 �����
	jmp		exit_blp_proc
	
blp_clock_mode_set:								;������� � ����� ������� + ��������� 12 �����
	ldi		templ,(1<<COM21) | (1<<COM20) | (1<<WGM21) | (1<<WGM20) | PRESCALER_2_BT							;����� �������� ������� ������� 2
	out		TCCR2,templ	
	sbr		state_flag,(1<<WWVM)
	cbr		state_flag,(1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS) 
	sbi		PORTB,0
	jmp		exit_blp_proc

blp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		blp_timer_not_set_mode	
	ldi		templ,(1<<COM21) | (1<<COM20) | (1<<WGM21) | (1<<WGM20) | PRESCALER_2_CLK							;����� �������� ������� ������� 2
	out		TCCR2,templ			
	cbr		state_flag,(1<<WWVM) | (1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS) 								;������� � ����� ������� � ����
	jmp		exit_blp_proc

blp_timer_not_set_mode:
	sbrc	state_flag,BTON
	jmp		blp_timer_is_on
	sbr		state_flag,(1<<WWSM)											;������� � ����� ��������� ���������� �������
	cbr		state_flag,(1<<BTON) | (1<<BTRT) | (1<<BTPS)
	clr		set_segm
	jmp		exit_blp_proc

blp_timer_is_on:
	cbr		state_flag,(1<<WWSM) | (1<<BTON) | (1<<BTRT) | (1<<BTPS)		;������� � ����� �������������� �������
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
	//���� ���� �������� ��������� ��������� �������� ������� ��������� ������� � ������ ��� � ������� SET_MODE_COUNTER
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
////////////////////////////////////////////////////////////////////� ������ ��������� ������� � ����
	cp		set_segm,templ							
	brne	cp_clock_mode_segm_1
	clr		temph												;�������� �������		
	clr		byte_address
	call	Write_byte_to_DS1307
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
cp_clock_mode_segm_1:
	ldi		templ,1												
	cp		set_segm,templ										;�������� ������
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
	call	BCD_TO_HEX												;�������� ����
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
	brne	cp_clock_mode_segm_5											;�������� ���� ������
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
cp_clock_mode_segm_5_intermed:													;�������� �����	
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;���� � ������ 31 ����
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;��� ������� ������ ���������� ������������ ����
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;���� � ������ 30 ����
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
cp_clock_mode_segm_4_intermed:													;�������� �����	
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
////////////////////////////////////////////////////////////////////� ������ ��������� ���������� �������
cp_timer_mode:
	sbrs	state_flag,WWSM
	jmp		exit_cp_proc

////////////////////////////////////////////////////////////////////
	ldi		templ,0
	cp		set_segm,templ
	brne	cp_timer_mode_segm_1
	sbrc	enc_state,EMPF											;�������� ������� ������ ����. �������
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
	sbrc	enc_state,EMPF											;�������� ������ ������ ����. �������
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
	sbrc	enc_state,EMPF											;�������� ������ ������ ����. �������
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
	sbrc	enc_state,EMPF											;�������� ������� ������ ����. �������
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
	sbrc	enc_state,EMPF											;�������� ������ ������ ����. �������
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
