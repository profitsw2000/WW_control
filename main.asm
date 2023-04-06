;
; WW_control.asm
;
/*
��������� ���������� ���������� ������.
*/
; Created: 30.06.2019 11:50:16
; Author : Asus
;


.def	seconds					=	r0
.def	minutes					=	r1
.def	round					=	r2
.def	sec_work				=	r3
.def	min_work				=	r4
.def	round_work				=	r5
.def	sec_rest				=	r6
.def	min_rest				=	r7
.def	sdi_high_time			=	r8
.def	sdi_low_time			=	r9
.def	sdi_high_data			=	r10
.def	sdi_low_data			=	r11
.def	mbi_clk_counter			=	r12
.def	digit_count				=	r13
.def	set_segm				=	r14
.def	byte_address			=	r15
.def	templ					=	r16
.def	temph					=	r17
.def	temp_2					=	r18
.def	temp_3					=	r19
.def	state_flag				=	r20
.def	status					=	r21
.def	twi_packet_size			=	r22
.def	count					=	r23
.def	t_count					=	r24
.def	enc_state				=	r25

.equ	WWVM					=	0											//Wall Watch Visual Mode - clock(0) or timer(1) 
.equ	WWSM					=	1											//Wall Watch Set Mode - not set(0) or set (1)
.equ	WWFF					=	2											//Wall Watch Flicking Flag - light on(0) or off(1)
.equ	SDBL					=	3											//Second Digit Bytes Load - first(0) or second(1)
.equ	RPTF					=	4											//Read Packet Timer Flag read (1) or not read(0)
.equ	BTON					=	5											//Boxing Timer ON timer on(1) or off(0)
.equ	BTRT					=	6											//Boxing Timer Rest Time rest(1) or work(0)
.equ	BTPS					=	7											//Boxing Timer PauSe pause(1) or play(0)
.equ	EMPF					=	6											//Encoder Minus Plus Flag - parameter minus(0) or plus(1)
.equ	T2IF					=	7											//Timer2 Interrupt Flag
.equ	BUTTON					=	2
.equ	ENC_PLUS				=	3
.equ	ENC_MINUS				=	4

.equ	F_CPU					=	16000000
.equ	F_TWI					=	100000
.equ	F_TIMER2_CLK			=	244
.equ	F_TIMER2_BT				=	244
.equ	F_1000Hz				=	1000
.equ	F_400Hz					=	400
.equ	F_TIMER1				=	100000
.equ	OCR0_1000Hz				=	((F_CPU)/(2*256*F_1000Hz))-1
.equ	OCR0_400Hz				=	((F_CPU)/(2*256*F_400Hz))-1
.equ	OCR1_REG				=	((F_CPU)/(F_TIMER1))-1
.equ	BAUD_RATE				=	2400
.equ	TWI_BAUD				=	(F_CPU/(2*F_TWI))-8
.equ	USART_REG				=	(F_CPU/(16*BAUD_RATE))-1
.equ	PRESCALER_2_CLK			=	(LOG2((F_CPU)/(256*F_TIMER2_CLK))) - 2
.equ	PRESCALER_2_BT			=	(LOG2((F_CPU)/(256*F_TIMER2_BT))) - 2
.equ	BT_MAX_TIME				=	600												//максимальное время нахождения в режиме выключенного бокс. таймера
.equ	PORT_ANODE				=	PORTC
.equ	PORT_CATHODE			=	PORTA
.equ	DDR_ANODE				=	DDRC
.equ	DDR_CATHODE				=	DDRA
.equ	OE						=	1
.equ	CLK						=	3
.equ	LE						=	4
.equ	SDI_TIME				=	2
.equ	SDI_DATA				=	5

//eeprom
.equ	EEPROM_PAGE_SIZE		=	64

.org	0
jmp		reset
.org	OVF2addr
jmp		Timer2
.org	OC1Aaddr
jmp		Timer1
.org	URXCaddr
jmp		UART_RX
.org	UTXCaddr
jmp		UART_TX
.org	TWIaddr
jmp		TWI_int


