# Физическая модель базы данных

## Описание

Физическая модель описывает конкретную структуру таблиц базы данных: поля, типы данных, ограничения, первичные и внешние ключи.

База данных проектируется для PostgreSQL.

---

## users

Таблица пользователей сервиса.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| user_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор пользователя |
| full_name | VARCHAR(100) | NOT NULL | Имя пользователя |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email пользователя |
| phone | VARCHAR(20) | UNIQUE | Телефон пользователя |
| registration_date | DATE | NOT NULL, DEFAULT CURRENT_DATE | Дата регистрации |
| city | VARCHAR(100) | NOT NULL | Город пользователя |

---

## restaurants

Таблица ресторанов.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| restaurant_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор ресторана |
| restaurant_name | VARCHAR(150) | NOT NULL | Название ресторана |
| city | VARCHAR(100) | NOT NULL | Город ресторана |
| cuisine_type | VARCHAR(100) | NOT NULL | Тип кухни |
| opened_at | DATE | NOT NULL | Дата открытия ресторана |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли ресторан |

---

## couriers

Таблица курьеров.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| courier_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор курьера |
| full_name | VARCHAR(100) | NOT NULL | Имя курьера |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | Телефон курьера |
| hire_date | DATE | NOT NULL | Дата найма |
| transport_type | VARCHAR(50) | NOT NULL | Тип транспорта |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли курьер |

Ограничение для `transport_type`:

```sql
transport_type IN ('bike', 'scooter', 'car', 'walking')
```

---

## categories

Таблица категорий товаров.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| category_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор категории |
| category_name | VARCHAR(100) | NOT NULL | Название категории |
| parent_category_id | BIGINT | FOREIGN KEY | Родительская категория |

Связь:

```sql
parent_category_id REFERENCES categories(category_id)
```

---

## products

Таблица товаров и блюд.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| product_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор товара |
| restaurant_id | BIGINT | NOT NULL, FOREIGN KEY | Ресторан |
| category_id | BIGINT | NOT NULL, FOREIGN KEY | Категория |
| product_name | VARCHAR(150) | NOT NULL | Название товара |
| price | NUMERIC(10, 2) | NOT NULL, CHECK price > 0 | Цена товара |
| is_available | BOOLEAN | NOT NULL, DEFAULT TRUE | Доступен ли товар |

Связи:

```sql
restaurant_id REFERENCES restaurants(restaurant_id)
category_id REFERENCES categories(category_id)
```

---

## promocodes

Таблица промокодов.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| promocode_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор промокода |
| code | VARCHAR(50) | UNIQUE, NOT NULL | Код промокода |
| discount_type | VARCHAR(20) | NOT NULL | Тип скидки |
| discount_value | NUMERIC(10, 2) | NOT NULL, CHECK discount_value > 0 | Размер скидки |
| starts_at | DATE | NOT NULL | Дата начала действия |
| ends_at | DATE | NOT NULL | Дата окончания действия |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Активен ли промокод |

Ограничения:

```sql
discount_type IN ('percent', 'fixed')
ends_at >= starts_at
```

---

## orders

Таблица заказов.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| order_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор заказа |
| user_id | BIGINT | NOT NULL, FOREIGN KEY | Пользователь |
| restaurant_id | BIGINT | NOT NULL, FOREIGN KEY | Ресторан |
| courier_id | BIGINT | FOREIGN KEY | Курьер |
| promocode_id | BIGINT | FOREIGN KEY | Промокод |
| order_created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Время создания заказа |
| order_status | VARCHAR(30) | NOT NULL | Текущий статус заказа |
| delivery_address | TEXT | NOT NULL | Адрес доставки |
| delivery_fee | NUMERIC(10, 2) | NOT NULL, DEFAULT 0, CHECK delivery_fee >= 0 | Стоимость доставки |
| discount_amount | NUMERIC(10, 2) | NOT NULL, DEFAULT 0, CHECK discount_amount >= 0 | Размер скидки |
| total_amount | NUMERIC(10, 2) | NOT NULL, CHECK total_amount >= 0 | Итоговая сумма заказа |

