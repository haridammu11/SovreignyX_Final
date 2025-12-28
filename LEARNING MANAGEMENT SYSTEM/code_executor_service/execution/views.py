import os
import subprocess
import tempfile
import json
import threading
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token

# Language configurations
LANGUAGE_CONFIGS = {
    'python': {
        'extension': '.py',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['python', file_path]
    },
    'javascript': {
        'extension': '.js',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['node', file_path]
    },
    'dart': {
        'extension': '.dart',
        'compile_cmd': None,
        'run_cmd': lambda file_path: ['dart', file_path]
    },
    'c': {
        'extension': '.c',
        'compile_cmd': lambda source_path, output_path: ['gcc', source_path, '-o', output_path],
        'run_cmd': lambda output_path: [output_path]
    },
    'cpp': {
        'extension': '.cpp',
        'compile_cmd': lambda source_path, output_path: ['g++', source_path, '-o', output_path],
        'run_cmd': lambda output_path: [output_path]
    },
    'java': {
        'extension': '.java',
        'compile_cmd': lambda source_path, _: ['javac', source_path],
        'run_cmd': lambda _: ['java', 'Main']
    }
}

def execute_with_timeout(cmd, cwd=None, timeout=30):
    """Execute a command with timeout"""
    try:
        process = subprocess.Popen(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Use threading timer to kill process if it exceeds timeout
        timer = threading.Timer(timeout, process.kill)
        try:
            timer.start()
            stdout, stderr = process.communicate()
        finally:
            timer.cancel()
            
        return process.returncode, stdout, stderr
    except Exception as e:
        return -1, '', str(e)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def authenticate_user(request):
    """Authenticate user and return token"""
    try:
        # For simplicity, we'll create a token for any valid request
        # In a real application, you'd verify the Supabase token here
        
        # Create or get user (using a dummy user for now)
        from django.contrib.auth.models import User
        user, created = User.objects.get_or_create(
            username='code_executor_user',
            defaults={'email': 'code@example.com'}
        )
        
        # Get or create token
        token, created = Token.objects.get_or_create(user=user)
        
        return JsonResponse({
            'token': token.key,
            'user_id': user.id
        })
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
        
        if not language or not code:
            return JsonResponse({'error': 'Language and code are required'}, status=400)
        
        if language not in LANGUAGE_CONFIGS:
            return JsonResponse({'error': f'Unsupported language: {language}'}, status=400)
        
        config = LANGUAGE_CONFIGS[language]
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            file_name = f"Main{config['extension']}"  # Main.java for Java
            file_path = os.path.join(temp_dir, file_name)
            
            # Write code to file
            with open(file_path, 'w') as f:
                f.write(code)
            
            # Compile if needed
            if config['compile_cmd']:
                try:
                    if language == 'java':
                        returncode, stdout, stderr = execute_with_timeout(
                            config['compile_cmd'](file_path, None),
                            cwd=temp_dir,
                            timeout=30
                        )
                    else:
                        output_name = 'a.out' if language in ['c', 'cpp'] else file_path.replace(config['extension'], '')
                        returncode, stdout, stderr = execute_with_timeout(
                            config['compile_cmd'](file_path, output_name),
                            cwd=temp_dir,
                            timeout=30
                        )
                    
                    if returncode != 0:
                        return JsonResponse({
                            'error': f'Compilation failed:\n{stderr}'
                        }, status=400)
                except subprocess.TimeoutExpired:
                    return JsonResponse({'error': 'Compilation timed out'}, status=400)
            
            # Execute code
            try:
                if language == 'java':
                    returncode, stdout, stderr = execute_with_timeout(
                        config['run_cmd'](None),
                        cwd=temp_dir,
                        timeout=30
                    )
                elif language in ['c', 'cpp']:
                    output_path = os.path.join(temp_dir, 'a.out')
                    returncode, stdout, stderr = execute_with_timeout(
                        config['run_cmd'](output_path),
                        cwd=temp_dir,
                        timeout=30
                    )
                else:
                    returncode, stdout, stderr = execute_with_timeout(
                        config['run_cmd'](file_path),
                        cwd=temp_dir,
                        timeout=30
                    )
                
                output = stdout
                if stderr:
                    output += f"\nErrors:\n{stderr}"
                    
                return JsonResponse({'output': output})
                
            except subprocess.TimeoutExpired:
                return JsonResponse({'error': 'Code execution timed out'}, status=400)
                
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_snippets(request):
    # This would return user's saved snippets
    return JsonResponse({'snippets': []})

@api_view(['POST'])
@permission_classes([AllowAny])
def save_snippet(request):
    # This would save a snippet
    return JsonResponse({'status': 'saved'})