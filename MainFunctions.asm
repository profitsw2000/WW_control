/*
�������� ��������� ��� ������ ��������� ����������������.
1. ��������� ��� ������ � ������ �����. � ������ ��������� ����� ������ ������ ������, ���������������� � ������������ ��������������, ����������
����� ��������� ������ ������� � ���� �� ������� ������� � ������ � ������ �� ������ TWI_BUFFER_IN. ����� ���������� ������ ���� �� ������ �����������
�� ������, ����������������� � ������ ��� ������ �� ���������� � ������������ ������� �� ������ TEMP_OUTPUT_BUFFER, � ����� ������ �������������� �� ������
OUTPUT_BUFFER ��� ����������� ����������(��� �������������� ������ ������ �� ������� �� ����� ���������� ��� ������ � ����). 
2. ��������� ���������� ���� ������ ���� ����� ��� ����� �� ������ �������� �� ������, ���������� � �������� Z. ���������� ������ ������������ � ��� ��
������ TEMP_OUTPUT_BUFFER + ����� ���������� + ����� ����� � ����������.
3. ���������� ����� �� ���������� ������ � ����� ������.
4. ��������� ��� ������ � ������ �������. � ������ ��������� ����� ������ ������ ������, ���������������� � �������������� � 1 �������, � �����������
�� ������ ������ (������ ���., ����., �����, ������, ����� � �.�.) ���������� ��������� ��������� �������. ����� ��������� ���� ��������� ������ �� ��������� 
�����������, ����������������� � ������������ ������� � TIMER_BUFFER, � ����� � OUTPUT_BUFFER.
5. ��������� ���������� �������� ��������� �������. ���� ������ �� �������, �� ����� ��� ���������� ��������� �������� ������� ������/������ �� ��������� ��
������������. ���� ������ �������, �������� �������� ������ ����������������, � � ������ ������������� �������� �������� ������ ���������.
6. ��������� ��������� ���� ������ ���� ����� ��� ������ �� ���������. ���� ���� ������������ � OUTPUT_BUFFER � ��������������� �������. 
7. ��������� �������� ������.
8. �������� �������� ������ 1000 ��.
9. �������� �������� ������ 400 ��.
10. ������ ������ ����� � ����-��, ����� ����� ����������� � �������� byte_address, ������������ ���� � �������� temph.
11. ������� ����� � �������� temph �� ������� BCD � ������ HEX.
12. ������� ����� � �������� temph �� ������� HEX � ������ BCD.
13. ��������� ������� �� ���������.
14. ������������� ������� �����. � ����� � ���, ��� � �������� ������ ����� � ������� ������������� �������, ��-�� ����������� �������� ������ ���������� 
����������, ��������� ����������� ����������� ������� ����������� DS1307. ������� ������ �����, � ����������� �����, ���������� ������������� �����. ��� �����
����� �������������� ���������� �������� ����� ������� � �������� �� ����� ��� ������ ���������� ������ �����.
15. ��������� �� ��������� ���������� �������.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Clock_mode_proc:

	sbrs	state_flag,RPTF							;���� ���������� ���� ���������� ������ ������� � ���� - ������ ������ � ��������������
	jmp		exit_clock_mode_proc

	//���� ���� �������� ��������� ���������� � �������� �������� ������� �������� ��������� �������
	sbrs	state_flag,(1<<WWSM)
	jmp		do_not_clear_set_mode_counter
	ldi		XL,LOW(SET_MODE_COUNTER)				
	ldi		XH,HIGH(SET_MODE_COUNTER)
	ld		templ,X
	inc		templ
	cpi		templ,250
	brlo	write_set_mode_counter
	cbr		state_flag,(1<<WWSM)
	sbi		PORTB,0
	clr		templ
write_set_mode_counter:
	ldi		XL,LOW(SET_MODE_COUNTER)				
	ldi		XH,HIGH(SET_MODE_COUNTER)
	st		X,templ
do_not_clear_set_mode_counter:

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	cbr		state_flag,(1<<RPTF)
	call	Read_packet								;������ ������ �� DS1307, ������ ������������ �� ������ TWI_BUFFER_IN

	clr		count									;������ ����������� ������

next_ds1307_byte:
	
	clr		templ									;���������� ����� ���������� �� ������ TWI_BUFFER_IN + count
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	add		XL,count
	adc		XH,templ
	ld		templ,X
	
	mov		temph,templ								;�������������� ����� ���������� - ���������� �������� � ������
	andi	templ,0xF								;������� � ������� ������, ������� - � �������
	andi	temph,0xF0
	swap	temph

	cpi		count,3									;� ���������� count - ����� ����������, ���������� �� ���� ����
	brge	data_bytes_format
	ldi		ZL,LOW(2*TIME_DIGIT_CATHODE)			;������ ��� ���������� (���. - �0, ���. - �1, ���� - �2) - ������� ����� ���������� �����
	ldi		ZH,HIGH(2*TIME_DIGIT_CATHODE)
	jmp		set_XY_reg
data_bytes_format:
	cpi		count,3
	breq	data_letter_format
	ldi		ZL,LOW(2*DATA_DIGIT_CATHODE)			;4-�� � 5-�� ��������� - ����� ����� ���� (����� - �4, ����� - �5)
	ldi		ZH,HIGH(2*DATA_DIGIT_CATHODE)
	jmp		set_XY_reg
data_letter_format:
	lsl		templ									;��� ����������� ������ ���� �� ��������� �������� templ � temph ���������� �������������
	mov		temph,templ								;templ �������� �� 2, temph �� 1 ������ templ	
	inc		temph
	ldi		ZL,LOW(2*DATA_LETTER_CATHODE)			;3-�� - ����� ����� ��� ������ (�4)
	ldi		ZH,HIGH(2*DATA_LETTER_CATHODE)
set_XY_reg:
	mov		XL,ZL									;�������� �������� �������� ��� ���������� �����������
	mov		XH,ZH
	clr		temp_2
	mov		temp_3,count
	lsl		temp_3									;��������� count �� 4 
	lsl		temp_3
	ldi		YL,LOW(TEMP_OUTPUT_BUFFER)				;���� �������� ����� ����� ��� ������ �� ���������
	ldi		YH,HIGH(TEMP_OUTPUT_BUFFER)
	add		YL,temp_3								;����� ���� ����� ��� ������ �� ��������� - ����� ���������� ���������� �� 4 + TEMP_OUTPUT_BUFFER
	adc		YH,temp_2
								
	lsl		templ									;���������� ���� ����� � ������������ �� ��������� � �������� templ
	add		ZL,templ								
	adc		ZH,temp_2
	call	Get_output	

	mov		ZL,XL
	mov		ZH,XH
	clr		temp_2
	lsl		temph
	add		ZL,temph								;���������� ���� ����� � ������������ �� ��������� � �������� temph
	adc		ZH,temp_2
	call	Get_output

	inc		count									;��������� ����� ���������� �� ���������� ��� �������� 6 � �����
	cpi		count,6
	brge	copy_output_buffers
	jmp		next_ds1307_byte

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

copy_output_buffers:
	ldi		XL,LOW(TEMP_OUTPUT_BUFFER)				;���������� ������ �� ���������� ������ � ����� ������ �������������� �������� ����������
	ldi		XH,HIGH(TEMP_OUTPUT_BUFFER)
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	cli
	clr		count
start_copy_bytes:	
	call	Copy_output_bytes
	cpi		count,16
	brlo	start_copy_bytes						;�������� ������� ������ ����� � ������ � ������ ������

	clr		templ
	ldi		temph,4
	add		YL,temph
	adc		YH,templ
next_data_byte:
	call	Copy_output_bytes
	cpi		count,20
	brlo	next_data_byte

	clr		templ
	ldi		temph,8
	sub		YL,temph
	sbc		YH,templ
next_month_byte:
	call	Copy_output_bytes
	cpi		count,24
	brlo	next_month_byte

	sei

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*	clr		count
	ldi		templ,0xFF
	call	Send_UART*/

