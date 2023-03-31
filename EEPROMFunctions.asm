/*
Основные процедуры для работы с eeprom
1. Считывание основных параметров таймера (5 параметров - продолжительность раунда (секунды и минуты), продолжительность отдыха (секунды и минуты)
и количество раундов) из eeprom и запись их в соответствующие регистры. Данные в eeprom храняться с двойным резервированием. Соответственно считывание
производится с трёх разных адресов памяти и сравнение полученных данных.
В templ содержится номер считываемого параметра (5 штук). Для каждого параметра считывается из eeprom 3 байта, проверяется, что все они равны. 
Если равны: 
- считанное из eeprom значение записвается в ОЗУ;
- считывается и проверяется следующий параметр;
- при успешном окончании данные из ОЗУ по адресу TIMER_PARAMETERS_TEMP переписываются в соответствующие регистры,
если не равны или содержат неверное значение (например значение секунд > 59):
-выход из процедуры без записи в соответствующие регистры. Таким образом, параметры таймера останутся по умолчанию.
Порядок расположения параметров в памяти:
0 - min_work,
1 - sec_work,
2 - min_rest,
3 - sec_rest,
4 - round_work

2. Чтение байта двнных из eeprom. В XH:XL - адрес считываемого байта. В YL - считанный байт

3. Запись параметра в ОЗУ по адресу TIMER_PARAMETERS_TEMP + templ. В templ - относительный адрес, в temph - байт для записи, temp_2 - портится.

4. Перезапись из ОЗУ по адресу TIMER_PARAMETERS_TEMP в регистры с параметрами таймера.

5. Запись параметров таймера в eeprom с двойным резервированием.

6. Запись байта в eeprom. В XH:XL - адрес записываемого байта. В YL - записываемый байт.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Read_timer_parameters_from_eeprom:
	ldi		templ,0
	
next_param_from_eeprom:
	mov		XL,templ										;считывание первого байта
	clr		XH
	call	Read_byte_from_eeprom
	mov		temph,YL
	subi	XL,-EEPROM_PAGE_SIZE								;считывание второго байта
	call	Read_byte_from_eeprom
	mov		temp_2,YL
	subi	XL,-EEPROM_PAGE_SIZE								;считывание третьего байта
	call	Read_byte_from_eeprom
	mov		temp_3,YL

	//проверка считанного байта - если битый или содержит неверное значение
	cp		temph,temp_2
	brne	exit_read_timer_parameters_from_eeprom
	cp		temp_2,temp_3
	brne	exit_read_timer_parameters_from_eeprom
	sbrs	templ,0											;если нулевой бит=1, то были считаны секунды 
	rjmp	check_minutes_or_rounds							;если нулевой бит=1, то были считаны минуты или раунды
	cpi		temph,60										;секунд д.б. меньше 60
	brsh	exit_read_timer_parameters_from_eeprom
	rjmp	check_param_number
check_minutes_or_rounds:
	cpi		temph,100										;минут или раундов д.б. меньше 100
	brsh	exit_read_timer_parameters_from_eeprom
			
check_param_number:
	call	Write_timer_param_to_RAM						;записать прошедший проверку параметр в ОЗУ
	inc		templ											;следующий параметр
	cpi		templ,5
	brlo	next_param_from_eeprom							;или переписать из ОЗУ параметры в соответствующие регистры
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
	ldi		ZL,LOW(TIMER_PARAMETERS_TEMP)					;адрес хранения параметра таймера в оперативной памяти
	ldi		ZH,HIGH(TIMER_PARAMETERS_TEMP)
	add		ZL,templ
	adc		ZH,temp_2
	st		Z,temph
ret

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////							4
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Write_timer_params_from_RAM_to_registers:
	ldi		ZL,LOW(TIMER_PARAMETERS_TEMP)					;адрес хранения параметров таймера в оперативной памяти
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

	//минуты работы
	mov		YL,min_work
	call	Write_byte_to_eeprom	
	//секунды работы
	adiw	XL,1
	mov		YL,sec_work
	call	Write_byte_to_eeprom
	//минуты отдыха
	adiw	XL,1
	mov		YL,min_rest
	call	Write_byte_to_eeprom
	//секунды работы
	adiw	XL,1
	mov		YL,sec_rest
	call	Write_byte_to_eeprom
	//количество раундов
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