/*
�������� ������� ��� ������ � TWI
*/

 .equ	DS1307_ADDRESS		=	104
 .equ	write				=	0
 .equ	read				=	1
 .equ	TWSR_MASK			=	0xFC
 .equ	TWI_NEED_ANSW		=	(1<<TWEA)
 .equ	TWI_NO_NEED_ANSW	=	(0<<TWEA)
// ����� ��������� ����                     
 .equ	TWI_START			=	0x08  // START has been transmitted  
 .equ	TWI_REP_START		=	0x10  // Repeated START has been transmitted
 .equ	TWI_ARB_LOST		=	0x38  // Arbitration lost

// ��������� ���� �������� �����������                     
 .equ	TWI_MTX_ADR_ACK     =	0x18  // SLA+W has been tramsmitted and ACK received
 .equ	TWI_MTX_ADR_NACK    =	0x20  // SLA+W has been tramsmitted and NACK received 
 .equ	TWI_MTX_DATA_ACK    =	0x28  // Data byte has been tramsmitted and ACK received
 .equ	TWI_MTX_DATA_NACK   =	0x30  // Data byte has been tramsmitted and NACK received 

// ��������� ���� �������� ��������� 
 .equ	TWI_MRX_ADR_ACK     =	0x40  // SLA+R has been tramsmitted and ACK received
 .equ	TWI_MRX_ADR_NACK    =	0x48  // SLA+R has been tramsmitted and NACK received
 .equ	TWI_MRX_DATA_ACK    =	0x50  // Data byte has been received and ACK tramsmitted
 .equ	TWI_MRX_DATA_NACK   =	0x58  // Data byte has been received and NACK tramsmitted


 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 //�������� ���������� ����� � ���������� ����������
 Start:
 ;�������� ���� ����� ������������	
	in		templ,TWCR
	sbrc	templ,(1<<TWIE)
	rjmp	Start
 ;������ ������ � ������� ����������
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWSTA)
	out		TWCR,templ
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //���������� ���������� TWI   
 TWI_int:
	push	templ
	push	temph	
 ;���������� ���������� �������� � ��� ������������
	in		status,TWSR
	andi	status,TWSR_MASK
 ;���� ���������� ������� ������������� ������, ���������� ������, �������� ��������
 ;������ ��� ����� ������ ���������� ������� � ������� ���������� �������� ����. ����� ��� ������������ ����
	cpi		status,TWI_START
	breq	tranceive
	cpi		status,TWI_REP_START
	breq	tranceive
	cpi		status,TWI_MTX_ADR_ACK
	breq	tranceive
	cpi		status,TWI_MTX_DATA_ACK
	brne	status_check_1
 tranceive:
	call	Send_byte	
	rjmp	exit_twi_int 
 ;��� �������� �������� ����� ������ � �������������� � ����������� �� ������ ��������� ����� 
 ;������ �������������� � ��������������� ������� � ����� ���������� �������, ������� ����� �����������
 ;����� ��� �������� �������� ������ � ������� �������
 status_check_1:
	cpi		status,TWI_MRX_DATA_ACK
	brne	receive
	call	Read_byte
	rjmp	exit_twi_int
 receive:
	cpi		status,TWI_MRX_ADR_ACK
	brne	status_check_2
	dec		byte_address
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWEA)
	out		TWCR,templ
	rjmp	exit_twi_int 
 status_check_2:
 ;���� ������ ���� ��� ������������� - ����������� ���� � ����������� ����
	cpi		status,TWI_MRX_DATA_NACK
	brne	status_check_3
	call	Read_byte
	rjmp	exit_twi_int 
 status_check_3:
 ;��������� �������� ����������� ��� ������������� ������
 ;������ ����������
	cpi		status,TWI_ARB_LOST
	brne	status_check_4
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWSTA)
	out		TWCR,templ
	rjmp	exit_twi_int
 status_check_4:	
 ;��� ������� ����� SLA+W � �� �������� �������������
 ;��� ������� ����� SLA+R � �� �������� �������������    
 ;��� ������� ���� ������ � �� �������� �������������
 ;������ �� ���� ��-�� ����������� ��������� ����� ��� ����
	ldi		templ,(1<<TWEN)|(0<<TWIE)|(0<<TWINT)|(0<<TWEA)|(0<<TWSTA)|(0<<TWSTO)|(0<<TWWC)	;������ ����������
	out		TWCR,templ
 exit_twi_int:	
	pop		temph
	pop		templ
 reti
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //�������� ����� � ����������� �� ������ ����������� ����� ��������� � �������� byte_address
 Send_byte:
	tst		twi_packet_size					;���������� ��������� ���� � �������
	breq	last_byte
	ldi		YL,LOW(TWI_BUFFER_OUT)			;��������� ���� �� ����, ����� ����� - � �������� byte_address
	ldi		YH,HIGH(TWI_BUFFER_OUT)
	clr		templ
	add		YL,byte_address
	adc		YH,templ
	ld		templ,Y
	out		TWDR,templ										;�������� ����������� ����� � ������� ������ TWI
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)			;�������� �����
	out		TWCR,templ
	inc		byte_address									;���������������� ����� ��� �������� ����. �����
	dec		twi_packet_size							
	rjmp	exit_send
 //���� ��������� ���� ��������� - ������������ ����
 last_byte:
	ldi		templ,(1<<TWEN)|(1<<TWINT)|(1<<TWSTO)|(0<<TWIE)
	out		TWCR,templ
 exit_send:
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //������ ����� � ������ ��������� ����� � ���� � ������������ � ��� ������� � �������,
 //������� ������ � �������� byte_address 
 Read_byte:
	tst		twi_packet_size
	brne	not_last_byte_in
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWINT)|(1<<TWSTO)|(0<<TWIE)
	out		TWCR,templ
	rjmp	exit_read
 not_last_byte_in:
	cpi		twi_packet_size,1
	brne	not_pre_last_byte_in
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(0<<TWEA)
	out		TWCR,templ
	rjmp	exit_read
 not_pre_last_byte_in:
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWEA)
	out		TWCR,templ	
 exit_read:
	ldi		YL,LOW(TWI_BUFFER_IN)			;��������� ���� � ����, ����� ����� ���� - � �������� byte_address
	ldi		YH,HIGH(TWI_BUFFER_IN)
	clr		templ
	add		YL,byte_address
	adc		YH,templ
	st		Y,temph	
	dec		twi_packet_size
	inc		byte_address
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //������ ������ ������ �� ������ ������� � ������ �� � ����� ����.
 //������ ���������� � �������� ������, ���������� ����������� ���� - 7.
 //����� ������� ����� � ���� �� ������, ��������� ������ TWI_BUFFER_IN
 //����� ������� ��������� ������ ������ ����-�� ��������������� � 0,
 //��� ����� ���������� ��������� 2 ����� - ����� ����-�� � 0 

 Read_packet:
	clr		templ
	out		PORT_ANODE,templ
	//��������� ��������� �� 0
	ldi		twi_packet_size,2						
	clr		byte_address
	ldi		YL,LOW(TWI_BUFFER_OUT)					;�������� ����� � ���� � �������� ���� ����� ���������� � 0
	ldi		YH,HIGH(TWI_BUFFER_OUT)	
	ldi		templ,(DS1307_ADDRESS<<1)|write			;����� ����������(���� ��� ������)						
	st		Y+,templ
	clr		templ						
	st		Y,templ
	call	Start
	call	Wait_TWI_finish
	//������ ������
	ldi		twi_packet_size,8						;7 ������ ����������� ������ � 1 ���� ��� ������
	clr		byte_address							;������ ������ � �������� ������
	ldi		templ,(DS1307_ADDRESS<<1)|read			;����� ����������(���� ��� ������)
	ldi		YL,LOW(TWI_BUFFER_OUT)					;�������� ����� � ���� � �������� ���� ����� ����������
	ldi		YH,HIGH(TWI_BUFFER_OUT)
	st		Y,templ
	call	Start
	call	Wait_TWI_finish
 ret

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //�������� ��������� ������ TWI
 Wait_TWI_finish:
	in		templ,TWCR
	sbrc	templ,TWIE
	rjmp	Wait_TWI_finish
 ret

 .dseg

 TWI_BUFFER_OUT:	.byte	16

 TWI_BUFFER_IN:		.byte	16

 .cseg
