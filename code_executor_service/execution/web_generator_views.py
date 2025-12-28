import os
import json
import uuid
import logging
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from django.conf import settings

logger = logging.getLogger(__name__)

# JSON storage path for project metadata
PROJECTS_JSON_PATH = os.path.join(settings.BASE_DIR, 'generated_projects.json')

def load_projects():
    """Load projects from JSON file"""
    if os.path.exists(PROJECTS_JSON_PATH):
        with open(PROJECTS_JSON_PATH, 'r') as f:
            return json.load(f)
    return {}

def save_projects(projects):
    """Save projects to JSON file"""
    with open(PROJECTS_JSON_PATH, 'w') as f:
        json.dump(projects, f, indent=2)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def create_page(request):
    """
    Generate a complete web page using AI based on requirements.
    
    Expected Input:
    {
        "page_type": "registration|login|landing|dashboard",
        "fields": [
            {"name": "email", "type": "email", "required": true, "label": "Email Address"},
            {"name": "password", "type": "password", "required": true, "label": "Password"}
        ],
        "theme": "dark|light|glassmorphism",
        "validation_rules": {
            "email": "email_format",
            "password": "min_8_chars"
        },
        "submit_endpoint": "/api/register/",
        "project_name": "My Registration Page"
    }
    """
    try:
        import requests
        data = json.loads(request.body)
        
        # Extract parameters
        page_type = data.get('page_type', 'registration')
        fields = data.get('fields', [])
        theme = data.get('theme', 'dark')
        validation_rules = data.get('validation_rules', {})
        submit_endpoint = data.get('submit_endpoint', '/api/submit/')
        project_name = data.get('project_name', f'{page_type.capitalize()} Page')
        
        # Generate unique project ID
        project_id = str(uuid.uuid4())
        
        # Debug logging
        print(f"--- WEB PAGE GENERATION REQUEST ---")
        print(f"Project: {project_name}")
        print(f"Type: {page_type}")
        print(f"Fields: {fields}")
        print(f"Theme: {theme}")
        
        # Construct AI prompt for web page generation
        prompt = f"""
        You are an expert full-stack web developer. Generate a COMPLETE, production-ready, single-page web application.

        **Project Requirements:**
        - Page Type: {page_type}
        - Project Name: {project_name}
        - Theme: {theme}
        - Fields: {json.dumps(fields, indent=2)}
        - Validation Rules: {json.dumps(validation_rules, indent=2)}
        - Submit Endpoint: {submit_endpoint}

        **Technical Requirements:**
        1. **HTML Structure:**
           - Complete <!DOCTYPE html> document
           - Semantic HTML5 elements
           - Proper meta tags for responsiveness
           - Form with all specified fields
        
        2. **Styling (Internal CSS):**
           - Modern {theme} theme design
           - Fully responsive (mobile-first)
           - Beautiful gradients and animations
           - Professional form styling with focus states
           - Loading states and error messages
           - Use Google Fonts (Inter or Roboto)
        
        3. **Advanced JavaScript Functionality:**
           - **Modern Syntax:** Use ES6+ features (arrow functions, const/let, template literals).
           - **Enhanced Interactivity:**
             * Real-time validation with visual cues (green checkboxes/red borders).
             * Dynamic DOM updates (e.g., adding success messages without alert boxes).
             * Interactive elements: Toggle password visibility, custom checkbox/radio styling.
           - **AJAX Handling:**
             * Use `fetch` API for asynchronous submission to `{submit_endpoint}`.
             * Handle all HTTP states (200, 400, 500).
             * **Loading State:** Disable buttons and show a sleek spinner or progress bar.
             * **Response Handling:** Parse JSON responses and display data or errors on the page dynamically.

        4. **Form Fields:**
           Generate appropriate HTML inputs for each field:
           {chr(10).join([f"   - {field['name']}: {field['type']} ({'required' if field.get('required') else 'optional'})" for field in fields])}

        5. **Validation Rules:**
           Implement these validations in JavaScript:
           {json.dumps(validation_rules, indent=2)}

        6. **Design Guidelines (Premium Aesthetics):**
           - **Visual Style:** High-end, polished design suited for {theme} theme.
           - **Effects:** Glassmorphism (blur), subtle drop shadows, smooth gradients.
           - **Typography:** Use modern font stacks (Inter, system-ui), varying weights (400, 500, 600, 700).
           - **Animations:**
             * Entry animations for the card/form (fade-up).
             * Hover effects on all interactive elements.
             * Ripple effects on buttons.
           - **Layout:** Flexbox and Grid for perfect alignment. Center the main content if it's a login/registration page.
        
        **Output Format:**
        Return ONLY the complete HTML code starting with <!DOCTYPE html>.
        Do NOT include markdown code fences like ```html.
        The page must be fully self-contained (no external files).
        """
        
        # Call Groq API
        api_key = 'YOUR_GROQ_API_KEY'
        url = 'https://api.groq.com/openai/v1/chat/completions'
        
        response = requests.post(
            url,
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={
                'model': 'llama-3.3-70b-versatile',
                'messages': [
                    {'role': 'system', 'content': 'You are an expert full-stack web developer specializing in modern, responsive web applications.'},
                    {'role': 'user', 'content': prompt}
                ],
                'temperature': 0.7,
                'max_tokens': 8000,
            },
            timeout=60
        )
        
        if response.status_code == 200:
            content = response.json()['choices'][0]['message']['content']
            # Clean markdown if present
            html_content = content.replace('```html', '').replace('```', '').strip()
            
            # Save HTML to file
            pages_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages')
            os.makedirs(pages_dir, exist_ok=True)
            
            filename = f"page_{project_id}.html"
            filepath = os.path.join(pages_dir, filename)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            # Construct public URL
            web_url = request.build_absolute_uri(settings.MEDIA_URL + 'generated_pages/' + filename)
            
            # Create project metadata (backend only - NO UI code)
            project_metadata = {
                "project_id": project_id,
                "project_name": project_name,
                "page_type": page_type,
                "api_endpoints": {
                    "submit": submit_endpoint,
                    "validate": f"/api/validate/{project_id}/"
                },
                "fields": fields,
                "validation_rules": validation_rules,
                "web_url": web_url,
                "theme": theme,
                "created_at": str(uuid.uuid1().time)
            }
            
            # Save to JSON storage
            projects = load_projects()
            projects[project_id] = project_metadata
            save_projects(projects)
            
            print(f"Generated Page URL: {web_url}")
            print(f"Project saved with ID: {project_id}")
            
            return JsonResponse({
                'success': True,
                'project_id': project_id,
                'web_url': web_url,
                'metadata': project_metadata
            })
        else:
            print(f"Groq API Error: {response.status_code} - {response.text}")
            return JsonResponse({
                'success': False,
                'error': f"AI Error: {response.text}"
            }, status=500)
    
    except Exception as e:
        print(f"Page Generation Exception: {e}")
        import traceback
        traceback.print_exc()
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@api_view(['GET'])
@permission_classes([AllowAny])
def get_page_url(request, project_id):
    """
    Retrieve the URL and metadata for a generated page.
    """
    try:
        projects = load_projects()
        
        if project_id not in projects:
            return JsonResponse({
                'success': False,
                'error': 'Project not found'
            }, status=404)
        
        project = projects[project_id]
        
        return JsonResponse({
            'success': True,
            'project_id': project_id,
            'web_url': project['web_url'],
            'metadata': project
        })
    
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@api_view(['GET'])
@permission_classes([AllowAny])
def list_projects(request):
    """
    List all generated projects.
    """
    try:
        projects = load_projects()
        
        return JsonResponse({
            'success': True,
            'projects': list(projects.values())
        })
    
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_page(request, project_id):
    """
    Delete a generated page and its metadata.
    """
    try:
        projects = load_projects()
        
        if project_id not in projects:
            return JsonResponse({
                'success': False,
                'error': 'Project not found'
            }, status=404)
        
        # Delete HTML file
        pages_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages')
        filename = f"page_{project_id}.html"
        filepath = os.path.join(pages_dir, filename)
        
        if os.path.exists(filepath):
            os.remove(filepath)
        
        # Remove from JSON storage
        del projects[project_id]
        save_projects(projects)
        
        return JsonResponse({
            'success': True,
            'message': 'Project deleted successfully'
        })
    
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)
