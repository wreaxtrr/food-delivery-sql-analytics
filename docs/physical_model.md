\# Физическая модель базы данных



\## Описание



Физическая модель описывает конкретную структуру таблиц базы данных: поля, типы данных, ограничения, первичные и внешние ключи.



База данных проектируется для PostgreSQL.



\---



\## users



Таблица пользователей сервиса.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| user\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор пользователя |

| full\_name | VARCHAR(100) | NOT NULL | Имя пользователя |

| email | VARCHAR(255) | UNIQUE, NOT NULL | Email пользователя |

| phone | VARCHAR(20) | UNIQUE | Телефон пользователя |

| registration\_date | DATE | NOT NULL, DEFAULT CURRENT\_DATE | Дата регистрации |

| city | VARCHAR(100) | NOT NULL | Город пользователя |



\---



\## restaurants



Таблица ресторанов.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| restaurant\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор ресторана |

| restaurant\_name | VARCHAR(150) | NOT NULL | Название ресторана |

| city | VARCHAR(100) | NOT NULL | Город ресторана |

| cuisine\_type | VARCHAR(100) | NOT NULL | Тип кухни |

| opened\_at | DATE | NOT NULL | Дата открытия ресторана |

| is\_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли ресторан |



\---



\## couriers



Таблица курьеров.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| courier\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор курьера |

| full\_name | VARCHAR(100) | NOT NULL | Имя курьера |

| phone | VARCHAR(20) | UNIQUE, NOT NULL | Телефон курьера |

| hire\_date | DATE | NOT NULL | Дата найма |

| transport\_type | VARCHAR(50) | NOT NULL | Тип транспорта |

| is\_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли курьер |



Ограничение для `transport\_type`:



```sql

transport\_type IN ('bike', 'scooter', 'car', 'walking')

```



\---



\## categories



Таблица категорий товаров.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| category\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор категории |

| category\_name | VARCHAR(100) | NOT NULL | Название категории |

| parent\_category\_id | BIGINT | FOREIGN KEY | Родительская категория |



Связь:



```sql

parent\_category\_id REFERENCES categories(category\_id)

```



\---



\## products



Таблица товаров / блюд.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| product\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор товара |

| restaurant\_id | BIGINT | NOT NULL, FOREIGN KEY | Ресторан |

| category\_id | BIGINT | NOT NULL, FOREIGN KEY | Категория |

| product\_name | VARCHAR(150) | NOT NULL | Название товара |

| price | NUMERIC(10, 2) | NOT NULL, CHECK price > 0 | Цена товара |

| is\_available | BOOLEAN | NOT NULL, DEFAULT TRUE | Доступен ли товар |



Связи:



```sql

restaurant\_id REFERENCES restaurants(restaurant\_id)

category\_id REFERENCES categories(category\_id)

```



\---



\## promocodes



Таблица промокодов.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| promocode\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор промокода |

| code | VARCHAR(50) | UNIQUE, NOT NULL | Код промокода |

| discount\_type | VARCHAR(20) | NOT NULL | Тип скидки |

| discount\_value | NUMERIC(10, 2) | NOT NULL, CHECK discount\_value > 0 | Размер скидки |

| starts\_at | DATE | NOT NULL | Дата начала действия |

| ends\_at | DATE | NOT NULL | Дата окончания действия |

| is\_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли промокод |



Ограничения:



```sql

discount\_type IN ('percent', 'fixed')

ends\_at >= starts\_at

```



\---



\## orders



Таблица заказов.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| order\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор заказа |

| user\_id | BIGINT | NOT NULL, FOREIGN KEY | Пользователь |

| restaurant\_id | BIGINT | NOT NULL, FOREIGN KEY | Ресторан |

| courier\_id | BIGINT | FOREIGN KEY | Курьер |

| promocode\_id | BIGINT | FOREIGN KEY | Промокод |

| order\_created\_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT\_TIMESTAMP | Время создания заказа |

| order\_status | VARCHAR(30) | NOT NULL | Текущий статус заказа |

| delivery\_address | TEXT | NOT NULL | Адрес доставки |

| delivery\_fee | NUMERIC(10, 2) | NOT NULL, DEFAULT 0, CHECK delivery\_fee >= 0 | Стоимость доставки |

