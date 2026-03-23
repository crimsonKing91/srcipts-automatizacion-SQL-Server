-- 1. Habilitar opciones avanzadas para ver la configuración de FileStream
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

-- 2. Activar FileStream
-- 0 = Deshabilitado
-- 1 = Solo acceso T-SQL
-- 2 = Acceso T-SQL y acceso de transmisión Win32 (Recomendado/Estándar)
EXEC sp_configure 'filestream access level', 2;
GO
RECONFIGURE;
GO

SELECT SERVERPROPERTY('FilestreamConfiguredLevel') AS NivelConfigurado;
-- Debe devolver 2