Связи:

```sql
user_id REFERENCES users(user_id)
restaurant_id REFERENCES restaurants(restaurant_id)
courier_id REFERENCES couriers(courier_id)
promocode_id REFERENCES promocodes(promocode_id)
```

Ограничение для `order_status`:

```sql
order_status IN (
    'created',
    'paid',
    'cooking',
    'delivering',
    'delivered',
    'cancelled'
)
```

---

## order_items

Таблица позиций заказа.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| order_item_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор позиции |
| order_id | BIGINT | NOT NULL, FOREIGN KEY | Заказ |
| product_id | BIGINT | NOT NULL, FOREIGN KEY | Товар |
| quantity | INTEGER | NOT NULL, CHECK quantity > 0 | Количество |
| unit_price | NUMERIC(10, 2) | NOT NULL, CHECK unit_price > 0 | Цена товара на момент заказа |

Связи:

```sql
order_id REFERENCES orders(order_id)
product_id REFERENCES products(product_id)
```

---

## payments

Таблица платежей.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| payment_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор платежа |
| order_id | BIGINT | UNIQUE, NOT NULL, FOREIGN KEY | Заказ |
| payment_method | VARCHAR(30) | NOT NULL | Способ оплаты |
| payment_status | VARCHAR(30) | NOT NULL | Статус платежа |
| paid_at | TIMESTAMP | — | Время оплаты |
| amount | NUMERIC(10, 2) | NOT NULL, CHECK amount >= 0 | Сумма платежа |

Связь:

```sql
order_id REFERENCES orders(order_id)
```

Ограничения:

```sql
payment_method IN ('card', 'cash', 'apple_pay', 'google_pay')
payment_status IN ('pending', 'paid', 'failed', 'refunded')
```

---

## order_status_history

История изменения статусов заказа.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| status_history_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор записи |
| order_id | BIGINT | NOT NULL, FOREIGN KEY | Заказ |
| status | VARCHAR(30) | NOT NULL | Статус заказа |
| status_changed_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Время изменения статуса |

Связь:

```sql
order_id REFERENCES orders(order_id)
```

Ограничение для `status`:

```sql
status IN (
    'created',
    'paid',
    'cooking',
    'delivering',
    'delivered',
    'cancelled'
)
```

---

## app_events

Таблица событий пользователей в приложении.

| Поле | Тип данных | Ограничения | Описание |
|---|---|---|---|
| event_id | BIGSERIAL | PRIMARY KEY | Уникальный идентификатор события |
| user_id | BIGINT | NOT NULL, FOREIGN KEY | Пользователь |
| event_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Время события |
| event_type | VARCHAR(50) | NOT NULL | Тип события |
| restaurant_id | BIGINT | FOREIGN KEY | Ресторан |
| product_id | BIGINT | FOREIGN KEY | Товар |
| order_id | BIGINT | FOREIGN KEY | Заказ |

Связи:

```sql
user_id REFERENCES users(user_id)
restaurant_id REFERENCES restaurants(restaurant_id)
product_id REFERENCES products(product_id)
order_id REFERENCES orders(order_id)
```

Ограничение для `event_type`:

```sql
event_type IN (
    'app_open',
    'restaurant_view',
    'product_view',
    'add_to_cart',
    'checkout_start',
    'order_created'
)
```

---

## Индексы

Для ускорения аналитических запросов используются следующие индексы:

| Таблица | Поля | Причина |
|---|---|---|
| orders | order_created_at | анализ динамики заказов по датам |
| orders | user_id, order_created_at | анализ заказов пользователей |
| orders | restaurant_id, order_created_at | анализ заказов ресторанов |
| orders | order_status, order_created_at | фильтрация заказов по статусу и дате |
| order_items | order_id | соединение позиций с заказами |
| order_items | product_id | анализ продаж товаров |
| order_status_history | order_id, status | поиск статусов и расчёт времени доставки |
| app_events | user_id, event_time | анализ поведения пользователей |
| app_events | event_type, event_time | анализ событий и продуктовой воронки |
