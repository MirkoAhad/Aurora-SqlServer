CREATE DATABASE supermercado;
go
USE supermercado;
go
CREATE SCHEMA productos;
go
CREATE SCHEMA ventas;
go
CREATE SCHEMA info;
go

-- usamos el go despues de cada linea para aseguranos que cuando ejecutemos todas juntas, se ejecute correctamente cada una.

CREATE TABLE productos.catalogo (
	ID int identity(1,1) primary key not null, -- identity para valores autoincrementales (empieza en 1, aumenta 1)
    Categoria VARCHAR(100),
    Nombre VARCHAR(200),
    Precio DECIMAL(6,2),	-- Decimal (6 dígitos en total, puede tener hasta 2 decimales)
    Precio_Referencia DECIMAL(10,2),
    Unidad_Referencia VARCHAR(10),
    Fecha DATETIME -- se utiliza para almacenar valores de fecha y hora
);
GO

CREATE TABLE productos.electronic_accesories (
	ID int identity(1,1) primary key not null, 
	Producto VARCHAR(50),
    Precio_Unitario DECIMAL(6,2)
);
GO

CREATE TABLE productos.productos_importados (
	IdProducto int primary key,
    NombreProducto VARCHAR(100),
    Proveedor VARCHAR(100),
    Categoria VARCHAR(30),
    CantidadPorUnidad VARCHAR(50),
    PrecioUnidad DECIMAL(5,2)
);
GO

