# Crear password cifrada en un fichero
# "MiPassword" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\PATH\PasswdBackupS3Aws"

# Fecha y Hora
$fechaHoraActual = Get-Date -uformat "%d/%m/%Y - %H:%M:%S"
$fechaActual = Get-Date -uformat "%d-%m-%Y"

# Email
$usuarioEmail = "usuarioEmail@gmail.com" 
$passwdEmailFile = "C:\PATH\PasswdBackupS3Aws"
$asuntoEmail = "asuntoEmail"

# Paths
# Compatibles en sistemas Windows: "C:/pathLocal/datos/" o "C:\\pathLocal\\datos\\"
$pathLocalDatos = "C:\\pathLocal\\datos\\"
$pathRemotoBucketS3 = "s3://bucketS3/backup/"
$backupLog = "backup_$fechaActual.log"

# Obtener password cifrada del fichero y establecer credenciales
$secPasswdEmail = Get-Content -Path $passwdEmailFile | ConvertTo-SecureString
$credencialesEmail = New-Object System.Management.Automation.PSCredential ($usuarioEmail, $secPasswdEmail)

# Comprobar si existen ficheros de log pasados del backup
if (Test-Path "*backup*.log") { 
    Remove-Item -Path "*backup*.log" -Recurse -Force
    }

# Mostrar fecha y hora del comienzo del proceso de backup al princpio del log
# $tiempoComienza será necesaria para calcular el tiempo transcurrido de backup
$tiempoComienza = (Get-Date)
Write-Output "Backup comienza: $fechaHoraActual" > $backupLog
Write-Output "# # # # # # # # # # # # # # # # # # # #`n" >> $backupLog

# Sincronizar datos locales a bucket S3 de AWS
aws s3 sync $pathLocalDatos $pathRemotoBucketS3 --sse AES256 --delete --include "*" >> $backupLog

Write-Output "# # # # # # # # # # # # # # # # # # # #" >> $backupLog
# Mostrar fecha y hora de la finalización del proceso de backup en el log y $tiempoFinaliza calculará el tiempo transcurrido
# Resetear la variable $fechaHoraActual para obtener la hora actual hasta este momento del proceso de backup
$tiempoFinaliza = (Get-Date)
$tiempoTranscurrido = $($tiempoFinaliza-$tiempoComienza).ToString().Substring(0,8)
$fechaHoraActual = Get-Date -uformat "%d/%m/%Y - %H:%M:%S"
Write-Output "Backup finaliza: $fechaHoraActual`n" >> $backupLog
Write-Output "Tiempo total transcurrido: $tiempoTranscurrido" >> $backupLog

# Body Email
$cuerpoEmail = [System.Io.File]::ReadAllText($backupLog)

# Alternativas usando Get-Content
# $cuerpoEmail = Get-Content -Path "$backupLog" | Out-String
# $cuerpoEmail = Get-Content -Path "$backupLog" -Raw

# Envío del fichero log adjunto vía Email usando Gmail.
Send-MailMessage -From $usuarioEmail -To $usuarioEmail -Subject "$asuntoEmail - $fechaHoraActual" -Body "$cuerpoEmail" -Attachments "$backupLog" -SmtpServer smtp.gmail.com -UseSsl -Credential $credencialesEmail

# Liberar los valores de passwords de los objetos SecureString almacenados que hacen referencia en un puntero de memoria (esta memoria se encuentra en una zona distinta donde no accede el recolector de basura)
$ptr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPasswdEmail)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr1)
$ptr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credencialesEmail)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr2)

exit
