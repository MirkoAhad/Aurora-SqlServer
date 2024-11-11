
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



--_______________________________________________________________ DE XLSX A SQL ____________________________________________________________


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


--_________________________________________________________________________________________________________________

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