exit_clock_mode_proc:
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	2
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



Get_output:	
	sbrs	state_flag,SDBL							;��������� ����� ����� �������� ���������� �� ����� SDBL (0 - ������ �����, 1 - ������)
	jmp		check_set_mode
	
	cpi		count,2									;���� ������ ����� �� ���������� ����� (count=2) ��� ����� ������ (count=4) ����� ����, �� ��� �� ������������ (temp_2=temp_3=0)
	breq	check_second_digit
	cpi		count,4
	brne	check_set_mode	
check_second_digit:
	cpi		temph,0
	breq	clr_output_bytes

check_set_mode:
	sbrs	state_flag,WWSM							;��������� ���� �� ����� ���������
	jmp		read_programm_memory
	cp		count,set_segm
	brne	read_programm_memory					;���� ����� ���������, �� ��������� �� ���������� ������ �������� ������������ �������� � ���������������� 
	sbrs	state_flag,WWFF
	jmp		read_programm_memory					;�������� ��������� ������� - ���� WWFF=1,�� ��������������� ��������� ������ ���� �������, � ��������
clr_output_bytes:
	clr		temp_2
	clr		temp_3
	jmp		write_to_output_buffer

read_programm_memory:								;������ �� ������ ��������
	lpm		temp_2,Z
	adiw	ZL,1
	lpm		temp_3,Z

	cpi		count,4									;��������� ����� ���������� � ����� � ���������� � ��������� �����
	brne	write_to_output_buffer
	sbrc	state_flag,SDBL							
	jmp		write_to_output_buffer
	ori		temp_2,0x80

