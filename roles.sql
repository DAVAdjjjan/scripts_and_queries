-------------------------ADMIN-------------------------
CREATE ROLE admin WITH
    LOGIN
    SUPERUSER
    CREATEDB
    CREATEROLE
    PASSWORD 'admin_password';



-------------------------MANAGER-------------------------
CREATE ROLE manager WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'manager_password';

-- Доступ на повний контроль над операційними даними
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE schedules TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cargo TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE employees TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE shipments TO manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE clients TO manager;

-- Доступ на читання до інфраструктурних даних
GRANT SELECT ON TABLE terminals TO manager;
GRANT SELECT ON TABLE berths TO manager;
GRANT SELECT ON TABLE transporters TO manager;

GRANT USAGE, SELECT ON SEQUENCE schedules_scheduleid_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE cargo_cargoid_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE employees_employeeid_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE shipments_shipmentid_seq TO manager;
GRANT USAGE, SELECT ON SEQUENCE clients_clientid_seq TO manager;



-------------------------OPERATOR-------------------------
CREATE ROLE operator WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'operator_password';

-- Доступ на додавання та оновлення даних у ключових таблицях
GRANT SELECT, INSERT, UPDATE ON TABLE schedules TO operator;
GRANT SELECT, INSERT, UPDATE ON TABLE cargo TO operator;

-- Доступ на перегляд довідкових даних
GRANT SELECT ON TABLE ships TO operator;
GRANT SELECT ON TABLE terminals TO operator;
GRANT SELECT ON TABLE berths TO operator;
GRANT SELECT ON TABLE clients TO operator;

GRANT USAGE, SELECT ON SEQUENCE schedules_scheduleid_seq TO operator;
GRANT USAGE, SELECT ON SEQUENCE cargo_cargoid_seq TO operator;



-------------------------ANALYST-------------------------
CREATE ROLE analyst WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'analyst_password';

-- Доступ на читання всіх ключових таблиць
GRANT SELECT ON TABLE schedules TO analyst;
GRANT SELECT ON TABLE cargo TO analyst;
GRANT SELECT ON TABLE clients TO analyst;
GRANT SELECT ON TABLE ships TO analyst;
GRANT SELECT ON TABLE terminals TO analyst;
GRANT SELECT ON TABLE berths TO analyst;
GRANT SELECT ON TABLE transporters TO analyst;
GRANT SELECT ON TABLE employees TO analyst;



-------------------------SUPERVISOR-------------------------
CREATE ROLE supervisor WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'supervisor_password';

GRANT SELECT, UPDATE ON TABLE schedules TO supervisor;
GRANT SELECT, UPDATE ON TABLE cargo TO supervisor;
GRANT SELECT, UPDATE ON TABLE employees TO supervisor;

-- Доступ на перегляд довідкової інформації
GRANT SELECT ON TABLE ships TO supervisor;
GRANT SELECT ON TABLE terminals TO supervisor;
GRANT SELECT ON TABLE berths TO supervisor;



-------------------------TECHNICIAN-------------------------
CREATE ROLE technician WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'technician_password';

GRANT SELECT, UPDATE ON TABLE berths TO technician;

GRANT SELECT ON TABLE terminals TO technician;
GRANT SELECT ON TABLE ports TO technician;



-------------------------DOCK_OPERATOR-------------------------
CREATE ROLE dock_operator WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'dock_password';

GRANT SELECT, UPDATE ON TABLE berths TO dock_operator;
GRANT SELECT ON TABLE terminals TO dock_operator;



-------------------------CLIENT-------------------------
CREATE ROLE client WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    PASSWORD 'client_password';

GRANT SELECT ON TABLE cargo TO client;
GRANT SELECT ON TABLE shipments TO client;
GRANT SELECT ON TABLE transporters TO client;


