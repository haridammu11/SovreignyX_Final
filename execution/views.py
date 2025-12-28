import os
import subprocess
import tempfile
import json
import logging
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.shortcuts import render
from django.core.mail import send_mail
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
User = get_user_model()
# Assuming .models exists and EmailLog is defined there
from django.utils import timezone
from datetime import timedelta
from .models import EmailLog, ProctorSession, ProctorEvent

# Configure logging
logger = logging.getLogger(__name__)

# Expanded Language Configurations
LANGUAGE_CONFIGS = {
    'python': {
        'extension': '.py',
        'run_cmd': lambda path, _: ['python', path]
    },
    'javascript': {
        'extension': '.js',
        'run_cmd': lambda path, _: ['node', path]
    },
    'dart': {
        'extension': '.dart',
        'run_cmd': lambda path, _: ['dart', path]
    },
    'c': {
        'extension': '.c',
        'compile_cmd': lambda src, out: ['gcc', '-O2', src, '-o', out],
        'run_cmd': lambda _, out: [out]
    },
    'cpp': {
        'extension': '.cpp',
        'compile_cmd': lambda src, out: ['g++', '-O2', src, '-o', out],
        'run_cmd': lambda _, out: [out]
    },
    'java': {
        'extension': '.java',
        'compile_cmd': lambda src, _: ['javac', src],
        'run_cmd': lambda _, __: ['java', 'Main']  # Expects public class Main
    },
    'go': {
        'extension': '.go',
        'run_cmd': lambda path, _: ['go', 'run', path]
    },
    'rust': {
        'extension': '.rs',
        'compile_cmd': lambda src, out: ['rustc', '-O', src, '-o', out],
        'run_cmd': lambda _, out: [out]
    },
    'ruby': {
        'extension': '.rb',
        'run_cmd': lambda path, _: ['ruby', path]
    },
    'php': {
        'extension': '.php',
        'run_cmd': lambda path, _: ['php', path]
    }
}

