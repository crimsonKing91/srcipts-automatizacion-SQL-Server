# ==========================================
# CONFIGURACIÓN
# ==========================================
$ipOrigen       = "174.142.204.100"
$servidorDestino = "DAN_SAC\ENGINE_17"

Set-DbatoolsConfig -Name 'sql.connection.trustcert' -Value $true

# 1. CREDENCIALES
Clear-Host
Write-Host "--- SEGURIDAD ---" -ForegroundColor Cyan
$cred = Get-Credential -Message "Usuario (sa) y Password del Servidor Remoto ($ipOrigen)"

# 2. CONEXIÓN
Write-Host "`n--- CONECTANDO ---" -ForegroundColor Cyan
try {
    $origen = Connect-DbaInstance -SqlInstance $ipOrigen -SqlCredential $cred -ErrorAction Stop
    Write-Host " [OK] Conectado al Origen" -ForegroundColor Green
} catch { Write-Error "ERROR ORIGEN: $($_.Exception.Message)"; return }

try {
    $destino = Connect-DbaInstance -SqlInstance $servidorDestino -ErrorAction Stop
    Write-Host " [OK] Conectado al Destino" -ForegroundColor Green
} catch { Write-Error "ERROR DESTINO: $($_.Exception.Message)"; return }

# 3. COMPARACIÓN
Write-Host "`n--- AUDITORÍA DE DATOS ---" -ForegroundColor Cyan

# Listar bases de datos
$bds = Get-DbaDatabase -SqlInstance $origen -ExcludeSystem

foreach ($bd in $bds) {
    $nombre = $bd.Name
    
    # Verificar si existe en destino
    $existe = Get-DbaDatabase -SqlInstance $destino -Database $nombre -ErrorAction SilentlyContinue

    if ($existe) {
        Write-Host "Verificando: $nombre ..." -NoNewline

        try {
            # === CORRECCIÓN AQUÍ: Usamos Get-DbaDbTable ===
            # Obtenemos tablas y seleccionamos solo Nombre y Conteo
            $tablasOrig = Get-DbaDbTable -SqlInstance $origen -Database $nombre | Select-Object Name, RowCount
            $tablasDest = Get-DbaDbTable -SqlInstance $destino -Database $nombre | Select-Object Name, RowCount

            # Comparamos
            $diffs = Compare-Object -ReferenceObject $tablasOrig -DifferenceObject $tablasDest -Property Name, RowCount

            if ($null -eq $diffs) {
                Write-Host " CORRECTO" -ForegroundColor Green
            } else {
                Write-Host " DIFERENCIAS:" -ForegroundColor Red
                
                foreach ($d in $diffs) {
                    $tbl = $d.Name
                    $cnt = $d.RowCount
                    
                    if ($d.SideIndicator -eq "<=") {
                        Write-Host "    -> Origen: Tabla '$tbl' tiene $cnt filas." -ForegroundColor Yellow
                    } else {
                        Write-Host "    -> Destino: Tabla '$tbl' tiene $cnt filas." -ForegroundColor Magenta
                    }
                }
                Write-Host "----------------------------------------"
            }
        }
        catch {
             Write-Host " ERROR LEYENDO: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}