CREATE TABLE Ports
(
    PortID   SERIAL PRIMARY KEY,
    PortName VARCHAR(50) NOT NULL UNIQUE
);
--#########################################################################--

CREATE TABLE Terminals
(
    TerminalID SERIAL PRIMARY KEY,
    Name       VARCHAR(50)    NOT NULL UNIQUE,
    PortID     INT            NOT NULL REFERENCES Ports (PortID) ON DELETE CASCADE,
    Capacity   DECIMAL(10, 2) NOT NULL CHECK (Capacity > 0)
);
--#########################################################################--


CREATE TABLE Clients
(
    ClientID    SERIAL PRIMARY KEY,
    Name        VARCHAR(50) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL UNIQUE CHECK (PhoneNumber ~ '^\d{7,20}$'),
    Type        VARCHAR(50) NOT NULL CHECK (Type IN ('Individual', 'Corporate', 'Government'))
);


--#########################################################################--


CREATE TABLE Cargo
(
    CargoID   SERIAL PRIMARY KEY,
    Weight    DECIMAL(10, 2) NOT NULL CHECK (Weight > 0),
    CargoType VARCHAR(50)    NOT NULL CHECK (CargoType IN
                                             ('General', 'Container', 'Bulk', 'Liquid', 'RoRo', 'Perishable',
                                              'Dangerous', 'Project')),
    ClientID  INT            REFERENCES Clients (ClientID) ON DELETE SET NULL
);
--#########################################################################--


CREATE TABLE Ships
(
    ShipID         SERIAL PRIMARY KEY,
    Name           VARCHAR(50)    NOT NULL UNIQUE,
    Flag           VARCHAR(3),
    Capacity       DECIMAL(10, 2) NOT NULL CHECK (Capacity > 0),
    ShipType       VARCHAR(50)    NOT NULL CHECK (ShipType IN ('Cargo', 'Tanker', 'Container', 'Bulk', 'RoRo')),
    RequiredLength DECIMAL(8, 2)  NOT NULL CHECK (RequiredLength > 0),
    Draft          DECIMAL(5, 2)  NOT NULL CHECK (Draft > 0)
);
--#########################################################################--


CREATE TABLE Berths
(
    BerthID    SERIAL PRIMARY KEY,
    TerminalID INT           NOT NULL REFERENCES Terminals (TerminalID) ON DELETE CASCADE,
    Length     DECIMAL(8, 2) NOT NULL CHECK (Length > 0),
    Depth      DECIMAL(5, 2) NOT NULL CHECK (Depth > 0),
    Status     VARCHAR(20)   NOT NULL CHECK (Status IN ('Available', 'Occupied', 'Under Maintenance'))
);
--#########################################################################--


CREATE TABLE Schedules
(
    ScheduleID    SERIAL PRIMARY KEY,
    ShipID        INT       REFERENCES Ships (ShipID) ON DELETE SET NULL,
    TerminalID    INT       REFERENCES Terminals (TerminalID) ON DELETE SET NULL,
    BerthID       INT       NOT NULL REFERENCES Berths (BerthID),
    ArrivalDate   TIMESTAMP NOT NULL,
    DepartureDate TIMESTAMP NOT NULL,
    CHECK (DepartureDate > ArrivalDate),
    UNIQUE (ShipID, ArrivalDate)
);

ALTER TABLE Schedules
    ADD COLUMN DestinationPortID INT REFERENCES Ports(PortID);
--#########################################################################--


CREATE TABLE Storage
(
    StorageID  SERIAL PRIMARY KEY,
    TerminalID INT       REFERENCES Terminals (TerminalID) ON DELETE SET NULL,
    CargoID    INT       NOT NULL REFERENCES Cargo (CargoID) ON DELETE CASCADE,
    StartDate  TIMESTAMP NOT NULL,
    EndDate    TIMESTAMP,
    CHECK (EndDate IS NULL OR EndDate > StartDate)
);
--#########################################################################--


CREATE TABLE Transporters
(
    TransporterID SERIAL PRIMARY KEY,
    Name          VARCHAR(50)    NOT NULL UNIQUE,
    VehicleType   VARCHAR(50)    NOT NULL CHECK (VehicleType IN ('Truck', 'Train', 'Plane', 'Ship', 'Van')),
    Capacity      DECIMAL(10, 2) NOT NULL CHECK (Capacity > 0)
);
--#########################################################################--


CREATE TABLE Shipments
(
    ShipmentID    SERIAL PRIMARY KEY,
    CargoID       INT         REFERENCES Cargo (CargoID) ON DELETE SET NULL,
    TransporterID INT         REFERENCES Transporters (TransporterID) ON DELETE SET NULL,
    ShipmentDate  TIMESTAMP   NOT NULL,
    Status        VARCHAR(50) NOT NULL CHECK (Status IN ('Pending', 'In Progress', 'Delivered', 'Canceled'))
);

ALTER TABLE Shipments
    ALTER COLUMN ShipmentDate DROP NOT NULL;

ALTER TABLE Shipments
    ADD CONSTRAINT check_shipment_status_date
        CHECK (
            (Status = 'Pending' AND ShipmentDate IS NULL) OR
            (Status = 'Canceled' AND ShipmentDate IS NULL) OR
            (Status IN ('In Progress', 'Delivered') AND ShipmentDate IS NOT NULL)
            );

alter table shipments
    add constraint check_shipment_date_valid
        check (shipmentdate >= (select startdate from storage where storage.cargoid = shipments.cargoid));

--#########################################################################--


CREATE TABLE Employees
(
    EmployeeID SERIAL PRIMARY KEY,
    Name       VARCHAR(50) NOT NULL,
    Position   VARCHAR(50) NOT NULL CHECK (Position IN ('Manager', 'Supervisor', 'Worker', 'Admin')),
    TerminalID INT         NOT NULL REFERENCES Terminals (TerminalID) ON DELETE CASCADE,
    IsActive   BOOLEAN DEFAULT TRUE
);






