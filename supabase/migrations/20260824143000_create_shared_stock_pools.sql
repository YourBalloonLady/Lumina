-- Give every vial/pen pair one authoritative stock balance.
-- Products.stock remains a mirrored compatibility field for the existing site.

select pg_catalog.pg_advisory_xact_lock(2026082401::bigint);

drop trigger if exists sync_paired_product_stock_trigger on public."Products";

create temporary table _lumina_stock_map (
  group_id text not null,
  label text not null,
  product_name text primary key
) on commit drop;

insert into _lumina_stock_map (group_id, label, product_name) values
  ('5-amino-1mq-50mg', '5 Amino 1MQ 50mg', '5 amino 1mq'),
  ('5-amino-1mq-50mg', '5 Amino 1MQ 50mg', '5 amino 1mq pen 50mg'),
  ('bpc157-tb500-10mg', 'BPC-157 + TB500 10mg', 'bpc-157 & tb500 blend 10mg'),
  ('bpc157-tb500-10mg', 'BPC-157 + TB500 10mg', 'bpc-157 + tb500 10mg pen'),
  ('cagrilintide-10mg', 'Cagrilintide 10mg', 'cagrilintide 10mg'),
  ('cagrilintide-10mg', 'Cagrilintide 10mg', 'cagrilintide 10mg pen'),
  ('cjc-ipamorelin-10mg', 'CJC-1295 + Ipamorelin 10mg', 'cjc-1295 (wo/dac) 5mg + ipamorelin 5mg pen'),
  ('cjc-ipamorelin-10mg', 'CJC-1295 + Ipamorelin 10mg', 'cjc-1295 (wo/dac) 5mg + ipamorelin 5mg vial'),
  ('epithalon-10mg', 'Epithalon 10mg', 'epithalon 10mg pen'),
  ('epithalon-10mg', 'Epithalon 10mg', 'epithalon 10mg vial'),
  ('ghk-cu-100mg', 'GHK-CU 100mg', 'ghk-cu 100mg'),
  ('ghk-cu-100mg', 'GHK-CU 100mg', 'ghk-cu 100mg pen'),
  ('klow-blend-80mg', 'Klow Blend 80mg', 'klow blend 80mg pen'),
  ('klow-blend-80mg', 'Klow Blend 80mg', 'klow blend 80mg vial'),
  ('mots-c-40mg', 'MOTS-C 40mg', 'mots-c 40mg pen'),
  ('mots-c-40mg', 'MOTS-C 40mg', 'mots-c 40mg vial'),
  ('mt-2-10mg', 'MT-2 10mg', 'mt-2 10mg'),
  ('mt-2-10mg', 'MT-2 10mg', 'mt-2 pen'),
  ('nad-plus-1000mg', 'NAD+ 1000mg', 'nad+1000mg pen'),
  ('nad-plus-1000mg', 'NAD+ 1000mg', 'nad+1000mg vial'),
  ('retatrutide-20mg', 'Retatrutide 20mg', 'retatrutide 20mg pen'),
  ('retatrutide-20mg', 'Retatrutide 20mg', 'retatrutide 20mg vial'),
  ('retatrutide-30mg', 'Retatrutide 30mg', 'retatrutide 30mg pen'),
  ('retatrutide-30mg', 'Retatrutide 30mg', 'retatrutide 30mg vial'),
  ('retatrutide-40mg', 'Retatrutide 40mg', 'retatrutide 40mg pen'),
  ('retatrutide-40mg', 'Retatrutide 40mg', 'retatrutide 40mg vial'),
  ('retatrutide-60mg', 'Retatrutide 60mg', 'retatrutide 60mg pen'),
  ('retatrutide-60mg', 'Retatrutide 60mg', 'retatrutide 60mg vial'),
  ('selank-10mg', 'Selank 10mg', 'selank 10mg pen'),
  ('selank-10mg', 'Selank 10mg', 'selank 10mg vial'),
  ('semaglutide-20mg', 'Semaglutide 20mg', 'semaglutide 20mg pen'),
  ('semaglutide-20mg', 'Semaglutide 20mg', 'semaglutide 20mg vial'),
  ('semaglutide-30mg', 'Semaglutide 30mg', 'semaglutide 30mg pen'),
  ('semaglutide-30mg', 'Semaglutide 30mg', 'semaglutide 30mg vial'),
  ('semax-10mg', 'Semax 10mg', 'semax 10mg pen'),
  ('semax-10mg', 'Semax 10mg', 'semax 10mg vial'),
  ('slu-pp-332', 'SLU-PP-332', 'slu-pp-332 pen'),
  ('slu-pp-332', 'SLU-PP-332', 'slu-pp-332 vial'),
  ('ss-31', 'SS-31', 'ss-31 pen'),
  ('ss-31', 'SS-31', 'ss-31 vial'),
  ('tesamorelin-10mg', 'Tesamorelin 10mg', 'tesamorelin 10mg vial'),
  ('tesamorelin-10mg', 'Tesamorelin 10mg', 'tesamorelin pen 10mg'),
  ('tirzepatide-10mg', 'Tirzepatide 10mg', 'tirzepatide 10mg pen'),
  ('tirzepatide-10mg', 'Tirzepatide 10mg', 'tirzepatide 10mg vial'),
  ('tirzepatide-20mg', 'Tirzepatide 20mg', 'tirzepatide 20mg pen'),
  ('tirzepatide-20mg', 'Tirzepatide 20mg', 'tirzepatide 20mg vial'),
  ('tirzepatide-30mg', 'Tirzepatide 30mg', 'tirzepatide 30mg pen'),
  ('tirzepatide-30mg', 'Tirzepatide 30mg', 'tirzepatide 30mg vial'),
  ('tirzepatide-40mg', 'Tirzepatide 40mg', 'tirzepatide 40mg pen'),
  ('tirzepatide-40mg', 'Tirzepatide 40mg', 'tirzepatide 40mg vial'),
  ('tirzepatide-60mg', 'Tirzepatide 60mg', 'tirzepatide 60mg pen'),
  ('tirzepatide-60mg', 'Tirzepatide 60mg', 'tirzepatide 60mg vial');

