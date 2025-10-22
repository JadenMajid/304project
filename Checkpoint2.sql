/*
When looking at this SQL file, there are 2 parts
1. Table Initializations
  - FK ON X justifications are done as comments
2. Insert statements
*/

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
    ON DELETE SET NULL,
  CONSTRAINT fk_sps_ratemodifier FOREIGN KEY (RateCode)
    REFERENCES RateModifier (RateCode)
    -- When a RateModifier's RateCode, any associated SeasonPasses should still reference the same RateCode
    ON DELETE CASCADE
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
    -- 
    ON DELETE SET NULL,
  CONSTRAINT fk_offers_room FOREIGN KEY (RoomName)
    REFERENCES RoomType (RoomName)
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
    ON DELETE CASCADE,
  CONSTRAINT fk_hs_room FOREIGN KEY (RoomName)
    REFERENCES RoomType (RoomName)
    ON DELETE CASCADE,
  CONSTRAINT fk_hs_booking FOREIGN KEY (BookingNumber)
    REFERENCES Booking (BookingNumber)
    ON DELETE CASCADE
);

CREATE TABLE ForRide (
  RideName  VARCHAR,
  TicketID  INTEGER,
  PRIMARY KEY (RideName, TicketID),
  CONSTRAINT fk_forride_ride FOREIGN KEY (RideName)
    REFERENCES Ride (RideName)
    ON DELETE SET NULL,
  CONSTRAINT fk_forride_ticket FOREIGN KEY (TicketID)
    REFERENCES Ticket2 (TicketID)
    ON DELETE SET NULL
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
    ON DELETE CASCADE
);

CREATE TABLE Guest (
  CustomerID  INTEGER,
  DateOfVisit DATE,
  PRIMARY KEY (CustomerID, DateOfVisit),
  CONSTRAINT fk_guest_customer FOREIGN KEY (CustomerID)
    REFERENCES Customer (CustomerID)
    ON DELETE CASCADE
);


