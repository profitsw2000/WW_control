/*
�������� ������� ��� ������ � ���������������� ����������� UART
1. �������� ����� ������ �� ����, ���� ������ ��������� � �������� templ.
2. ��������� ��������� ���������� �� ���������� �������� ����� ������.
3. ��������� ��������� ���������� �� �������� ����� ������. �� ������ ����������� ��������� "������" ���������� ������, ���������������� � ������������ ������� � ������.
���� �������� ������ ������������ � ��������� ����� �� ������ ����� ���������� ������ + �������� ��������� ������.
4. ��������� ������ �� ���������� ������. ���� ���-�� ����������� ������ �� ���������� ������ ����� 9 (������� "������" ������ "������" ��� ������� �� 9),
���������� ��������� ������ �� ���������� ������. ����������� ���� ������ �� ������, ������������ � ��������� ������, 
����������� ��� �������� (��������� ���� � ������� = 0xCC). ���� ��� ��������� ����, �� ����������� 7 ���� ����������� �� ��������� ������.
��� ���� ����������� ����������� ����� �������, � ���� ����������� ����� � �����, ������ �� ���������� ������ 
UART_TEMP ���������� � ����� ��� ������ ������ ������ � ������ TWI_BUFFER_OUT.
5. ����������� ������ �� ���������� ������ UART_TEMP � ����� ��� ������ ������ ������ � ������ TWI_BUFFER_OUT. ������ ���� ������ TWI_BUFFER_OUT - ����� ������ + �������
������/������, ������ - ��������� ����� � ������ �������, ����������� - ����� ������ (����� 7).
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Send_UART:
	sbis	UCSRA,UDRE
	rjmp	Send_UART
	out		UDR,templ
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	2
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

UART_TX:
	push	templ
	push	temph
	in		templ,SREG
	push	templ

	cpi		count,7
	brsh	exit_uart_tx
	clr		temph
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	add		XL,count
	adc		XH,temph
	ld		templ,X
	call	Send_UART	

	inc		count

exit_uart_tx:	
	pop		templ
	out		SREG,templ
	pop		temph
	pop		templ
reti

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	3
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

UART_RX:
	push	temp_2
	push	templ
	push	temph
	push	XL
	push	XH
	push	YL
	push	YH
	in		templ,SREG
	push	templ

	in		templ,UDR
	call	Send_UART
	clr		temp_2
	ldi		XL,LOW(RX_HEAD)
	ldi		XH,HIGH(RX_HEAD)
	ld		temph,X
		
	ldi		YL,LOW(UART_IN)
	ldi		YH,HIGH(UART_IN)
	add		YL,temph
	adc		YH,temp_2
	st		Y,templ

	inc		temph
	andi	temph,0x3F
	st		X,temph

	pop		templ
	out		SREG,templ
	pop		YH
	pop		YL
	pop		XH
	pop		XL
	pop		temph
	pop		templ
	pop		temp_2
reti

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	4
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

UART_proc:
	ldi		XL,LOW(RX_HEAD)							;��������� ������
	ldi		XH,HIGH(RX_HEAD)
	ld		temph,X

	ldi		YL,LOW(RX_TAIL)							;��������� ������
	ldi		YH,HIGH(RX_TAIL)
	ld		templ,Y

	mov		temp_2,templ
	mov		temp_3,temph

	sub		temp_3,temp_2							;�������� ���������� ����������� ������ � ��������� ������
	andi	temp_3,0x3F									

	cpi		temp_3,9								;��������� ������ ����� ����������� ���� ���������� �� ����� 9 ����������� ������ (������ �������)
	brsh	uart_packet_income
	jmp		exit_uart_proc

uart_packet_income:
	clr		temp_3									;����������� ���� ������
	ldi		XL,LOW(UART_IN)							
	ldi		XH,HIGH(UART_IN)
	add		XL,templ
	adc		XH,temp_3
	ld		temp_2,X+

	cpi		temp_2,0xCC								;����������, �������� �� ��������� ���� ���������
	breq	packet_start_byte
	inc		templ									;���� ���, ��������� ��������� �������
	andi	templ,0x3F
	st		Y,templ
	jmp		UART_proc

packet_start_byte:									;���� ��������� ���� ���������, ������������ ����������� 8 ������ ���������� ������
	ldi		YL,LOW(UART_TEMP)							
	ldi		YH,HIGH(UART_TEMP)						;����� ������� � ���� ��������� �� ��������� �����, ����� �������� ����������� �����
	clr		temph									;� ������ � ������������ ������ �������� � ������ (����� ����� TWI_BUFFER_OUT)

next_uart_byte:
	ld		temp_3,X+
	st		Y+,temp_3
	add		temp_2,temp_3
	inc		temph
	cpi		temph,7
	brlo	next_uart_byte

	ld		temp_3,X
	cp		temp_2,temp_3
	breq	crc_is_good
	inc		templ
	andi	templ,0x3F
	ldi		YL,LOW(RX_TAIL)							;��������� ������
	ldi		YH,HIGH(RX_TAIL)
	st		Y,templ

	jmp		UART_proc

crc_is_good:
	subi	templ,-9
	andi	templ,0x3F
	ldi		YL,LOW(RX_TAIL)							;����������� ����� � �����, ��������� ��������� ������ �� 9 � �������� � ������
	ldi		YH,HIGH(RX_TAIL)
	st		Y,templ									
	
	call	Write_packet_to_TWI_buffer				;���������� ������ �� ���������� ������ � ����� �������� ������
	
exit_uart_proc:
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	5
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_packet_to_TWI_buffer:
	clr		temph
	ldi		XL,LOW(TWI_BUFFER_OUT)										;����� ������, �� �������� ������� ������ ��� ������ � ������
	ldi		XH,HIGH(TWI_BUFFER_OUT)
	ldi		YL,LOW(UART_TEMP)											;����� ���������� ������
	ldi		YH,HIGH(UART_TEMP)
	ldi		templ,(DS1307_ADDRESS<<1)|write								;������ ���� - ������� ������/������ + ����� �������
	st		X+,templ													;������ ���� - ��������� ����� � ������ �������
	clr		templ														;����������� ����� - ����� ������ ��� ������ � ������
	st		X+,templ
write_next_byte_to_twi_buffer:
	ld		templ,Y+
	st		X+,templ
	inc		temph
	cpi		temph,7
	brne	write_next_byte_to_twi_buffer	
	ldi		twi_packet_size,9
	clr		templ
	mov		byte_address,templ
	call	Start
	call	Wait_TWI_finish	

ret	

.dseg	

RX_HEAD:		.byte	1

RX_TAIL:		.byte	1

UART_IN:		.byte	64

UART_TEMP:		.byte	7

.cseg