do $validation$
declare
  v_missing_products text;
begin
  select pg_catalog.string_agg(m.product_name, ', ' order by m.product_name)
  into v_missing_products
  from _lumina_stock_map m
  left join public."Products" p
    on lower(pg_catalog.btrim(p.name, E' \t\n\r')) = m.product_name
  where p.id is null;

  if v_missing_products is not null then
    raise exception
      'Shared-stock cutover stopped: mapped products are missing: %',
      v_missing_products;
  end if;

  if exists (
    select m.group_id
    from _lumina_stock_map m
    join public."Products" p
      on lower(pg_catalog.btrim(p.name, E' \t\n\r')) = m.product_name
    group by m.group_id
    having count(*) <> 2
  ) then
    raise exception 'Shared-stock cutover stopped: every group must resolve to exactly two products.';
  end if;
end;
$validation$;

create table if not exists public.stock_groups (
  id text primary key,
  label text not null,
  stock integer not null check (stock >= 0),
  updated_at timestamp with time zone not null default pg_catalog.clock_timestamp()
);

alter table public.stock_groups enable row level security;
revoke all on table public.stock_groups from public, anon, authenticated;

alter table public."Products"
  add column if not exists stock_group_id text;

create index if not exists products_stock_group_id_idx
  on public."Products" (stock_group_id)
  where stock_group_id is not null;

insert into public.stock_groups (id, label, stock)
select
  m.group_id,
  max(m.label),
  min(p.stock)
from _lumina_stock_map m
join public."Products" p
  on lower(pg_catalog.btrim(p.name, E' \t\n\r')) = m.product_name
group by m.group_id
on conflict (id) do update
set label = excluded.label;

update public."Products" p
set stock_group_id = m.group_id
from _lumina_stock_map m
where lower(pg_catalog.btrim(p.name, E' \t\n\r')) = m.product_name
  and p.stock_group_id is distinct from m.group_id;

do $constraint$
begin
  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public."Products"'::regclass
      and conname = 'products_stock_group_fk'
  ) then
    alter table public."Products"
      add constraint products_stock_group_fk
      foreign key (stock_group_id)
      references public.stock_groups(id)
      on update cascade
      on delete restrict
      not valid;
  end if;
end;
$constraint$;

alter table public."Products"
  validate constraint products_stock_group_fk;

-- Reconcile existing drift to the lower currently sellable figure. Once live,
-- setting either paired row in Admin replaces this temporary baseline for both.
update public."Products" p
set stock = g.stock
from public.stock_groups g
where p.stock_group_id = g.id
  and p.stock is distinct from g.stock;

create or replace function public.lock_shared_stock_write()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  perform pg_catalog.pg_advisory_xact_lock(2026082401::bigint);
  return null;
end;
$function$;

