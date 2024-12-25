-- кораблі, які є в розкладі для причалів у терміналах, що належать порту "Роттердам"
select distinct ships.name      as Ship_Name,
                terminals.name  as Terminal_Name,
                ports.portname
from schedules
        join ships on schedules.shipid = ships.shipid
        join berths on schedules.berthid = berths.berthid
        join terminals on berths.terminalid = terminals.terminalid
        join ports on terminals.portid = ports.portid

where terminals.terminalid in (
    select terminalid from terminals
    join ports on terminals.portid = ports.portid
    where ports.portname = 'Rotterdam'
    );




-- знайти всі вантажі, які були відправлені вантажівками та вже доставлені; отримати назву
-- клієнта, що є власником
select cargo.cargoid,
       cargo.weight,
       cargo.cargotype,
       clients.Name      as Client_Name,
       transporters.name as Transporter_Name
from cargo
         join clients on cargo.clientid = clients.clientid
         join shipments on cargo.cargoid = shipments.cargoid
         join transporters on shipments.transporterid = transporters.transporterid

where transporters.vehicletype = 'Tr' and shipments.status = 'Delivered';



-- знайти імена клієнтів і загальну вагу їх вантажів, якщо вона перевищує 50 тонн
select clients.name      as Client_Name,
       sum(cargo.weight) as Total_Weight
from clients
         join cargo on clients.clientid = cargo.clientid

where clients.clientid in (
                            select clientid
                            from cargo
                            group by clientid
                            having sum(weight) > 50
                         )
group by clients.name
order by Total_Weight desc;



-- причали, які можуть прийняти конкретний корабель, що прямує до заданого порту
select berths.berthid,
       terminals.name    as Terminal_Name,
       berths.length     as Berth_Lenght,
       berths.depth      as Bearth_Depth
from berths
        join terminals on berths.terminalid = terminals.terminalid
        join ports on terminals.portid = ports.portid

where ports.portname = 'Reykjavik'
    and berths.length >= (
                            select ships.requiredlength
                            from ships
                            where ships.name = 'Harbor Queen 533'

                         )

    and berths.depth >= (
                            select ships.draft
                            from ships
                            where ships.name = 'Harbor Queen 533'
                        );





-- імена клієнтів і кількість скасованих їх замовлень, якщо вони в них є
select clients.name                     as Client_Name,
       count(shipments.shipmentid)      as Canceled_Shipments
from clients
        join cargo on clients.clientid = cargo.clientid
        join shipments on cargo.cargoid = shipments.cargoid

where shipments.status = 'Canceled'
group by clients.name
having count(shipments.shipmentid) > 0
order by Canceled_Shipments desc;




-- термінали, де частка активних робітників перевищує 70%.
select terminals.name                   as Terminal_Name,
       activeworkers.total_active       as Active_Workers,
       totalworkers.total_count         as Total_Workers
from terminals
        join (
                select terminalid,
                       count(employeeid)     as Total_Active
                from employees
                where isactive = TRUE
                group by terminalid
             ) activeworkers on terminals.terminalid = activeworkers.terminalid

        join (
                select terminalid,
                       count(employeeid)    as Total_Count
                from employees
                group by terminalid
             ) totalworkers on terminals.terminalid = totalworkers.terminalid

where activeworkers.Total_Active > (totalworkers.Total_Count * 0.7)
order by activeworkers.Total_Active desc;




-- перевозчики та кількість доставлень, які вони виконали
select transporters.name                as Transporter_Name,
       count(shipments.shipmentid)      as Total_Shipments
from transporters
        left join shipments on transporters.transporterid = shipments.transporterid
group by transporters.name
order by Total_Shipments desc;




-- термінали з найвищою загальною вантажопідйомністю вантажів, що зберігаються
select terminals.name       as Terminal_Name,
       sum(cargo.weight)    as Total_Stored_Weight
from storage
        left join cargo on storage.cargoid = cargo.cargoid
        left join terminals on storage.terminalid = terminals.terminalid
group by terminals.name
order by Total_Stored_Weight desc;




-- типи вантажів та їх ідентифікатори, що зберігаються на складах кожного терміналу
select terminals.name                                                        as Terminal_Name,
       string_agg(concat(cargo.cargoid, ' (', cargo.cargotype, ')'), ', ')   as Stored_Cargo_Details
from storage
        join cargo on storage.cargoid = cargo.cargoid
        join terminals on storage.terminalid = terminals.terminalid
group by terminals.name
order by terminals.name;




-- кількість кораблів кожного типу, які мають запланований розклад
select ships.shiptype                    as Ship_Type,
       count(distinct ships.shipid)      as Total_Ships
from ships
        join schedules on ships.shipid = schedules.shipid
group by ships.shiptype
order by Total_Ships desc;




-- інфраструктура термінала
select terminals.name            as Terminal_Name,
       count(berths.berthid)     as Total_Berths,
       avg(berths.depth)        as Average_Depth,
       avg(berths.length)        as Average_Length
