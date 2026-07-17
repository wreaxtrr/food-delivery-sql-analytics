set search_path to food_delivery;


-- 1. основные метрики по месяцам

select
    date_trunc('month', order_created_at)::date as month,
    count(*) as orders_count,
    count(distinct user_id) as users_count,
    round(sum(total_amount), 2) as gmv,
    round(avg(total_amount), 2) as avg_order_value
from v_order_summary
where order_status = 'delivered'
group by 1
order by 1;


-- 2. изменение выручки относительно прошлого месяца

with monthly_metrics as (
    select
        date_trunc('month', order_created_at)::date as month,
        count(*) as orders_count,
        sum(total_amount) as gmv
    from v_order_summary
    where order_status = 'delivered'
    group by 1
),

metrics_with_lag as (
    select
        month,
        orders_count,
        gmv,
        lag(gmv) over (order by month) as previous_gmv
    from monthly_metrics
)

select
    month,
    orders_count,
    round(gmv, 2) as gmv,
    round(previous_gmv, 2) as previous_gmv,
    round(
        (gmv - previous_gmv) / nullif(previous_gmv, 0) * 100,
        2
    ) as gmv_growth_pct
from metrics_with_lag
order by month;


-- 3. топ-3 ресторана по выручке в каждом месяце

with restaurant_metrics as (
    select
        date_trunc('month', order_created_at)::date as month,
        restaurant_id,
        restaurant_name,
        count(*) as orders_count,
        sum(total_amount) as gmv
    from v_order_summary
    where order_status = 'delivered'
    group by 1, 2, 3
),

ranked_restaurants as (
    select
        *,
        dense_rank() over (
            partition by month
            order by gmv desc
        ) as restaurant_rank
    from restaurant_metrics
)

select
    month,
    restaurant_name,
    orders_count,
    round(gmv, 2) as gmv,
    restaurant_rank
from ranked_restaurants
where restaurant_rank <= 3
order by month, restaurant_rank;


-- 4. доля отменённых заказов по ресторанам

select
    restaurant_name,
    count(*) as all_orders,
    count(*) filter (
        where order_status = 'cancelled'
    ) as cancelled_orders,
    round(
        100.0 * count(*) filter (
            where order_status = 'cancelled'
        ) / nullif(count(*), 0),
        2
    ) as cancellation_rate
from v_order_summary
group by restaurant_name
order by cancellation_rate desc;


-- 5. эффективность курьеров

select
    c.courier_id,
    c.full_name,
    c.transport_type,
    count(*) as delivered_orders,
    round(avg(v.delivery_minutes), 2) as avg_delivery_minutes
from v_order_summary v
join couriers c
    on c.courier_id = v.courier_id
where v.order_status = 'delivered'
group by
    c.courier_id,
    c.full_name,
    c.transport_type
having count(*) >= 10
order by avg_delivery_minutes, delivered_orders desc;


-- 6. сравнение заказов с промокодом и без него

select
    case
        when promocode_id is null then 'without promo'
        else 'with promo'
    end as promo_group,
    count(*) as orders_count,
    round(avg(total_amount), 2) as avg_order_value,
    round(sum(total_amount), 2) as gmv,
    round(
        100.0 * count(*) filter (
            where order_status = 'cancelled'
        ) / nullif(count(*), 0),
        2
    ) as cancellation_rate
from v_order_summary
group by 1
order by 1;


-- 7. доля пользователей с повторными заказами

with user_orders as (
    select
        user_id,
        count(*) as orders_count
    from v_order_summary
    where order_status = 'delivered'
    group by user_id
)

select
    count(*) as buyers_count,
    count(*) filter (
        where orders_count >= 2
    ) as repeat_buyers_count,
    round(
        100.0 * count(*) filter (
            where orders_count >= 2
        ) / nullif(count(*), 0),
        2
    ) as repeat_buyer_rate
from user_orders;


-- 8. когортный retention по месяцам

with user_months as (
    select distinct
        user_id,
        date_trunc('month', order_created_at)::date as order_month
    from v_order_summary
    where order_status = 'delivered'
),

cohorts as (
    select
        user_id,
        min(order_month) as cohort_month
    from user_months
    group by user_id
),

activity as (
    select
        um.user_id,
        c.cohort_month,
        um.order_month,
        (
            extract(year from age(um.order_month, c.cohort_month)) * 12
            + extract(month from age(um.order_month, c.cohort_month))
        )::int as month_number
    from user_months um
    join cohorts c
        on c.user_id = um.user_id
),

cohort_sizes as (
    select
        cohort_month,
        count(*) as cohort_size
    from cohorts
    group by cohort_month
),

retention as (
    select
        cohort_month,
        month_number,
        count(distinct user_id) as active_users
    from activity
    group by cohort_month, month_number
)

select
    r.cohort_month,
    r.month_number,
    cs.cohort_size,
    r.active_users,
    round(
        100.0 * r.active_users / nullif(cs.cohort_size, 0),
        2
    ) as retention_rate
from retention r
join cohort_sizes cs
    on cs.cohort_month = r.cohort_month
order by r.cohort_month, r.month_number;


-- 9. RFM-анализ пользователей

with user_stats as (
    select
        user_id,
        date '2025-01-01' - max(order_created_at)::date as recency_days,
        count(*) as frequency,
        round(sum(total_amount), 2) as monetary
    from v_order_summary
    where order_status = 'delivered'
    group by user_id
),

rfm_scores as (
    select
        *,
        ntile(4) over (
            order by recency_days desc
        ) as r_score,
        ntile(4) over (
            order by frequency
        ) as f_score,
        ntile(4) over (
            order by monetary
        ) as m_score
    from user_stats
)

select
    user_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    concat(r_score, f_score, m_score) as rfm_code
from rfm_scores
order by r_score desc, f_score desc, m_score desc;


-- 10. дерево категорий через рекурсивный CTE

with recursive category_tree as (
    select
        category_id,
        category_name,
        parent_category_id,
        1 as category_level,
        category_name::text as category_path
    from categories
    where parent_category_id is null

    union all

    select
        c.category_id,
        c.category_name,
        c.parent_category_id,
        ct.category_level + 1,
        ct.category_path || ' > ' || c.category_name
    from categories c
    join category_tree ct
        on ct.category_id = c.parent_category_id
)

select
    category_id,
    category_name,
    category_level,
    category_path
from category_tree
order by category_path;