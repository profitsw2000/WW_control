/*
��������� ��� ������ � ������������� ���������� �� ������������ �������.
1.��������� ������� 1 - ���������� ������ 10 ���.
2.���������� ������� 1.
3.���������� ������� 2.  � ���������� ���������������� ���������� t_count. � ����������� �� �������� ������ ���������� ��������������� ����� 
RPTF (�������� ������ ��� ������ �� ���������),T2IF (������� ������������ ���������� �������) � WWFF (��� �������� � ������ ���������).
4.���������� ������ �� ��������� ������ � �������� � �������� sdi_high_time, sdi_low_time,
sdi_high_data � sdi_low_data. ����� ��� �������� ����������� ��������� �������:
-����� sdi_low_time = digit_number*2,
-����� sdi_high_time = digit_number*2+1,
-����� sdi_low_data = digit_number*2+12,
-����� sdi_high_data = digit_number*2+13.
��� ����, ����� ������ ������ ���� �� ����� ������� 0, � ������� ����� ����������� ������ ��� ������ �� ���� ������ �������� � 
����������� �� ������ ���������� �����. 
5.��������� ���������� ������� 1. ������������ ��������� ������� �� ��� �/�� MBI5026, ��������� �������� ������ �� ��������� � ����������� �������.
����� �������� ���� ������ ����������� ������ LE � OE � ����� �� ���� ������ PORTA ������ �� �������� �����.
*/


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								1
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 Timer1_ON:
	ldi		templ,(1<<CS10) | (1<<WGM12)
	out		TCCR1B,templ
	ldi		templ,LOW(OCR1_REG)
	ldi		temph,HIGH(OCR1_REG)	
	out		OCR1AL,templ
	out		OCR1AH,temph
	in		templ,TIMSK
	sbr		templ,(1<<OCIE1A)
	out		TIMSK,templ
	clr		mbi_clk_counter
 ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								2
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 Timer1_OFF:
	clr		templ
	out		TCCR1B,templ	
 ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								3
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//���������� ������� 2
Timer2:
//���������� ��������� � �����	
	push	templ
	push	temph
	in		templ,SREG
	push	templ												//7
	
//��������� ������� ������������ �������	
	inc		t_count												//8

//��� ��������� � ������ ���������	
	cpi		t_count,0x80
	brlo	set_flicking_flag
	cbr		state_flag,(1<<WWFF)
	jmp		timer2_ww_mode
set_flicking_flag:
	sbr		state_flag,(1<<WWFF)

//����������� ������ ������
timer2_ww_mode:	
	sbrs	state_flag,WWVM
	jmp		timer2_clock_mode
	sbrc	state_flag,WWSM
	jmp		timer2_clock_mode
//����� �������	
	cpi		t_count,F_TIMER2_BT
	brlo	read_encoder_state
	clr		t_count
	sbr		state_flag,(1<<RPTF)	
	jmp		read_encoder_state

//����� �����
timer2_clock_mode:
	mov		templ,t_count
	andi	templ,0x3E
	cpi		templ,0x3E
	brne	read_encoder_state
	sbr		state_flag,(1<<RPTF)	

//��������� �������� ��������
read_encoder_state:
	in		templ,PIND											;������� ��������� �����, � �������� ��������� �������
	andi	templ,0x1C
	sbr		templ,(1<<T2IF)
	andi	enc_state,3
	or		enc_state,templ
	

//�������� ����� �������� �����
change_digit_number:	
	//call	Get_Next_Digit

exit_timer2:
//��������� ����		
	pop		templ
	out		SREG,templ
	pop		temph
	pop		templ
reti


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								4
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 Get_Next_Digit:
	ldi		templ,6
	inc		digit_count
	cp		digit_count,templ
	brlo	digit_lower_six
	clr		digit_count
digit_lower_six:
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	mov		temph,digit_count							;����� �� ������� ������� ������������� ����� ��������� �����
	lsl		temph										;�������� �� 2
	clr		templ
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	add		YL,temph
	adc		YH,templ
	ld		sdi_low_time,Y+
	ld		sdi_high_time,Y
	subi	temph,-12
	clr		templ
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	add		YL,temph
	adc		YH,templ
	ld		sdi_low_data,Y+
	ld		sdi_high_data,Y
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	out		PORT_ANODE,templ							;���������� �� ������� ����
	sbi		PORT_CATHODE,OE
	clr		mbi_clk_counter

	