reset:
//��������� ����� 
ldi		templ,LOW(RAMEND)
ldi		temph,HIGH(RAMEND)
out		SPL,templ
out		SPH,temph
//��������� ������� 2
ldi		templ,(1<<COM21) | (1<<COM20) | (1<<WGM21) | (1<<WGM20) | PRESCALER_2_CLK
out		TCCR2,templ
ldi		templ,3
out		OCR2,templ
ldi		templ,(1<<TOIE2)
out		TIMSK,templ
//��������� TWI
ldi		templ,TWI_BAUD
out		TWBR,templ
clr		templ
out		TWSR,templ
//��������� UART
ldi		templ,(1<<RXCIE) | (1<<RXEN) | (1<<TXEN)// | (1<<TXCIE)
out		UCSRB,templ
ldi		templ,(1<<URSEL) | (1<<UCSZ1) | (1<<UCSZ0)
out		UCSRC,templ
ldi		templ,LOW(USART_REG)
ldi		temph,HIGH(USART_REG)
out		UBRRH,temph
out		UBRRL,templ
 //��������� ���, ������������ - 128, ������ - �������
 ldi	templ,(1<<REFS0) | (1<<ADLAR)
 out	ADMUX,templ
 ldi	templ,(1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
 out	ADCSRA,templ
//��������� ������ ��
sbi		DDRB,0
sbi		PORTB,0
sbi		DDRB,3
sbi		PORTD,BUTTON
sbi		PORTD,ENC_PLUS
sbi		PORTD,ENC_MINUS
sbi		DDRD,7
//sbi		PORTD,7
ldi		templ,0xFC
out		DDR_ANODE,templ
ldi		templ,(1<<OE) | (1<<CLK) | (1<<LE) | (1<<SDI_TIME) | (1<<SDI_DATA)
out		DDR_CATHODE,templ
//���������� ��������� ����������
sei
clr		set_segm
clr		state_flag
clr		t_count
clr		seconds
clr		minutes
clr		round
inc		round
ldi		templ,0
mov		sec_work,templ
mov		sec_rest,templ
ldi		templ,2
mov		min_work,templ
ldi		templ,1
mov		min_rest,templ
ldi		templ,12
mov		round_work,templ
call	Read_timer_parameters_from_eeprom				;������� �������� ��������� �������
clr		templ
ldi		XL,LOW(RX_HEAD)							;��������� ������
ldi		XH,HIGH(RX_HEAD)
st		X,templ	
ldi		YL,LOW(RX_TAIL)							;��������� ������
ldi		YH,HIGH(RX_TAIL)
st		Y,templ

jmp		program_begin

.include	"TWI_functions.asm"
.include	"MainFunctions.asm"
.include	"EncoderFunctions.asm"
.include	"Timers.asm"
.include	"UARTFunctions.asm"
.include	"ADC.asm"
.include	"TimeCorrect.asm"
.include	"EEPROMFunctions.asm"

program_begin:

call	Start_time
call	Read_write_time_inaccuracy						;������� �������� ����� ������� � �������� �� ����� �� ����-������ � ������������ � ����������� ������
call	Clear_timer_mode_counter						;обнулить счетчик времени незапущенного таймера

main:
//����� ������������ ������� ������ ����������� ��������� �������� ������ ��� ������ �� ���������
	sbrs	enc_state,T2IF
	jmp		read_next_packet_main
	call	Get_Next_Digit
	call	Encoder_proc
read_next_packet_main:
	sbrs	state_flag,RPTF
	jmp		main
//���������� ����� ������ ��������� �����
	sbrs	state_flag,WWVM
	call	Clock_mode_proc							//����� �����
	sbrc	state_flag,WWVM
	call	Timer_mode_proc							//����� �������
	call	UART_proc
	call	Set_brightness

jmp	main




