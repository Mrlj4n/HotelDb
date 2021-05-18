CREATE DATABASE HotelDb
COLLATE Serbian_Latin_100_CI_AI
GO

USE HotelDb
GO

CREATE TABLE Gost(
GostId int IDENTITY(1,1) PRIMARY KEY,
Ime nvarchar(30) NOT NULL,
Prezime nvarchar(50) NOT NULL,
Jmbg char(13) NOT NULL,
BrojTelefona varchar(20) NOT NULL
)

CREATE TABLE Usluga(
UslugaId int NOT NULL IDENTITY(1,1) PRIMARY KEY,
VrstaUsluge nvarchar(50) NOT NULL,
Cena money NOT NULL,
PopustDeca decimal(5,2) NOT NULL DEFAULT 30
)


CREATE TABLE Soba(
SobaId int IDENTITY(1,1) PRIMARY KEY,
BrojSobe int NOT NULL,
BrojBracnihKreveta tinyint NOT NULL DEFAULT 1,
BrojSingleKreveta tinyint NOT NULL,
BrojSofa tinyint NOT NULL,
Kapacitet int NOT NULL,
Terasa bit NOT NULL DEFAULT 1,
TV bit NOT NULL DEFAULT 1,
MiniBar bit NOT NULL DEFAULT 1,
CONSTRAINT CHK_Kapacitet CHECK(Kapacitet <= BrojBracnihKreveta*2 + BrojSingleKreveta + BrojSofa*2)
)

CREATE TABLE Rezervacija(
RezervacijaId int IDENTITY(1,1) PRIMARY KEY,
GostId int NOT NULL FOREIGN KEY REFERENCES Gost(GostId),
SobaId int NOT NULL FOREIGN KEY REFERENCES Soba(SobaId),
BrojOdraslih tinyint NOT NULL DEFAULT 2,
BrojDece tinyint NOT NULL DEFAULT 0,
DatumDolaska date NOT NULL, 
DatumOdlaska date NOT NULL,
UslugaId int NOT NULL FOREIGN KEY REFERENCES Usluga(UslugaId),
DatumIzdavanjaRacuna date NULL,
IznosRacuna money NULL,
)
GO
CREATE FUNCTION fn_RaspoloziveSobe
(
	@Prijava date,
	@Odjava date
)
RETURNS TABLE
AS
RETURN
SELECT s.SobaId, s.BrojSobe
FROM Soba as s
WHERE s.SobaId NOT IN
				(
					SELECT s.SobaId
					FROM Soba as s
					INNER JOIN Rezervacija as r
					ON s.SobaId = r.SobaId
					WHERE (@Prijava >=DatumDolaska AND @Prijava<DatumOdlaska)
					OR (@Odjava >= DatumDolaska AND @Odjava<DatumOdlaska)
				)
GO


CREATE VIEW View_VrednostRezervacije
AS
SELECT r.RezervacijaId,r.BrojOdraslih,r.BrojDece,r.DatumOdlaska, u.VrstaUsluge,
u.Cena, u.PopustDeca,
r.BrojOdraslih *u.Cena + r.BrojDece*u.Cena* (1-u.PopustDeca/100) AS [Vrednost rezervacije]
FROM Rezervacija as r 
INNER JOIN Usluga as u
ON r.UslugaId = u.UslugaId

GO
CREATE PROC PromeniRezervaciju
(
	@RezervacijaId int,
	@DatumIzdavanjaRacuna date =NULL
)
AS
DECLARE @VrednostRezervacije money

SELECT @VrednostRezervacije = [Vrednost rezervacije]
FROM View_VrednostRezervacije
WHERE RezervacijaId = @RezervacijaId

IF(@DatumIzdavanjaRacuna IS NULL)
	BEGIN
		SELECT @DatumIzdavanjaRacuna = DatumOdlaska
		FROM View_VrednostRezervacije
		WHERE RezervacijaId = @RezervacijaId
	END

UPDATE Rezervacija
SET DatumIzdavanjaRacuna = @DatumIzdavanjaRacuna,
IznosRacuna = @VrednostRezervacije
WHERE RezervacijaId = @RezervacijaId
GO