write_to_output_buffer:								;������ �� ��������� �����

	st		Y+,temp_2
	st		Y+,temp_3

	sbrc	state_flag,SDBL							;�������������� ����� SDBL
	jmp		clear_sdbl_flag
	sbr		state_flag,(1<<SDBL)
	jmp		exit_get_output_proc
clear_sdbl_flag:
	cbr		state_flag,(1<<SDBL)
	
exit_get_output_proc:
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	3
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Copy_output_bytes:
	ld		templ,X+
	st		Y+,templ
	inc		count
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	4
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Timer_mode_proc:
	sbrs	state_flag,RPTF							;���� ���������� ���� ���������� ��������� ��������� ������� - ������� �� ��������� ������ � ������ �������
	jmp		exit_clock_mode_proc
	cbr		state_flag,(1<<RPTF)

	call	Update_BT_counter						;�������� �������� ��������� �������
	call	Get_output_timer_mode					;������������� ������ ������� ��� ������ �� ����������
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	5
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Update_BT_counter:
	sbrs	state_flag,BTON							;���������� ��������� ������� (��������/���, �� �����/���)				
	jmp		timer_is_off
	sbrc	state_flag,BTPS
	jmp		timer_pause
	
////////////////////////////////////////////////
	inc		seconds									;��������� �������� ������

	clr		temph									;��������� ������������� ������� ��������� ������� � ������ �������
	ldi		templ,4
	cp		minutes,temph
	brne	check_next_minute
	cp		seconds,templ
	brne	check_next_minute
	call	Sound_OFF								;���� ��� ������ ������� ���������� ������� - ��������� ����
	jmp		check_rest_work_1

check_next_minute:									;��������� ������������� ���������� �������� �����
	ldi		templ,60
	cp		seconds,templ
	brne	check_rest_work_1						;���� �������� ������ �������� 60 - �������� �������� ������ � ��������� �������� �����
	clr		seconds
	inc		minutes

check_rest_work_1:									;���������� ����� ��� ������
	sbrc	state_flag,BTRT
	jmp		rest_time_1		
	
	cp		minutes,min_work						;��������� �� ���������� ������������ ��������
	brne	fill_buffer_var_1_temp
	cp		seconds,sec_work
	brne	fill_buffer_var_1_temp
	call	Sound_1000Hz_ON							;���� �������� ������ � ����� �������� ������������ ��������, �� �� ���������� �������� � �������� ���� ��������� ������
	clr		seconds
	clr		minutes
	sbr		state_flag,(1<<BTRT)
	cp		round,round_work
	brne	fill_buffer_var_2_temp
	cbr		state_flag,(1<<BTON)					;���� ����� ��������� - ���������� ������
	clr		round
	inc		round
	sbr		state_flag,(1<<BTPS)
	jmp		fill_buffer_var_3

fill_buffer_var_1_temp:
	jmp		fill_buffer_var_1
fill_buffer_var_2_temp:
	jmp		fill_buffer_var_2


