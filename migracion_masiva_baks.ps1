# 1. Configuración de confianza
Set-DbatoolsConfig -Name 'sql.connection.trustcert' -Value $true

# 2. Variables
$servidor = "DAN_SAC\ENGINE_17"
$rutaBackups = "D:\UNIDAD_D\RESPALDOS_BAK" 
$rutaDestino = "D:\DATABASES" 

# 3. Verificación y Conexión
$archivosEncontrados = Get-ChildItem -Path $rutaBackups -Filter *.bak -Recurse

if ($archivosEncontrados.Count -eq 0) {
    Write-Warning "No encontré archivos .bak en $rutaBackups"
}
else {
    Write-Host "Iniciando proceso para $($archivosEncontrados.Count) archivos..." -ForegroundColor Green
    
    $conexion = Connect-DbaInstance -SqlInstance $servidor -TrustServerCertificate

    # 4. Restauración
    foreach ($archivo in $archivosEncontrados) {
        Write-Host "Procesando: $($archivo.Name)" -ForegroundColor Yellow
        
        try {
            Restore-DbaDatabase -SqlInstance $conexion `
                -Path $archivo.FullName `
                -DestinationDataDirectory $rutaDestino `
                -DestinationLogDirectory $rutaDestino `
                -DestinationFileStreamDirectory $rutaDestino `
                -WithReplace `
                -ErrorAction Stop
                
            Write-Host "  -> OK: $($archivo.Name) restaurada." -ForegroundColor Green
        }
        catch {
            # Esto nos dará el error exacto si falla algo más
            Write-Host "  -> ERROR en $($archivo.Name): $($_.Exception.Message)" -ForegroundColor Red
            
            # Si el error es sobre FileStream, intenta mostrar más detalle
            if ($_.Exception.InnerException) {
                Write-Host "     Detalle: $($_.Exception.InnerException.Message)" -ForegroundColor Red
            }
        }
    }
}