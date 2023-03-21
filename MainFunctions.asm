/*
Основные процедуры для работы программы микроконтроллера.
1. Процедура для работы в режиме часов. В случае установки флага чтения пакета данных, устанавливаемого с определенной периодичностью, происходит
вызов процедуры чтения времени и даты из датчика времени и запись в память по адресу TWI_BUFFER_IN. Далее полученные данные байт за байтом считываются
из памяти, преобразовываются в формат для вывода на индикаторы и записываются сначала по адресу TEMP_OUTPUT_BUFFER, а затем оттуда переписываются по адресу
OUTPUT_BUFFER при отключенном прерывании(для предотвращения чтения данных из буффера во время прерывания при записи в него). 
2. Процедура извлечения двух байтов кода буквы или цифры из памяти программ по адресу, указанному в регистре Z. Полученные данные записываются в ОЗУ по
адресу TEMP_OUTPUT_BUFFER + номер индикатора + номер цифры в индикаторе.
3. Считывание байта из временного буфера в буфер вывода.
4. Процедура для работы в режиме таймера. В случае установки флага чтения пакета данных, устанавливаемого с периодичностью в 1 секунду, в зависимости
от режима работы (таймер вкл., выкл., отдых, работа, пауза и т.д.) происходит изменение регистров таймера. После окончания этой процедуры данные из регистров 
считываются, преобразовываются и записываются сначала в TIMER_BUFFER, а затем в OUTPUT_BUFFER.
5. Процедура обновления значений регистров таймера. Если таймер не запущен, на паузе или происходит установка значения времени работы/отдыха то изменения не
производятся. Если таймер запущен, значение регистра секунд инкрементируется, и в случае необходимости меняются значение других регистров.
6. Процедура получения двух байтов кода цифры для вывода на индикатор. Коды цифр записываются в OUTPUT_BUFFER в соответствующем порядке. 
7. Выключить звуковой сигнал.
8. Включить звуковой сигнал 1000 Гц.
9. Включить звуковой сигнал 400 Гц.
10. Запись одного байта в устр-во, адрес байта указывается в регистре byte_address, записываемый байт в регистре temph.
11. Перевод числа в регистре temph из формата BCD в формат HEX.
12. Перевод числа в регистре temph из формата HEX в формат BCD.
13. Установка времени по умолчанию.
14. Корректировка времени часов. В связи с тем, что в процессе работы часов в течении определенного времени, из-за неидеальной точности работы кварцевого 
резонатора, возникает погрешность определения времени микросхемой DS1307. Поэтому каждые сутки, в определённое время, происходит корректировка часов. Для этого
нужно самостоятельно определить значение ухода времени в секундах за сутки для каждой конкретной модели часов.
15. Процедура по установке начального времени.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	1
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Clock_mode_proc:

	sbrs	state_flag,RPTF							;если установлен флаг разрешения чтения времени и даты - начать чтение и преобразование
	jmp		exit_clock_mode_proc

	//сюда надо добавить процедуру считывания и проверки счетчика времени процесса установки времени
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
	call	Read_packet								;чтение данных из DS1307, данные записываются по адресу TWI_BUFFER_IN

	clr		count									;отсчет считываемых байтов

next_ds1307_byte:
	
	clr		templ									;считывание байта информации по адресу TWI_BUFFER_IN + count
	ldi		XL,LOW(TWI_BUFFER_IN)
	ldi		XH,HIGH(TWI_BUFFER_IN)
	add		XL,count
	adc		XH,templ
	ld		templ,X
	
	mov		temph,templ								;преобразование байта информации - разделение десятков и единиц
	andi	templ,0xF								;десятки в старшем ниббле, единицы - в младшем
	andi	temph,0xF0
	swap	temph

	cpi		count,3									;в переменной count - номер индикатора, состоящего из двух цифр
	brge	data_bytes_format
	ldi		ZL,LOW(2*TIME_DIGIT_CATHODE)			;первые три индикатора (сек. - №0, мин. - №1, часы - №2) - большие цифры индикатора часов
	ldi		ZH,HIGH(2*TIME_DIGIT_CATHODE)
	jmp		set_XY_reg
data_bytes_format:
	cpi		count,3
	breq	data_letter_format
	ldi		ZL,LOW(2*DATA_DIGIT_CATHODE)			;4-ый и 5-ый индикатор - малые цифры даты (месяц - №4, число - №5)
	ldi		ZH,HIGH(2*DATA_DIGIT_CATHODE)
	jmp		set_XY_reg
data_letter_format:
	lsl		templ									;для корректного вывода букв на индикатор регистры templ и temph необходимо преобразовать
	mov		temph,templ								;templ умножить на 2, temph на 1 больше templ	
	inc		temph
	ldi		ZL,LOW(2*DATA_LETTER_CATHODE)			;3-ий - малые буквы дня недели (№4)
	ldi		ZH,HIGH(2*DATA_LETTER_CATHODE)
set_XY_reg:
	mov		XL,ZL									;копируем значение регистра для дальнейших манипуляций
	mov		XH,ZH
	clr		temp_2
	mov		temp_3,count
	lsl		temp_3									;умножение count на 4 
	lsl		temp_3
	ldi		YL,LOW(TEMP_OUTPUT_BUFFER)				;сюда временно кладём байты для вывода на индикатор
	ldi		YH,HIGH(TEMP_OUTPUT_BUFFER)
	add		YL,temp_3								;адрес кода цифры для вывода на индикатор - номер индикатора умноженное на 4 + TEMP_OUTPUT_BUFFER
	adc		YH,temp_2
								
	lsl		templ									;считывание кода цифры в соответствии со значением в регистре templ
	add		ZL,templ								
	adc		ZH,temp_2
	call	Get_output	

	mov		ZL,XL
	mov		ZH,XH
	clr		temp_2
	lsl		temph
	add		ZL,temph								;считывание кода цифры в соответствии со значением в регистре temph
	adc		ZH,temp_2
	call	Get_output

	inc		count									;увеличить номер индикатора до достижения его значения 6 и более
	cpi		count,6
	brge	copy_output_buffers
	jmp		next_ds1307_byte

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

copy_output_buffers:
	ldi		XL,LOW(TEMP_OUTPUT_BUFFER)				;переписать данные из временного буфера в буфер вывода предварительно запретив прерывания
	ldi		XH,HIGH(TEMP_OUTPUT_BUFFER)
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	cli
	clr		count
start_copy_bytes:	
	call	Copy_output_bytes
	cpi		count,16
	brlo	start_copy_bytes						;поменять порядок байтов числа и месяца в буфере вывода

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
	sbrs	state_flag,SDBL							;проверить номер цифры текущего индикатора по флагу SDBL (0 - первая цифра, 1 - вторая)
	jmp		check_set_mode
	
	cpi		count,2									;если вторая цифра на индикаторе часов (count=2) или числа месяца (count=4) равна нулю, то она не отображается (temp_2=temp_3=0)
	breq	check_second_digit
	cpi		count,4
	brne	check_set_mode	
check_second_digit:
	cpi		temph,0
	breq	clr_output_bytes

check_set_mode:
	sbrs	state_flag,WWSM							;проверить часы на режим установки
	jmp		read_programm_memory
	cp		count,set_segm
	brne	read_programm_memory					;если режим установки, то проверить на совпадение номера текущего считываемого сегмента и устанавливаемого 
	sbrs	state_flag,WWFF
	jmp		read_programm_memory					;проверка интервала времени - если WWFF=1,то устанавливаемый индикатор должен быть погашен, и наоборот
clr_output_bytes:
	clr		temp_2
	clr		temp_3
	jmp		write_to_output_buffer

read_programm_memory:								;чтение из памяти программ
	lpm		temp_2,Z
	adiw	ZL,1
	lpm		temp_3,Z

	cpi		count,4									;проверить номер индикатора и цифры в индикаторе и поставить точку
	brne	write_to_output_buffer
	sbrc	state_flag,SDBL							
	jmp		write_to_output_buffer
	ori		temp_2,0x80

write_to_output_buffer:								;запись во временный буфер

	st		Y+,temp_2
	st		Y+,temp_3

	sbrc	state_flag,SDBL							;инвертирование флага SDBL
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
	sbrs	state_flag,RPTF							;если установлен флаг разрешения изменения регистров таймера - перейти на процедуру работы в режиме таймера
	jmp		exit_clock_mode_proc
	cbr		state_flag,(1<<RPTF)

	call	Update_BT_counter						;обновить значения регистров таймера
	call	Get_output_timer_mode					;преобразовать данные таймера для вывода на индикаторы
ret

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////	5
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Update_BT_counter:
	sbrs	state_flag,BTON							;определить состояние таймера (работает/нет, на паузе/нет)				
	jmp		timer_is_off
	sbrc	state_flag,BTPS
	jmp		timer_pause
	
////////////////////////////////////////////////
	inc		seconds									;увеличить значение секунд

	clr		temph									;проверить необходимость наличия звукового сигнала в начале периода
	ldi		templ,4
	cp		minutes,temph
	brne	check_next_minute
	cp		seconds,templ
	brne	check_next_minute
	call	Sound_OFF								;если это третья секунда временного периода - отключить звук
	jmp		check_rest_work_1

check_next_minute:									;проверить необходимость увеличения значения минут
	ldi		templ,60
	cp		seconds,templ
	brne	check_rest_work_1						;если значение секунд достигло 60 - обнулить значение секунд и увеличить значение минут
	clr		seconds
	inc		minutes

check_rest_work_1:									;определить отдых или работа
	sbrc	state_flag,BTRT
	jmp		rest_time_1		
	
	cp		minutes,min_work						;проверить на достижение максимальных значений
	brne	fill_buffer_var_1_temp
	cp		seconds,sec_work
	brne	fill_buffer_var_1_temp
	call	Sound_1000Hz_ON							;если значения секунд и минут достигло максимальных значений, то их необходимо обнулить и включить звук окончания раунда
	clr		seconds
	clr		minutes
	sbr		state_flag,(1<<BTRT)
	cp		round,round_work
	brne	fill_buffer_var_2_temp
	cbr		state_flag,(1<<BTON)					;если раунд последний - остановить таймер
	clr		round
	inc		round
	sbr		state_flag,(1<<BTPS)
	jmp		fill_buffer_var_3

fill_buffer_var_1_temp:
	jmp		fill_buffer_var_1
fill_buffer_var_2_temp:
	jmp		fill_buffer_var_2


rest_time_1:										;действия при работе таймера в режиме отдыха
	cp		minutes,min_rest						;далее идет проверка на необходимость подачи сигнала 1000Гц(3 сек в начале отдыха и в конце) 
	brne	rest_seconds_set_zero					;и 400Гц (за 6,4 и 2 сек. до конца отдыха на 1 сек.) 
	cp		seconds,sec_rest
	brne	check_400Hz_on	
	call	Sound_1000Hz_ON
	clr		minutes
	clr		seconds
	cbr		state_flag,(1<<BTRT)
	inc		round
	jmp		fill_buffer_var_1

rest_seconds_set_zero:								;операции выполняются в случае, если заданное значение секунд отдыха равно нулю
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

check_400Hz_on:											;операции выполняются в случае, если заданное значение секунд отдыха не равны нулю
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

	
fill_buffer_var_1:									;записать значения регистров в буффер таймера (в зависимости от состояния)			
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
	clr		temph											;загрузить в templ байт из ОЗУ по адресу TIMER_BUFFER + count
	ldi		XL,LOW(TIMER_BUFFER)
	ldi		XH,HIGH(TIMER_BUFFER)
	add		XL,count
	adc		XH,temph
	ld		templ,X

timer_subtract_ten:											;в templ оставить единицы числа, загруженного из ОЗУ, в temph - десятки того числа
	cpi		templ,10
	brlo	timer_check_digit_count
	inc		temph
	subi	templ,10
	jmp		timer_subtract_ten

timer_check_digit_count:									;загрузить в Z адрес из памяти программ, в котором указан код цифры
	cpi		count,3
	brsh	timer_small_digit_address
	ldi		ZL,LOW(2*TIME_DIGIT_CATHODE)					;для больших цифр
	ldi		ZH,HIGH(2*TIME_DIGIT_CATHODE)
	jmp		timer_copy_address

timer_small_digit_address:
	ldi		ZL,LOW(2*DATA_DIGIT_CATHODE)					;для маленьких цифр
	ldi		ZH,HIGH(2*DATA_DIGIT_CATHODE)	

timer_copy_address:											;копировать начальный адрес в Х для восстановления его значения перед загрузкой кода второй цифры сегмента
	mov		XL,ZL
	mov		XH,ZH
	
	clr		temp_3											;загрузить в Y адрес, по которому будут записываться прочитанные из флеш байты
	mov		temp_2,count									;адрес зависит от регистра count (номер сегмента)
	lsl		temp_2
	lsl		temp_2
	ldi		YL,LOW(OUTPUT_BUFFER)
	ldi		YH,HIGH(OUTPUT_BUFFER)
	add		YL,temp_2
	adc		YH,temp_3
	
	lsl		templ											;получить адрес первой цифры сегмента
	add		ZL,templ
	adc		ZH,temp_3

timer_get_ouput_data:
	sbrs	state_flag,SDBL									;в случае если с текущим сегментом происходит установка его нужно погасить, т.е. код для вывода = 0 
	jmp		timer_first_byte_load							;аналогично, если старшая цифра в сегменте = 0, код для вывода также равен нулю
	cpi		count,0											;исключение - сегменты секунд (сегмент 0 и 4)
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
	cpi		count,2											;убрать точки после значения раунда (2-ой сегмент)
	brne	tm_get_output_set_point
	andi	temp_2,0xF7	
	jmp		put_regs_to_output_buffer
	
tm_get_output_set_point:
	cpi		count,5									;проверить номер индикатора и цифры в индикаторе и поставить точку
	brne	put_regs_to_output_buffer
	sbrc	state_flag,SDBL							
	jmp		put_regs_to_output_buffer
	ori		temp_2,0x80					

put_regs_to_output_buffer:									;положить значения регистров и повторить процедуру для temph
	st		Y+,temp_2
	st		Y+,temp_3
	sbrc	state_flag,SDBL									;если ещё не получили код для второй цифры сегмента
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
	cbr		state_flag,(1<<SDBL)					;после получения кода второй цифры сегмента увеличить номер сегмента и так пока номер сегмента не достигнет 6 
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
	swap	templ										;в temph - единицы, templ - десятки							
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
	cpi		temph,100									//если число больше или равно 100, число преобразовывать не надо
	brsh	exit_change_format
next_decrement:											//реализация деления на 10 с помощью операций сложение и вычитания, делимое - temph, частное - templ
	cpi		temph,10									//остаток в temph		
	brlo	next_format_operation
	subi	temph,10
	inc		templ
	jmp		next_decrement
next_format_operation:	
	swap	templ										//старшие 4 байта temph должны содержать младшие 4 байта templ
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
//						NL///			NL///			д////			П////			т////			В////			
		.db		0x31,	0x90,	0x51,	0x43,	0x20,	0xA0,	0x20,	0xE4,	0x20,	0xA0,	0x03,	0x4B,	0x31,	0x92,	0x51,	0x43,	0x11,	0x80,	0x72,	0x2F
//						д///			С///			т////			Ч////			т////			П////			б////			С////			с///			В///			

DATA_DIGIT_CATHODE:
		.db		0x53,	0x4B,	0x02,	0x08,	0x51,	0xAB,	0x52,	0xAB,	0x02,	0xE8,	0x52,	0xE3,	0x53,	0xE3
//						0////			1////			2////			3////			4////			5////			6///
		.db		0x02,	0x0B,	0x53,	0xEB,	0x52,	0xEB,	0x00,	0x00
//						7////			8////			9////			NA////