from terminals
        join berths on terminals.terminalid = berths.terminalid
group by terminals.name
order by Total_Berths desc;





-- причали терміналів, на яких зможе пришвартуватись корабель, коли він прибуде за розкладом
select ships.name       as Ship_Name,
       berths.berthid,
       terminals.name   as Terminal_Name,
       ports.portname   as Destination_Port
from schedules
        join ships on schedules.shipid = ships.shipid
        join berths on schedules.berthid = berths.berthid
        join terminals on berths.terminalid = terminals.terminalid
        join ports on terminals.portid = ports.portid

where ports.portid = schedules.destinationportid
    and berths.length >= ships.requiredlength
    and berths.depth >= ships.draft
order by ships.name, berths.berthid;




-- кількість активних та неактивних працівників кожного амплуа
select employees.position                                         as Employee_Type,
       sum(case when employees.isactive = TRUE then 1 else 0 end) as Active_Workers,
       sum(case when employees.isactive = FALSE then 1 else 0 end) as Inactive_Workers
from employees
group by employees.position
order by Active_Workers desc, Inactive_Workers desc;




-- клієнти, для яких було доставлено найбільше вантажів за 2024
select clients.name                 as Client_Name,
       count(shipments.shipmentid)  as Total_Delivered_Shipments
from clients
        join cargo on clients.clientid = cargo.clientid
        join shipments on cargo.cargoid = shipments.cargoid

where shipments.status = 'Delivered'
    and shipments.shipmentdate between '2024-01-01' and '2024-12-31'
group by clients.name
order by Total_Delivered_Shipments desc
limit 10;


-- сумарна вага вантажів за типами та кількість відправлень вантажу даного типу
select cargo.cargotype,
       sum(cargo.weight)            as Total_weight,
       count(shipments.shipmentid)   as Number_Of_Shipments
from cargo
        join shipments on cargo.cargoid = shipments.cargoid
group by cargo.cargotype ;




-- ідентифікатор вантажу, який немає дати кінця зберігання та номер телефону клієнта-власника
select cargo.cargoid,
       clients.phonenumber
from cargo
        join clients on cargo.clientid = clients.clientid
        left join storage on cargo.cargoid = storage.cargoid

where storage.enddate is NULL;




-- термінали з їхніми місткостями, де є небезпечні вантажі, та загальна вага цього вантажу
select terminals.name       as Terminal_Name,
       terminals.capacity   as Terminal_Capacity,
       sum(cargo.weight)    as Total_Dangerous_Weight
from terminals
        join storage on terminals.terminalid = storage.terminalid
        join cargo on storage.cargoid = cargo.cargoid

where cargo.cargotype = 'Dangerous'
group by terminals.terminalid, terminals.name, terminals.capacity;




-- причали на обслуговуванні
select berths.berthid,
       terminals.name       as Terminal_Name,
       ports.portname       as Port_Name
from berths
        join terminals on berths.terminalid = terminals.terminalid
        join ports on terminals.portid = ports.portid

where berths.status = 'Under Maintenance';





-- час перебування кораблів у порту за розкладом
select ships.name                      as Ship_Name,
       ports.portname                  as Port_Name,
       schedules.arrivaldate           as Arrival_Date,
       schedules.departuredate         as Departure_Date,
       extract(epoch from (schedules.departuredate - schedules.arrivaldate)) / 3600
                                       as Hours_In_Port
from schedules
         join ships on schedules.shipid = ships.shipid
         join terminals on schedules.terminalid = terminals.terminalid
         join ports on terminals.portid = ports.portid
order by Hours_In_Port desc
limit 10;



-- всі кораблі, які мають перевантаження
select ships.name                           as Ship_Name,
       ships.capacity                       as Ship_Capacity,
       sum(cargo.weight)                    as Total_Cargo_Weight,
       (sum(cargo.weight) - ships.capacity)  as Overload
from ships
         join schedules on ships.shipid = schedules.shipid
         join terminals on schedules.terminalid = terminals.terminalid
         join storage on terminals.terminalid = storage.terminalid
         join cargo on storage.cargoid = cargo.cargoid
group by ships.shipid, ships.name, ships.capacity
having sum(cargo.weight) > ships.capacity;


create index idx_ships_shipid on ships(shipid);
create index idx_schedules_shipid on schedules(shipid);
create index idx_storage_cargoid on storage(cargoid);
create index idx_cargo_weight on cargo(weight);
create index idx_terminals_terminalid on terminals(terminalid);



DROP INDEX IF EXISTS idx_ships_shipid;
DROP INDEX IF EXISTS idx_schedules_shipid;
DROP INDEX IF EXISTS idx_storage_cargoid;
DROP INDEX IF EXISTS idx_cargo_weight;
DROP INDEX IF EXISTS idx_terminals_terminalid;
