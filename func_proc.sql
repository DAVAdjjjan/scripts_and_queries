create or replace function count_delivered_shipment_by_vehicle(p_vehicle_type VARCHAR)
returns int as $$
declare v_count int;
begin
    select count(shipments.shipmentid)
    into v_count
    from shipments
            join transporters on shipments.transporterid = transporters.transporterid
    where transporters.vehicletype = p_vehicle_type
    and shipments.status = 'Delivered';

    return v_count;
end;
$$ language plpgsql;

select count_delivered_shipments_by_vehicle('Truck');
--##################################################################################################--


create or replace procedure update_employee_status
    (
        p_employee_ids int[],
        p_isactive boolean
    )
    language plpgsql
as $$
begin
    update employees
    set isactive = p_isactive
    where employeeid = any(p_employee_ids);

    raise notice 'Employee status updated successfully';
end;
$$;

call update_employee_status(array[1, 2, 3], true);

--##################################################################################################--

create or replace function is_berth_available(p_berth_id int)
    returns boolean as $$
declare
    v_status varchar;
begin
    if not exists (select 1 from berths where berthid = p_berth_id) then
        raise exception 'Berth with ID % does not exist.', p_berth_id;
    end if;

    select status
    into v_status
    from berths
    where berthid = p_berth_id;

    return v_status = 'Available';
end;
$$ language plpgsql;


select is_berth_available(101);
select is_berth_available(111);
select is_berth_available(103);
--##################################################################################################--


create or replace function count_client_cargo(p_client_id int, p_cargo_type varchar default null)
    returns int as $$
declare
    v_cargo_count int;
begin
    if not exists (select 1 from clients where clientid = p_client_id) then
        raise exception 'Client with ID % does not exist.', p_client_id;
    end if;

    select count(*)
    into v_cargo_count
    from cargo
    where clientid = p_client_id
      and (p_cargo_type is null or cargotype = p_cargo_type);

    return v_cargo_count;
end;
$$ language plpgsql;

select count_client_cargo(100, 'RoRo');
--##################################################################################################--

create or replace function mark_cargo_as_delivered(p_cargo_id int, p_delivery_date timestamp)
    returns text as $$
declare
    v_shipment_id int;

begin
    if not exists (select 1 from cargo where cargoid = p_cargo_id) then
        raise exception 'cargo id % does not exist', p_cargo_id;
    end if;

    select shipmentid
    into v_shipment_id
    from shipments
    where cargoid = p_cargo_id and status = 'In Progress'
    order by shipmentdate desc
    limit 1;

    if not found then
        raise exception 'no shipment with status "in progress" found for cargoid %', p_cargo_id;
    end if;

    update shipments
    set status = 'Delivered', shipmentdate = p_delivery_date
    where shipmentid = v_shipment_id;

    return format('cargo id %s has been marked as delivered on %s', p_cargo_id, p_delivery_date);
end;
$$ language plpgsql;

select mark_cargo_as_delivered(815, '2024-09-15 23:50:00');

--##################################################################################################--


create or replace function can_add_cargo_to_storage(p_terminal_id int, p_cargo_weight decimal)
    returns boolean as $$
declare
    v_current_weight decimal;
    v_capacity decimal;

begin
    select capacity
    into v_capacity
    from terminals
    where terminalid = p_terminal_id;

    if not found then
        raise exception 'terminal with id % does not exist', p_terminal_id;
    end if;

    select coalesce(sum(cargo.weight), 0)
    into v_current_weight
    from storage
             join cargo on storage.cargoid = cargo.cargoid
    where storage.terminalid = p_terminal_id;

    return v_current_weight + p_cargo_weight <= v_capacity;
end;
$$ language plpgsql;

select can_add_cargo_to_storage(1, 500.0);
--##################################################################################################--

create or replace function count_ships_in_port(p_port_id int, p_start_date date, p_end_date date)
    returns int as $$
declare
    v_ship_count int;

begin
    if not exists (select 1 from ports where portid = p_port_id) then
        raise exception 'port with id % does not exist', p_port_id;
    end if;

    select count(distinct schedules.shipid)
    into v_ship_count
    from schedules
             join terminals on schedules.terminalid = terminals.terminalid
             join ports on terminals.portid = ports.portid
    where ports.portid = p_port_id
      and schedules.arrivaldate >= p_start_date
      and schedules.departuredate <= p_end_date;

    return v_ship_count;
end;
$$ language plpgsql;


select count_ships_in_port(5, '2024-01-01', '2024-12-31');
--##################################################################################################--


create or replace function find_longest_available_berth(p_port_id int)
    returns table (
                      berthid       int,
                      terminalid    int,
                      length        decimal,
                      depth         decimal
                  ) as $$
begin

    if not exists (select 1 from ports where portid = p_port_id) then
        raise exception 'Port with ID % does not exist', p_port_id;
    end if;

    return query
        select berths.berthid, berths.terminalid, berths.length, berths.depth
        from berths
                 join terminals on berths.terminalid = terminals.terminalid
                 join ports on terminals.portid = ports.portid
        where ports.portid = p_port_id
          and berths.status = 'Available'
        order by berths.length desc
        limit 1;

    if not found then
        raise notice 'No available berths found for port ID %', p_port_id;
    end if;
end;
$$ language plpgsql;

select * from find_longest_available_berth(3);
select * from find_longest_available_berth(80);
--##################################################################################################--

create or replace function check_schedule_date_conflicts(p_berth_id int)
    returns table (
                      conflict_ship1    varchar,
                      conflict_ship2    varchar,
                      overlap_start     timestamp,
                      overlap_end       timestamp
                  ) as $$
begin
    return query
        select s1.shipid::varchar as conflict_ship1,
               s2.shipid::varchar as conflict_ship2,
               greatest(s1.arrivaldate, s2.arrivaldate) as overlap_start,
               least(s1.departuredate, s2.departuredate) as overlap_end
        from schedules s1
                 join schedules s2
                      on s1.berthid = s2.berthid
                          and s1.scheduleid <> s2.scheduleid
                          and s1.arrivaldate < s2.departuredate
                          and s2.arrivaldate < s1.departuredate
        where s1.berthid = p_berth_id
        order by overlap_start;
end;
$$ language plpgsql;


select * from check_schedule_date_conflicts(11);
select * from check_schedule_date_conflicts(1);
--##################################################################################################--

create or replace function average_delivery_time_by_vehicle_type(p_vehicle_type varchar)
    returns interval as $$
declare
    v_average_time interval;
begin

    select avg(shipments.shipmentdate - storage.startdate)
    into v_average_time
    from shipments
             join transporters on shipments.transporterid = transporters.transporterid
             join storage on shipments.cargoid = storage.cargoid
    where transporters.vehicletype = p_vehicle_type
      and shipments.status = 'Delivered';

    return v_average_time;
end;
$$ language plpgsql;

select average_delivery_time_by_vehicle_type('Truck');

