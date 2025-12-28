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

# JSON storage path
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
def create_page_with_backend(request):
    """
    Generate a web page with REAL backend functionality.
    
    Expected Input:
    {
        "prompt": "Create a registration page",
        "theme": "dark",
        "backend_config": {
            "type": "supabase",  // or "custom"
            "supabase_url": "https://xxx.supabase.co",
            "supabase_anon_key": "xxx",
            "table_name": "users",
            "fields_mapping": {
                "email": "email",
                "password": "password_hash"
            }
        }
    }
    """
    try:
        import requests
        data = json.loads(request.body)
        
        prompt = data.get('prompt', '')
        theme = data.get('theme', 'dark')
        project_name = data.get('project_name', 'AI Generated Page')
        backend_config = data.get('backend_config', {})
        
        if not prompt:
            return JsonResponse({'success': False, 'error': 'Prompt is required'}, status=400)
        
        project_id = str(uuid.uuid4())
        
        logger.info(f"--- BACKEND-ENABLED PAGE GENERATION ---")
        logger.info(f"Project: {project_name}")
        logger.info(f"Prompt: {prompt}")
        logger.info(f"Backend: {backend_config.get('type', 'none')}")
        
        # Generate backend integration code
        backend_js_code = _generate_backend_code(backend_config, project_id)
        
        # Construct AI prompt with backend instructions
        ai_prompt = f"""
        You are a WORLD-CLASS full-stack web developer. Create a STUNNING, FUNCTIONAL web page with REAL backend integration.

        **User's Request:**
        {prompt}

        **Theme:** {theme}

        **CRITICAL: BACKEND INTEGRATION REQUIRED**
        This page MUST have WORKING backend functionality. The form submission must:
        1. Collect data from the form
        2. Validate the data
        3. Send it to the backend API
        4. Show success/error messages
        5. Handle loading states

        **Backend Configuration:**
        {json.dumps(backend_config, indent=2)}

        **DESIGN REQUIREMENTS:**
        1. **Visual Excellence:**
           - Beautiful, modern design with {theme} theme
           - Smooth animations and transitions
           - Premium color palette with gradients
           - Professional typography (Google Fonts)
           - Hover effects and micro-interactions

        2. **Form Functionality:**
           - Client-side validation for all fields
           - Real-time validation feedback
           - Beautiful error messages
           - Loading spinner during submission
           - Success/error notifications
           - Prevent multiple submissions

        3. **Backend Integration:**
           - AJAX form submission
           - Proper error handling
           - Success redirect or message
           - Data sanitization
           - Security best practices

        4. **User Experience:**
           - Clear labels and placeholders
           - Helpful validation messages
           - Smooth transitions
           - Responsive design
           - Accessible (ARIA labels)

        **JAVASCRIPT INTEGRATION - ADVANCED & MODERN:**
        1. **Backend Code Injection:**
           Include the provided backend integration code EXACTLY as shown below, but wrap it or use it within a modern module/class structure if appropriate.
           ```javascript
           {backend_js_code}
           ```

        2. **Interactive Logic (CRITICAL):**
           - Use **ES6+ syntax** (arrow functions, spread operators, async/await).
           - **Enhanced Form Handling:**
             * dynamic validation *while typing* (not just on submit).
             * Disable submit button & show loading state (spinner/skeleton) during network requests.
             * specific error handling (parse backend error messages and display them next to the relevant field).
           - **Dynamic UI:**
             * If the backend returns data, display it nicely (e.g., render a card or list item dynamically using `document.createElement`).
             * Use helper functions for DOM manipulation.
           - **UX Enhancements:**
             * Auto-focus the first field.
             * clear form after success (if applicable) and show a success toast/modal.

        **OUTPUT REQUIREMENTS:**
        - Return ONLY complete HTML starting with <!DOCTYPE html>.
        - NO markdown code fences.
        - Fully self-contained (all CSS/JS inside `<style>` and `<script>` tags).
        - **Must include the backend integration code.**
        - **VISUALS MUST BE PREMIUM:** Use shadows, gradients, rounded corners, and generous padding.
        - Must work immediately when opened.

        Make this page STUNNING, PROFESSIONAL, and HIGHLY INTERACTIVE! 🚀
        """
        
        # Call Groq API
        api_key = 'YOUR_GROQ_API_KEY'
        url = 'https://api.groq.com/openai/v1/chat/completions'
        
        logger.info("Calling Groq API for backend-enabled page...")
        
        response = requests.post(
            url,
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={
                'model': 'llama-3.3-70b-versatile',
                'messages': [
                    {'role': 'system', 'content': 'You are a world-class full-stack developer who creates beautiful, functional web applications with real backend integration.'},
                    {'role': 'user', 'content': ai_prompt}
                ],
                'temperature': 0.8,
                'max_tokens': 8000,
            },
            timeout=60
        )
        
        if response.status_code == 200:
            content = response.json()['choices'][0]['message']['content']
            html_content = content.replace('```html', '').replace('```', '').strip()
            
            # Save HTML to file
            pages_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages')
            os.makedirs(pages_dir, exist_ok=True)
            
            filename = f"page_{project_id}.html"
            filepath = os.path.join(pages_dir, filename)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            web_url = request.build_absolute_uri(settings.MEDIA_URL + 'generated_pages/' + filename)
            
            # Save metadata
            project_metadata = {
                "project_id": project_id,
                "project_name": project_name,
                "page_type": "backend_enabled",
                "prompt": prompt,
                "web_url": web_url,
                "theme": theme,
                "backend_type": backend_config.get('type', 'none'),
                "has_backend": bool(backend_config),
                "created_at": str(uuid.uuid1().time)
            }
            
            projects = load_projects()
            projects[project_id] = project_metadata
            save_projects(projects)
            
            logger.info(f"Generated Backend-Enabled Page: {web_url}")
            
            return JsonResponse({
                'success': True,
                'project_id': project_id,
                'web_url': web_url,
                'metadata': project_metadata
            })
        else:
            logger.error(f"Groq API Error: {response.status_code}")
            return JsonResponse({'success': False, 'error': f"AI Error: {response.text}"}, status=500)
    
    except Exception as e:
        logger.error(f"Backend Page Generation Exception: {e}")
        import traceback
        traceback.print_exc()
        return JsonResponse({'success': False, 'error': str(e)}, status=500)


