USE supermercado
GO

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
GO



CREATE OR ALTER PROCEDURE ImportarDesdeExcel
    @ruta_archivo VARCHAR(MAX),
	@tabla_variable NVARCHAR(200),
	@nombre_hoja NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Consulta para importar datos desde el archivo Excel usando OPENROWSET
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
        INSERT INTO ' + @tabla_variable + '
		SELECT * 
		FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
		 ''Excel 12.0;Database='++ @ruta_archivo ++''', ''select * from ' ++ @nombre_hoja ++''');
    ';
    EXEC sp_executesql @sql;
END;
GO




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
GO


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
		Email_Personal VARCHAR(100),
		Email_Empresa VARCHAR(100),
		CUIL CHAR (11) null,
		Cargo VARCHAR (50),
		Sucursal VARCHAR (50),
		Turno VARCHAR (30),
		CONSTRAINT CK_TURNO CHECK ( Turno IN ('TT','TM','Jornada completa'))
	);

	EXEC ImportarDesdeExcel 
	@ruta_archivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx',
	@tabla_Variable = '#EmpleadosTemp',
	@nombre_hoja = '[Empleados$]'

	INSERT INTO info.empleados
	SELECT e.Legajo, e.Nombre, e.Apellido, e.DNI, e.Direccion, e.Email_Personal, e.Email_Empresa, e.CUIL, e.Cargo, s.ID, e.Turno
	FROM #EmpleadosTemp AS e, info.sucursal AS s
	WHERE e.Legajo IS NOT NULL AND e.Sucursal = s.ReemplazarPor;

	drop table #EmpleadosTemp

END;
GO