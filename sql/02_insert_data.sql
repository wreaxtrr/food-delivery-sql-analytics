set search_path to food_delivery;

select setseed(0.42);

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
    date '2023-01-01' + floor(random() * 365)::int,
    (array[
        'Moscow',
        'Saint Petersburg',
        'Kazan',
        'Novosibirsk',
        'Sochi'
    ])[floor(random() * 5)::int + 1]
from generate_series(1, 500) as gs(n);


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
from generate_series(1, 40) as gs(n);


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
from generate_series(1, 120) as gs(n);


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

with generated_orders as (
    select
        n,
        floor(random() * 500)::bigint + 1 as user_id,
        timestamp '2024-01-02'
            + random() * interval '364 days' as order_created_at,
        random() as promo_probability,
        random() as cancellation_probability
    from generate_series(1, 3000) as gs(n)
),

prepared_orders as (
    select
        g.n,
        g.user_id,
        u.city as user_city,
        r.restaurant_id,
        floor(random() * 40)::bigint + 1 as courier_id,
        g.order_created_at,
        g.promo_probability,
        g.cancellation_probability
    from generated_orders g
    join users u
        on u.user_id = g.user_id
    cross join lateral (
        select restaurant_id
        from restaurants r
        where r.city = u.city
        order by random()
        limit 1
    ) r
),

orders_with_promo as (
    select
        o.*,
        p.promocode_id
    from prepared_orders o
    left join lateral (
        select promocode_id
        from promocodes p
        where o.promo_probability < 0.35
          and p.is_active = true
          and o.order_created_at::date
              between p.starts_at and p.ends_at
        order by random()
        limit 1
    ) p on true
)

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
    user_id,
    restaurant_id,
    courier_id,
    promocode_id,
    order_created_at,

    case
        when cancellation_probability < 0.08 then 'cancelled'
        else 'delivered'
    end,

    user_city || ', Address ' || n,
    round((99 + random() * 200)::numeric, 2),
    0,
    0
from orders_with_promo;


-- позиции заказов
-- в каждом заказе три товара из нужного ресторана

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


-- скидки и итоговая сумма

with order_sums as (
    select
        order_id,
        sum(quantity * unit_price) as items_sum
    from order_items
    group by order_id
),

order_values as (
    select
        o.order_id,
        s.items_sum,

        case
            when p.promocode_id is null then 0

            when p.discount_type = 'percent' then
                least(
                    s.items_sum,
                    s.items_sum * p.discount_value / 100
                )

            when p.discount_type = 'fixed' then
                least(s.items_sum, p.discount_value)

            else 0
        end as discount_amount

    from orders o
    join order_sums s
        on s.order_id = o.order_id
    left join promocodes p
        on p.promocode_id = o.promocode_id
)

update orders o
set
    discount_amount = round(v.discount_amount, 2),

    total_amount = round(
        greatest(
            0,
            v.items_sum
            + o.delivery_fee
            - v.discount_amount
        ),
        2
    )

from order_values v
where v.order_id = o.order_id;


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

    order_created_at + interval '5 minutes',
    total_amount
from orders;


-- план доставки
-- время зависит от транспорта и отличается для каждого заказа

drop table if exists delivery_plan;

create temp table delivery_plan as
select
    o.order_id,

    case c.transport_type
        when 'scooter' then 25 + floor(random() * 46)::int
        when 'bike' then 30 + floor(random() * 51)::int
        when 'car' then 30 + floor(random() * 61)::int
        when 'walking' then 45 + floor(random() * 56)::int
    end as delivery_minutes

from orders o
join couriers c
    on c.courier_id = o.courier_id
where o.order_status = 'delivered';


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
    order_created_at + interval '5 minutes'
from orders;


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    order_id,
    'cooking',
    order_created_at + interval '12 minutes'
from orders
where order_status = 'delivered';


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    o.order_id,
    'delivering',
    o.order_created_at
        + (
            greatest(18, d.delivery_minutes - 15)::text
            || ' minutes'
        )::interval
from orders o
join delivery_plan d
    on d.order_id = o.order_id;


insert into order_status_history (
    order_id,
    status,
    status_changed_at
)
select
    o.order_id,
    'delivered',
    o.order_created_at
        + (d.delivery_minutes::text || ' minutes')::interval
