-- ==========================
--  CREAR BASE DE DATOS
-- ==========================
CREATE DATABASE MayaCodeDB;
GO
USE MayaCodeDB;
GO

-- ==========================
--  CREACIÓN DE TABLAS
-- ==========================
-- Tabla de Lenguajes
CREATE TABLE Lenguajes (
    id_lenguaje INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE
);

-- Tabla de Periodos
CREATE TABLE Periodo (
    id_periodo INT IDENTITY(1,1) PRIMARY KEY,
    año INT,
    trimestre INT,
    CONSTRAINT UQ_Periodo UNIQUE (año, trimestre)
);

-- Tabla de Uso de Lenguajes
CREATE TABLE Uso_Lenguaje (
    id_uso INT IDENTITY(1,1) PRIMARY KEY,
    id_lenguaje INT,
    id_periodo INT,
    conteo INT,
    FOREIGN KEY (id_lenguaje) REFERENCES Lenguajes(id_lenguaje),
    FOREIGN KEY (id_periodo) REFERENCES Periodo(id_periodo)
);

-- ==========================
--  CREACIÓN DE TABLA TEMPORAL PARA CARGA
-- ==========================
CREATE TABLE #TempLenguajes (
    nombre VARCHAR(100),
    año INT,
    trimestre INT,
    conteo INT
);

-- ==========================
--  CARGAR LOS DATOS DESDE CSV CON BULK INSERT
-- ==========================
BULK INSERT #TempLenguajes
FROM 'C:\Temp\issues.csv'  
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A', 
    FIRSTROW = 2
);

-- ==========================
--  TRANSFORMAR Y POBLAR LAS TABLAS FINALES
-- ==========================
-- Insertar Lenguajes sin duplicados
INSERT INTO Lenguajes (nombre)
SELECT DISTINCT nombre FROM #TempLenguajes
WHERE nombre IS NOT NULL;

-- Insertar Periodos sin duplicados
INSERT INTO Periodo (año, trimestre)
SELECT DISTINCT año, trimestre FROM #TempLenguajes;

-- Insertar Uso de Lenguajes
INSERT INTO Uso_Lenguaje (id_lenguaje, id_periodo, conteo)
SELECT 
    L.id_lenguaje,
    P.id_periodo,
    T.conteo
FROM #TempLenguajes T
JOIN Lenguajes L ON T.nombre = L.nombre
JOIN Periodo P ON T.año = P.año AND T.trimestre = P.trimestre;

-- ==========================
--  LIMPIAR LA TABLA TEMPORAL
-- ==========================
DROP TABLE #TempLenguajes;

-- ==========================
--  CONSULTAS PARA EXPORTAR A POWER BI
-- ==========================

--  TOP 10 LENGUAJES MÁS USADOS (2011-2022)
SELECT TOP 10 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
GROUP BY L.nombre
ORDER BY total_uso DESC;

--  TOP 10 LENGUAJES MENOS USADOS (2011-2022)
SELECT TOP 10 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
GROUP BY L.nombre
ORDER BY total_uso ASC;

--  TOP 5 LENGUAJES MÁS ACTIVOS EN Q4 2022
SELECT TOP 5 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
JOIN Periodo P ON U.id_periodo = P.id_periodo
WHERE P.año = 2022 AND P.trimestre = 1
GROUP BY L.nombre
ORDER BY total_uso DESC;