create or replace function public.mirror_stock_group_to_products()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_previous text := pg_catalog.current_setting('lumina.stock_mirror', true);
begin
  perform pg_catalog.set_config('lumina.stock_mirror', 'on', true);

  update public."Products" p
  set stock = new.stock
  where p.stock_group_id = new.id
    and p.stock is distinct from new.stock;

  perform pg_catalog.set_config(
    'lumina.stock_mirror',
    coalesce(nullif(v_previous, ''), 'off'),
    true
  );
  return new;
exception when others then
  perform pg_catalog.set_config(
    'lumina.stock_mirror',
    coalesce(nullif(v_previous, ''), 'off'),
    true
  );
  raise;
end;
$function$;

create or replace function public.mirror_product_stock_to_group()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.stock_group_id is null
     or new.stock is not distinct from old.stock
     or pg_catalog.current_setting('lumina.stock_mirror', true) = 'on' then
    return new;
  end if;

  update public.stock_groups g
  set stock = new.stock,
      updated_at = pg_catalog.clock_timestamp()
  where g.id = new.stock_group_id;

  if not found then
    raise exception 'Unknown shared stock group %.', new.stock_group_id;
  end if;

  return new;
end;
$function$;

create or replace function public.hydrate_product_stock_from_group()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.stock_group_id is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and new.stock_group_id is not distinct from old.stock_group_id then
    return new;
  end if;

  select g.stock
  into new.stock
  from public.stock_groups g
  where g.id = new.stock_group_id;

  if not found then
    raise exception 'Unknown shared stock group %.', new.stock_group_id;
  end if;

  return new;
end;
$function$;

drop trigger if exists lock_product_stock_writes on public."Products";
create trigger lock_product_stock_writes
before update of stock on public."Products"
for each statement
execute function public.lock_shared_stock_write();

drop trigger if exists lock_stock_group_writes on public.stock_groups;
create trigger lock_stock_group_writes
before update of stock on public.stock_groups
for each statement
execute function public.lock_shared_stock_write();

drop trigger if exists product_stock_to_group on public."Products";
create trigger product_stock_to_group
after update of stock on public."Products"
for each row
when (old.stock is distinct from new.stock)
execute function public.mirror_product_stock_to_group();

drop trigger if exists stock_group_to_products on public.stock_groups;
create trigger stock_group_to_products
after insert or update of stock on public.stock_groups
for each row
execute function public.mirror_stock_group_to_products();

drop trigger if exists hydrate_product_stock_group on public."Products";
create trigger hydrate_product_stock_group
before insert or update of stock_group_id on public."Products"
for each row
execute function public.hydrate_product_stock_from_group();

