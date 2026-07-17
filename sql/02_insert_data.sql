set search_path to food_delivery;

truncate table
    app_events,
    order_status_history,
    payments,
    order_items,
    orders,
    products,
    promocodes,
    categories,
    couriers,
    restaurants,
    users
restart identity cascade;


-- пользователи

insert into users (
    full_name,
    email,
    phone,
    registration_date,
    city
)
select
    'User ' || n,
    'user' || n || '@mail.com',
    '+7999' || lpad(n::text, 7, '0'),
    date '2023-01-01' + floor(random() * 500)::int,
    (array[
        'Moscow',
        'Saint Petersburg',
        'Kazan',
        'Novosibirsk',
        'Sochi'
    ])[floor(random() * 5)::int + 1]
from generate_series(1, 500) as n;


-- рестораны

insert into restaurants (
    restaurant_name,
    city,
    cuisine_type,
    opened_at,
    is_active
)
values
    ('Burger House', 'Moscow', 'Burgers', '2021-04-10', true),
    ('Pizza Time', 'Moscow', 'Pizza', '2020-09-15', true),
    ('Sushi Place', 'Saint Petersburg', 'Sushi', '2022-02-01', true),
    ('Wok Street', 'Kazan', 'Asian', '2021-11-20', true),
    ('Taco City', 'Moscow', 'Mexican', '2023-03-18', true),
    ('Pasta Bar', 'Saint Petersburg', 'Italian', '2020-06-05', true),
    ('Green Bowl', 'Sochi', 'Healthy', '2022-07-12', true),
    ('Coffee Point', 'Moscow', 'Coffee', '2019-12-01', true),
    ('Kebab Master', 'Kazan', 'Street Food', '2021-08-25', true),
    ('Breakfast Club', 'Novosibirsk', 'Breakfast', '2023-01-10', true);


-- курьеры

insert into couriers (
    full_name,
    phone,
    hire_date,
    transport_type,
    is_active
)
select
    'Courier ' || n,
    '+7888' || lpad(n::text, 7, '0'),
    date '2022-01-01' + floor(random() * 700)::int,
    (array[
        'bike',
        'scooter',
        'car',
        'walking'
    ])[floor(random() * 4)::int + 1],
    true
from generate_series(1, 40) as n;


-- категории

insert into categories (
    category_name,
    parent_category_id
)
values
    ('Food', null),
    ('Drinks', null),
    ('Burgers', 1),
    ('Pizza', 1),
    ('Sushi', 1),
    ('Pasta', 1),
    ('Salads', 1),
    ('Coffee', 2),
    ('Tea', 2),
    ('Desserts', 1);


-- товары
-- у каждого ресторана будет по 12 товаров

insert into products (
    restaurant_id,
    category_id,
    product_name,
    price,
    is_available
)
select
    ((n - 1) % 10) + 1,
    ((n - 1) % 8) + 3,
    'Product ' || n,
    round((250 + random() * 950)::numeric, 2),
    true
from generate_series(1, 120) as n;


-- промокоды

insert into promocodes (
    code,
    discount_type,
    discount_value,
    starts_at,
    ends_at,
    is_active
)
values
    ('WELCOME10', 'percent', 10, '2024-01-01', '2024-12-31', true),
    ('SALE15', 'percent', 15, '2024-03-01', '2024-06-30', true),
    ('FOOD200', 'fixed', 200, '2024-01-01', '2024-12-31', true),
    ('SUMMER20', 'percent', 20, '2024-06-01', '2024-08-31', true),
    ('DELIVERY100', 'fixed', 100, '2024-01-01', '2024-12-31', true);


-- заказы

insert into orders (
    user_id,
    restaurant_id,
    courier_id,
    promocode_id,
    order_created_at,
    order_status,
    delivery_address,
    delivery_fee,
    discount_amount,
    total_amount
)
select
    floor(random() * 500)::int + 1,
    floor(random() * 10)::int + 1,
    floor(random() * 40)::int + 1,

    case
        when random() < 0.35
            then floor(random() * 5)::int + 1
        else null
    end,

    timestamp '2024-01-01'
        + random() * interval '365 days',

    case
        when random() < 0.08 then 'cancelled'
        else 'delivered'
    end,

    'Address ' || n,
    round((99 + random() * 200)::numeric, 2),
    0,
    0
