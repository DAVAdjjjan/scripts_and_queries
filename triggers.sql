create or replace function validate_shipment_and_storage_date()
    returns trigger as $$
declare
    v_startdate timestamp;
begin
    select startdate
    into v_startdate
    from storage
    where storage.cargoid = new.cargoid;

    if v_startdate is not null and new.shipmentdate > v_startdate then
        raise exception 'shipmentdate % cannot be later than storage startdate % for cargoid %',
            new.shipmentdate, v_startdate, new.cargoid;
    end if;

    return new;
end;
$$ language plpgsql;



create trigger check_shipment_storage_date
    before insert or update on shipments
                         for each row
                         execute function validate_shipment_and_storage_date();


INSERT INTO shipments (cargoid, transporterid, shipmentdate, status)
VALUES (1, 1, '2024-12-25 10:00:00', 'In Progress');

UPDATE shipments
SET shipmentdate = '2024-12-20 10:00:00'
WHERE shipmentid = 1;

--##################################################################################################--

--helper
SELECT terminalid,
       COUNT(employeeid) AS total_employees
FROM employees
WHERE isactive = TRUE
GROUP BY terminalid
ORDER BY total_employees DESC;
--------

create or replace function check_employee_limit()
    returns trigger as $$
declare
    v_max_limit int := 20;
    v_current_count int;

begin
    select count(employeeid)
    into v_current_count
    from employees
    where terminalid = new.terminalid and isactive = true;

    if v_current_count >= v_max_limit then
        raise exception 'terminal % already has the maximum allowed active employees (%).', new.terminalid, v_max_limit;
    end if;

    return new;
end;
$$ language plpgsql;


create trigger before_insert_employee
    before insert on employees
    for each row
execute function check_employee_limit();

insert into employees (name, position, terminalid, isactive)
values ('Paul Lee', 'Worker', 202, true);
--##################################################################################################--

CREATE OR REPLACE FUNCTION check_dangerous_cargo_weight()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cargotype = 'Dangerous' AND NEW.weight > 50 THEN
        RAISE EXCEPTION 'Dangerous cargo weight % exceeds the allowed limit of 50 tons', NEW.weight;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_dangerous_cargo_weight
    BEFORE INSERT OR UPDATE ON cargo
    FOR EACH ROW
EXECUTE FUNCTION check_dangerous_cargo_weight();

INSERT INTO cargo (weight, cargotype, clientid)
VALUES (40, 'Dangerous', 1);

--##################################################################################################-

create or replace function check_schedule_constraints()
    returns trigger as $$
declare
    v_terminal_portid int;
    v_berth_terminalid int;
    v_required_length numeric;
    v_required_draft numeric;
    v_berth_length numeric;
    v_berth_depth numeric;
begin

    if new.departuredate <= new.arrivaldate then
        raise exception 'departure date % must be later than arrival date %', new.departuredate, new.arrivaldate;
    end if;


    select terminalid
    into v_berth_terminalid
    from berths
    where berthid = new.berthid;

    if not found then
        raise exception 'berth with id % does not exist', new.berthid;
    end if;


    select portid
    into v_terminal_portid
    from terminals
    where terminalid = new.terminalid;

    if v_terminal_portid is null then
        raise exception 'terminal with id % does not belong to any port', new.terminalid;
    end if;

    if v_berth_terminalid != new.terminalid then
        raise exception 'berth % does not belong to terminal %', new.berthid, new.terminalid;
    end if;


    if not exists (
        select 1
        from ports
        where portid = new.destinationportid
    ) then
        raise exception 'destination port with id % does not exist', new.destinationportid;
    end if;


    select requiredlength, draft
    into v_required_length, v_required_draft
    from ships
    where shipid = new.shipid;

    select length, depth
    into v_berth_length, v_berth_depth
    from berths
    where berthid = new.berthid;

    if v_required_length > v_berth_length then
        raise exception 'berth % is too short for ship %', new.berthid, new.shipid;
    end if;

    if v_required_draft > v_berth_depth then
        raise exception 'berth % is too shallow for ship %', new.berthid, new.shipid;
    end if;


    if exists (
        select 1
        from schedules
        where berthid = new.berthid
          and (
            (new.arrivaldate between arrivaldate and departuredate)
                or
            (new.departuredate between arrivaldate and departuredate)
            )
          and scheduleid != new.scheduleid
    ) then
        raise exception 'berth % is already occupied during the specified time', new.berthid;
    end if;


    if exists (
        select 1
        from schedules
        where shipid = new.shipid
          and arrivaldate = new.arrivaldate
          and scheduleid != new.scheduleid
    ) then
        raise exception 'ship with id % already has a schedule at %', new.shipid, new.arrivaldate;
    end if;

    return new;
end;
$$ language plpgsql;



create trigger trg_check_schedule_constraints
    before insert or update on schedules
    for each row
execute function check_schedule_constraints();





insert into schedules (shipid, terminalid, berthid, arrivaldate, departuredate, destinationportid)
values (2, 2, 3, '2024-12-20 10:00:00', '2024-12-20 09:00:00', 5);


insert into schedules (shipid, terminalid, berthid, arrivaldate, departuredate, destinationportid)
values (1, 2, 3, '2024-12-20 10:00:00', '2024-12-28 18:00:00', 5);


insert into schedules (shipid, terminalid, berthid, arrivaldate, departuredate, destinationportid)
values (1, 2, 2, '2024-12-20 10:00:00', '2024-12-28 18:00:00', 5);

--##################################################################################################-


CREATE OR REPLACE FUNCTION validate_perishable_cargo()
    RETURNS TRIGGER AS $$
DECLARE
    v_cargotype VARCHAR;
BEGIN
    SELECT cargotype
    INTO v_cargotype
    FROM cargo
    WHERE cargoid = NEW.cargoid;

    IF v_cargotype = 'Perishable' AND NEW.enddate IS NULL THEN
        RAISE EXCEPTION 'Perishable cargo must have an enddate specified.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



create trigger trg_validate_perishable_cargo
    before insert or update on storage
    for each row
execute function validate_perishable_cargo();



insert into storage (terminalid, cargoid, startdate) values (1, 1004, '2024-12-20 10:00:00');
