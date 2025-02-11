# MayaCode

Esta base de datos ha sido diseñada para almacenar y analizar datos históricos sobre el uso de diferentes lenguajes de programación desde 2011 hasta 2022. La estructura permite realizar consultas eficientes para reportes en **Power BI**.

---

## 🏛️ Modelo Relacional

El modelo relacional está compuesto por **tres tablas principales**:

### 1️⃣ **Lenguajes**

- Almacena los diferentes lenguajes de programación.
- **Clave primaria:** `id_lenguaje`
- **Restricción única:** `nombre`

### 2️⃣ **Periodo**

- Guarda los periodos de tiempo en los que se registra el uso de los lenguajes.
- **Clave primaria:** `id_periodo`
- **Restricción única:** `año, trimestre` (para evitar registros duplicados)

### 3️⃣ **Uso_Lenguaje**

- Relaciona los lenguajes con los periodos de uso y la cantidad de registros de actividad.
- **Clave primaria:** `id_uso`
- **Claves foráneas:** `id_lenguaje`, `id_periodo`

**🔹 Razón para esta estructura:**

- Permite normalización y evita redundancia de datos.
- Facilita consultas eficientes y reportes en Power BI.

---

## 🛠️ Creación de la Base de Datos

```sql
-- CREAR BASE DE DATOS
CREATE DATABASE MayaCodeDB;
GO
USE MayaCodeDB;
GO
```

---

## 🏗️ Creación de Tablas

```sql
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
```

---

## 📥 Carga de Datos desde CSV

Para cargar los datos desde un archivo CSV, se utiliza `BULK INSERT` en una tabla temporal.

```sql
-- CREACIÓN DE TABLA TEMPORAL PARA CARGA
CREATE TABLE #TempLenguajes (
    nombre VARCHAR(100),
    año INT,
    trimestre INT,
    conteo INT
);

-- CARGAR LOS DATOS DESDE CSV
BULK INSERT #TempLenguajes
FROM 'C:\\Temp\\issues.csv'  
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A', 
    FIRSTROW = 2
);
```

---

## 🔄 Transformación y Poblamiento de la Base de Datos

```sql
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

-- ELIMINAR LA TABLA TEMPORAL
DROP TABLE #TempLenguajes;
```

---

## 📊 Consultas para Reportes en Power BI

Estas consultas permiten generar reportes para análisis de tendencias de uso de lenguajes.

### 🔹 **Top 10 Lenguajes Más Usados (2011-2022)**

```sql
SELECT TOP 10 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
GROUP BY L.nombre
ORDER BY total_uso DESC;
```

### 🔹 **Top 10 Lenguajes Menos Usados (2011-2022)**

```sql
SELECT TOP 10 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
GROUP BY L.nombre
ORDER BY total_uso ASC;
```

### 🔹 **Top 5 Lenguajes Más Activos en Q4 2022**

```sql
SELECT TOP 5 L.nombre, SUM(U.conteo) AS total_uso
FROM Uso_Lenguaje U
JOIN Lenguajes L ON U.id_lenguaje = L.id_lenguaje
JOIN Periodo P ON U.id_periodo = P.id_periodo
WHERE P.año = 2022 AND P.trimestre = 4
GROUP BY L.nombre
ORDER BY total_uso DESC;
```

---

## 📌 Conclusión

Este modelo relacional facilita la consulta y análisis de tendencias de uso de lenguajes de programación a lo largo del tiempo. La estructura elegida:

- **Evita redundancia de datos** mediante la normalización.
- **Permite agregar nuevos datos fácilmente** sin afectar la estructura.
- **Optimiza la generación de reportes en Power BI**.

🚀 **Este enfoque garantiza un almacenamiento eficiente y consultas rápidas para la toma de decisiones.**
