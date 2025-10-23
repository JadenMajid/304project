/*
When looking at this SQL file, there are 2 parts
1. Table Initializations
  - FK ON X justifications are done as comments
2. Insert statements
*/

-- 1. Table Initializations
CREATE TABLE Ride (
  RideName      VARCHAR PRIMARY KEY,
  Capacity      INTEGER,       -- should CHECK (Capacity > 0)
  InstallDate   DATE
);

CREATE TABLE Customer (
  CustomerID    INTEGER PRIMARY KEY,
  CustomerName  VARCHAR,
  Sex           VARCHAR,
  DOB           DATE
);

CREATE TABLE Booking (
  BookingNumber INTEGER PRIMARY KEY,
  BookingDate   DATE,
  Cost          INTEGER        -- should CHECK (Cost >= 0)
);

CREATE TABLE RateModifier (
  RateCode      INTEGER PRIMARY KEY,
  Modifier      FLOAT DEFAULT 1.0
);

CREATE TABLE RoomType (
  RoomName      VARCHAR PRIMARY KEY,
  MaxGuests     INTEGER,       -- should CHECK (MaxGuests > 0)
  Category      VARCHAR,
  BaseRate      FLOAT
);

CREATE TABLE Hotel (
  HotelName     VARCHAR PRIMARY KEY,
  StreetAddress VARCHAR,
  PostalCode    VARCHAR,
  City          VARCHAR,
  Province      VARCHAR
);

CREATE TABLE Ticket2 (
  TicketID      INTEGER PRIMARY KEY,
  BookingNumber INTEGER,
  ValidFrom     DATE,
  RemainingUses INTEGER,       -- should CHECK (RemainingUses >= 0)
  ValidHours    INTEGER,       -- should CHECK (ValidHours >= 0)
  CONSTRAINT fk_ticket2_booking FOREIGN KEY (BookingNumber)
    REFERENCES Booking (BookingNumber)
    -- When bookings are deleted(like a cancellation or refund), any associated tickets should be deleted as well
    ON DELETE CASCADE
    -- Booking numbers should not be updated, in cases where they are, tickets that reference them should still reference the same booking 
    ON UPDATE CASCADE
);

CREATE TABLE Ticket1 (
  ValidFrom     DATE,
  ValidUntil    DATE,
  ValidHours    INTEGER,       -- should CHECK (ValidHours >= 0)
  PRIMARY KEY (ValidFrom, ValidUntil)
);

CREATE TABLE FastPassTicket (
  TicketID      INTEGER PRIMARY KEY,
  NumberOfRides INTEGER,       -- should CHECK (NumberOfRides >= 0)
  ValidHours    INTEGER,       -- should CHECK (ValidHours >= 0)
  CONSTRAINT fk_fastpass_ticket FOREIGN KEY (TicketID)
    REFERENCES Ticket2 (TicketID)
    -- When tickets IDs are changed, they should still be fastpass tickets
    ON UPDATE CASCADE
    -- When tickets are deleted, the associated fastpass information should also be deleted
    ON DELETE CASCADE
);

CREATE TABLE LoyaltyMember (
  CustomerID    INTEGER PRIMARY KEY,
  LoyaltyID     INTEGER UNIQUE,
  Points        INTEGER DEFAULT 0,  -- should CHECK (Points >= 0)
  UUID          INTEGER UNIQUE
);

CREATE TABLE SeasonPass (
  UUID            INTEGER PRIMARY KEY,
  SeasonPassLevel VARCHAR,
  SeasonStart     DATE,
  SeasonEnd       DATE,
  LoyaltyID       INTEGER,
  CONSTRAINT fk_seasonpass_loyalty FOREIGN KEY (LoyaltyID)
    REFERENCES LoyaltyMember (LoyaltyID)
    -- Should never be triggered, but SeasonPasses should be tied to one user
    ON UPDATE CASCADE
    -- When a user deletes their account, any associations like SeasonPasses should also be deleted
    ON DELETE CASCADE
);

