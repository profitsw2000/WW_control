/*
�������� ��������� ��� ������������� ������� �����

1. ������������� ������� �����. � ����� � ���, ��� � �������� ������ ����� � ������� ������������� �������, ��-�� ����������� �������� ������ ���������� 
����������, ��������� ����������� ����������� ������� ����������� DS1307. ������� ������ �����, � ����������� �����, ���������� ������������� �����. ��� �����
����� �������������� ���������� �������� ����� ������� � �������� �� ����� ��� ������ ���������� ������ �����.

2. ���������� �� ������ �������� ������������ ������������ (���� ������� � �������� �� �����) � ������ ����������� �������� � �����������
������. ������������ ����� ����� ��������� ����� � ������ ������ ���������.
*/

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							1
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Correct_time:
	ldi		XL,LOW(TIME_INACCURACY_SEC_PER_DAY_TEMP)					;����� �������� �������� ����� ������� � ����������� ������
	ldi		XH,HIGH(TIME_INACCURACY_SEC_PER_DAY_TEMP)
	ld		templ,X
	//�������� �������� ������ ����� - ���� �������� ������������� - �������, ����� - ������
	sbrs	templ,7														
	rjmp	clock_ahead
	
	
	clock_ahead:
	//���������� �������� �������
	ldi		temph,1
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	add		XL,count
	adc		XH,templ
	ld		templ,X		
ret

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							2
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Read_write_time_inaccuracy:	
	ldi		ZL,LOW(2*TIME_INACCURACY_SEC_PER_DAY_CONST)					;����� �������� �������� ����� ������� �� ����-������
	ldi		ZH,HIGH(2*TIME_INACCURACY_SEC_PER_DAY_CONST)
	lpm		templ,Z
	
	ldi		XL,LOW(TIME_INACCURACY_SEC_PER_DAY_TEMP)					;����� �������� �������� ����� ������� � ����������� ������
	ldi		XH,HIGH(TIME_INACCURACY_SEC_PER_DAY_TEMP)
	st		X,templ
ret

.dseg 

TIME_INACCURACY_SEC_PER_DAY_TEMP:	.byte	1

CORRECTION_FLAG:	.byte	1

.cseg

TIME_INACCURACY_SEC_PER_DAY_CONST:
		.db		0x06,	0x00

TIME_INACCURACY_MIN_PER_DAY_CONST:
		.db		0x06,	0x00
