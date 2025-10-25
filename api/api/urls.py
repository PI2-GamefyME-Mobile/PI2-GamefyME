from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/usuarios/', include('usuarios.urls')),
    path('api/atividades/', include('atividades.urls')),
    path('api/desafios/', include('desafios.urls')),
    path('api/conquistas/', include('conquistas.urls')),
    path('api/notificacoes/', include('notificacoes.urls')),
]

# Servir arquivos de mídia em desenvolvimento
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)