rest_time_1:										;�������� ��� ������ ������� � ������ ������
	cp		minutes,min_rest						;����� ���� �������� �� ������������� ������ ������� 1000��(3 ��� � ������ ������ � � �����) 
	brne	rest_seconds_set_zero					;� 400�� (�� 6,4 � 2 ���. �� ����� ������ �� 1 ���.) 
	cp		seconds,sec_rest
	brne	check_400Hz_on	
	call	Sound_1000Hz_ON
	clr		minutes
	clr		seconds
	cbr		state_flag,(1<<BTRT)
	inc		round
	jmp		fill_buffer_var_1

rest_seconds_set_zero:								;�������� ����������� � ������, ���� �������� �������� ������ ������ ����� ����
	tst		sec_rest
	brne	check_400Hz_on
	mov		templ,min_rest
	dec		templ
	cp		minutes,templ
	brne	set_sound_off
	ldi		templ,54
	cp		seconds,templ
	breq	set_sound_400Hz_on
	ldi		templ,56
	cp		seconds,templ
	breq	set_sound_400Hz_on
	ldi		templ,58
	cp		seconds,templ
	breq	set_sound_400Hz_on
	jmp		set_sound_off

check_400Hz_on:											;�������� ����������� � ������, ���� �������� �������� ������ ������ �� ����� ����
	mov		templ,sec_rest
	subi	templ,2
	cp		seconds,templ
	breq	set_sound_400Hz_on
	subi	templ,2
	cp		seconds,templ
	breq	set_sound_400Hz_on
	subi	templ,2
	cp		seconds,templ
	breq	set_sound_400Hz_on
	jmp		set_sound_off	
	
set_sound_off:
	ldi		templ,4
	cp		seconds,templ
	brlo	fill_buffer_var_2
	call	Sound_OFF
	jmp		fill_buffer_var_2

set_sound_400Hz_on:
	call	Sound_400Hz_ON
	jmp		fill_buffer_var_2



////////////////////////////////////////////////////////////////////////////////////////////////////////

timer_is_off:
	sbrc	state_flag,BTRT
	jmp		timer_just_stopped	
	call	Sound_OFF
	jmp		check_timer_set_mode

timer_just_stopped:
	sbrs	state_flag,BTPS
	jmp		set_btrt_to_zero
	cbr		state_flag,(1<<BTPS)
	jmp		check_timer_set_mode
set_btrt_to_zero:
	cbr		state_flag,(1<<BTRT)
check_timer_set_mode:
	sbrs	state_flag,WWSM
	jmp		fill_buffer_var_3	
	jmp		fill_buffer_var_4

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

timer_pause:
	call	Sound_OFF
	sbrs	state_flag,BTRT
	jmp		fill_buffer_var_1
	jmp		fill_buffer_var_2

	
fill_buffer_var_1:									;�������� �������� ��������� � ������ ������� (� ����������� �� ���������)			
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	st		X+,seconds
	st		X+,minutes
	st		X+,round
	st		X+,round_work
	st		X+,sec_work
	st		X,min_work
	jmp		exit_bt_counter_procedure

fill_buffer_var_2:
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	st		X+,seconds
	st		X+,minutes
	st		X+,round
	st		X+,round_work
	st		X+,sec_rest
	st		X,min_rest
	jmp		exit_bt_counter_procedure

fill_buffer_var_3:
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	st		X+,seconds
	st		X+,minutes
	st		X+,round
	st		X+,round_work
	st		X+,sec_work
	st		X,min_work
	jmp		exit_bt_counter_procedure

fill_buffer_var_4:
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	st		X+,sec_work
	st		X+,min_work
	st		X+,round_work
	st		X+,round_work
	st		X+,sec_rest
	st		X,min_rest

exit_bt_counter_procedure:	
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	6
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Get_output_timer_mode:
	clr		count

next_timer_digit_code:
	clr		temph											;��������� � templ ���� �� ��� �� ������ TIMER_BUFFER + count
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	add		XL,count
	adc		XH,temph
	ld		templ,X

timer_subtract_ten:											;� templ �������� ������� �����, ������������ �� ���, � temph - ������� ���� �����
	cpi		templ,10
	brlo	timer_check_digit_count
	inc		temph
	subi	templ,10
	jmp		timer_subtract_ten

timer_check_digit_count:									;��������� � Z ����� �� ������ ��������, � ������� ������ ��� �����
	cpi		count,3
	brsh	timer_small_digit_address
	ldi		ZL,LOW(2*TIME_DIGIT_CATHODE)					;��� ������� ����
	ldi		ZH,HIGH(2*TIME_DIGIT_CATHODE)
	jmp		timer_copy_address