CREATE TABLE SeasonPassSpecial (
  UUID       INTEGER,
  RateCode   INTEGER,
  PRIMARY KEY (UUID, RateCode),
  CONSTRAINT fk_sps_seasonpass FOREIGN KEY (UUID)
    REFERENCES SeasonPass (UUID)
    -- Should never be triggered, SeasonPass should be immutable after insertion
    ON DELETE SET NULL
    -- Should never be triggered, but a SeasonPassSpecial should still be connected to the same UUID even if it changes
    ON UPDATE CASCADE,
  CONSTRAINT fk_sps_ratemodifier FOREIGN KEY (RateCode)
    REFERENCES RateModifier (RateCode)
    -- When a RateModifier is deleted, any associated SeasonPassSpecials should also be deleted
    ON DELETE CASCADE
    -- When a RateModifier's RateCode is changed, any associated SeasonPassSpecials should still reference the same RateCode
    ON UPDATE CASCADE
);

CREATE TABLE BookedWithRateModifier (
  RateCode      INTEGER DEFAULT 0,
  BookingNumber INTEGER,
  PRIMARY KEY (RateCode, BookingNumber),
  CONSTRAINT fk_bwrm_rate FOREIGN KEY (RateCode)
    REFERENCES RateModifier (RateCode)
    -- Bookings should always point to the same RateCode, even if that ratecode is changed
    ON UPDATE CASCADE
    -- Bookings booked with rate modifiers point to a default ratecode with Modifier=1.0 when its ratecode is deleted 
    ON DELETE SET DEFAULT,
  CONSTRAINT fk_bwrm_booking FOREIGN KEY (BookingNumber)
    REFERENCES Booking (BookingNumber)
    -- When booking are deleted, references to it become invalid so should be deleted too
    ON DELETE CASCADE
);

CREATE TABLE OffersRoomType (
  HotelName     VARCHAR,
  RoomName      VARCHAR,
  Quantity      INTEGER,       -- should CHECK (Quantity >= 0)
  PRIMARY KEY (HotelName, RoomName),
  CONSTRAINT fk_offers_hotel FOREIGN KEY (HotelName)
    REFERENCES Hotel (HotelName)
    -- Hotels should never be deleted, but in that case that it is, the Roomtypes offered should be saved for history reasons
    ON DELETE SET NULL,
  CONSTRAINT fk_offers_room FOREIGN KEY (RoomName)
    REFERENCES RoomType (RoomName)
    -- Roomtypes should never be deleted, but if they are they should be kept for history reasons
    ON DELETE SET NULL
);

CREATE TABLE HotelStay (
  HotelBookingID INTEGER PRIMARY KEY,
  NumGuests      INTEGER,       -- should CHECK (NumGuests > 0)
  CheckInDate    DATE,
  CheckOutDate   DATE,
  HotelName      VARCHAR NOT NULL,
  RoomName       VARCHAR NOT NULL,
  BookingNumber  INTEGER NOT NULL,
  CONSTRAINT fk_hs_hotel FOREIGN KEY (HotelName)
    REFERENCES Hotel (HotelName)
    -- if a hotel is deleted, hotel stays should be kept for historical reasons
    ON DELETE SET NULL
    -- if a hotel changes its name, the new name should be used for all records for consistency
    ON UPDATE CASCADE,
  CONSTRAINT fk_hs_room FOREIGN KEY (RoomName)
    REFERENCES RoomType (RoomName)
    -- if a roomtype is deleted, we should keep the stays 
    ON DELETE SET NULL
    -- if the name of a roomtype changes, we should update records to reflect the new name
    ON UPDATE CASCADE,
  CONSTRAINT fk_hs_booking FOREIGN KEY (BookingNumber)
    REFERENCES Booking (BookingNumber)
    -- If a booking is deleted, the hotel stay associated with it is no longer valid, so should be deleted
    ON DELETE CASCADE
    -- If a booking is updated, it's hotel stay should stay attached to it 
    ON UPDATE CASCADE
);