| discount\_amount | NUMERIC(10, 2) | NOT NULL, DEFAULT 0, CHECK discount\_amount >= 0 | Размер скидки |

| total\_amount | NUMERIC(10, 2) | NOT NULL, CHECK total\_amount >= 0 | Итоговая сумма заказа |



Связи:



```sql

user\_id REFERENCES users(user\_id)

restaurant\_id REFERENCES restaurants(restaurant\_id)

courier\_id REFERENCES couriers(courier\_id)

promocode\_id REFERENCES promocodes(promocode\_id)

```



Ограничение для `order\_status`:



```sql

order\_status IN ('created', 'paid', 'cooking', 'delivering', 'delivered', 'cancelled')

```



\---



\## order\_items



Таблица позиций заказа.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| order\_item\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор позиции |

| order\_id | BIGINT | NOT NULL, FOREIGN KEY | Заказ |

| product\_id | BIGINT | NOT NULL, FOREIGN KEY | Товар |

| quantity | INTEGER | NOT NULL, CHECK quantity > 0 | Количество |

| unit\_price | NUMERIC(10, 2) | NOT NULL, CHECK unit\_price > 0 | Цена товара на момент заказа |



Связи:



```sql

order\_id REFERENCES orders(order\_id)

product\_id REFERENCES products(product\_id)

```



\---



\## payments



Таблица платежей.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| payment\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор платежа |

| order\_id | BIGINT | UNIQUE, NOT NULL, FOREIGN KEY | Заказ |

| payment\_method | VARCHAR(30) | NOT NULL | Способ оплаты |

| payment\_status | VARCHAR(30) | NOT NULL | Статус платежа |

| paid\_at | TIMESTAMP | | Время оплаты |

| amount | NUMERIC(10, 2) | NOT NULL, CHECK amount >= 0 | Сумма платежа |



Связь:



```sql

order\_id REFERENCES orders(order\_id)

```



Ограничения:



```sql

payment\_method IN ('card', 'cash', 'apple\_pay', 'google\_pay')

payment\_status IN ('pending', 'paid', 'failed', 'refunded')

```



\---



\## order\_status\_history



История изменения статусов заказа.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| status\_history\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор записи |

| order\_id | BIGINT | NOT NULL, FOREIGN KEY | Заказ |

| status | VARCHAR(30) | NOT NULL | Статус заказа |

| status\_changed\_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT\_TIMESTAMP | Время изменения статуса |



Связь:



```sql

order\_id REFERENCES orders(order\_id)

```



Ограничение для `status`:



```sql

status IN ('created', 'paid', 'cooking', 'delivering', 'delivered', 'cancelled')

```



\---



\## app\_events



Таблица событий пользователей в приложении.



| Поле | Тип данных | Ограничения | Описание |

|---|---|---|---|

| event\_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор события |

| user\_id | BIGINT | NOT NULL, FOREIGN KEY | Пользователь |

| event\_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT\_TIMESTAMP | Время события |

| event\_type | VARCHAR(50) | NOT NULL | Тип события |

| restaurant\_id | BIGINT | FOREIGN KEY | Ресторан |

| product\_id | BIGINT | FOREIGN KEY | Товар |

| order\_id | BIGINT | FOREIGN KEY | Заказ |



Связи:



```sql

user\_id REFERENCES users(user\_id)

restaurant\_id REFERENCES restaurants(restaurant\_id)

product\_id REFERENCES products(product\_id)

order\_id REFERENCES orders(order\_id)

```



Ограничение для `event\_type`:



```sql

event\_type IN ('app\_open', 'restaurant\_view', 'product\_view', 'add\_to\_cart', 'checkout\_start', 'order\_created')

```



\---



\## Планируемые индексы



Для ускорения аналитических запросов планируется добавить индексы:



| Таблица | Поле | Причина |

|---|---|---|

| orders | user\_id | анализ заказов по пользователям |

| orders | restaurant\_id | анализ заказов по ресторанам |

| orders | order\_created\_at | анализ динамики по датам |

| order\_items | order\_id | соединение с заказами |

| order\_items | product\_id | анализ продаж товаров |

| app\_events | user\_id | анализ поведения пользователей |

| app\_events | event\_time | анализ событий по времени |

| payments | order\_id | соединение платежей с заказами |

