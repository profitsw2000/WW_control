/*
�������� ��������� ��� ������ � eeprom
1. ���������� �������� ���������� ������� (5 ���������� - ����������������� ������ (������� � ������), ����������������� ������ (������� � ������)
� ���������� �������) �� eeprom � ������ �� � ��������������� ��������. ������ � eeprom ��������� � ������� ���������������. �������������� ����������
������������ � ��� ������ ������� ������ � ��������� ���������� ������.
� templ ���������� ����� ������������ ��������� (5 ����). ��� ������� ��������� ����������� �� eeprom 3 �����, �����������, ��� ��� ��� �����. 
���� �����: 
- ��������� �� eeprom �������� ����������� � ���;
- ����������� � ����������� ��������� ��������;
- ��� �������� ��������� ������ �� ��� �� ������ TIMER_PARAMETERS_TEMP �������������� � ��������������� ��������,
���� �� ����� ��� �������� �������� �������� (�������� �������� ������ > 59):
-����� �� ��������� ��� ������ � ��������������� ��������. ����� �������, ��������� ������� ��������� �� ���������.
������� ������������ ���������� � ������:
0 - min_work,
1 - sec_work,
2 - min_rest,
3 - sec_rest,
4 - round_work

2. ������ ����� ������ �� eeprom. � XH:XL - ����� ������������ �����. � YL - ��������� ����

3. ������ ��������� � ��� �� ������ TIMER_PARAMETERS_TEMP + templ. � templ - ������������� �����, � temph - ���� ��� ������, temp_2 - ��������.

4. ���������� �� ��� �� ������ TIMER_PARAMETERS_TEMP � �������� � ����������� �������.

5. ������ ���������� ������� � eeprom � ������� ���������������.

6. ������ ����� � eeprom. � XH:XL - ����� ������������� �����. � YL - ������������ ����.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Read_timer_parameters_from_eeprom:
	ldi		templ,0
	
next_param_from_eeprom:
	mov		XL,templ										;���������� ������� �����
	clr		XH
	call	Read_byte_from_eeprom
	mov		temph,YL
	subi	XL,-EEPROM_PAGE_SIZE								;���������� ������� �����
	call	Read_byte_from_eeprom
	mov		temp_2,YL
	subi	XL,-EEPROM_PAGE_SIZE								;���������� �������� �����
	call	Read_byte_from_eeprom
	mov		temp_3,YL

	//�������� ���������� ����� - ���� ����� ��� �������� �������� ��������
	cp		temph,temp_2
	brne	exit_read_timer_parameters_from_eeprom
	cp		temp_2,temp_3
	brne	exit_read_timer_parameters_from_eeprom
	sbrs	templ,0											;���� ������� ���=1, �� ���� ������� ������� 
	rjmp	check_minutes_or_rounds							;���� ������� ���=1, �� ���� ������� ������ ��� ������
	cpi		temph,60										;������ �.�. ������ 60
	brsh	exit_read_timer_parameters_from_eeprom
	rjmp	check_param_number
check_minutes_or_rounds:
	cpi		temph,100										;����� ��� ������� �.�. ������ 100
	brsh	exit_read_timer_parameters_from_eeprom
			
check_param_number:
	call	Write_timer_param_to_RAM						;�������� ��������� �������� �������� � ���
	inc		templ											;��������� ��������
	cpi		templ,5
	brlo	next_param_from_eeprom							;��� ���������� �� ��� ��������� � ��������������� ��������
	call	Write_timer_params_from_RAM_to_registers
			
exit_read_timer_parameters_from_eeprom:
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	2
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Read_byte_from_eeprom:

	sbic	EECR,EEWE
	rjmp	Read_byte_from_eeprom
	out		EEARH,XH
	out		EEARL,XL
	sbi		EECR,EERE
	in		YL,EEDR

ret

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							3
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_timer_param_to_RAM:
	clr		temp_2
	ldi		ZL,LOW(TIMER_PARAMETERS_TEMP)					;����� �������� ��������� ������� � ����������� ������
	ldi		ZH,HIGH(TIMER_PARAMETERS_TEMP)
	add		ZL,templ
	adc		ZH,temp_2
	st		Z,temph
ret

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							4
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_timer_params_from_RAM_to_registers:
	ldi		ZL,LOW(TIMER_PARAMETERS_TEMP)					;����� �������� ���������� ������� � ����������� ������
	ldi		ZH,HIGH(TIMER_PARAMETERS_TEMP)
	ld		min_work,Z+
	ld		sec_work,Z+
	ld		min_rest,Z+
	ld		sec_rest,Z+
	ld		round_work,Z
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							5
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_timer_parameters_to_eeprom:
	
	clr		XL
	clr		XH
	clr		templ

write_timer_params_to_next_page:

	cpi		temph,0
	breq	start_write_params_to_eeprom
	dec		temph
	ldi		temp_2,EEPROM_PAGE_SIZE
	clr		temp_3
	add		XL,temp_2
	adc		XH,temp_3
	rjmp	write_timer_params_to_next_page

start_write_params_to_eeprom:

	//������ ������
	mov		YL,min_work
	call	Write_byte_to_eeprom	
	//������� ������
	adiw	XL,1
	mov		YL,sec_work
	call	Write_byte_to_eeprom
	//������ ������
	adiw	XL,1
	mov		YL,min_rest
	call	Write_byte_to_eeprom
	//������� ������
	adiw	XL,1
	mov		YL,sec_rest
	call	Write_byte_to_eeprom
	//���������� �������
	adiw	XL,1
	mov		YL,round_work
	call	Write_byte_to_eeprom

	inc		templ
	mov		temph,templ
	clr		XL
	clr		XH
	cpi		templ,3
	brlo	write_timer_params_to_next_page
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							6
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_byte_to_eeprom:
	
	sbic	EECR,EEWE
	rjmp	Write_byte_to_eeprom

	out		EEARH, XH
	out		EEARL, XL
	out		EEDR, YL

	sbi		EECR,EEMWE

	sbi		EECR,EEWE
	
ret

.dseg 

TIMER_PARAMETERS_TEMP:	.byte	5

.cseg