CREATE TABLE ForRide (
  RideName  VARCHAR,
  TicketID  INTEGER,
  PRIMARY KEY (RideName, TicketID),
  CONSTRAINT fk_forride_ride FOREIGN KEY (RideName)
    REFERENCES Ride (RideName)
    -- When Rides are deleted(should never be), we should keep the ticket association with the ride just in case
    ON DELETE SET NULL
    -- When RideNames are updated(should never be), the tickets should still be for the same ride
    ON UPDATE CASCADE,
  CONSTRAINT fk_forride_ticket FOREIGN KEY (TicketID)
    REFERENCES Ticket2 (TicketID)
    -- When tickets are deleted(like when a booking is deleted/refunded), their associations to some ride should be deleted too
    ON DELETE CASCADE
    -- When tickets are updated(should never be), their associations to some ride should be attached to the same ticket
    ON UPDATE CASCADE
);

CREATE TABLE MaintenanceRecord1 (
  MaintenancePerformed VARCHAR PRIMARY KEY,
  NumberOfWorkers      INTEGER        -- should CHECK (NumberOfWorkers >= 0)
);

CREATE TABLE MaintenanceRecord2 (
  RideName             VARCHAR,
  RecordID             INTEGER,
  MaintenancePerformed VARCHAR,
  MaintenanceDate      DATE,
  PRIMARY KEY (RideName, RecordID),
  CONSTRAINT fk_mr2_ride FOREIGN KEY (RideName)
    REFERENCES Ride (RideName)
    -- When rides are deleted, their maintenance records should be deleted too 
    ON DELETE CASCADE
    -- When ride names are updated(should never happen), their maintenance records should still be for the same ride
    ON UPDATE CASCADE
);

CREATE TABLE Guest (
  CustomerID  INTEGER,
  DateOfVisit DATE,
  PRIMARY KEY (CustomerID, DateOfVisit),
  CONSTRAINT fk_guest_customer FOREIGN KEY (CustomerID)
    REFERENCES Customer (CustomerID)
    -- When a customer is deleted, their Guest info should be deleted too(Data Privacy reasons)
    ON DELETE CASCADE
    -- Guests should always be attached to the same Customer object
    ON UPDATE CASCADE
);

-- 2. Insert Statements
INSERT INTO RateModifier (RateCode, Modifier) VALUES
(0, 1.0),
(1, 0.9),
(2, 1.2),
(3, 0.75),
(4, 1.5);

INSERT INTO Ride (RideName, Capacity, InstallDate) VALUES
('ThunderCoaster', 24, '2015-06-01'),
('SkyDrop', 16, '2017-08-10'),
('RapidRiver', 20, '2018-03-15'),
('HauntedRide', 12, '2020-10-01'),
('GalaxySpin', 30, '2019-05-22');

INSERT INTO Customer (CustomerID, CustomerName, Sex, DOB) VALUES
(1, 'Alice Smith', 'F', '1990-02-14'),
(2, 'Bob Jones', 'M', '1985-07-09'),
(3, 'Carol White', 'F', '1992-11-30'),
(4, 'David Kim', 'M', '1998-01-20'),
(5, 'Eve Brown', 'F', '2000-04-25');

INSERT INTO Booking (BookingNumber, BookingDate, Cost) VALUES
(100, '2025-06-15', 120),
(101, '2025-07-01', 250),
(102, '2025-07-15', 300),
(103, '2025-08-05', 180),
(104, '2025-09-10', 400);

INSERT INTO Ticket2 (TicketID, BookingNumber, ValidFrom, RemainingUses, ValidHours) VALUES
(200, 100, '2025-06-16', 5, 10),
(201, 101, '2025-07-02', 3, 8),
(202, 102, '2025-07-16', 4, 12),
(203, 103, '2025-08-06', 2, 6),
(204, 104, '2025-09-11', 6, 10);

INSERT INTO FastPassTicket (TicketID, NumberOfRides, ValidHours) VALUES
(200, 10, 8),
(201, 5, 6),
(202, 8, 12),
(203, 6, 10),
(204, 12, 14);

INSERT INTO LoyaltyMember (CustomerID, LoyaltyID, Points, UUID) VALUES
(1, 10, 150, 1000),
(2, 11, 200, 1001),
(3, 12, 50, 1002),
(4, 13, 400, 1003),
(5, 14, 300, 1004);

