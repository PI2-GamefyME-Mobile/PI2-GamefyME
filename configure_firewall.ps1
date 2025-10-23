# Script para configurar o Firewall do Windows para o Django Backend
# Execute como Administrador

Write-Host "Configurando Firewall para Django Backend na porta 8000..." -ForegroundColor Green

# Remove regra antiga se existir
try {
    Remove-NetFirewallRule -DisplayName "Django Backend Port 8000" -ErrorAction SilentlyContinue
    Write-Host "Regra antiga removida (se existia)" -ForegroundColor Yellow
} catch {
    # Ignora se não existir
}

# Cria nova regra
try {
    New-NetFirewallRule `
        -DisplayName "Django Backend Port 8000" `
        -Direction Inbound `
        -LocalPort 8000 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private,Public `
        -Enabled True
    
    Write-Host "✅ Regra de firewall criada com sucesso!" -ForegroundColor Green
    Write-Host "A porta 8000 agora aceita conexões da rede local" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao criar regra: $_" -ForegroundColor Red
    Write-Host "Execute este script como Administrador!" -ForegroundColor Red
}

# Verifica a regra
Write-Host "`nVerificando a regra criada:" -ForegroundColor Cyan
Get-NetFirewallRule -DisplayName "Django Backend Port 8000" | Format-Table -AutoSize

Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
