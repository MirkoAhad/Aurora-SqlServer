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