INSERT INTO SeasonPass (UUID, SeasonPassLevel, SeasonStart, SeasonEnd, LoyaltyID) VALUES
(1000, 'Gold', '2025-03-01', '2025-03-01', 10),
(1001, 'Silver', '2025-03-01', '2025-03-01', 11),
(1002, 'Bronze', '2025-03-01', '2025-03-01', 12),
(1003, 'Platinum', '2025-03-01', '2025-03-01', 13),
(1004, 'Gold', '2025-03-01', '2025-03-01', 14);

INSERT INTO SeasonPassSpecial (UUID, RateCode) VALUES
(1000, 1),
(1001, 2),
(1002, 3),
(1003, 4),
(1004, 0);

INSERT INTO RoomType (RoomName, MaxGuests, Category, BaseRate) VALUES
('Standard', 2, 'Economy', 100.0),
('Deluxe', 4, 'Premium', 180.0),
('Suite', 5, 'Luxury', 250.0),
('Family', 6, 'Economy', 150.0),
('Penthouse', 4, 'Luxury', 400.0);

INSERT INTO Hotel (HotelName, StreetAddress, PostalCode, City, Province) VALUES
('OceanView', '123 Beach Rd', 'A1A1A1', 'Halifax', 'NS'),
('SkylineInn', '88 Tower St', 'B2B2B2', 'Toronto', 'ON'),
('MountainLodge', '45 Summit Way', 'C3C3C3', 'Banff', 'AB'),
('LakeResort', '9 Shoreline Dr', 'D4D4D4', 'Kelowna', 'BC'),
('UrbanStay', '555 Main St', 'E5E5E5', 'Montreal', 'QC');

INSERT INTO OffersRoomType (HotelName, RoomName, Quantity) VALUES
('OceanView', 'Standard', 20),
('SkylineInn', 'Deluxe', 15),
('MountainLodge', 'Suite', 10),
('LakeResort', 'Family', 12),
('UrbanStay', 'Penthouse', 5);

INSERT INTO HotelStay (HotelBookingID, NumGuests, CheckInDate, CheckOutDate, HotelName, RoomName, BookingNumber) VALUES
(500, 2, '2025-06-16', '2025-06-18', 'OceanView', 'Standard', 100),
(501, 4, '2025-07-02', '2025-07-06', 'SkylineInn', 'Deluxe', 101),
(502, 5, '2025-07-16', '2025-07-19', 'MountainLodge', 'Suite', 102),
(503, 3, '2025-08-06', '2025-08-08', 'LakeResort', 'Family', 103),
(504, 2, '2025-09-11', '2025-09-15', 'UrbanStay', 'Penthouse', 104);

INSERT INTO BookedWithRateModifier (RateCode, BookingNumber) VALUES
(0, 100),
(1, 101),
(2, 102),
(3, 103),
(4, 104);

INSERT INTO Ticket1 (ValidFrom, ValidUntil, ValidHours) VALUES
('2025-06-01', '2025-06-30', 10),
('2025-07-01', '2025-07-31', 12),
('2025-08-01', '2025-08-31', 8),
('2025-09-01', '2025-09-30', 6),
('2025-10-01', '2025-10-31', 14);

INSERT INTO ForRide (RideName, TicketID) VALUES
('ThunderCoaster', 200),
('SkyDrop', 201),
('RapidRiver', 202),
('HauntedRide', 203),
('GalaxySpin', 204);

INSERT INTO MaintenanceRecord1 (MaintenancePerformed, NumberOfWorkers) VALUES
('Engine Overhaul', 3),
('Track Inspection', 2),
('Electrical Check', 1),
('Brake Replacement', 4),
('Safety Test', 2);

INSERT INTO MaintenanceRecord2 (RideName, RecordID, MaintenancePerformed, MaintenanceDate) VALUES
('ThunderCoaster', 1, 'Engine Overhaul', '2025-01-15'),
('SkyDrop', 2, 'Track Inspection', '2025-02-10'),
('RapidRiver', 3, 'Electrical Check', '2025-03-05'),
('HauntedRide', 4, 'Brake Replacement', '2025-04-20'),
('GalaxySpin', 5, 'Safety Test', '2025-05-25');

INSERT INTO Guest (CustomerID, DateOfVisit) VALUES
(1, '2025-06-16'),
(2, '2025-07-02'),
(3, '2025-07-16'),
(4, '2025-08-06'),
(5, '2025-09-11');


