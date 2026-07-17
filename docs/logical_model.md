# Логическая модель базы данных

## Описание

Логическая модель описывает таблицы базы данных, их основные поля, первичные ключи, внешние ключи и связи между таблицами.

База данных проектируется для сервиса доставки еды и должна поддерживать хранение информации о пользователях, ресторанах, товарах, заказах, платежах, промокодах, курьерах и событиях пользователей в приложении.

## Таблицы

### users

Таблица пользователей сервиса.

| Поле | Описание |
|---|---|
| user_id | Уникальный идентификатор пользователя |
| full_name | Имя пользователя |
| email | Email пользователя |
| phone | Телефон пользователя |
| registration_date | Дата регистрации |
| city | Город пользователя |

Связи:

- `users.user\\\\\\\_id` → `orders.user\\\\\\\_id`
- `users.user\\\\\\\_id` → `app\\\\\\\_events.user\\\\\\\_id`

---

### restaurants

Таблица ресторанов.

| Поле | Описание |
|---|---|
| restaurant_id | Уникальный идентификатор ресторана |
| restaurant_name | Название ресторана |
| city | Город ресторана |
| cuisine_type | Тип кухни |
| opened_at | Дата открытия ресторана |
| is_active | Активен ли ресторан |

Связи:

- `restaurants.restaurant\\\\\\\_id` → `products.restaurant\\\\\\\_id`
- `restaurants.restaurant\\\\\\\_id` → `orders.restaurant\\\\\\\_id`

---

### couriers

Таблица курьеров.

| Поле | Описание |
|---|---|
| courier_id | Уникальный идентификатор курьера |
| full_name | Имя курьера |
| phone | Телефон курьера |
| hire_date | Дата найма |
| transport_type | Тип транспорта |
| is_active | Активен ли курьер |

Связи:

- `couriers.courier\\\\\\\_id` → `orders.courier\\\\\\\_id`

---

### categories

Таблица категорий товаров.

| Поле | Описание |
|---|---|
| category_id | Уникальный идентификатор категории |
| category_name | Название категории |
| parent_category_id | Родительская категория |

Связи:

- `categories.category\\\\\\\_id` → `products.category\\\\\\\_id`
- `categories.category\\\\\\\_id` → `categories.parent\\\\\\\_category\\\\\\\_id`

---

### products

Таблица товаров / блюд.

| Поле | Описание |
|---|---|
| product_id | Уникальный идентификатор товара |
| restaurant_id | Ресторан, которому принадлежит товар |
| category_id | Категория товара |
| product_name | Название товара |
| price | Цена товара |
| is_available | Доступен ли товар |

Связи:

- `products.restaurant\\\\\\\_id` → `restaurants.restaurant\\\\\\\_id`
- `products.category\\\\\\\_id` → `categories.category\\\\\\\_id`
- `products.product\\\\\\\_id` → `order\\\\\\\_items.product\\\\\\\_id`

---

### promocodes

Таблица промокодов.

| Поле | Описание |
|---|---|
| promocode_id | Уникальный идентификатор промокода |
| code | Код промокода |
| discount_type | Тип скидки |
| discount_value | Размер скидки |
| starts_at | Дата начала действия |
| ends_at | Дата окончания действия |
| is_active | Активен ли промокод |

Связи:

- `promocodes.promocode\\\\\\\_id` → `orders.promocode\\\\\\\_id`

---

### orders

Таблица заказов.

| Поле | Описание |
|---|---|
| order_id | Уникальный идентификатор заказа |
| user_id | Пользователь, сделавший заказ |
| restaurant_id | Ресторан, в котором сделан заказ |
| courier_id | Курьер заказа |
| promocode_id | Применённый промокод |
| order_created_at | Время создания заказа |
| order_status | Текущий статус заказа |
| delivery_address | Адрес доставки |
| delivery_fee | Стоимость доставки |
| discount_amount | Размер скидки |
| total_amount | Итоговая сумма заказа |

Связи:

- `orders.user\\\\\\\_id` → `users.user\\\\\\\_id`
- `orders.restaurant\\\\\\\_id` → `restaurants.restaurant\\\\\\\_id`
- `orders.courier\\\\\\\_id` → `couriers.courier\\\\\\\_id`
- `orders.promocode\\\\\\\_id` → `promocodes.promocode\\\\\\\_id`
- `orders.order\\\\\\\_id` → `order\\\\\\\_items.order\\\\\\\_id`
- `orders.order\\\\\\\_id` → `payments.order\\\\\\\_id`
- `orders.order\\\\\\\_id` → `order\\\\\\\_status\\\\\\\_history.order\\\\\\\_id`

---

### order_items

Таблица позиций заказа.

| Поле | Описание |
|---|---|
| order_item_id | Уникальный идентификатор позиции заказа |
| order_id | Заказ |
| product_id | Товар |
| quantity | Количество |
| unit_price | Цена товара на момент заказа |

Связи:

- `order\\\\\\\_items.order\\\\\\\_id` → `orders.order\\\\\\\_id`
- `order\\\\\\\_items.product\\\\\\\_id` → `products.product\\\\\\\_id`

---

### payments

Таблица платежей.

| Поле | Описание |
|---|---|
| payment_id | Уникальный идентификатор платежа |
| order_id | Заказ |
| payment_method | Способ оплаты |
| payment_status | Статус платежа |
| paid_at | Время оплаты |
| amount | Сумма платежа |

Связи:

- `payments.order\\\\\\\_id` → `orders.order\\\\\\\_id`

---

### order_status_history

История изменения статусов заказов.

| Поле | Описание |
|---|---|
| status_history_id | Уникальный идентификатор записи |
| order_id | Заказ |
| status | Статус заказа |
| status_changed_at | Время изменения статуса |

Связи:

- `order\\\\\\\_status\\\\\\\_history.order\\\\\\\_id` → `orders.order\\\\\\\_id`

---

### app_events

Таблица событий пользователей в приложении.

| Поле | Описание |
|---|---|
| event_id | Уникальный идентификатор события |
| user_id | Пользователь |
| event_time | Время события |
| event_type | Тип события |
| restaurant_id | Ресторан, связанный с событием |
| product_id | Товар, связанный с событием |
| order_id | Заказ, связанный с событием |

Связи:

- `app\\\\\\\_events.user\\\\\\\_id` → `users.user\\\\\\\_id`
- `app\\\\\\\_events.restaurant\\\\\\\_id` → `restaurants.restaurant\\\\\\\_id`
- `app\\\\\\\_events.product\\\\\\\_id` → `products.product\\\\\\\_id`
- `app\\\\\\\_events.order\\\\\\\_id` → `orders.order\\\\\\\_id`

## Основные связи

- `users` 1 → N `orders`
- `users` 1 → N `app\\\\\\\_events`
- `restaurants` 1 → N `products`
- `restaurants` 1 → N `orders`
- `categories` 1 → N `products`
- `categories` 1 → N `categories`
- `orders` 1 → N `order\\\\\\\_items`
- `products` 1 → N `order\\\\\\\_items`
- `orders` 1 → 1 `payments`
- `orders` 1 → N `order\\\\\\\_status\\\\\\\_history`
- `couriers` 1 → N `orders`
- `promocodes` 1 → N `orders`