def _generate_backend_code(backend_config, project_id):
    """Generate JavaScript code for backend integration"""
    
    backend_type = backend_config.get('type', 'none')
    
    if backend_type == 'supabase':
        return _generate_supabase_code(backend_config)
    elif backend_type == 'custom':
        return _generate_custom_api_code(backend_config)
    else:
        return _generate_generic_code()


def _generate_supabase_code(config):
    """Generate Supabase integration code"""
    supabase_url = config.get('supabase_url', '')
    supabase_key = config.get('supabase_anon_key', '')
    table_name = config.get('table_name', 'users')
    
    return f"""
// Supabase Configuration
const SUPABASE_URL = '{supabase_url}';
const SUPABASE_ANON_KEY = '{supabase_key}';

async function submitFormData(formData) {{
    try {{
        const response = await fetch(`${{SUPABASE_URL}}/rest/v1/{table_name}`, {{
            method: 'POST',
            headers: {{
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${{SUPABASE_ANON_KEY}}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            }},
            body: JSON.stringify(formData)
        }});
        
        if (response.ok) {{
            const data = await response.json();
            return {{ success: true, data: data }};
        }} else {{
            const error = await response.json();
            return {{ success: false, error: error.message || 'Submission failed' }};
        }}
    }} catch (error) {{
        console.error('Supabase Error:', error);
        return {{ success: false, error: 'Network error. Please try again.' }};
    }}
}}
"""


def _generate_custom_api_code(config):
    """Generate custom API integration code"""
    api_endpoint = config.get('api_endpoint', '')
    api_key = config.get('api_key', '')
    
    return f"""
// Custom API Configuration
const API_ENDPOINT = '{api_endpoint}';
const API_KEY = '{api_key}';

async function submitFormData(formData) {{
    try {{
        const response = await fetch(API_ENDPOINT, {{
            method: 'POST',
            headers: {{
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${{API_KEY}}`
            }},
            body: JSON.stringify(formData)
        }});
        
        if (response.ok) {{
            const data = await response.json();
            return {{ success: true, data: data }};
        }} else {{
            return {{ success: false, error: 'Submission failed' }};
        }}
    }} catch (error) {{
        console.error('API Error:', error);
        return {{ success: false, error: 'Network error. Please try again.' }};
    }}
}}
"""


def _generate_generic_code():
    """Generate generic form handling code"""
    return """
// Generic Form Handling (Console logging for demo)
async function submitFormData(formData) {
    console.log('Form Data:', formData);
    
    // Simulate API call
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve({ 
                success: true, 
                message: 'Form submitted successfully! (Demo mode - no real backend)' 
            });
        }, 1000);
    });
}
"""
