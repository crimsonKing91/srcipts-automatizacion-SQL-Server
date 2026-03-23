# ==========================================
# CONFIGURACIÓN
# ==========================================
$ipOrigen       = "174.142.204.100"
$servidorDestino = "DAN_SAC\ENGINE_17"

# Evitar errores de SSL
Set-DbatoolsConfig -Name 'sql.connection.trustcert' -Value $true

# ==========================================
# 1. CREDENCIALES
# ==========================================
Clear-Host
Write-Host "--- SEGURIDAD ---" -ForegroundColor Cyan
$cred = Get-Credential -Message "Ingresa usuario (sa) y password del Servidor Remoto ($ipOrigen)"

# ==========================================
# 2. CONEXIÓN
# ==========================================
Write-Host "`n--- CONECTANDO ---" -ForegroundColor Cyan

try {
    $origen = Connect-DbaInstance -SqlInstance $ipOrigen -SqlCredential $cred -ErrorAction Stop
    Write-Host " [OK] Conectado al Origen ($ipOrigen)" -ForegroundColor Green
} catch {
    Write-Error " ERROR FATAL EN ORIGEN: $($_.Exception.Message)"
    return
}

try {
    $destino = Connect-DbaInstance -SqlInstance $servidorDestino -ErrorAction Stop
    Write-Host " [OK] Conectado al Destino ($servidorDestino)" -ForegroundColor Green
} catch {
    Write-Error " ERROR FATAL EN DESTINO: $($_.Exception.Message)"
    return
}

# ==========================================
# 3. COMPARACIÓN DE DATOS
# ==========================================
Write-Host "`n--- AUDITORÍA DE DATOS ---" -ForegroundColor Cyan

# Listar bases de datos en origen
$bds = Get-DbaDatabase -SqlInstance $origen -ExcludeSystem

foreach ($bd in $bds) {
    $nombre = $bd.Name
    
    # Verificar si existe en destino
    $existe = Get-DbaDatabase -SqlInstance $destino -Database $nombre -ErrorAction SilentlyContinue

    if ($existe) {
        Write-Host "Verificando: $nombre ..." -NoNewline

        try {
            # Obtener conteos
            $filasOrig = Get-DbaTableRowCount -SqlInstance $origen -Database $nombre
            $filasDest = Get-DbaTableRowCount -SqlInstance $destino -Database $nombre

            # Comparar
            $diffs = Compare-Object -ReferenceObject $filasOrig -DifferenceObject $filasDest -Property Table, RowCount

            if ($null -eq $diffs) {
                Write-Host " CORRECTO (Idénticas)" -ForegroundColor Green
            } else {
                Write-Host " ERROR - DIFERENCIAS ENCONTRADAS:" -ForegroundColor Red
                
                # --- AQUÍ ESTÁ LA CORRECCIÓN SIMPLIFICADA ---
                foreach ($d in $diffs) {
                    # Sacamos los valores a variables simples primero
                    $tbl = $d.Table
                    $cnt = $d.RowCount
                    
                    if ($d.SideIndicator -eq "<=") {
                        Write-Host "    -> En Origen: Tabla '$tbl' tiene $cnt filas." -ForegroundColor Yellow
                    } else {
                        Write-Host "    -> En Destino: Tabla '$tbl' tiene $cnt filas." -ForegroundColor Magenta
                    }
                }
                Write-Host "----------------------------------------"
            }
        }
        catch {
             Write-Host " ERROR LEYENDO TABLAS" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- FIN DEL PROCESO ---" -ForegroundColor Cyan