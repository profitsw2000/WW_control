/*
Основные функции для работы с АЦП, вычисление сопротивления фоторезистора,
установка яркости светодиодных индикаторов.
1.Измерение напряжения, вычисление значения, которое будет использоваться для генерации ШИМ. Изменение 
значения OCR таймера 1.
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////								1
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Set_brightness:
 //измерить напряжение
	sbi		ADCSRA,ADSC
 wait_conv:
	sbic	ADCSRA,ADSC
	jmp		wait_conv
	in		templ,ADCL
	in		temph,ADCH

/*	ldi		templ,0xFF
	sub		templ,temph*/
	cpi		temph,0xFF
	brne	not_abs_dark
	ldi		temph,0xFE
not_abs_dark:
	call	Average_measure
ret


Average_measure:
	ldi		XL,LOW(ADC_NUM)							;считать номер очередного байта с измеренным значением АЦП
	ldi		XH,HIGH(ADC_NUM)
	ld		templ,X
	
	clr		temp_2
	ldi		YL,LOW(ADC_RES)							;записать измеренное значение в буфер
	ldi		YH,HIGH(ADC_RES)
	add		YL,templ
	adc		YH,temp_2
	st		Y,temph

	inc		templ									;если номер записываемого байта достигло 32 провести операцию усреднения считанных данных и обнулить номер
	cpi		templ,32
	brlo	adc_res_num_low
	clr		templ
	call	Calculate_average
adc_res_num_low:
	st		X,templ
	
ret


Calculate_average:
	push	templ

	clr		temp_2
	clr		temp_3
	clr		templ
	clr		count
	ldi		YL,LOW(ADC_RES)
	ldi		YH,HIGH(ADC_RES)

aver_calc_next_byte:
	ld		temph,Y+
	add		temp_2,temph								;в temp_3:temp_2 сумма всех записанных в буффер байтов
	adc		temp_3,templ
	inc		count
	cpi		count,32
	brlo	aver_calc_next_byte

	lsl		temp_2										;умножить на 8 (сдвинуть влево 3 бита) двухбайтовое число
	rol		temp_3
	lsl		temp_2										
	rol		temp_3
	lsl		temp_2										
	rol		temp_3										;temp_3 после сдвига содержит среднее однобайтовое значение

	mov		temph,temp_3
	out		OCR2,temph

/*	mov		templ,temph
	call	Send_UART*/

	pop		templ
ret	

.dseg

ADC_NUM:		.byte	1

ADC_RES:		.byte	32

.cseg
