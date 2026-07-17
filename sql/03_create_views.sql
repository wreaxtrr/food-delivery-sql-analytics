set search_path to food_delivery;

drop view if exists v_daily_metrics;
drop view if exists v_order_summary;

create view v_order_summary as

with item_stats as (
    select
        order_id,
        sum(quantity) as items_count,
        sum(quantity * unit_price) as items_amount
    from order_items
    group by order_id
),

delivery_stats as (
    select
        order_id,
        min(status_changed_at) filter (
            where status = 'delivered'
        ) as delivered_at
    from order_status_history
    group by order_id
)

select
    o.order_id,
    o.order_created_at,
    o.user_id,
    u.city as user_city,
    o.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    o.courier_id,
    o.promocode_id,
    p.code as promocode,
    o.order_status,

    coalesce(i.items_count, 0) as items_count,
    coalesce(i.items_amount, 0) as items_amount,

    o.delivery_fee,
    o.discount_amount,
    o.total_amount,

    pay.payment_method,
    pay.payment_status,

    d.delivered_at,

    round(
        (
            extract(epoch from (
                d.delivered_at - o.order_created_at
            )) / 60
        )::numeric,
        2
    ) as delivery_minutes

from orders o
join users u
    on u.user_id = o.user_id
join restaurants r
    on r.restaurant_id = o.restaurant_id
left join promocodes p
    on p.promocode_id = o.promocode_id
left join payments pay
    on pay.order_id = o.order_id
left join item_stats i
    on i.order_id = o.order_id
left join delivery_stats d
    on d.order_id = o.order_id;


create view v_daily_metrics as

select
    order_created_at::date as order_date,
    count(*) as orders_count,
    count(distinct user_id) as unique_users,
    round(sum(items_amount), 2) as items_gmv,
    round(sum(total_amount), 2) as total_gmv,
    round(avg(total_amount), 2) as avg_order_value,
    round(avg(delivery_minutes), 2) as avg_delivery_minutes

from v_order_summary
where order_status = 'delivered'
group by order_created_at::date;