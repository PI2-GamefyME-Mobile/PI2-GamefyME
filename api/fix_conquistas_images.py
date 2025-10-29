"""
Script para corrigir os caminhos das imagens de conquistas existentes.
Execute com: python manage.py shell < fix_conquistas_images.py
Ou: python fix_conquistas_images.py (se configurar DJANGO_SETTINGS_MODULE)
"""

import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from conquistas.models import Conquista  # noqa: E402
import shutil  # noqa: E402

def fix_image_paths():
    """Corrige os caminhos das imagens e move arquivos se necessário."""
    
    conquistas = Conquista.objects.all()
    print(f"Encontradas {conquistas.count()} conquistas")
    
    # Criar diretório media/conquistas se não existir
    media_conquistas = os.path.join('media', 'conquistas')
    os.makedirs(media_conquistas, exist_ok=True)
    print(f"Diretório {media_conquistas} verificado/criado")
    
    # Verificar se existe pasta de assets do Flutter
    flutter_assets = os.path.join('..', 'gamefymobile', 'assets', 'conquistas')
    has_flutter_assets = os.path.exists(flutter_assets)
    
    updated_count = 0
    copied_count = 0
    
    for conquista in conquistas:
        old_path = str(conquista.nmimagem) if conquista.nmimagem else ''
        
        if not old_path:
            print(f"  {conquista.nmconquista}: SEM IMAGEM")
            continue
            
        # Se já está no formato correto (conquistas/arquivo.png), pular
        if old_path.startswith('conquistas/'):
            print(f"  {conquista.nmconquista}: Já está correto ({old_path})")
            continue
        
        # Se é só o nome do arquivo, adicionar o prefixo conquistas/
        filename = os.path.basename(old_path)
        new_path = f'conquistas/{filename}'
        
        # Tentar copiar a imagem se existir nos assets do Flutter
        if has_flutter_assets:
            source_file = os.path.join(flutter_assets, filename)
            dest_file = os.path.join(media_conquistas, filename)
            
            if os.path.exists(source_file) and not os.path.exists(dest_file):
                try:
                    shutil.copy2(source_file, dest_file)
                    print(f"  ✓ Copiado: {filename} de assets para media")
                    copied_count += 1
                except Exception as e:
                    print(f"  ✗ Erro ao copiar {filename}: {e}")
        
        # Atualizar o caminho no banco
        conquista.nmimagem = new_path
        conquista.save(update_fields=['nmimagem'])
        print(f"  ✓ Atualizado: {conquista.nmconquista}")
        print(f"    De: {old_path}")
        print(f"    Para: {new_path}")
        updated_count += 1
    
    print("\n=== Resumo ===")
    print(f"Conquistas atualizadas: {updated_count}")
    print(f"Arquivos copiados: {copied_count}")
    print("\nScript concluído!")

if __name__ == '__main__':
    fix_image_paths()