-- The current checkout function remains responsible for validation, prices and
-- order creation. This wrapper reserves each shared group once, lets that
-- function build the order, then writes the final shared balance to both rows.
create or replace function public.place_order(
  p_customer jsonb,
  p_items jsonb,
  p_delivery_method text default 'tracked24'::text,
  p_referral_code text default null::text,
  p_telegram_token text default null::text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_result jsonb;
  v_item jsonb;
  v_items jsonb := '[]'::jsonb;
  v_quantity integer;
  v_total_quantity integer := 0;
  v_product_subtotal numeric(12, 2) := 0;
  v_unit_price numeric(12, 2);
  v_regular_line_total numeric(12, 2);
  v_line_discount numeric(12, 2);
  v_discount numeric(12, 2) := 0;
  v_total numeric(12, 2);
  v_order_id uuid;
  v_reference text;
  v_shared record;
  v_stock_targets jsonb := '{}'::jsonb;
  v_previous_mirror text := pg_catalog.current_setting('lumina.stock_mirror', true);
begin
  perform pg_catalog.pg_advisory_xact_lock(2026082401::bigint);

  if pg_catalog.jsonb_typeof(p_items) <> 'array' then
    raise exception using errcode = '22023', message = 'The cart is invalid.';
  end if;

  for v_shared in
    with requested as (
      select
        p.stock_group_id,
        sum((item.value->>'qty')::integer)::integer as requested_quantity
      from pg_catalog.jsonb_array_elements(p_items) item(value)
      join public."Products" p
        on p.id = (item.value->>'id')::uuid
      where p.stock_group_id is not null
      group by p.stock_group_id
    )
    select
      requested.stock_group_id,
      requested.requested_quantity,
      g.stock,
      g.label
    from requested
    join public.stock_groups g
      on g.id = requested.stock_group_id
    order by requested.stock_group_id
    for update of g
  loop
    if v_shared.requested_quantity > v_shared.stock then
      raise exception using
        errcode = 'P0001',
        message = pg_catalog.format(
          'Only %s shared unit(s) of %s remain in stock.',
          v_shared.stock,
          v_shared.label
        );
    end if;

    v_stock_targets := v_stock_targets || pg_catalog.jsonb_build_object(
      v_shared.stock_group_id,
      v_shared.stock - v_shared.requested_quantity
    );
  end loop;

  perform pg_catalog.set_config('lumina.stock_mirror', 'on', true);

  begin
    v_result := public.place_order_without_volume_offers(
      p_customer,
      p_items,
      p_delivery_method,
      p_referral_code,
      p_telegram_token
    );

    for v_shared in
      select key as stock_group_id, value::integer as target_stock
      from pg_catalog.jsonb_each_text(v_stock_targets)
    loop
      update public.stock_groups
      set stock = v_shared.target_stock,
          updated_at = pg_catalog.clock_timestamp()
      where id = v_shared.stock_group_id;
    end loop;

    perform pg_catalog.set_config(
      'lumina.stock_mirror',
      coalesce(nullif(v_previous_mirror, ''), 'off'),
      true
    );
  exception when others then
    perform pg_catalog.set_config(
      'lumina.stock_mirror',
      coalesce(nullif(v_previous_mirror, ''), 'off'),
      true
    );
    raise;
  end;

  select
    coalesce(sum(greatest(0, coalesce((value->>'qty')::integer, 0))), 0)::integer,
    coalesce(sum(
      greatest(0, coalesce((value->>'qty')::integer, 0))
      * greatest(0, coalesce((value->>'price_each')::numeric, 0))
    ), 0)::numeric(12, 2)
  into v_total_quantity, v_product_subtotal
  from pg_catalog.jsonb_array_elements(v_result->'items');

  if v_total_quantity >= 3 then
    v_discount := round(v_product_subtotal * 0.10, 2);
  end if;

  for v_item in select value from pg_catalog.jsonb_array_elements(v_result->'items')
  loop
    v_quantity := greatest(0, coalesce((v_item->>'qty')::integer, 0));
    v_unit_price := greatest(0, coalesce((v_item->>'price_each')::numeric, 0));
    v_regular_line_total := v_unit_price * v_quantity;
    v_line_discount := case
      when v_total_quantity >= 3 then round(v_regular_line_total * 0.10, 2)
      else 0
    end;

    v_items := v_items || pg_catalog.jsonb_build_array(
      v_item || pg_catalog.jsonb_build_object(
        'line_total', v_regular_line_total - v_line_discount,
        'promotion_discount', v_line_discount,
        'promotion_label', case
          when v_total_quantity >= 3 then '10% multi-product discount'
          else null
        end
      )
    );
  end loop;

  v_order_id := (v_result->>'order_id')::uuid;
  v_reference := v_result->>'reference';
  v_total := greatest(0, (v_result->>'total_amount')::numeric - v_discount);

  update public."Orders"
  set total_amount = v_total,
      details = details
        || pg_catalog.jsonb_build_object('items', v_items)
        || pg_catalog.jsonb_build_object(
          'meta',
          coalesce(details->'meta', '{}'::jsonb)
          || pg_catalog.jsonb_build_object('promotion_discount', v_discount)
        )
  where id = v_order_id;

  update public."ReferralEvents"
  set order_total = v_total
  where order_reference = v_reference;

  return v_result || pg_catalog.jsonb_build_object(
    'total_amount', v_total,
    'items', v_items,
    'promotion_discount', v_discount,
    'promotion_label', case
      when v_total_quantity >= 3 then '10% multi-product discount'
      else null
    end
  );
end;
$function$;

revoke execute on function public.place_order_without_volume_offers(jsonb, jsonb, text, text, text)
  from public, anon, authenticated;
grant execute on function public.place_order(jsonb, jsonb, text, text, text)
  to anon, authenticated;

create or replace function public.cancel_order_and_restock(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_order public."Orders"%rowtype;
  v_item jsonb;
  v_product public."Products"%rowtype;
  v_product_id uuid;
  v_quantity integer;
  v_group_quantities jsonb := '{}'::jsonb;
  v_product_quantities jsonb := '{}'::jsonb;
  v_entry record;
  v_updated_details jsonb;
  v_admin_email text := lower(coalesce(auth.email(), ''));
begin
  if v_admin_email <> 'luminaweight@gmail.com' then
    raise exception using errcode = '42501', message = 'Administrator access is required.';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(2026082401::bigint);

  select *
  into v_order
  from public."Orders"
  where id = p_order_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Order not found.';
  end if;

  if lower(coalesce(v_order.status, '')) = 'cancelled'
     or v_order.details #>> '{meta,restocked_at}' is not null then
    raise exception using errcode = 'P0001', message = 'This order has already been cancelled or restocked.';
  end if;

  if pg_catalog.jsonb_typeof(v_order.details->'items') <> 'array'
     or pg_catalog.jsonb_array_length(v_order.details->'items') = 0 then
    raise exception using errcode = '22023', message = 'This order has no items to restock.';
  end if;

  for v_item in
    select value from pg_catalog.jsonb_array_elements(v_order.details->'items')
  loop
    begin
      v_quantity := (v_item->>'qty')::integer;
    exception when others then
      raise exception using errcode = '22023', message = 'An order item has an invalid quantity.';
    end;

    if v_quantity < 1 then
      raise exception using errcode = '22023', message = 'An order item has an invalid quantity.';
    end if;

    v_product := null;
    v_product_id := null;

    begin
      v_product_id := coalesce(
        nullif(v_item->>'id', ''),
        nullif(v_item->>'product_id', '')
      )::uuid;
    exception when others then
      v_product_id := null;
    end;

    if v_product_id is not null then
      select *
      into v_product
      from public."Products"
      where id = v_product_id;
    end if;

    if v_product.id is null then
      select *
      into v_product
      from public."Products"
      where pg_catalog.btrim(name, E' \t\n\r')
        = pg_catalog.btrim(coalesce(v_item->>'name', ''), E' \t\n\r')
      order by id
      limit 1;
    end if;

    -- Three early orders used the old vial label without storing a product ID.
    if v_product.id is null
       and lower(pg_catalog.btrim(coalesce(v_item->>'name', ''), E' \t\n\r')) = 'semaglutide 20mg' then
      select *
      into v_product
      from public."Products"
      where stock_group_id = 'semaglutide-20mg'
      order by id
      limit 1;
    end if;

    if v_product.id is null then
      raise exception using
        errcode = 'P0002',
        message = pg_catalog.format(
          'Product %s could not be found for restocking.',
          coalesce(v_item->>'name', v_item->>'id', 'unknown')
        );
    end if;

    if v_product.stock_group_id is not null then
      v_group_quantities := pg_catalog.jsonb_set(
        v_group_quantities,
        array[v_product.stock_group_id],
        pg_catalog.to_jsonb(
          coalesce((v_group_quantities->>v_product.stock_group_id)::integer, 0)
          + v_quantity
        ),
        true
      );
    else
      v_product_quantities := pg_catalog.jsonb_set(
        v_product_quantities,
        array[v_product.id::text],
        pg_catalog.to_jsonb(
          coalesce((v_product_quantities->>v_product.id::text)::integer, 0)
          + v_quantity
        ),
        true
      );
    end if;
  end loop;

  for v_entry in
    select key, value from pg_catalog.jsonb_each_text(v_group_quantities)
  loop
    update public.stock_groups
    set stock = stock + v_entry.value::integer,
        updated_at = pg_catalog.clock_timestamp()
    where id = v_entry.key;

    if not found then
      raise exception 'Unknown shared stock group %.', v_entry.key;
    end if;
  end loop;

  for v_entry in
    select key, value from pg_catalog.jsonb_each_text(v_product_quantities)
  loop
    update public."Products"
    set stock = stock + v_entry.value::integer
    where id = v_entry.key::uuid;

    if not found then
      raise exception 'Product % could not be restocked.', v_entry.key;
    end if;
  end loop;

  v_updated_details := coalesce(v_order.details, '{}'::jsonb)
    || pg_catalog.jsonb_build_object(
      'meta',
      coalesce(v_order.details->'meta', '{}'::jsonb)
      || pg_catalog.jsonb_build_object(
        'restocked_at', pg_catalog.clock_timestamp(),
        'restocked_by', v_admin_email
      )
    );

  update public."Orders"
  set status = 'Cancelled',
      details = v_updated_details
  where id = v_order.id;

  return pg_catalog.jsonb_build_object(
    'id', v_order.id,
    'status', 'Cancelled',
    'details', v_updated_details,
    'reference', v_order.reference,
    'total_amount', v_order.total_amount,
    'created_at', v_order.created_at
  );
end;
$function$;

revoke all on function public.cancel_order_and_restock(uuid) from public, anon;
grant execute on function public.cancel_order_and_restock(uuid) to authenticated;
