drop schema if exists food_delivery cascade;
create schema food_delivery;

set search_path to food_delivery;

create table users (
    user_id bigserial primary key,
    full_name varchar(100) not null,
    email varchar(255) unique not null,
    phone varchar(20) unique,
    registration_date date not null default current_date,
    city varchar(100) not null
);

create table restaurants (
    restaurant_id bigserial primary key,
    restaurant_name varchar(150) not null,
    city varchar(100) not null,
    cuisine_type varchar(100) not null,
    opened_at date not null,
    is_active boolean not null default true
);

create table couriers (
    courier_id bigserial primary key,
    full_name varchar(100) not null,
    phone varchar(20) unique not null,
    hire_date date not null,
    transport_type varchar(50) not null check (transport_type in ('bike', 'scooter', 'car', 'walking')),
    is_active boolean not null default true
);

create table categories (
    category_id bigserial primary key,
    category_name varchar(100) not null,
    parent_category_id bigint references categories(category_id)
);

create table products (
    product_id bigserial primary key,
    restaurant_id bigint not null references restaurants(restaurant_id),
    category_id bigint not null references categories(category_id),
    product_name varchar(150) not null,
    price numeric(10, 2) not null check (price > 0),
    is_available boolean not null default true
);

create table promocodes (
    promocode_id bigserial primary key,
    code varchar(50) unique not null,
    discount_type varchar(20) not null check (discount_type in ('percent', 'fixed')),
    discount_value numeric(10, 2) not null check (discount_value > 0),
    starts_at date not null,
    ends_at date not null,
    is_active boolean not null default true,
    check (ends_at >= starts_at)
);

create table orders (
    order_id bigserial primary key,
    user_id bigint not null references users(user_id),
    restaurant_id bigint not null references restaurants(restaurant_id),
    courier_id bigint references couriers(courier_id),
    promocode_id bigint references promocodes(promocode_id),
    order_created_at timestamp not null default current_timestamp,
    order_status varchar(30) not null check (
        order_status in ('created', 'paid', 'cooking', 'delivering', 'delivered', 'cancelled')
    ),
    delivery_address text not null,
    delivery_fee numeric(10, 2) not null default 0 check (delivery_fee >= 0),
    discount_amount numeric(10, 2) not null default 0 check (discount_amount >= 0),
    total_amount numeric(10, 2) not null check (total_amount >= 0)
);

create table order_items (
    order_item_id bigserial primary key,
    order_id bigint not null references orders(order_id),
    product_id bigint not null references products(product_id),
    quantity int not null check (quantity > 0),
    unit_price numeric(10, 2) not null check (unit_price > 0)
);

create table payments (
    payment_id bigserial primary key,
    order_id bigint unique not null references orders(order_id),
    payment_method varchar(30) not null check (
        payment_method in ('card', 'cash', 'apple_pay', 'google_pay')
    ),
    payment_status varchar(30) not null check (
        payment_status in ('pending', 'paid', 'failed', 'refunded')
    ),
    paid_at timestamp,
    amount numeric(10, 2) not null check (amount >= 0)
);

create table order_status_history (
    status_history_id bigserial primary key,
    order_id bigint not null references orders(order_id),
    status varchar(30) not null check (
        status in ('created', 'paid', 'cooking', 'delivering', 'delivered', 'cancelled')
    ),
    status_changed_at timestamp not null default current_timestamp
);

create table app_events (
    event_id bigserial primary key,
    user_id bigint not null references users(user_id),
    event_time timestamp not null default current_timestamp,
    event_type varchar(50) not null check (
        event_type in (
            'app_open',
            'restaurant_view',
            'product_view',
            'add_to_cart',
            'checkout_start',
            'order_created'
        )
    ),
    restaurant_id bigint references restaurants(restaurant_id),
    product_id bigint references products(product_id),
    order_id bigint references orders(order_id)
);

select table_name
from information_schema.tables
where table_schema = 'food_delivery'
order by table_name;