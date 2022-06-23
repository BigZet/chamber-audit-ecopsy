Запуск скрипта:
```Rscript calculation.R --filepath "Путь к файлу xlsx" --dir "Путь к папке с файлами" --jsontype "Тип json на выходе" --output "Путь и наименование файла на выходе"```

Возможно либо указать полный путь к файлу в аргументе ```--filepath```, единственное желательно использовать путь на латинице,
либо указать путь к папке с файлами xlsx, тогда система выведет список и предложит выбрать. Полный путь к файлу приоритетнее, пути к папке.
По умолчанию ```--dir = "./excel_import_data".```

По умолчанию ```--output = "output.json"```
JSON в кодировке в UTF-8

На выходе данные представляются в двух возможных форматах:
1. ```--jsontype "nested"``` (по умолчанию). Используется "вложенный" формат. Пример структуры:
```
[
    {
        "FIO": "Титова  Анна Александровна", # ФИО респондента
        "z_total_common": 17, # Итоговая оценка по всем шкалам
        "z_cut_mean": -0.73, # Средняя оценка обрезанных на 3 отклонения z-value
        #Кол-во верно отвеченных вопросов для каждой из шкал
        "raw": {
            "communication_competence": 12, #Коммуникативная компетентость
            "search_storage_transfer_digital_content": 8, #Поиск, хранение и передача цифрового контента
            "creation_digital_content": 11, #Создание цифрового контента
            "information_security": 3 #Цифровая безопасность
        },
        # Обрезанные на 3 отклонения z-value для каждой из шкал
        "zscore": {
            "communication_competence": -0.16,
            "search_storage_transfer_digital_content": -0.43,
            "creation_digital_content": -0.24,
            "information_security": -2.1
        },
        #Процентили подсчитанные по обрезанным z-value по формуле компании
        "percentiles": {
            "communication_competence": 41,
            "search_storage_transfer_digital_content": 28,
            "creation_digital_content": 34,
            "information_security": 4
        }
    },
]
```

2. ```--jsontype "flatten"```. Используется "плоский" формат. Пример структуры:
```
[
    {
        "FIO": "Цуканова Анна Евгеньевна",
        "z_cut_mean": -0.93,
        "z_total_common": 11,
        "raw_communication_competence": 11,
        "raw_search_storage_transfer_digital_content": 8,
        "raw_creation_digital_content": 9,
        "raw_information_security": 4,
        "z_communication_competence": -0.74,
        "z_search_storage_transfer_digital_content": -0.43,
        "z_creation_digital_content": -1.05,
        "z_information_security": -1.51,
        "z_cut_communication_competence": -0.74,
        "z_cut_search_storage_transfer_digital_content": -0.43,
        "z_cut_creation_digital_content": -1.05,
        "z_cut_information_security": -1.51,
        "z_total_communication_competence": 19,
        "z_total_search_storage_transfer_digital_content": 28,
        "z_total_creation_digital_content": 12,
        "z_total_information_security": 11
    },
]
```