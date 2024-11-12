USE supermercado

/*
CHECK_CONSTRAINTS,	   -- Verifica las restricciones de la tabla al insertar los datos
FORMAT = 'CSV',		   -- Especifica que el archivo que se está importando está en formato CSV permitiendo que SQL Server maneje automáticamente la coma como delimitador y considere comillas dobles para los valores con caracteres especiales.
CODEPAGE = '65001',	   -- indica que SQL Server debe utilizar UTF-8 como la página de códigos, al leer el archivo
FIRSTROW = 2,		   -- Omitir la primera fila si el archivo tiene encabezados
FIELDTERMINATOR = ',', -- Define el delimitador de campos
ROWTERMINATOR = '0x0A') -- Define el delimitador de filas
*/


CREATE OR ALTER PROCEDURE info.SucursalImportar
	@data_file_path VARCHAR(MAX)
AS
BEGIN
	BEGIN TRY

	IF OBJECT_ID('tempdb..#tmpSucursal') IS NOT NULL
			DROP TABLE #tmpSucursal;

		CREATE TABLE #tmpSucursal (
			Ciudad VARCHAR(100),
			ReemplazarPor VARCHAR(100),
			Direccion VARCHAR(100),
			Horario VARCHAR(100),
			Telefono VARCHAR(100)
		);

	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
			INSERT INTO #tmpSucursal (Ciudad,RemplazarPor,Direccion,Horario,Telefono)
			SELECT * 
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
			 ''Excel 12.0;Database='++ @data_file_path ++''',
			 ''select * from [sucursal$]'');
		';
		EXEC sp_executesql @sql;

		INSERT INTO info.sucursal(Ciudad,ReemplazarPor,Direccion,Horario,Telefono) 
		SELECT tmp.Ciudad,tmp.ReemplazarPor,tmp.Direccion,tmp.Horario,tmp.Telefono
		FROM #tmpSucursal tmp
		WHERE NOT EXISTS
			(SELECT 1 FROM info.sucursal s
			WHERE tmp.ReemplazarPor = s.Ciudad COLLATE Modern_Spanish_CI_AS
			AND tmp.Direccion = s.direccion COLLATE Modern_Spanish_CI_AS)
	END TRY
	BEGIN CATCH
		PRINT 'Error al importar Excel Sucursal' + ERROR_MESSAGE();
	END CATCH

		DROP TABLE IF EXISTS #tmpSucursal;
END;
GO

DROP PROCEDURE info.SucursalImportar


CREATE OR ALTER PROCEDURE info.EmpleadosImportar
	@data_file_path VARCHAR(MAX)
AS
BEGIN
	BEGIN TRY

		IF OBJECT_ID('tempdb..#tmpEmpleado') IS NOT NULL
			DROP TABLE #tmpEmpleado;

		CREATE TABLE #tmpEmpleado (
			Legajo VARCHAR(100),
			Nombre VARCHAR(100),
			Apellido VARCHAR(100),
			DNI VARCHAR(100),
			Direccion VARCHAR(100),
			emailpersonal VARCHAR(100),
			emailempresa VARCHAR(100),
			CUIL VARCHAR(100),
			Cargo VARCHAR(100),
			Ciudad_sucursal VARCHAR(100),
			Turno VARCHAR(100)
		);

		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);

		SET @sql = '
			INSERT INTO #tmpEmpleado (Legajo,Nombre,Apellido,DNI,Direccion,emailpersonal,emailempresa,CUIL,Cargo,Ciudad_sucursal,Turno)
			SELECT * 
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
			 ''Excel 12.0;Database='++ @data_file_path ++''',
			 ''select * from [Empleados$]'');
		';
		EXEC sp_executesql @sql;
	
		INSERT INTO info.empleados(Legajo,Nombre,Apellido,DNI,emailpersonal,emailempresa,CUIL,Cargo,Turno,FKSucursal)
			(SELECT tmp.Legajo,tmp.Nombre,tmp.Apellido,tmp.DNI,REPLACE(REPLACE(tmp.emailpersonal, ' ', ''), CHAR(9), ''),
			REPLACE(REPLACE(tmp.emailempresa, ' ', ''), CHAR(9), ''),tmp.CUIL,tmp.Cargo,tmp.Turno,
			(SELECT Id_sucursal FROM info.sucursal WHERE Ciudad = tmp.Ciudad_sucursal COLLATE Modern_Spanish_CS_AS)
		FROM #tmpEmpleado tmp
		WHERE tmp.Legajo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM info.empleados e WHERE tmp.Legajo = e.Legajo))

	END TRY
	BEGIN CATCH
		PRINT 'Error al importar Excel Empleados' + ERROR_MESSAGE();
	END CATCH

		DROP TABLE IF EXISTS #tmpEmpleado;
