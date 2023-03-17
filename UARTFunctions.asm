/*
Основные функции для работы с последовательным интерфейсом UART
1. Отправка байта данных по УАРТ, байт данных находится в регистре templ.
2. Процедура обработки прерывания по завершению отправки байта данных.
3. Процедура обработки прерывания по принятию байта данных. Из памяти считывается указатель "головы" кольцевого буфера, инкрементируется и записывается обратно в память.
Байт принятых данных записывается в кольцевой буфер по адресу метки кольцевого буфера + значение указателя головы.
4. Обработка данных из кольцевого буфера. Если кол-во несчитанных данных из кольцевого буфера более 9 (регистр "головы" больше "хвоста" как минимум на 9),
происходит обработка данных из кольцевого буфера. Считывается байт данных по адресу, содержащемся в указателе хвоста, 
проверяется его значение (стартовый байт в посылке = 0xCC). Если это стартовый байт, то последующие 7 байт размещаются во временном буфере.
При этом проверяется контрольная сумма посылки, и если контрольная сумма в норме, данные из временного буфера 
UART_TEMP копируются в буфер для записи пакета данных в датчик TWI_BUFFER_OUT.
5. Копирование данных из временного буфера UART_TEMP в буфер для записи пакета данных в датчик TWI_BUFFER_OUT. Первый байт буфера TWI_BUFFER_OUT - адрес дачика + команда
чтение/запись, второй - начальный адрес в памяти датчика, последующие - байты данных (всего 7).
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
	ldi		XL,LOW(RX_HEAD)							;указатель головы
	ldi		XH,HIGH(RX_HEAD)
	ld		temph,X

	ldi		YL,LOW(RX_TAIL)							;указатель хвоста
	ldi		YH,HIGH(RX_TAIL)
	ld		templ,Y

	mov		temp_2,templ
	mov		temp_3,temph

	sub		temp_3,temp_2							;проверка количества несчитанных байтов в кольцевом буфере
	andi	temp_3,0x3F									

	cpi		temp_3,9								;обработка данных будет происходить если накопилось не менее 9 несчитанных байтов (размер посылки)
	brsh	uart_packet_income
	jmp		exit_uart_proc

uart_packet_income:
	clr		temp_3									;считывается байт данных
	ldi		XL,LOW(UART_IN)							
	ldi		XH,HIGH(UART_IN)
	add		XL,templ
	adc		XH,temp_3
	ld		temp_2,X+

	cpi		temp_2,0xCC								;определить, является ли считанный байт стартовым
	breq	packet_start_byte
	inc		templ									;если нет, повторить процедуру сначала
	andi	templ,0x3F
	st		Y,templ
	jmp		UART_proc

packet_start_byte:									;если считанный байт стартовый, обрабатываем последующие 8 байтов кольцевого буфера
	ldi		YL,LOW(UART_TEMP)							
	ldi		YH,HIGH(UART_TEMP)						;байты времени и даты поместить во временный буфер, после проверки контрольной суммы
	clr		temph									;в случае её правильности данные записать в датчик (через буфер TWI_BUFFER_OUT)

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
	ldi		YL,LOW(RX_TAIL)							;указатель хвоста
	ldi		YH,HIGH(RX_TAIL)
	st		Y,templ

	jmp		UART_proc

crc_is_good:
	subi	templ,-9
	andi	templ,0x3F
	ldi		YL,LOW(RX_TAIL)							;контрольная сумма в норме, увеличить указатель хвоста на 9 и записать в память
	ldi		YH,HIGH(RX_TAIL)
	st		Y,templ									
	
	call	Write_packet_to_TWI_buffer				;переписать данные из временного буфера в буфер отправки данных
	
exit_uart_proc:
ret


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	5
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_packet_to_TWI_buffer:
	clr		temph
	ldi		XL,LOW(TWI_BUFFER_OUT)										;адрес буфера, из которого берутся данные для записи в датчик
	ldi		XH,HIGH(TWI_BUFFER_OUT)
	ldi		YL,LOW(UART_TEMP)											;адрес временного буфера
	ldi		YH,HIGH(UART_TEMP)
	ldi		templ,(DS1307_ADDRESS<<1)|write								;первый байт - команда чтение/запись + адрес датчика
	st		X+,templ													;второй байт - начальный адрес в памяти датчика
	clr		templ														;последующие байты - байты данных для записи в датчик
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