/*	ldi		templ,0xAA
	call	Send_UART*/
/*	mov		templ,round_work
	call	Send_UART*/
/*	mov		templ,sdi_low_time
	call	Send_UART
	mov		templ,sdi_high_time
	call	Send_UART
	mov		templ,sdi_low_data
	call	Send_UART
	mov		templ,sdi_high_data
	call	Send_UART*/

	call	Timer1_ON									;�������� ������ 1 (������ � �/�� MBI5026)

ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								5
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 Timer1:
	push	ZL
	push	ZH	
	push	templ
	push	temph
	in		templ,SREG
	push	templ	
		
	sbrc	mbi_clk_counter,5
	rjmp	data_latch_end								//����� �������� �������� 32
	sbrc	mbi_clk_counter,0				
	rjmp	set_clk_line								//������� �������� ������
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	sbrs	sdi_high_time,7								//���������� ����� sdi � ������������ �� ��������� ������ �������� ���� sdi_high
	cbi		PORT_CATHODE,SDI_TIME
	sbrc	sdi_high_time,7
	sbi		PORT_CATHODE,SDI_TIME
	sbrs	sdi_high_data,7							
	cbi		PORT_CATHODE,SDI_DATA
	sbrc	sdi_high_data,7
	sbi		PORT_CATHODE,SDI_DATA
 
 	rol		sdi_low_time								//�������� �� 1 ��� �������� ��������� sdi
	rol		sdi_high_time 
	rol		sdi_low_data
	rol		sdi_high_data 

	cbi		PORT_CATHODE,CLK						//���������� � 0 ����� clk � �����
	rjmp	exit_timer1
 set_clk_line:
	sbi		PORT_CATHODE,CLK						//���������� � 1 ����� clk � �����
	rjmp	exit_timer1	
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //����� ������ ��������, ����� ����� ���������� ��������� �� �������� ����� ����� LE � 1
 //� ����� ����� OE � 0
 data_latch_end:
 	sbrc	mbi_clk_counter,1							//���� ������� ����� 32(bit0=0, bit1=0) - ���������� 0 �� clk, ���� 33(bit0=1, bit1=0) ���������� LE 1				
	rjmp	line_le_oe
	sbrc	mbi_clk_counter,0	
	rjmp	set_le_line
	cbi		PORT_CATHODE,CLK
	cbi		PORT_CATHODE,SDI_TIME
	cbi		PORT_CATHODE,SDI_DATA
	rjmp	exit_timer1
 set_le_line:
	sbi		PORT_CATHODE,LE
	rjmp	exit_timer1
 //���� ������� ����� 34(bit0=0, bit1=1) - ���������� 0 �� LE, ���� 35(bit0=1, bit1=1) ���������� 0 �� OE
 line_le_oe:
	sbrc	mbi_clk_counter,0	
	rjmp	clr_oe_line
	cbi		PORT_CATHODE,LE
	rjmp	exit_timer1
 clr_oe_line:
	cbi		PORT_CATHODE,OE
	clr		templ
	ldi		ZL,LOW(2*ANODE_OUTPUT)						;��������� ������ ��� ������ �� ����
	ldi		ZH,HIGH(2*ANODE_OUTPUT)
	add		ZL,digit_count
	adc		ZH,templ
	lpm		templ,Z
	out		PORT_ANODE,templ
	call	Timer1_OFF

 //�����, �������������� ��������������� �������
 exit_timer1:
	inc		mbi_clk_counter	
	pop		templ
	out		SREG,templ
	pop		temph
	pop		templ
	pop		ZH
	pop		ZL
 reti

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////						6		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Timer2_ON:
/*	ldi		templ,(1<<COM21) | (1<<WGM21) | (1<<WGM20) | PRESCALER_0
	out		TCCR2,templ
	ldi		templ,120
	out		OCR2,templ
	ldi		templ,(1<<TOIE2)
	out		TIMSK,templ*/
ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////						7		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Timer2_OFF:
/*	clr		templ
	out		TCCR2,templ*/
ret



 ANODE_OUTPUT:
	.db		0x04,	0x08,	0x10,	0x20,	0x40,	0x80

