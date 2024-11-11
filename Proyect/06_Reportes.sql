CREATE PROCEDURE ventas.Reporte_Mensual @mes TINYINT, @anio SMALLINT
AS
BEGIN
	SELECT DATENAME(WEEKDAY, v.Fecha) AS dia_semana, SUM(v.Cantidad*v.Precio_Unitario) AS total_facturado
	FROM ventas.venta AS v
	WHERE YEAR(v.Fecha) = @anio AND MONTH(v.Fecha) = @mes
	GROUP BY DAYOFWEEK(v.Fecha)
	ORDER BY DAYOFWEEK(v.Fecha);