timer_small_digit_address:
	ldi		ZL,LOW(2*DATA_DIGIT_CATHODE)					;��� ��������� ����
	ldi		ZH,HIGH(2*DATA_DIGIT_CATHODE)	

timer_copy_address:											;���������� ��������� ����� � � ��� �������������� ��� �������� ����� ��������� ���� ������ ����� ��������
	mov		XL,ZL
	mov		XH,ZH
	
	clr		temp_3											;��������� � Y �����, �� �������� ����� ������������ ����������� �� ���� �����
	mov		temp_2,count									;����� ������� �� �������� count (����� ��������)
	lsl		temp_2
	lsl		temp_2
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	add		YL,temp_2
	adc		YH,temp_3
	
	lsl		templ											;�������� ����� ������ ����� ��������
	add		ZL,templ
	adc		ZH,temp_3

timer_get_ouput_data:
	sbrs	state_flag,SDBL									;� ������ ���� � ������� ��������� ���������� ��������� ��� ����� ��������, �.�. ��� ��� ������ = 0 
	jmp		timer_first_byte_load							;����������, ���� ������� ����� � �������� = 0, ��� ��� ������ ����� ����� ����
	cpi		count,0											;���������� - �������� ������ (������� 0 � 4)
	breq	timer_first_byte_load
	cpi		count,4
	breq	timer_first_byte_load
	cpi		temph,0
	breq	timer_clear_output_bytes

timer_first_byte_load:
	sbrs	state_flag,WWSM
	jmp		timer_load_output_bytes
	cp		count,set_segm
	brne	timer_load_output_bytes
	sbrs	state_flag,WWFF
	jmp		timer_load_output_bytes

timer_clear_output_bytes:
	clr		temp_2
	clr		temp_3
	jmp		put_regs_to_output_buffer

timer_load_output_bytes:
	lpm		temp_2,Z+
	lpm		temp_3,Z
	cpi		count,2											;������ ����� ����� �������� ������ (2-�� �������)
	brne	tm_get_output_set_point
	andi	temp_2,0xF7	
	jmp		put_regs_to_output_buffer
	
tm_get_output_set_point:
	cpi		count,5									;��������� ����� ���������� � ����� � ���������� � ��������� �����
	brne	put_regs_to_output_buffer
	sbrc	state_flag,SDBL							
	jmp		put_regs_to_output_buffer
	ori		temp_2,0x80					

put_regs_to_output_buffer:									;�������� �������� ��������� � ��������� ��������� ��� temph
	st		Y+,temp_2
	st		Y+,temp_3
	sbrc	state_flag,SDBL									;���� ��� �� �������� ��� ��� ������ ����� ��������
	jmp		timer_clear_sdbl
	sbr		state_flag,(1<<SDBL)							
	mov		ZL,XL
	mov		ZH,XH
	lsl		temph
	clr		temp_2
	add		ZL,temph
	adc		ZH,temp_2
	jmp		timer_get_ouput_data

timer_clear_sdbl:
	cbr		state_flag,(1<<SDBL)					;����� ��������� ���� ������ ����� �������� ��������� ����� �������� � ��� ���� ����� �������� �� ��������� 6 
	inc		count
	cpi		count,6
	brsh	exit_get_output_timer_mode
	jmp		next_timer_digit_code

exit_get_output_timer_mode:
/*	clr		count
	ldi		templ,0xCC
	call	Send_UART*/
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	7
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Sound_OFF:
	sbi		PORTB,0
	clr		templ
	out		TCCR0,templ
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	8
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Sound_1000Hz_ON:
	cbi		PORTB,0
	ldi		templ,(1<<CS00) | (1<<CS01) | (1<<WGM01) | (1<<COM00)
	out		TCCR0,templ
	ldi		templ,OCR0_1000Hz
	out		OCR0,templ
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	9
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Sound_400Hz_ON:
	cbi		PORTB,0
	ldi		templ,(1<<CS02) | (1<<WGM01) | (1<<COM00)
	out		TCCR0,templ
	ldi		templ,OCR0_400Hz
	out		OCR0,templ