END;
GO



CREATE OR ALTER PROCEDURE info.CategoriaImportar
	@data_file_path VARCHAR(MAX)
AS
BEGIN
		BEGIN TRY

			IF OBJECT_ID('tempdb..#tmpCategoria') IS NOT NULL
				DROP TABLE #tmpCategoria;

			CREATE TABLE #tmpCategoria (
				NombreCategoria VARCHAR(100),
				Linea_De_Producto VARCHAR(100)
				);

			SET NOCOUNT ON;

			DECLARE @sql NVARCHAR(MAX);

			SET @sql = '
				INSERT INTO #tmpCategoria(NombreCategoria,Linea_De_Producto)
				SELECT * 
				FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				 ''Excel 12.0;Database='++ @data_file_path ++''',
				 ''select * from [Clasificacion productos$]'');
			';
			EXEC sp_executesql @sql;

			INSERT INTO info.categoria(NombreCategoria,Linea_De_Producto)
			(
				SELECT tmp.NombreCategoria, tmp.Linea_De_Producto
				FROM #tmpCategoria tmp
				WHERE NOT EXISTS(
					SELECT 1
					FROM info.categoria c
					WHERE tmp.NombreCategoria = c.NombreCategoria COLLATE Modern_Spanish_CI_AS)
			)
		END TRY

	BEGIN CATCH
		PRINT 'Error al importar Excel Categoria' + ERROR_MESSAGE();
	END CATCH
		DROP TABLE IF EXISTS #tmpCategoria;
END;
GO



CREATE OR ALTER PROCEDURE info.CatalogoImportar
	@data_file_path VARCHAR(MAX)
AS
BEGIN
		BEGIN TRY

			IF OBJECT_ID('tempdb..#tmpCatalogo') IS NOT NULL
				DROP TABLE #tmpCatalogo;

			CREATE TABLE #tmpCatalogo (
				ID INT,
				Category VARCHAR(100),
				Nombre VARCHAR(100),
				Price DECIMAL(100,2),
				Reference_price DECIMAL(100,2),
				Reference_unit VARCHAR(100),
				Fecha DATETIME
			);
			
	SET NOCOUNT ON; -- nos evitamos mensajes que generan trafico de red.
    
    DECLARE @sql NVARCHAR(MAX); -- creo de forma dinamica el ingreso, usando @sql

	SET @sql = '
		BULK INSERT #tmpCatalogo
		FROM ''' + @data_file_path + '''
		WITH(
				CHECK_CONSTRAINTS,
				FORMAT = ''CSV'',		   
				CODEPAGE = ''65001'',
				FIRSTROW = 2,		   
				FIELDTERMINATOR = '','',
				ROWTERMINATOR = ''0x0A''
			);
	';
	EXEC sp_executesql @sql;

	WITH cte_Dup
	AS
	(
		SELECT tmp.ID, ROW_NUMBER() OVER (PARTITION BY tmp.Nombre, tmp.Reference_price, tmp.Reference_unit, tmp.Price ORDER BY tmp.Fecha) as Duplicados
		FROM #tmpCatalogo tmp
	)

	/*SELECT *
	FROM cte_Dup
	WHERE Duplicados > 1
	*/

	DELETE FROM cte_Dup
	WHERE Duplicados > 1
	
	--UPDATE #tmpCatalogo

	INSERT INTO productos.producto(Nombre,PrecioUnitario,Precio_Referencia,Unidad_Referencia,Fecha,FKCategoria)
	(
		SELECT tmp.Nombre,tmp.Price,tmp.Reference_price,tmp.Reference_unit,tmp.Fecha,
		(SELECT c.ID_categoria
			FROM info.categoria c
			WHERE c.NombreCategoria = tmp.Category COLLATE Modern_Spanish_CI_AS)
		FROM #tmpCatalogo tmp
		WHERE NOT EXISTS(
			SELECT 1
				FROM productos.producto p
				WHERE p.Nombre = tmp.Nombre COLLATE Modern_Spanish_CI_AS
				AND p.PrecioUnitario = tmp.Price
				AND p.Precio_Referencia = tmp.Reference_price
				AND p.Unidad_Referencia = tmp.Reference_unit COLLATE Modern_Spanish_CI_AS)
	)

	END TRY
	BEGIN CATCH
		PRINT 'Error al importar Excel Catalogo' + ERROR_MESSAGE();
	END CATCH
		DROP TABLE IF EXISTS #tmpCatalogo;