def run_process(cmd, cwd, input_data=None, timeout=10):
    """
    Optimized process execution using subprocess.run
    """
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            input=input_data,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, '', 'Execution timed out'
    except Exception as e:
        return -1, '', str(e)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def authenticate_user(request):
    try:
        user, _ = User.objects.get_or_create(
            username='code_executor_user',
            defaults={'email': 'code@example.com'}
        )
        token, _ = Token.objects.get_or_create(user=user)
        return JsonResponse({'token': token.key, 'user_id': user.id})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def execute_code(request):
    try:
        data = json.loads(request.body)
        language = data.get('language')
        code = data.get('code')
        stdin_input = data.get('input', '')  # Support for stdin inputs

        if not language or not code:
            return JsonResponse({'error': 'Language and code are required'}, status=400)
        
        config = LANGUAGE_CONFIGS.get(language.lower())
        if not config:
            return JsonResponse({'error': f'Unsupported language: {language}'}, status=400)

        # Use temp directory for isolation
        with tempfile.TemporaryDirectory() as temp_dir:
            file_name = f"Main{config['extension']}"
            file_path = os.path.join(temp_dir, file_name)
            
            # Write code to file
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(code)

            # Compilation phase (if required)
            output_binary = os.path.join(temp_dir, 'a.out') if language not in ['java', 'python', 'javascript', 'dart', 'ruby', 'php', 'go'] else None
            
            if 'compile_cmd' in config:
                compile_cmd = config['compile_cmd'](file_path, output_binary)
                ret, stdout, stderr = run_process(compile_cmd, temp_dir, timeout=15)
                
                if ret != 0:
                    return JsonResponse({'output': '', 'error': f"Compilation Error:\n{stderr}\n{stdout}"})

            # Execution phase
            run_cmd_func = config['run_cmd']
            if language == 'java':
                 # Java specific: run_cmd doesn't use file path directly in the list usually, but needs cwd
                 exec_cmd = run_cmd_func(file_path, output_binary)
            else:
                 exec_cmd = run_cmd_func(file_path, output_binary)

            # Execute with strict timeout (adjustable) and optimization
            ret, stdout, stderr = run_process(exec_cmd, temp_dir, input_data=stdin_input, timeout=10)
            
            response_data = {
                'output': stdout,
                'error': stderr if ret != 0 else None,
                'statusCode': ret
            }
            return JsonResponse(response_data)

    except Exception as e:
        logger.error(f"Execution failed: {e}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_snippets(request):
    return JsonResponse({'snippets': []})

@api_view(['POST'])
@permission_classes([AllowAny])
def save_snippet(request):
    return JsonResponse({'status': 'saved'})

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def generate_portfolio(request):
    """
    Generates a single-page HTML portfolio for the user based on provided details using Groq API.
    Enhanced with comprehensive error handling for production deployment.
    """
    try:
        # Import requests - catch if not installed
        try:
            import requests
        except ImportError as e:
            logger.error(f"requests library not installed: {e}")
            return JsonResponse({
                'success': False,
                'error': 'Server configuration error: requests library missing'
            }, status=500)
        
        # Parse request body
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return JsonResponse({
                'success': False,
                'error': f'Invalid JSON: {str(e)}'
            }, status=400)
        
        # User Details with safe defaults
        name = data.get('name', 'User')
        bio = data.get('bio', '')
        skills = data.get('skills', '')
        interests = data.get('interests', '')
        projects = data.get('projects', '')
        social_links = data.get('social_links', {})
        certificates = data.get('certificates', '')

        # --- DEBUG LOGGING ---
        logger.info(f"--- PORTFOLIO GENERATION REQUEST ---")
        logger.info(f"User: {name}")
        logger.info(f"Social Links: {social_links}")
        print(f"[PORTFOLIO] Request for user: {name}")
        # ---------------------

        # GitHub API integration (optional - don't fail if it errors)
        if 'github' in social_links and social_links.get('github'):
            try:
                github_url = social_links['github']
                username_part = github_url.rstrip('/').split('/')[-1]
                
                logger.info(f"Fetching GitHub repos for: {username_part}")
                gh_response = requests.get(
                    f"https://api.github.com/users/{username_part}/repos?sort=updated&per_page=5",
                    timeout=5
                )
                
                if gh_response.status_code == 200:
                    repos = gh_response.json()
                    fetched_projects = "\n".join([
                        f"- Name: {r.get('name')} | Lang: {r.get('language')} | Stars: {r.get('stargazers_count')} | Link: {r.get('html_url')} | Desc: {r.get('description')}" 
                        for r in repos if not r.get('fork')
                    ])
                    projects += f"\n\n[Real GitHub Data Fetched via API]:\n{fetched_projects}"
                    logger.info(f"GitHub data fetched successfully")
                else:
                    logger.warning(f"GitHub API returned {gh_response.status_code}")
            except Exception as gh_e:
                logger.warning(f"GitHub fetch failed (non-critical): {gh_e}")
                # Continue without GitHub data

        # Filter empty social links
        social_links = {k: v for k, v in social_links.items() if v and str(v).strip()}
        
        # Construct AI Prompt
        prompt = f"""
        You are an expert web developer and designer. Generate a COMPLETE, single-page HTML Portfolio Website for "{name}".

        Input Data:
        - Bio: {bio}
        - Skills: {skills}
        - Interests: {interests}
        - Projects: {projects}
        - Certificates: {certificates}
        - Social Links: {json.dumps(social_links)}

        Instructions:
        1. **Social Links**: 
           - If 'linkedin' is present, create a 'Connect on LinkedIn' button
           - If 'github' is present, create a 'GitHub Profile' button
           - Use styled buttons with visible labels
        
        2. **Projects**: If "Link: ..." is present, create clickable buttons
        
        3. **Design**: Modern, responsive, dark theme with internal CSS
        
        4. **Output**: Return ONLY raw HTML starting with <!DOCTYPE html>
           Do NOT include markdown code fences.
        """

        # Groq API Call with error handling and retry logic
        max_retries = 3
        retry_delay = 2  # seconds
        
        for attempt in range(max_retries):
            try:
                api_key = 'YOUR_GROQ_API_KEY'
                url = 'https://api.groq.com/openai/v1/chat/completions'
                
                logger.info(f"Calling Groq API (attempt {attempt + 1}/{max_retries})...")
                
                response = requests.post(
                    url,
                    headers={
                        'Authorization': f'Bearer {api_key}',
                        'Content-Type': 'application/json',
                    },
                    json={
                        'model': 'llama-3.3-70b-versatile',
                        'messages': [
                            {'role': 'system', 'content': 'You are a professional web designer.'},
                            {'role': 'user', 'content': prompt}
                        ],
                        'temperature': 0.7,
                    },
                    timeout=60
                )
                
                logger.info(f"Groq API response status: {response.status_code}")
                
                # If successful, break out of retry loop
                if response.status_code == 200:
                    break
                    
                # If rate limited, wait and retry
                if response.status_code == 429:
                    if attempt < max_retries - 1:
                        wait_time = retry_delay * (2 ** attempt)  # Exponential backoff
                        logger.warning(f"Rate limited. Waiting {wait_time}s before retry...")
                        import time
                        time.sleep(wait_time)
                        continue
                    else:
                        logger.error("Rate limit exceeded, max retries reached")
                        return JsonResponse({
                            'success': False,
                            'error': 'AI service is busy. Please try again in a few moments.'
                        }, status=429)
                
                # For other errors, log and continue to error handling
                logger.error(f"Groq API error: {response.status_code} - {response.text[:200]}")
                
            except requests.exceptions.Timeout:
                logger.error(f"Groq API timeout (attempt {attempt + 1})")
                if attempt < max_retries - 1:
                    logger.info(f"Retrying after timeout...")
                    continue
                else:
                    return JsonResponse({
                        'success': False,
                        'error': 'AI service timeout - please try again'
                    }, status=504)
                    
            except requests.exceptions.RequestException as e:
                logger.error(f"Groq API request failed (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    logger.info(f"Retrying after connection error...")
                    import time
                    time.sleep(retry_delay)
                    continue
                else:
                    return JsonResponse({
                        'success': False,
                        'error': f'AI service connection error. Please check your internet connection.'
                    }, status=503)

        if response.status_code == 200:
            try:
                content = response.json()['choices'][0]['message']['content']
                html_content = content.replace('```html', '').replace('```', '').strip()
                
                logger.info("HTML content generated successfully")
                
            except (KeyError, IndexError) as e:
                logger.error(f"Failed to parse Groq response: {e}")
                return JsonResponse({
                    'success': False,
                    'error': 'Invalid AI response format'
                }, status=500)
            
            # Save to file with error handling
            try:
                # Ensure directories exist
                portfolios_dir = os.path.join(settings.MEDIA_ROOT, 'portfolios')
                os.makedirs(portfolios_dir, exist_ok=True)
                
                filename = f"portfolio_{uuid.uuid4().hex[:8]}.html"
                filepath = os.path.join(portfolios_dir, filename)
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(html_content)
                
                logger.info(f"Portfolio saved to: {filepath}")
                
            except PermissionError as e:
                logger.error(f"Permission denied writing file: {e}")
                return JsonResponse({
                    'success': False,
                    'error': 'Server permission error - contact administrator'
                }, status=500)
            except Exception as e:
                logger.error(f"File write error: {e}")
                return JsonResponse({
                    'success': False,
                    'error': f'File save error: {str(e)}'
                }, status=500)
            
            # Construct URL
            try:
                file_url = request.build_absolute_uri(settings.MEDIA_URL + 'portfolios/' + filename)
                logger.info(f"Generated URL: {file_url}")
                
                return JsonResponse({
                    'success': True,
                    'url': file_url
                })
                
            except Exception as e:
                logger.error(f"URL construction error: {e}")
                return JsonResponse({
                    'success': False,
                    'error': f'URL generation error: {str(e)}'
                }, status=500)
        else:
            error_msg = f"Groq API Error: {response.status_code}"
            try:
                error_detail = response.text
                logger.error(f"{error_msg} - {error_detail}")
            except:
                logger.error(error_msg)
            
            return JsonResponse({
                'success': False,
                'error': f'AI service returned error: {response.status_code}'
            }, status=500)

    except Exception as e:
        # Catch-all for any unexpected errors
        logger.error(f"Portfolio Generation Exception: {e}")
        import traceback
        traceback.print_exc()
        
@csrf_exempt
def send_email_notification(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            recipient = data.get('recipient')
            subject = data.get('subject')
            body = data.get('body')
            
            if not recipient or not subject or not body:
                return JsonResponse({'error': 'Missing required fields'}, status=400)

            # Log the request
            email_log = EmailLog.objects.create(
                recipient=recipient,
                subject=subject,
                body=body,
                status='PENDING'
            )

            try:
                # Use Django's send_mail which uses SMTP settings from settings.py
                send_mail(
                    subject,
                    "", # Plain text body (optional if html_message provided)
                    settings.EMAIL_HOST_USER, # Sender
                    [recipient],
                    html_message=body,
                    fail_silently=False,
                )
                email_log.status = 'SENT'
                email_log.save()
                return JsonResponse({'message': 'Email sent successfully', 'log_id': email_log.id})
            except Exception as e:
                email_log.status = 'FAILED'
                email_log.error_message = str(e)
                email_log.save()
                return JsonResponse({'error': str(e), 'log_id': email_log.id}, status=500)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
    
    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def start_proctor_session(request):
    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        contest_id = data.get('contest_id')
        
        if not user_id or not contest_id:
            return JsonResponse({'error': 'user_id and contest_id are required'}, status=400)
            
        # Deactivate any existing active sessions for this user/contest to prevent duplicates
        ProctorSession.objects.filter(user_id=user_id, contest_id=contest_id, is_active=True).update(is_active=False)
            
        session = ProctorSession.objects.create(
            user_id=user_id,
            contest_id=contest_id
        )
        return JsonResponse({'session_id': session.id, 'status': 'ACTIVE'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def record_proctor_event(request):
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
        event_type = data.get('event_type')
        description = data.get('description', '')
        image_data = data.get('image_data', '')
        code_content = data.get('code_content', '')
        
        if not session_id or not event_type:
            return JsonResponse({'error': 'session_id and event_type are required'}, status=400)
            
        session = ProctorSession.objects.get(id=session_id)
        
        # Simple AI simulation for Anomaly Detection (if type is FRAME)
        is_suspicious = False
        if event_type == 'FRAME' and image_data:
             # In a real app, send image_data to a Vision AI (like OpenAI/Groq Vision)
             # Here we simulate some basic flags
             if "suspicious" in description.lower():
                 is_suspicious = True
        elif event_type == 'TAB_SWITCH':
             is_suspicious = True
             
        event = ProctorEvent.objects.create(
            session=session,
            event_type=event_type,
            description=description,
            image_data=image_data,
            code_content=code_content,
            is_suspicious=is_suspicious
        )
        
        # Update session heartbeat
        session.save() 
        
        return JsonResponse({'event_id': event.id, 'is_suspicious': is_suspicious})
    except ProctorSession.DoesNotExist:
        return JsonResponse({'error': 'Session not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def update_live_stream(request):
    """
    Highly optimized for 200ms-500ms updates. 
    Updates the session's current_frame without creating a logged event.
    """
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
        image_data = data.get('image_data')
        
        if not session_id or not image_data:
            return JsonResponse({'error': 'session_id and image_data required'}, status=400)
            
        # Update session directly (fast)
        # We use .update() to avoid pulling the whole object if we just want to push data
        ProctorSession.objects.filter(id=session_id).update(live_frame=image_data)
        
        return JsonResponse({'status': 'UPDATED'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_proctor_sessions(request):
    try:
        # Only show sessions that are marked active AND have had activity in the last 5 minutes
        # This prevents "ghost" sessions from cluttering the command center
        heartbeat_threshold = timezone.now() - timedelta(minutes=5)
        sessions = ProctorSession.objects.filter(
            is_active=True, 
            updated_at__gte=heartbeat_threshold
        )
        data = []
        for s in sessions:
            # Get the absolute latest event for status/description
            latest_any_event = s.events.order_by('-timestamp').first()
            # Specifically find the latest FRAME event for the camera feed
            latest_frame_event = s.events.filter(event_type='FRAME').order_by('-timestamp').first()
            # Specifically find the latest CODE event
            latest_code_event = s.events.exclude(code_content__exact='').exclude(code_content__isnull=True).order_by('-timestamp').first()
            
            data.append({
                'id': s.id,
                'user_id': s.user_id,
                'contest_id': s.contest_id,
                'start_time': s.start_time.isoformat() if s.start_time else None,
                'latest_frame': s.live_frame if s.live_frame else (latest_frame_event.image_data if latest_frame_event else None),
                'latest_code': latest_code_event.code_content if latest_code_event else '',
                'latest_description': latest_any_event.description if latest_any_event else 'Monitoring active',
                'is_flagged': s.events.filter(is_suspicious=True).exists(),
                'last_seen': latest_any_event.timestamp.isoformat() if latest_any_event else s.start_time.isoformat()
            })
        return JsonResponse({'sessions': data})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def end_proctor_session(request):
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
        if not session_id:
            return JsonResponse({'error': 'session_id is required'}, status=400)
            
        session = ProctorSession.objects.get(id=session_id)
        session.is_active = False
        session.save()
        return JsonResponse({'status': 'TERMINATED'})
    except ProctorSession.DoesNotExist:
        return JsonResponse({'error': 'Session not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_contest_leaderboard(request, contest_id):
    try:
        # Since we use Supabase for scores, this would ideally fetch from Supabase.
        # However, for simplicity and persistence in the command center, 
        # let's assume we fetch from our local DB if we had synced it.
        # But wait, we are using contest_participants in Supabase directly.
        # A better approach is to fetch this directly in the Flutter app from Supabase.
        # I'll keep this as a dummy or proxy for now if needed.
        return JsonResponse({'message': 'Fetch directly from Supabase for real-time leaderboard'}, status=200)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_session_snapshots(request, session_id):
    try:
        events = ProctorEvent.objects.filter(
            session_id=session_id, 
            event_type='FRAME'
        ).order_by('-timestamp')
        
        data = []
        for e in events:
            # If the image_data is stored as a full base64 string including prefix, we keep it.
            # If not, we ensure it is correctly formatted for the frontend.
            data.append({
                'id': e.id,
                'timestamp': e.timestamp.isoformat(),
                'image_data': e.image_data,
                'is_suspicious': e.is_suspicious,
                'description': e.description
            })
        return JsonResponse({'snapshots': data})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
