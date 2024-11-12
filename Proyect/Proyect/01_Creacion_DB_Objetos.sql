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


CREATE TABLE info.sucursal(
	Id_sucursal INT IDENTITY(1,1) primary key,
	Ciudad VARCHAR(50),
	ReemplazarPor VARCHAR(50),
	Direccion VARCHAR(100),
	Horario VARCHAR(50),
	Telefono CHAR(9),
	FechaBaja DATETIME -- si fechabaja es NULL, es porque no esta dado de baja.
);
GO

CREATE TABLE info.empleados(
	Legajo CHAR(7) primary key,
		CONSTRAINT CK_LegajoEmpleado CHECK ( Legajo LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Nombre VARCHAR(25),
	Apellido VARCHAR(25),
	DNI CHAR(8) UNIQUE,
		CONSTRAINT CK_DNIEmpleado CHECK ( DNI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	emailpersonal VARCHAR(50),
		CONSTRAINT CK_EmailPersonalEmpleado CHECK ( emailpersonal LIKE '%_@__%.__%'),
	emailempresa VARCHAR(50),
		CONSTRAINT CK_EmailEmpresaEmpleado CHECK ( emailempresa LIKE '%_@__%.__%'),
	CUIL CHAR (13),
		CONSTRAINT CK_CuilEmpleado CHECK ( CUIL LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
	Cargo VARCHAR (19),
		CONSTRAINT CK_Cargo CHECK (Cargo IN ('Cajero','Supervisor','Gerente de sucursal')),
	FKSucursal INT not null,
		CONSTRAINT FK_Sucursal FOREIGN KEY (FKSucursal) REFERENCES info.sucursal(Id_sucursal),
	Turno VARCHAR (16),
		CONSTRAINT CK_TURNO CHECK ( Turno IN ('TT','TM','Jornada completa')),
	FechaBaja DATETIME,
);
GO


CREATE TABLE info.categoria(
	ID_categoria int identity(1,1) primary key not null,
	NombreCategoria VARCHAR(100),
	Linea_De_Producto VARCHAR(20),
	FechaBaja DATETIME
);
GO

CREATE TABLE productos.producto (
	ID_producto int identity(1,1) primary key not null, -- identity para valores autoincrementales (empieza en 1, aumenta 1)
    Nombre VARCHAR(200),
    PrecioUnitario DECIMAL(10,2),	-- Decimal (6 dígitos en total, puede tener hasta 2 decimales)
    Precio_Referencia DECIMAL(10,2),
    Unidad_Referencia VARCHAR(10),
    Fecha DATETIME, -- se utiliza para almacenar valores de fecha y hora
	FKCategoria INT NOT NULL,
		CONSTRAINT FK_Categoria FOREIGN KEY (FKCategoria) REFERENCES info.categoria(ID_categoria),
	FechaBaja DATETIME
);
GO

CREATE TABLE ventas.metodo_de_pago(
	ID_metodo_de_pago int identity(1,1) primary key not null,
	nombre VARCHAR(11),
	FechaBaja DATETIME
)
GO

CREATE TABLE info.cliente(
	ID_cliente int identity(1,1) primary key not null,
	Nombre VARCHAR(30),
	Genero VARCHAR(6),
		CONSTRAINT CK_GeneroCliente CHECK ( Genero IN ('Male','Female')),
	Tipo_Cliente CHAR(6),
		CONSTRAINT CK_IipoCliente CHECK ( Tipo_Cliente IN ('Member','Normal')),
	FechaBaja DATETIME
);
GO

CREATE TABLE ventas.factura (
	ID_factura int identity(1,1) primary key not null,
	Factura CHAR(11), 
		CONSTRAINT CK_id CHECK ( Factura LIKE  '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    Tipo_Factura CHAR,
		CONSTRAINT CK_TipoFactura CHECK ( Tipo_Factura IN ( 'A','B','C')),
    Fecha DATE,
    Hora TIME,
	Estado VARCHAR(10),
		CONSTRAINT CK_Estado CHECK ( Estado IN ('Pagada','No Pagada')),
    FKEmpleado CHAR(7) NOT NULL,
		CONSTRAINT FK_EmpleadoVenta FOREIGN KEY (FKEmpleado) REFERENCES info.empleados(Legajo),
	FKMetodoDePago INT NOT NULL,
		CONSTRAINT FK_MetodoDePagoVenta FOREIGN KEY (FKMetodoDePago) REFERENCES ventas.metodo_de_pago(ID_metodo_de_pago),
	FKSucursal INT NOT NULL,
		CONSTRAINT FK_SucursalVenta FOREIGN KEY (FKSucursal) REFERENCES info.sucursal(Id_sucursal),
	FKCliente INT NOT NULL,
		CONSTRAINT FK_ClienteVenta FOREIGN KEY (FKCliente) REFERENCES info.cliente(ID_cliente),
);
GO

CREATE TABLE ventas.detalle_factura(
	ID_detalle int identity(1,1) primary key not null,
	FKFactura INT NOT NULL,
		CONSTRAINT FK_FacturaDetalle FOREIGN KEY (FKFactura) REFERENCES ventas.factura(ID_factura),
	FKProducto INT NOT NULL,
		CONSTRAINT FK_ProductoDetalle FOREIGN KEY (FKProducto) REFERENCES productos.producto(ID_producto),
	Identificador_de_Pago VARCHAR(30) NULL,
		CONSTRAINT CK_Indetificador_de_pago CHECK ( Identificador_de_Pago LIKE  '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
													OR Identificador_de_Pago LIKE '''[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Cantidad INT,
	Precio DECIMAL(10,2)
);
GO

CREATE TABLE ventas.nota_de_credito(
	ID_credito int identity(1,1) primary key not null,
	FKCliente INT NOT NULL,
		CONSTRAINT FK_ClienteCredito FOREIGN KEY (FKCliente) REFERENCES info.cliente(ID_cliente),
	FKFactura INT NOT NULL,
		CONSTRAINT FK_FacturaCredito FOREIGN KEY (FKFactura) REFERENCES ventas.factura(ID_factura),
	FKProducto INT NOT NULL,
		CONSTRAINT FK_ProductoCredito FOREIGN KEY (FKProducto) REFERENCES productos.producto(ID_producto),
	NumeroComprobante INT,
	NumeroComprobanteCon0 AS RIGHT(REPLICATE('0', 8) + CAST(NumeroComprobante AS VARCHAR), 8), --REPLICATE('0', 8): Crea una cadena con 8 ceros.+ CAST(NumeroComprobante AS VARCHAR): Convierte el número enviado a cadena y concatena con los ceros.RIGHT(..., 8): Extrae los últimos 8 caracteres, para garantizar que la longitud total sea de 8 dígitos.
	PuntoDeVenta VARCHAR(5)
);
GO

DROP TABLE IF EXISTS productos.producto
GO


DROP TABLE IF EXISTS ventas.factura
GO

DROP TABLE IF EXISTS ventas.detalle_factura
GO

DROP TABLE IF EXISTS ventas.nota_de_credito
GO
DROP table IF EXISTS info.Empleados
GO
DROP TABLE IF EXISTS info.categoria
GO
DROP TABLE IF EXISTS info.sucursal
GO

DROP TABLE IF EXISTS ventas.metodo_de_pago
GO

DROP TABLE IF EXISTS info.cliente
GO



-- PROCEDURES

DROP PROCEDURE ImportarDesdeExcel
GO

DROP PROCEDURE ImportarCSV
GO
