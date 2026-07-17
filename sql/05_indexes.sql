set search_path to food_delivery;

create index if not exists idx_orders_created_at
    on orders(order_created_at);

create index if not exists idx_orders_user_date
    on orders(user_id, order_created_at);

create index if not exists idx_orders_restaurant_date
    on orders(restaurant_id, order_created_at);

create index if not exists idx_orders_status_date
    on orders(order_status, order_created_at);

create index if not exists idx_order_items_order
    on order_items(order_id);

create index if not exists idx_order_items_product
    on order_items(product_id);

create index if not exists idx_status_history_order_status
    on order_status_history(order_id, status);

create index if not exists idx_app_events_user_time
    on app_events(user_id, event_time);

create index if not exists idx_app_events_type_time
    on app_events(event_type, event_time);

analyze;