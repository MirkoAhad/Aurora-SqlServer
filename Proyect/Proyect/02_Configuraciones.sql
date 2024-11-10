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

SET DATEFORMAT mdy; --Seteamos el formato de fecha a mdy, como en los archivos.