from django.urls import path
from . import views

urlpatterns = [
    path('execute/', views.execute_code, name='execute_code'),
    path('snippets/', views.get_user_snippets, name='get_user_snippets'),
    path('snippets/save/', views.save_snippet, name='save_snippet'),
    path('save-snippet/', views.save_snippet, name='save_snippet_alt'),
    path('auth/', views.authenticate_user, name='authenticate_user'),
]