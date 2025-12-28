from django.urls import path
from . import views
from . import web_generator_views
from . import prompt_generator_views
from . import backend_generator_views

urlpatterns = [
    path('execute/', views.execute_code, name='execute_code'),
    path('snippets/', views.get_user_snippets, name='get_user_snippets'),
    path('snippets/save/', views.save_snippet, name='save_snippet'),
    path('save-snippet/', views.save_snippet, name='save_snippet_alt'),
    path('auth/', views.authenticate_user, name='authenticate_user'),
    path('generate-portfolio/', views.generate_portfolio, name='generate_portfolio'),
    
    # Web Page Generation Endpoints
    path('create-page/', web_generator_views.create_page, name='create_page'),
    path('create-page-from-prompt/', prompt_generator_views.create_page_from_prompt, name='create_page_from_prompt'),
    path('create-page-with-backend/', backend_generator_views.create_page_with_backend, name='create_page_with_backend'),
    path('page-url/<str:project_id>/', web_generator_views.get_page_url, name='get_page_url'),
    path('list-projects/', web_generator_views.list_projects, name='list_projects'),
    path('delete-page/<str:project_id>/', web_generator_views.delete_page, name='delete_page'),
    path('modify-page/', prompt_generator_views.modify_page, name='modify_page'),
    path('send-email/', views.send_email_notification, name='send_email'),
    
    # Proctoring Endpoints
    path('start-proctor-session/', views.start_proctor_session, name='start_proctor_session'),
    path('record-proctor-event/', views.record_proctor_event, name='record_proctor_event'),
    path('update-live-stream/', views.update_live_stream, name='update_live_stream'),
    path('list-proctor-sessions/', views.list_proctor_sessions, name='list_proctor_sessions'),
    path('end-proctor-session/', views.end_proctor_session, name='end_proctor_session'),
    path('contest-leaderboard/<str:contest_id>/', views.get_contest_leaderboard, name='get_contest_leaderboard'),
    path('get-session-snapshots/<int:session_id>/', views.get_session_snapshots, name='get_session_snapshots'),
]