END;
GO


--__________________________________PRODUCTOS IMPORTADOS__________________________

CREATE OR ALTER PROCEDURE productos.ProductosImport
	@data_file_path VARCHAR(MAX)
AS
BEGIN
		BEGIN TRY

			IF OBJECT_ID('tempdb..#tmpProductos') IS NOT NULL
				DROP TABLE #tmpProductos;

			CREATE TABLE #tmpProductos (
				IdProducto VARCHAR(100),
				NombreProducto VARCHAR(100),
				Proveedor VARCHAR(100),
				Categoria VARCHAR(100),
				CantidadPorUnidad VARCHAR(100),
				PrecioUnidad VARCHAR(100)
			);

			SET NOCOUNT ON;

			DECLARE @sql NVARCHAR(MAX);

			SET @sql = '
				INSERT INTO #tmpProductos(IdProducto,NombreProducto,Proveedor,Categoria,CantidadPorUnidad,PrecioUnidad)
				SELECT * 
				FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				 ''Excel 12.0;Database='++ @data_file_path ++''',
				 ''select * from [Listado de Productos$]'');
			';
			EXEC sp_executesql @sql;

			UPDATE #tmpProductos
			SET Categoria = CONCAT('importado_',Categoria)

			INSERT INTO info.categoria(NombreCategoria,Linea_De_Producto)
			(
				SELECT DISTINCT 'Importado',tmp.Categoria
					FROM #tmpProductos tmp
					WHERE NOT EXISTS 
					(
						SELECT 1
							FROM info.categoria c
							WHERE c.NombreCategoria = tmp.Categoria COLLATE Modern_Spanish_CI_AS
					)
			)

			INSERT INTO productos.producto(Nombre,PrecioUnitario,Precio_Referencia,Unidad_Referencia,Fecha,FKCategoria)
			SELECT tmp.Nombre,tmp.Price,tmp.Reference_price,tmp.Reference_unit,tmp.Fecha,
			(SELECT c.ID_categoria
			FROM info.categoria c
			WHERE c.NombreCategoria = tmp.Category COLLATE Modern_Spanish_CI_AS)
			FROM #tmpCatalogo tmp
			WHERE NOT EXISTS(
				SELECT 1
					FROM productos.producto p
					WHERE p.Nombre = tmp.Nombre COLLATE Modern_Spanish_CI_AS
					AND p.PrecioUnitario = tmp.Price
					AND p.Precio_Referencia = tmp.Reference_price
					AND p.Unidad_Referencia = tmp.Reference_unit COLLATE Modern_Spanish_CI_AS)
	)
 


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