from orders o
join delivery_plan d
    on d.order_id = o.order_id;


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


-- события пользователей, которые оформили заказ

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
    item.product_id
from orders o
join lateral (
    select product_id
    from order_items oi
    where oi.order_id = o.order_id
    order by oi.order_item_id
    limit 1
) item on true;


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
    item.product_id
from orders o
join lateral (
    select product_id
    from order_items oi
    where oi.order_id = o.order_id
    order by oi.order_item_id
    limit 1
) item on true;


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


-- дополнительные сессии без заказа
-- они нужны, чтобы в воронке были пользователи,
-- которые остановились на разных этапах

drop table if exists funnel_sessions;

create temp table funnel_sessions as

with sessions as (
    select
        n as session_number,
        floor(random() * 500)::bigint + 1 as user_id,
        timestamp '2024-01-02'
            + random() * interval '364 days' as session_started_at,
        random() as funnel_progress
    from generate_series(1, 4000) as gs(n)
),

sessions_with_restaurants as (
    select
        s.*,
        r.restaurant_id
    from sessions s
    join users u
        on u.user_id = s.user_id
    cross join lateral (
        select restaurant_id
        from restaurants r
        where r.city = u.city
        order by random()
        limit 1
    ) r
)

select
    s.*,
    p.product_id
from sessions_with_restaurants s
cross join lateral (
    select product_id
    from products p
    where p.restaurant_id = s.restaurant_id
    order by random()
    limit 1
) p;


-- все дополнительные сессии открыли приложение

insert into app_events (
    user_id,
    event_time,
    event_type
)
select
    user_id,
    session_started_at,
    'app_open'
from funnel_sessions;


-- 75% дошли до просмотра ресторана

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id
)
select
    user_id,
    session_started_at + interval '2 minutes',
    'restaurant_view',
    restaurant_id
from funnel_sessions
where funnel_progress < 0.75;


-- 55% дошли до просмотра товара

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id,
    product_id
)
select
    user_id,
    session_started_at + interval '4 minutes',
    'product_view',
    restaurant_id,
    product_id
from funnel_sessions
where funnel_progress < 0.55;


-- 35% добавили товар в корзину

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id,
    product_id
)
select
    user_id,
    session_started_at + interval '7 minutes',
    'add_to_cart',
    restaurant_id,
    product_id
from funnel_sessions
where funnel_progress < 0.35;


-- 18% начали оформление, но не создали заказ

insert into app_events (
    user_id,
    event_time,
    event_type,
    restaurant_id
)
select
    user_id,
    session_started_at + interval '10 minutes',
    'checkout_start',
    restaurant_id
from funnel_sessions
where funnel_progress < 0.18;


analyze;


-- количество строк

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


-- проверка логической согласованности данных

select
    count(*) filter (
        where o.order_created_at::date < u.registration_date
    ) as orders_before_registration,

    count(*) filter (
        where u.city <> r.city
    ) as city_mismatches,

    count(*) filter (
        where o.promocode_id is not null
          and o.order_created_at::date
              not between p.starts_at and p.ends_at
    ) as invalid_promocodes

from orders o
join users u
    on u.user_id = o.user_id
join restaurants r
    on r.restaurant_id = o.restaurant_id
left join promocodes p
    on p.promocode_id = o.promocode_id;


-- проверка времени доставки

with delivery_times as (
    select
        o.order_id,
        extract(
            epoch from (
                max(h.status_changed_at) filter (
                    where h.status = 'delivered'
                ) - o.order_created_at
            )
        ) / 60 as delivery_minutes

    from orders o
    join order_status_history h
        on h.order_id = o.order_id
    where o.order_status = 'delivered'
    group by
        o.order_id,
        o.order_created_at
)

select
    min(delivery_minutes) as min_delivery_minutes,
    round(avg(delivery_minutes), 2) as avg_delivery_minutes,
    max(delivery_minutes) as max_delivery_minutes
from delivery_times;


-- проверка продуктовой воронки

select
    event_type,
    count(*) as events_count
from app_events
group by event_type
order by case event_type
    when 'app_open' then 1
    when 'restaurant_view' then 2
    when 'product_view' then 3
    when 'add_to_cart' then 4
    when 'checkout_start' then 5
    when 'order_created' then 6
end;