from generate_series(1, 3000) as n;


-- позиции заказов
-- в заказ попадают товары только из выбранного ресторана

insert into order_items (
    order_id,
    product_id,
    quantity,
    unit_price
)
select
    o.order_id,
    p.product_id,
    floor(random() * 3)::int + 1,
    p.price
from orders o
join lateral (
    select
        product_id,
        price
    from products p
    where p.restaurant_id = o.restaurant_id
    order by random()
    limit 3
) p on true;


-- рассчитываем скидку и итоговую сумму

with order_sums as (
    select
        order_id,
        sum(quantity * unit_price) as items_sum
    from order_items
    group by order_id
)
update orders o
set
    discount_amount =
        case
            when p.promocode_id is null then 0

            when p.discount_type = 'percent' then
                round(
                    least(
                        s.items_sum,
                        s.items_sum * p.discount_value / 100
                    ),
                    2
                )

            when p.discount_type = 'fixed' then
                least(s.items_sum, p.discount_value)

            else 0
        end,

    total_amount =
        round(
            greatest(
                0,
                s.items_sum
                + o.delivery_fee
                - case
                    when p.promocode_id is null then 0

                    when p.discount_type = 'percent' then
                        least(
                            s.items_sum,
                            s.items_sum * p.discount_value / 100
                        )

                    when p.discount_type = 'fixed' then
                        least(s.items_sum, p.discount_value)

                    else 0
                end
            ),
            2
        )
from order_sums s
left join promocodes p
    on p.promocode_id = o.promocode_id
where o.order_id = s.order_id;


-- платежи

insert into payments (
    order_id,
    payment_method,
    payment_status,
    paid_at,
    amount
)
select
    order_id,

    (array[
        'card',
        'cash',
        'apple_pay',
        'google_pay'
    ])[floor(random() * 4)::int + 1],

    case
        when order_status = 'cancelled' then 'refunded'
        else 'paid'
    end,

    order_created_at + interval '10 minutes',
    total_amount
from orders;


-- история статусов

insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'created',
    order_created_at
from orders;


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'paid',
    order_created_at + interval '10 minutes'
from orders
where order_status <> 'cancelled';


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'cooking',
    order_created_at + interval '20 minutes'
from orders
where order_status <> 'cancelled';


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'delivering',
    order_created_at + interval '40 minutes'
from orders
where order_status <> 'cancelled';


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'delivered',
    order_created_at + interval '65 minutes'
from orders
where order_status = 'delivered';


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'cancelled',
    order_created_at + interval '15 minutes'
from orders
where order_status = 'cancelled';


-- открытия приложения

insert into app_events (
    user_id,
    event_time,
    event_type
)
select
    user_id,
    order_created_at - interval '20 minutes',
    'app_open'
from orders;


-- просмотры ресторанов

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id
)
select
    user_id,
    order_created_at - interval '15 minutes',
    'restaurant_view',
    restaurant_id
from orders;


-- просмотры товаров

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id,
    product_id
)
select
    o.user_id,
    o.order_created_at - interval '10 minutes',
    'product_view',
    o.restaurant_id,
    oi.product_id
from orders o
join order_items oi
    on oi.order_id = o.order_id;


-- добавления в корзину

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id,
    product_id
)
select
    o.user_id,
    o.order_created_at - interval '5 minutes',
    'add_to_cart',
    o.restaurant_id,
    oi.product_id
from orders o
join order_items oi
    on oi.order_id = o.order_id;


-- переходы к оформлению

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id
)
select
    user_id,
    order_created_at - interval '2 minutes',
    'checkout_start',
    restaurant_id
from orders;


-- создание заказов

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id,
    order_id
)
select
    user_id,
    order_created_at,
    'order_created',
    restaurant_id,
    order_id
from orders;


-- проверка количества строк

select
    'users' as table_name,
    count(*) as rows_count
from users

union all

select
    'restaurants',
    count(*)
from restaurants

union all

select
    'couriers',
    count(*)
from couriers

union all

select
    'products',
    count(*)
from products

union all

select
    'orders',
    count(*)
from orders

union all

select
    'order_items',
    count(*)
from order_items

union all

select
    'payments',
    count(*)
from payments

union all

select
    'app_events',
    count(*)
from app_events;