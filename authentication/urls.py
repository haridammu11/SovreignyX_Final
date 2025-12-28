from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register, name='register'),
    path('login/', views.login_view, name='login'),
    path('google-login/', views.google_login, name='google_login'),
    path('google-login-direct/', views.google_login_direct, name='google_login_direct'),
    path('logout/', views.logout_view, name='logout'),
    path('profile/', views.user_profile, name='user_profile'),
    path('profile/detail/', views.UserProfileDetailView.as_view(), name='user_profile_detail'),
    path('dashboard/', views.dashboard_data, name='dashboard_data'),
    path('test-auth/', views.test_auth, name='test_auth'),
]
