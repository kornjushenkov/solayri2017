#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область СлужебныйПрограммныйИнтерфейс

////////////////////////////////////////////////////////////////////////////////
// Обработчики обновления.

// Регистрирует на плане обмена ОбновлениеИнформационнойБазы объекты,
// для которых необходимо обновить записи в реестре.
//
Процедура ЗарегистрироватьДанныеКОбработкеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ВсеДокументы.Ссылка
	|ИЗ
	|	(ВЫБРАТЬ
	|		_ДемоОприходованиеТоваров.Ссылка КАК Ссылка,
	|		_ДемоОприходованиеТоваров.Дата КАК Дата
	|	ИЗ
	|		Документ._ДемоОприходованиеТоваров КАК _ДемоОприходованиеТоваров
	|	
	|	ОБЪЕДИНИТЬ ВСЕ
	|	
	|	ВЫБРАТЬ
	|		_ДемоПеремещениеТоваров.Ссылка,
	|		_ДемоПеремещениеТоваров.Дата
	|	ИЗ
	|		Документ._ДемоПеремещениеТоваров КАК _ДемоПеремещениеТоваров
	|	
	|	ОБЪЕДИНИТЬ ВСЕ
	|	
	|	ВЫБРАТЬ
	|		_ДемоСписаниеТоваров.Ссылка,
	|		_ДемоСписаниеТоваров.Дата
	|	ИЗ
	|		Документ._ДемоСписаниеТоваров КАК _ДемоСписаниеТоваров) КАК ВсеДокументы
	|
	|УПОРЯДОЧИТЬ ПО
	|	ВсеДокументы.Дата УБЫВ";
	
	МассивСсылок = Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("Ссылка");
	
	ОбновлениеИнформационнойБазы.ОтметитьКОбработке(Параметры, МассивСсылок);
	
КонецПроцедуры

// Обновить записи реестра.
Процедура ОбработатьДанныеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	ОбработкаЗавершена = Истина;
	
	ОбновитьРеестрСкладскихДокументовУказанногоВида(Параметры, "Документ._ДемоОприходованиеТоваров", ОбработкаЗавершена);
	ОбновитьРеестрСкладскихДокументовУказанногоВида(Параметры, "Документ._ДемоПеремещениеТоваров", ОбработкаЗавершена);
	ОбновитьРеестрСкладскихДокументовУказанногоВида(Параметры, "Документ._ДемоСписаниеТоваров", ОбработкаЗавершена);
	
	Параметры.ОбработкаЗавершена = ОбработкаЗавершена;
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ОбновитьРеестрСкладскихДокументов(Документ, ПриОбновленииИБ = Ложь) Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	
	Если ОбщегоНазначения.ЭтоСсылка(ТипЗнч(Документ)) Тогда
		Ссылка = Документ;
		
		Реквизиты = "Ссылка, ПометкаУдаления, Проведен, Дата, Номер, Организация, Ответственный, Комментарий";
		
		Если ТипЗнч(Ссылка) = Тип("ДокументСсылка._ДемоПеремещениеТоваров") Тогда
			Реквизиты = Реквизиты + ", МестоХраненияИсточник, МестоХраненияПриемник";
		Иначе
			Реквизиты = Реквизиты + ", МестоХранения";
		КонецЕсли;
		
		Данные = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Ссылка, Реквизиты);
		Если Не ЗначениеЗаполнено(Данные.Ссылка) Тогда
			Возврат; // Объект удален, связанная запись удаляется платформой.
		КонецЕсли;
	Иначе
		Ссылка = Документ.Ссылка;
		Данные = Документ;
	КонецЕсли;
	
	НаборЗаписей = СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Ссылка.Установить(Ссылка);
	Запись = НаборЗаписей.Добавить();
	ЗаполнитьЗначенияСвойств(Запись, Данные);
	Запись.ТипСсылки = ОбщегоНазначения.ИдентификаторОбъектаМетаданных(ТипЗнч(Запись.Ссылка));
	
	Если ТипЗнч(Ссылка) = Тип("ДокументСсылка._ДемоПеремещениеТоваров") Тогда
		Запись.МестоХранения = Данные.МестоХраненияИсточник;
		// Дополнительная запись для операции перемещения.
		ВтораяЗапись = НаборЗаписей.Добавить();
		ЗаполнитьЗначенияСвойств(ВтораяЗапись, Данные);
		ВтораяЗапись.ТипСсылки = Запись.ТипСсылки;
		ВтораяЗапись.МестоХранения = Данные.МестоХраненияПриемник;
		ВтораяЗапись.ДополнительнаяЗапись = Истина;
	КонецЕсли;
	
	Если ПриОбновленииИБ Тогда
		// Используется параллельное обновление с нестандартной отметкой выполнения
		// обработанных данных (см. процедуру ЗаполнитьРеестрСкладскихДокументовУказанногоВида
		// общего модуля _ДемоОбновлениеИнформационнойБазыБСП).
		НаборЗаписей.ОбменДанными.Загрузка = Истина;
		НаборЗаписей.ДополнительныеСвойства.Вставить("ОтключитьМеханизмРегистрацииОбъектов");
		НаборЗаписей.ОбменДанными.Получатели.АвтоЗаполнение = Ложь;
	КонецЕсли;
	
	НаборЗаписей.Записать();
	
КонецПроцедуры

// Для процедуры ОбработатьДанныеДляПереходаНаНовуюВерсию.
Процедура ОбновитьРеестрСкладскихДокументовУказанногоВида(Параметры, ВидДокумента, ОбработкаЗавершена)
	
	Выборка = ОбновлениеИнформационнойБазы.ВыбратьСсылкиДляОбработки(Параметры.Очередь, ВидДокумента);
	
	ОбъектовОбработано = 0;
	ПроблемныхОбъектов = 0;
	
	Пока Выборка.Следующий() Цикл
		
		НачатьТранзакцию();
		Попытка
			ОбновитьРеестрСкладскихДокументов(Выборка.Ссылка, Истина);
			ОбновлениеИнформационнойБазы.ОтметитьВыполнениеОбработки(Выборка.Ссылка);
			ОбъектовОбработано = ОбъектовОбработано + 1;
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			// Если не удалось обработать какой-либо документ, повторяем попытку снова.
			ПроблемныхОбъектов = ПроблемныхОбъектов + 1;
			
			ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Не удалось обработать документ: %1 по причине:
					|%2'"), 
					Выборка.Ссылка, ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
			ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(), УровеньЖурналаРегистрации.Предупреждение,
				Выборка.Ссылка.Метаданные(), Выборка.Ссылка, ТекстСообщения);
		КонецПопытки;
		
	КонецЦикла;
	
	Если Не ОбновлениеИнформационнойБазы.ОбработкаДанныхЗавершена(Параметры.Очередь, ВидДокумента) Тогда
		ОбработкаЗавершена = Ложь;
	КонецЕсли;
	
	Если ОбъектовОбработано = 0 И ПроблемныхОбъектов <> 0 Тогда
		ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Процедуре ЗаполнитьРеестрСкладскихДокументов не удалось обработать некоторые документы (пропущены): %1'"), 
				ПроблемныхОбъектов);
		ВызватьИсключение ТекстСообщения;
	Иначе
		ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(), УровеньЖурналаРегистрации.Информация,
			Метаданные.НайтиПоПолномуИмени(ВидДокумента),,
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = 'Процедура ЗаполнитьРеестрСкладскихДокументов обработала очередную порцию документов: %1'"),
					ОбъектовОбработано));
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#КонецЕсли
