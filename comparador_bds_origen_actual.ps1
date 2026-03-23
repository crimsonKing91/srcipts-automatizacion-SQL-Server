# ==========================================
# CONFIGURACIÓN C:\SCRIPTS_SQL_AUTOMATICOS
# ==========================================
$servidorOrigen  = "174.142.204.100"  # <--- PON AQUÍ EL NOMBRE DEL SERVER VIEJO
$servidorDestino = "DAN_SAC\ENGINE_17"    # Tu servidor actual

# Configuración de seguridad para ambos
Set-DbatoolsConfig -Name 'sql.connection.trustcert' -Value $true

# ==========================================
# PROCESO DE COMPARACIÓN
# ==========================================
Write-Host "Conectando a servidores..." -ForegroundColor Cyan
try {
    $connOrigen  = Connect-DbaInstance -SqlInstance $servidorOrigen -TrustServerCertificate
    $connDestino = Connect-DbaInstance -SqlInstance $servidorDestino -TrustServerCertificate
} catch {
    Write-Error "No se pudo conectar a uno de los servidores. Verifica nombres y red."
    break
}

# Obtenemos la lista de bases de datos que existen en AMBOS lados
$dbsOrigen = Get-DbaDatabase -SqlInstance $connOrigen -ExcludeSystem
$dbsDestinoNames = (Get-DbaDatabase -SqlInstance $connDestino -ExcludeSystem).Name

Write-Host "Iniciando comparación de conteo de filas..." -ForegroundColor Cyan

foreach ($db in $dbsOrigen) {
    $nombreDB = $db.Name
    
    # Solo comparamos si la base existe en el destino (las que acabamos de restaurar)
    if ($dbsDestinoNames -contains $nombreDB) {
        Write-Host "Comparando: [$nombreDB]" -ForegroundColor Yellow

        # Obtiene conteo de filas de TODAS las tablas de esa BD en Origen
        $filasOrigen = Get-DbaTableRowCount -SqlInstance $connOrigen -Database $nombreDB
        
        # Obtiene conteo de filas de TODAS las tablas de esa BD en Destino
        $filasDestino = Get-DbaTableRowCount -SqlInstance $connDestino -Database $nombreDB

        # Compara los objetos
        # SideIndicator "==" significa que son iguales
        # SideIndicator "=>" o "<=" significa diferencia
        $diferencias = Compare-Object -ReferenceObject $filasOrigen -DifferenceObject $filasDestino -Property Table, RowCount

        if ($null -eq $diferencias) {
            Write-Host "   -> INTEGRIDAD PERFECTA (Tablas y filas idénticas)" -ForegroundColor Green
        }
        else {
            Write-Host "   -> ¡DISCREPANCIA DETECTADA!" -ForegroundColor Red
            # Muestra solo las tablas que no coinciden
            $diferencias | Format-Table Table, RowCount, SideIndicator -AutoSize
            
            # Leyenda para entender el error:
            # <= : El valor existe en Origen pero es diferente o no existe en Destino
            # => : El valor existe en Destino pero es diferente o no existe en Origen
        }
    }
    else {
        Write-Host "   -> Omitida: [$nombreDB] no existe en el servidor destino." -ForegroundColor Gray
    }
}