ret
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							10
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_byte_to_DS1307:
	ldi		twi_packet_size,3
	clr		templ
	ldi		YL,LOW(TWI_BUFFER_OUT)			
	ldi		YH,HIGH(TWI_BUFFER_OUT)
	add		YL,byte_address
	adc		YH,templ
	ldi		templ,(DS1307_ADDRESS<<1)|write
	st		Y+,templ
	mov		templ,byte_address
	st		Y+,templ
	mov		templ,temph
	st		Y,templ	
	call	Start
	call	Wait_TWI_finish
ret
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							11
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

BCD_TO_HEX:
	mov		templ,temph
	andi	temph,0xF
	andi	templ,0xF0
	swap	templ										;� temph - �������, templ - �������							
next_increment:
	tst		templ
	breq	exit_bcd_to_hex
	subi	temph,-10
	dec		templ
	jmp		next_increment
exit_bcd_to_hex:	
ret
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							12
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

HEX_TO_BCD:
	clr		templ
	cpi		temph,100									//���� ����� ������ ��� ����� 100, ����� ��������������� �� ����
	brsh	exit_change_format
next_decrement:											//���������� ������� �� 10 � ������� �������� �������� � ���������, ������� - temph, ������� - templ
	cpi		temph,10									//������� � temph		
	brlo	next_format_operation
	subi	temph,10
	inc		templ
	jmp		next_decrement
next_format_operation:	
	swap	templ										//������� 4 ����� temph ������ ��������� ������� 4 ����� templ
	or		temph,templ
exit_change_format:	
ret
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							13
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Set_default_time:
	 ldi	YL,LOW(TWI_BUFFER_OUT)			
	 ldi	YH,HIGH(TWI_BUFFER_OUT)
	 ldi	templ,(DS1307_ADDRESS<<1)|write
	 st		Y+,templ
	 ldi	templ,0
	 st		Y+,templ	
	 ldi	templ,0
	 st		Y+,templ	
	 ldi	templ,0
	 st		Y+,templ
	 ldi	templ,0x16
	 st		Y+,templ
	 ldi	templ,0x7
	 st		Y+,templ	
	 ldi	templ,0x21
	 st		Y+,templ	
	 ldi	templ,0x7
	 st		Y+,templ
	 ldi	templ,0x19
	 st		Y,templ	
	 ldi	twi_packet_size,9
	 clr	byte_address
	 call	Start
	 call	Wait_TWI_finish
ret

Start_time:
	call	Read_packet
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	ld		templ,X
	cpi		templ,0x80
	brne	exit_start_time
	call	Set_default_time
exit_start_time:
ret

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							14
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Correct_time:

ret

.dseg

TEMP_OUTPUT_BUFFER:		.byte	24

OUTPUT_BUFFER:			.byte	24

TIMER_BUFFER:			.byte	6

.cseg

TIME_DIGIT_CATHODE:
		.db		0xFF,	0x0B,	0x09,	0x0B,	0xEF,	0x0D,	0xCF,	0x0F,	0x1D,	0x0F,	0xDF,	0x07,	0xFF,	0x07
//						0////			1////			2////			3////			4////			5////			6///
		.db		0x0F,	0x0B,	0xFF,	0x0F,	0xDF,	0x0F,	0x00,	0x00
//						7////			8////			9////			NA////

DATA_LETTER_CATHODE:
		.db		0x00,	0x00,	0x00,	0x00,	0x31,	0x90,	0x03,	0x4B,	0x20,	0xA0,	0x72,	0x2F
//						NL///			NL///			�////			�////			�////			�////			
		.db		0x31,	0x90,	0x51,	0x43,	0x20,	0xA0,	0x20,	0xE4,	0x20,	0xA0,	0x03,	0x4B,	0x31,	0x92,	0x51,	0x43,	0x11,	0x80,	0x72,	0x2F
//						�///			�///			�////			�////			�////			�////			�////			�////			�///			�///			

DATA_DIGIT_CATHODE:
		.db		0x53,	0x4B,	0x02,	0x08,	0x51,	0xAB,	0x52,	0xAB,	0x02,	0xE8,	0x52,	0xE3,	0x53,	0xE3
//						0////			1////			2////			3////			4////			5////			6///
		.db		0x02,	0x0B,	0x53,	0xEB,	0x52,	0xEB,	0x00,	0x00
//						7////			8////			9////			NA////