CREATE TABLE ventas.ventas_registradas (
	ID CHAR(11) primary key, 
	CONSTRAINT CK_id CHECK ( ID LIKE  '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    Tipo_Factura CHAR,
    Ciudad VARCHAR(100),
    Tipo_Cliente VARCHAR(100),
    Genero VARCHAR(100),
    Producto VARCHAR(150),
    Precio_Unitario DECIMAL(10,2),
    Cantidad INT,
    Fecha DATE,
    Hora TIME,
    Medio_De_Pago VARCHAR(100),
    Id_Empleado VARCHAR(100),		-- probar con UNIQUE
    Id_De_Pago VARCHAR(100),
);
GO

CREATE TABLE info.sucursal(
	Ciudad VARCHAR(50),
	ReemplazarPor VARCHAR(50),
	direccion VARCHAR(100),
	Horario VARCHAR(50),
	Telefono VARCHAR(50) primary key
);
GO

CREATE TABLE info.Empleados(
	Legajo VARCHAR(7) primary key,
	Nombre VARCHAR(50),
	Apellido VARCHAR(50),
	DNI INT,
	Direccion VARCHAR(100),
	emailpersonal VARCHAR(100),
	emailempresa VARCHAR(100),
	CUIL CHAR (11) null,
	Cargo VARCHAR (50),
	Sucursal VARCHAR (50),
	Turno VARCHAR (30),
	CONSTRAINT CK_TURNO CHECK ( Turno IN ('TT','TM','Jornada completa'))
);
GO

CREATE TABLE info.ClasificacionProductos (
	ID int identity(1,1) primary key not null, 
	Linea_De_Producto VARCHAR(20),
    Producto VARCHAR(100)
);
GO


/*
CHECK_CONSTRAINTS,	   -- Verifica las restricciones de la tabla al insertar los datos
FORMAT = 'CSV',		   -- Especifica que el archivo que se está importando está en formato CSV permitiendo que SQL Server maneje automáticamente la coma como delimitador y considere comillas dobles para los valores con caracteres especiales.
CODEPAGE = '65001',	   -- indica que SQL Server debe utilizar UTF-8 como la página de códigos, al leer el archivo
FIRSTROW = 2,		   -- Omitir la primera fila si el archivo tiene encabezados
FIELDTERMINATOR = ',', -- Define el delimitador de campos
ROWTERMINATOR = '0x0A') -- Define el delimitador de filas
*/


CREATE OR ALTER PROCEDURE ImportarCSV
    @data_file_path VARCHAR(MAX),
	@tabla_Variable NVARCHAR(200),
	@separador CHAR
AS
BEGIN
    SET NOCOUNT ON; -- nos evitamos mensajes que generan trafico de red.
    
    DECLARE @sql NVARCHAR(MAX); -- creo de forma dinamica el ingreso, usando @sql
	SET @sql = '
	BULK INSERT ' + @tabla_Variable + '
    FROM ''' + @data_file_path + '''
    WITH(
			CHECK_CONSTRAINTS,
			FORMAT = ''CSV'',		   
			CODEPAGE = ''65001'',
			FIRSTROW = 2,		   
			FIELDTERMINATOR = ''' + @separador + ''',
			ROWTERMINATOR = ''0x0A''
		);
';
	EXEC sp_executesql @sql; --Usamos sp_executesql en vez de EXEC, por un tema de seguridad (https://www.geeksforgeeks.org/exec-vs-sp_executesql-in-sql-server/)
END;


EXEC ImportarCSV 
    @data_file_path = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\catalogo.csv',
    @tabla_Variable = 'productos.catalogo',
	@separador = ','

EXEC ImportarCSV 
    @data_file_path = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Ventas_registradas.csv',
    @tabla_Variable = 'ventas.ventas_registradas',
	@separador = ';'


--_______________________________________________________________ DE XLSX A SQL ____________________________________________________________

https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-data-from-excel-to-sql?view=sql-server-ver16#openrowset-and-linked-servers

USE [master]
GO
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DisallowAdHocAccess', 0
GO

--Para poder ejecutar una consulta distribuida, debe habilitar la opción de configuración del servidor
sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


CREATE OR ALTER PROCEDURE ImportarDesdeExcel
    @RutaArchivo VARCHAR(MAX),
	@tabla_Variable NVARCHAR(200),
	@NombreHoja NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Consulta para importar datos desde el archivo Excel usando OPENROWSET
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
        INSERT INTO ' + @tabla_Variable + '
		SELECT * 
		FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
		 ''Excel 12.0;Database='++ @RutaArchivo ++''', ''select * from ' ++ @NombreHoja ++''');
    ';
    EXEC sp_executesql @sql;
END;

EXEC ImportarDesdeExcel 
    @RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\Electronic accessories.xlsx',
	@tabla_Variable = 'productos.electronic_accesories',
	@NombreHoja = '[Sheet1$]'

-- _________________________________Eliminar Duplicados_________________________________________________________

CREATE OR ALTER PROCEDURE EliminarDupElectronicos
AS
BEGIN

	SET NOCOUNT ON;

	WITH C AS
	(
		SELECT ID,Producto,Precio_Unitario,
		ROW_NUMBER() OVER (PARTITION BY
							Producto, Precio_Unitario
							ORDER BY ID) AS DUPLICADO
		FROM productos.electronic_accesories
	)

	DELETE FROM C  --SELECT * FROM C 
	WHERE DUPLICADO > 1

END;

EXEC EliminarDupElectronicos;

--_________________________________________________________________________________________________________________

EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
	@tabla_Variable = 'productos.productos_importados',
	@NombreHoja = '[Listado de Productos$]'

EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx',
	@tabla_Variable = 'info.sucursal',
	@NombreHoja = '[sucursal$]'


CREATE OR ALTER PROCEDURE CargaEmpleados
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #EmpleadosTemp(
		Legajo VARCHAR(7),
		Nombre VARCHAR(50),
		Apellido VARCHAR(50),
		DNI INT,
		Direccion VARCHAR(100),
		emailpersonal VARCHAR(100),
		emailempresa VARCHAR(100),
		CUIL CHAR (11) null,
		Cargo VARCHAR (50),
		Sucursar VARCHAR (50),
		Turno VARCHAR (30),
		CONSTRAINT CK_TURNO CHECK ( Turno IN ('TT','TM','Jornada completa'))
	);

	EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx',
	@tabla_Variable = '#EmpleadosTemp',
	@NombreHoja = '[Empleados$]'

	INSERT INTO info.Empleados
	SELECT *
	FROM #EmpleadosTemp
	WHERE Legajo IS NOT NULL;

	drop table #EmpleadosTemp

END;

EXEC CargaEmpleados


EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx',
	@tabla_Variable = 'info.ClasificacionProductos',
	@NombreHoja = '[Clasificacion productos$]'


--______________________________CSV_____________________________
select *
from ventas.ventas_registradas

select *
from productos.catalogo

--______________________________XLXS_____________________________

select *
from productos.electronic_accesories

select *
from productos.productos_importados

SELECT *
FROM info.sucursal

SELECT *
FROM info.Empleados

SELECT *
FROM info.ClasificacionProductos

-- CSV
DROP TABLE ventas.ventas_registradas
GO
DROP TABLE productos.catalogo
GO
-- XLXS
DROP TABLE productos.electronic_accesories
GO
DROP TABLE productos.productos_importados
GO

DROP TABLE info.sucursal
GO
DROP table info.Empleados
GO

DROP TABLE info.ClasificacionProductos
GO

-- PROCEDURES

DROP PROCEDURE ImportarDesdeExcel
GO

DROP PROCEDURE ImportarCSV
GO




-- cambio cambio prueba
--
/*



asDFADSF
ASDF
ASD
F
ASDF

ASDF
A
SDF
/*