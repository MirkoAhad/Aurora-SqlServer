
-- ______________________________________CSV___________________________________

EXEC ImportarCSV 
    @data_file_path = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\catalogo.csv',
    @tabla_Variable = 'productos.catalogo',
	@separador = ','

EXEC ImportarCSV 
    @data_file_path = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Ventas_registradas.csv',
    @tabla_Variable = 'ventas.ventas_registradas',
	@separador = ';'

--________________________________________EXCEL______________________________

EXEC ImportarDesdeExcel 
    @RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\Electronic accessories.xlsx',
	@tabla_Variable = 'productos.electronic_accesories',
	@NombreHoja = '[Sheet1$]'



EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
	@tabla_Variable = 'productos.productos_importados',
	@NombreHoja = '[Listado de Productos$]'

EXEC ImportarDesdeExcel 
	@RutaArchivo = 'C:\Users\ahadm\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx',
	@tabla_Variable = 'info.sucursal',
	@NombreHoja = '[sucursal$]'

--_________________________________________otras___________________________


EXEC EliminarDupElectronicos;