-- Створення представлення для перегляду вантажів та їх статусу для клієнтів
create or replace view client_cargo_status as
select c.cargoid,
       c.weight,
       c.cargotype,
       clients.name                                             as Client_Name,
       shipments.status                                         as Shipment_Status,
       coalesce(shipments.shipmentdate::text, 'Not Scheduled')  as shipment_date
from cargo c
        join clients on c.clientid = clients.clientid
        left join shipments on c.cargoid = shipments.cargoid;

select * from client_cargo_status;
--#############################################################################################--

create or replace view terminal_load_status as
select t.name                                                       as terminal_name,
       t.capacity                                                   as terminal_capacity,
       coalesce(sum(c.weight), 0)                                   as total_cargo_weight,
       round((coalesce(sum(c.weight), 0) / t.capacity) * 100, 2)    as load_percentage

from terminals t
         left join storage s on t.terminalid = s.terminalid
         left join cargo c on s.cargoid = c.cargoid
group by t.terminalid, t.name, t.capacity
order by load_percentage desc;


select * from terminal_load_status;
--#############################################################################################--


create or replace view ship_load_status as
select sh.shipid,
       sh.name                                                         as ship_name,
       sh.capacity                                                     as ship_capacity,
       coalesce(sum(cargo.weight), 0)                                  as total_cargo_weight,
       round((coalesce(sum(cargo.weight), 0) / sh.capacity ) * 100, 2) as load_percentage,
       schedules.arrivaldate,
       schedules.departuredate
from ships sh
        join schedules on sh.shipid = schedules.shipid
        left join storage on schedules.terminalid = storage.terminalid
        left join cargo on storage.cargoid = cargo.cargoid

group by sh.shipid, sh.name, sh.capacity, schedules.arrivaldate, schedules.departuredate
order by load_percentage desc, sh.name;


select * from ship_load_status;
--#############################################################################################--


create or replace view cargo_status_summary as
select c.cargotype                                                              as cargo_type,
       count(c.cargoid)                                                         as total_cargo_count,
       coalesce(sum(case when s.status = 'Pending' then 1 else 0 end), 0)       as pending_count,
       coalesce(sum(case when s.status = 'In Progress' then 1 else 0 end), 0)   as in_progress_count,
       coalesce(sum(case when s.status = 'Delivered' then 1 else 0 end), 0)     as delivered_count,
       coalesce(sum(case when s.status = 'Canceled' then 1 else 0 end), 0)      as canceled_count,
       coalesce(sum(c.weight), 0)                                               as total_weight
from cargo c
         left join shipments s on c.cargoid = s.cargoid
group by c.cargotype
order by total_weight desc;


select * from cargo_status_summary;
--#############################################################################################--


create or replace view berth_occupancy_schedule as
select schedules.scheduleid,
       ships.name               as ship_name,
       ports.portname           as destination_port,
       terminals.name           as terminal_name,
       berths.berthid           as berth_id,
       berths.length            as berth_length,
       berths.depth             as berth_depth,
       berths.status            as berth_status,
       schedules.arrivaldate    as arrival_date,
       schedules.departuredate  as departure_date
from schedules
         join ships on schedules.shipid = ships.shipid
         join berths on schedules.terminalid = berths.terminalid
         join terminals on berths.terminalid = terminals.terminalid
         join ports on terminals.portid = ports.portid
where berths.status = 'Available'
  and berths.length >= ships.requiredlength
  and berths.depth >= ships.draft
  and ports.portid = schedules.destinationportid
order by schedules.arrivaldate, berths.berthid;

select * from berth_occupancy_schedule;
--#############################################################################################--

create or replace view client_type_cargo_summary as
select clients.type                     as client_type,
       count(cargo.cargoid)             as total_cargo_count,
       coalesce(sum(cargo.weight), 0)   as total_cargo_weight
from clients
         left join cargo on clients.clientid = cargo.clientid
group by clients.type
order by total_cargo_weight desc;

select * from client_type_cargo_summary;
--#############################################################################################--