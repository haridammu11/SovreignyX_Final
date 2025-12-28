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
def create_page_from_prompt(request):
    """
    Generate a complete web page from a natural language prompt.
    
    Expected Input:
    {
        "prompt": "Create an effective dashboard with charts, stats cards, and user activity feed",
        "theme": "dark|light|glassmorphism",
        "project_name": "My Dashboard"
    }
    """
    try:
        import requests
        data = json.loads(request.body)
        
        # Extract parameters
        prompt = data.get('prompt', '')
        theme = data.get('theme', 'dark')
        project_name = data.get('project_name', 'AI Generated Page')
        
        if not prompt:
            return JsonResponse({
                'success': False,
                'error': 'Prompt is required'
            }, status=400)
        
        # Generate unique project ID
        project_id = str(uuid.uuid4())
        
        # Debug logging
        logger.info(f"--- PROMPT-BASED WEB PAGE GENERATION ---")
        logger.info(f"Project: {project_name}")
        logger.info(f"Prompt: {prompt}")
        logger.info(f"Theme: {theme}")
        
        
        # Construct AI prompt
        ai_prompt = f"""
        You are a WORLD-CLASS full-stack web designer and developer who creates COMPLETE, PRODUCTION-READY websites (not just single pages).
        
        **User's Request:**
        {prompt}

        **Theme:** {theme}

        **YOUR MISSION:**
        Create a COMPLETE, PROFESSIONAL WEBSITE that includes:
        1. A stunning landing/welcome page
        2. Professional header with logo and navigation menu
        3. Well-structured footer with links
        4. Multiple interconnected pages with bi-directional navigation
        5. Smooth transitions and modern UI/UX
        
        This must look like a REAL, professionally built website - not a demo or mockup.

        **CRITICAL WEBSITE STRUCTURE REQUIREMENTS:**

        1. **COMPLETE WEBSITE (NOT JUST ONE PAGE):**
           - Generate a MAIN landing page with full navigation
           - Include proper header with logo and menu
           - Include footer with relevant links
           - The main page should have sections that link to other pages
           - Example structure:
             * Landing page (index.html) with hero, features, CTA
             * About page (about.html)
             * Services/Products page (services.html)
             * Contact page (contact.html)
             * Any other relevant pages based on the request

        2. **NAVIGATION SYSTEM (CRITICAL):**
           - Create a professional header with navigation menu
           - Menu items must link to actual pages: <a href="about.html">About</a>
           - Every page must have the SAME header/footer for consistency
           - Bi-directional navigation: users can go from any page to any other page
           - Active page highlighting in navigation
           - Mobile-responsive hamburger menu
           - Smooth scroll for anchor links

        3. **HEADER REQUIREMENTS:**
           - Professional logo (text-based or SVG)
           - Navigation menu with all main pages
           - Sticky/fixed header on scroll
           - Hover effects on menu items
           - Mobile hamburger menu
           - Call-to-action button (e.g., "Get Started", "Contact Us")

        4. **FOOTER REQUIREMENTS:**
           - Multi-column layout with sections
           - Quick links to all pages
           - Social media icons/links
           - Contact information
           - Copyright notice
           - Newsletter signup (optional)
           - Consistent across all pages

        **CRITICAL DESIGN REQUIREMENTS:**


        1. **VISUAL MASTERY & "AWWWARDS" LEVEL DESIGN (NON-NEGOTIABLE):**
           - You are not just a developer, you are a **DIGITAL ARTIST**.
           - The page MUST look high-end, expensive, and futuristic.
           - **NO BORING BOOTSTRAP LOOKS.** Custom CSS is mandatory.
           - **Glassmorphism:** Heavy use of `backdrop-filter: blur()`, translucent backgrounds, and white borders.
           - **Gradients:** Use "Mesh Gradients" or "Aurora Gradients" for backgrounds.
           - **Typography:** Use massive, bold headings (72px+) mixed with clean, thin sans-serif body text (Inter/Outfit).

        2. **ADVANCED ANIMATIONS (GSAP & CSS):**
           - **MANDATORY:** You MUST use GSAP (GreenSock) for entrance animations.
           - Animate elements as they scroll into view (Staggered fade-ups).
           - **Parallax Effects:** Background moves slower than foreground.
           - **Magnetic Buttons:** Buttons that slightly follow the cursor on hover.
           - **Text Reveals:** Characters sliding up or fading in.
           - **Micro-Interactions:** Every click, hover, and focus must have a smooth feedback animation.

        3. **MODERN LAYOUTS:**
           - **Bento Grids:** Use CSS Grid for "Apple-style" feature blocks.
           - **Asymmetry:** Don't just center everything. Use off-center layouts for interest.
           - **Floating Elements:** 3D cards causing depth with `box-shadow` and `transform: translateZ`.

        4. **INTERACTIVITY:**
           - **Custom Cursor:** A trailing circle or dot that inverts colors.
           - **Smooth Scroll:** Implement lenis.js or custom smooth scrolling if possible.
           - **Interactive Backgrounds:** Particles, moving waves, or gradient orbs that follow the mouse.

         5. **REQUIRED LIBRARIES (Include CDNs):**
            - **GSAP (Core):** `<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>`
            - **GSAP (ScrollTrigger):** `<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js"></script>`
            - **Google Fonts:** `<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700;900&family=Playfair+Display:ital,wght@0,600;1,600&display=swap" rel="stylesheet">`
            - **FontAwesome:** `<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">`
        
        6. **JAVASCRIPT LOGIC (MANDATORY IMPLEMENTATION):**
           - **Primary Requirement:** Your `script.js` MUST be complex and robust. NO EMPTY SCRIPTS.
           - **Animation Engine:**
             * Create a function `initAnimations()`.
             * Use `gsap.timeline()` for page load sequences.
             * Apply `gsap.from(".hero-content", {{y: 100, opacity: 0, duration: 1}})`.
             * Apply `ScrollTrigger` to ALL sections: `gsap.from(section, {{scrollTrigger: section...}})`.
           - **Interactive Features:**
             * Implement a `CustomCursor` class that follows mouse movement with lag/smoothing.
             * Add `mouseenter` events to buttons to scale the custom cursor.
           - **Logic:**
             * Navigation toggle (Hamburger menu) must use GSAP for smooth open/close.
             * Form validation must provide instant visual feedback (shake effect on error).
           - **Error Handling:** Wrap initialization in `document.addEventListener('DOMContentLoaded', ...)`

        9. **CONTENT:**
           - Use REALISTIC, PROFESSIONAL placeholder content
           - Meaningful text (not "Lorem ipsum" unless appropriate)
           - Proper data that makes sense for the page type
           - Professional imagery placeholders (use placeholder.com or similar)

        10. **TECHNICAL EXCELLENCE:**
            - Semantic HTML5
            - Clean, organized CSS
            - Efficient JavaScript
            - Accessibility (ARIA labels)
            - SEO-friendly structure
            - Fast loading
            - **CRITICAL: Include CDN links in <head> for ANY libraries you use:**
              * Chart.js: `<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>`
              * Google Fonts: `<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">`
              * Font Awesome (optional)
              * Chart.js (if charts needed)

        **OUTPUT REQUIREMENTS (CRITICAL):**
        
        **You MUST return a JSON Object** where keys are filenames and values are the file contents.
        Do NOT return Markdown. Do NOT return a single HTML string.
        
        **Required Structure:**
        {{
            "index.html": "<!DOCTYPE html>... (Main landing page)",
            "style.css": "/* All CSS styles */",
            "script.js": "// All JavaScript logic",
            "about.html": "<!DOCTYPE html>... (About page)",
            "services.html": "<!DOCTYPE html>... (Services page)",
            "contact.html": "<!DOCTYPE html>... (Contact page)"
        }}
        
        **Crucial Rules:**
        1. **index.html** MUST link to `style.css` and `script.js` properly.
        2. **NO DEAD LINKS:** If you create a navigation link to "About" (<a href="about.html">), you **MUST** include "about.html" in the JSON response.
        3. **Navigation Consistency:** Every generated page must share the SAME Header (with nav) and Footer.
        4. **Interactive Elements:** If you add a "Login" button, you MUST generate "login.html".
        5. **Strict File Separation:**
           - HTML files contain structure.
           - `style.css` contains ALL visuals (responsive, animations).
           - `script.js` contains ALL logic (mobile menu toggle, form validation).

        **Return ONLY the raw JSON object.**
        """
        
        # Call Groq API
        api_key = 'YOUR_GROQ_API_KEY'
        url = 'https://api.groq.com/openai/v1/chat/completions'
        
        logger.info("Calling Groq API for prompt-based generation...")
        
        # Retry mechanism for Rate Limits (429)
        max_retries = 3
        retry_delay = 2
        
        for attempt in range(max_retries):
            response = requests.post(
                url,
                headers={
                    'Authorization': f'Bearer {api_key}',
                    'Content-Type': 'application/json',
                },
                json={
                    'model': 'llama-3.3-70b-versatile',
                    'messages': [
                        {'role': 'system', 'content': 'You are a world-class full-stack developer. You output strictly valid JSON containing web files.'},
                        {'role': 'user', 'content': ai_prompt}
                    ],
                    # Ensure response format is JSON object to force valid JSON
                    'response_format': {"type": "json_object"},
                    'temperature': 0.7,
                    'max_tokens': 8000,
                },
                timeout=120
           )
           
            if response.status_code == 429:
                if attempt < max_retries - 1:
                    wait_time = retry_delay * (2 ** attempt)
                    logger.warning(f"Rate limited (429). Retrying in {wait_time}s...")
                    import time
                    time.sleep(wait_time)
                    continue
                else:
                    return JsonResponse({'success': False, 'error': "System busy (Rate Limit). Please try again in a minute."}, status=429)
            elif response.status_code == 400:
                 logger.error(f"Groq API Error: 400 - {response.text}")
                 return JsonResponse({'success': False, 'error': f"AI Generation Failed (400): {response.text}"}, status=400)
            
            break
        
        if response.status_code == 200:
            content = response.json()['choices'][0]['message']['content']
            
            # Determine Project Directory
            project_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages', project_id)
            os.makedirs(project_dir, exist_ok=True)
            
            try:
                # Clean content (remove markdown if present)
                clean_content = content.replace('```json', '').replace('```', '').strip()
                
                # Robust extraction: Find first { and last }
                start_idx = clean_content.find('{')
                end_idx = clean_content.rfind('}')
                
                if start_idx != -1 and end_idx != -1:
                    clean_content = clean_content[start_idx:end_idx+1]
                
                # Try to parse as JSON
                files_data = json.loads(clean_content)
                
                # Check for files
                if "index.html" not in files_data:
                    # Fallback if no index.html or not valid structure
                    raise ValueError("JSON missing index.html")
                
                # Save ALL files
                for filename, file_content in files_data.items():
                    file_path = os.path.join(project_dir, filename)
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(file_content)
                
                logger.info(f"Saved {len(files_data)} files to {project_dir}")
                
            except (json.JSONDecodeError, ValueError) as e:
                logger.warning(f"Failed to parse JSON response: {e}. Falling back to single file mode.")
                # Fallback: Treat content as single HTML file
                html_content = content.replace('```html', '').replace('```', '').strip()
                # If regex detected JSON-like string but failed, ensure we have HTML
                if not html_content.strip().startswith('<!DOCTYPE'):
                     html_content = f"<!DOCTYPE html><html><body><h1>Error generating multi-file project</h1><pre>{html_content}</pre></body></html>"
                
                with open(os.path.join(project_dir, 'index.html'), 'w', encoding='utf-8') as f:
                    f.write(html_content)
            
            # Construct Web URL pointing to index.html in the project folder
            web_url = request.build_absolute_uri(settings.MEDIA_URL + f'generated_pages/{project_id}/index.html')
            
            # Create project metadata
            project_metadata = {
                "project_id": project_id,
                "project_name": project_name,
                "page_type": "custom",
                "prompt": prompt,
                "web_url": web_url,
                "theme": theme,
                "is_multi_file": True,
                "created_at": str(uuid.uuid1().time)
            }
            
            # Save to JSON storage
            projects = load_projects()
            projects[project_id] = project_metadata
            save_projects(projects)
            
            logger.info(f"Generated Page URL: {web_url}")
            logger.info(f"Project saved with ID: {project_id}")
            
            return JsonResponse({
                'success': True,
                'project_id': project_id,
                'web_url': web_url,
                'metadata': project_metadata
            })
        else:
            logger.error(f"Groq API Error: {response.status_code} - {response.text}")
            return JsonResponse({
                'success': False,
                'error': f"AI Error: {response.text}"
            }, status=500)
    
    except Exception as e:
        logger.error(f"Prompt-based Generation Exception: {e}")
        import traceback
        traceback.print_exc()
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def modify_page(request):
    """
    Modify an existing web page based on user prompts.
    
    Expected Input:
    {
        "project_id": "uuid...",
        "prompt": "Change the background to blue and add a contact form"
    }
    """
    try:
        import requests
        data = json.loads(request.body)
        
        project_id = data.get('project_id')
        prompt = data.get('prompt')
        
        if not project_id or not prompt:
            return JsonResponse({'success': False, 'error': 'Project ID and prompt are required'}, status=400)
            
        # Load existing project metadata
        projects = load_projects()
        if project_id not in projects:
            return JsonResponse({'success': False, 'error': 'Project not found'}, status=404)
            
        project = projects[project_id]
        
        # Determine if multi-file project
        pages_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages')
        project_dir = os.path.join(pages_dir, project_id)
        single_file_path = os.path.join(pages_dir, f"page_{project_id}.html")
        
        is_multi_file = os.path.isdir(project_dir)
        
        if is_multi_file:
            # Multi-file Logic
            # Read all key files
            project_files = {}
            for fname in ['index.html', 'style.css', 'script.js']:
                fpath = os.path.join(project_dir, fname)
                if os.path.exists(fpath):
                    with open(fpath, 'r', encoding='utf-8') as f:
                        project_files[fname] = f.read()
            
            # Construct Prompt for Multi-File
            files_context = "\n".join([f"--- {name} ---\n{content}\n" for name, content in project_files.items()])
            
            ai_prompt = f"""
            You are a SENIOR LEAD DEVELOPER maintaining a multi-file production website.
            
            **User Request:** "{prompt}"
            
            **Current Project Files:**
            {files_context}
            
            **MANDATE:**
            1. Modify the code to satisfy the request.
            2. **CRITICAL - DESIGN PRESERVATION:** do NOT degrade the design.
               - If adding elements, use **GSAP** for entrance animations.
               - Match the existing **Glassmorphism/Gradient** style.
               - Maintain **Bento Grid** layouts.
            3. **CRITICAL - NEW PAGES:** If the request implies a new page (e.g., "Add a Login button", "Link to Contact page"), you MUST:
               - Add the button/link to the existing HTML.
               - **GENERATE THE NEW PAGE FILE** (e.g., "login.html", "contact.html") with full content (header, footer, styles).
               - Return it in the JSON.
            4. **Visual Consistency:**
               - Use the SAME font (check Google Fonts link).
               - Use the SAME color variables.
               - Use the SAME border-radius and box-shadows.
            
            **OUTPUT:**
            Return a JSON Object with keys as filenames and values as updated/new content.
            Include files that need changing AND any new files you created.
            Example: 
            {{
                "index.html": "...updated nav...", 
                "login.html": "<!DOCTYPE html>..." 
            }}
            """
            
            # We need to handle the API call specifically for JSON response here or make the main call generic
            # For simplicity, we will assume the main call logic below needs adjustment or we use a specific branch here.
            # Let's customize the call for multi-file:
            
        else:
            # Single File Logic (Legacy)
            if not os.path.exists(single_file_path):
                 return JsonResponse({'success': False, 'error': 'Project file not found'}, status=404)
                 
            with open(single_file_path, 'r', encoding='utf-8') as f:
                current_html = f.read()

            ai_prompt = f"""
            You are a SENIOR LEAD DEVELOPER responsible for maintaining a LIVE, PRODUCTION-READY WEBSITE.
            You must treat this modification as a critical update to a production system, NOT a prototype.
    
            **User Request:**
            "{prompt}"
            
            **Current HTML Code:**
            ```html
            {current_html}
            ```
            
            **YOUR MANDATE:**
            1. **PRODUCTION QUALITY:** Every change must be robust, scalable, and maintainable.
            2. **NAVIGATION INTEGRITY:** NEVER break existing navigation. If adding a page, ADD it to the navigation menu.
            3. **DESIGN CONSISTENCY:** Match new elements PERFECTLY with the existing design system.
    
            **CRITICAL INSTRUCTIONS:**
            1. **NAVIGATION:** If adding a page link, add it to the Header `<nav>`: `<a href="contact.html">Contact</a>`.
            2. **SMART LINKING:** If the user asks for a new page, JUST create the link. The system auto-generates the page.
            3. **Keep everything in this SINGLE HTML file** (Legacy Mode).
            4. **Ensure Chart.js CDN** is present if needed.

            **OUTPUT:**
            Return ONLY the updated complete HTML code starting with <!DOCTYPE html>.
            NO markdown code fences.
            """

        
        # Call Groq API
        api_key = 'YOUR_GROQ_API_KEY'
        url = 'https://api.groq.com/openai/v1/chat/completions'
        
        logger.info(f"Modifying page {project_id} with prompt: {prompt}")
        
        # Prepare request payload
        payload = {
            'model': 'llama-3.3-70b-versatile',
            'messages': [
                {'role': 'system', 'content': 'You are an expert web developer who modifies code precisely based on user instructions.'},
                {'role': 'user', 'content': ai_prompt}
            ],
            'temperature': 0.5,
            'max_tokens': 8000,
        }
        
        # Enable JSON mode for multi-file
        if is_multi_file:
            payload['response_format'] = {"type": "json_object"}
            
        # Retry mechanism for Rate Limits (429)
        max_retries = 3
        retry_delay = 2
        
        for attempt in range(max_retries):
            response = requests.post(
                url,
                headers={
                    'Authorization': f'Bearer {api_key}',
                    'Content-Type': 'application/json',
                },
                json=payload,
                timeout=120
            )
            
            if response.status_code == 429:
                if attempt < max_retries - 1:
                    wait_time = retry_delay * (2 ** attempt)
                    logger.warning(f"Rate limited (429). Retrying in {wait_time}s...")
                    import time
                    time.sleep(wait_time)
                    continue
                else:
                    logger.error("Max retries exceeded for rate limit.")
                    return JsonResponse({'success': False, 'error': "System busy (Rate Limit). Please try again in a minute."}, status=429)
            
            elif response.status_code == 400:
                logger.error(f"Groq API Bad Request (400): {response.text}")
                # Analyze if context is too long
                return JsonResponse({'success': False, 'error': f"AI Request Failed (400): {response.text}"}, status=400)
                
            break # Exit loop if not 429
        
        if response.status_code == 200:
            content = response.json()['choices'][0]['message']['content']
            
            if is_multi_file:
                # Multi-File Handling
                try:
                    # Clean content (remove markdown if present)
                    clean_content = content.replace('```json', '').replace('```', '').strip()
                    
                    # Robust extraction: Find first { and last }
                    start_idx = clean_content.find('{')
                    end_idx = clean_content.rfind('}')
                    
                    if start_idx != -1 and end_idx != -1:
                        clean_content = clean_content[start_idx:end_idx+1]
                        
                    files_data = json.loads(clean_content)
                    updated_files_count = 0
                    
                    for filename, file_content in files_data.items():
                        # Security check: prevent path traversal
                        if '..' in filename or filename.startswith('/'):
                            continue
                            
                        file_path = os.path.join(project_dir, filename)
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(file_content)
                        updated_files_count += 1
                        
                    return JsonResponse({
                        'success': True,
                        'project_id': project_id,
                        'message': f'Updated {updated_files_count} files successfully'
                    })
                    
                except json.JSONDecodeError:
                    return JsonResponse({'success': False, 'error': "AI failed to return valid JSON for multi-file update"}, status=500)
                    
            else:
                # Single File Handling (Legacy)
                html_content = content.replace('```html', '').replace('```', '').strip()
                
                # Detect and auto-generate linked pages
                linked_pages = _detect_and_generate_linked_pages(html_content, project, request)
                
                # CRITICAL: Update the HTML to replace placeholder links with actual generated URLs
                if linked_pages:
                    for page_info in linked_pages:
                        original_link = page_info['original_link']
                        actual_url = page_info['web_url']
                        
                        # Replace the placeholder link with the actual URL
                        html_content = html_content.replace(f'href="{original_link}"', f'href="{actual_url}"')
                        html_content = html_content.replace(f"href='{original_link}'", f"href='{actual_url}'")
                        
                        logger.info(f"Replaced link: {original_link} → {actual_url}")
                
                # Save updated HTML to file (with corrected links)
                with open(single_file_path, 'w', encoding='utf-8') as f:
                    f.write(html_content)
                
                response_data = {
                    'success': True, 
                    'project_id': project_id,
                    'message': 'Page updated successfully'
                }
                
                if linked_pages:
                    response_data['linked_pages'] = linked_pages
                    response_data['message'] = f"Page updated successfully. Auto-generated {len(linked_pages)} linked page(s) and updated all links."
                
                return JsonResponse(response_data)
        else:
            logger.error(f"Groq API Error: {response.status_code}")
            return JsonResponse({'success': False, 'error': f"AI Error: {response.text}"}, status=500)
            
    except Exception as e:
        logger.error(f"Modify Page Exception: {e}")
        return JsonResponse({'success': False, 'error': str(e)}, status=500)


def _detect_and_generate_linked_pages(html_content, parent_project, request):
    """
    Detect links to non-existent pages and auto-generate them.
    Returns list of generated pages with their URLs.
    """
    import re
    import requests as req
    
    # Extract all href links from HTML
    href_pattern = r'href=["\']([^"\']+\.html)["\']'
    links = re.findall(href_pattern, html_content)
    
    # Filter to only local HTML pages (not external URLs or anchors)
    local_pages = [link for link in links if not link.startswith(('http://', 'https://', '#', 'mailto:'))]
    
    # Remove duplicates and get unique page names
    unique_pages = list(set(local_pages))
    
    generated_pages = []
    pages_dir = os.path.join(settings.MEDIA_ROOT, 'generated_pages')
    
    for page_link in unique_pages:
        # Extract page name (e.g., "login.html" -> "login")
        page_name = page_link.replace('.html', '').replace('./', '').strip()
        
        # Skip if it's the current page or common placeholders
        if page_name in ['#', 'javascript:void(0)', '']:
            continue
            
        # Check if this page already exists as a project
        projects = load_projects()
        page_exists = any(
            p.get('page_type') == page_name or 
            page_name.lower() in p.get('project_name', '').lower()
            for p in projects.values()
        )
        
        if not page_exists:
            # Auto-generate this page
            logger.info(f"Auto-generating linked page: {page_name}")
            
            try:
                # Create prompt for the new page based on its name
                page_prompt = _generate_page_prompt_from_name(page_name, parent_project)
                
                # Call Groq API to generate the page
                api_key = 'YOUR_GROQ_API_KEY'
                url = 'https://api.groq.com/openai/v1/chat/completions'
                
                response = req.post(
                    url,
                    headers={
                        'Authorization': f'Bearer {api_key}',
                        'Content-Type': 'application/json',
                    },
                    json={
                        'model': 'llama-3.3-70b-versatile',
                        'messages': [
                            {'role': 'system', 'content': 'You are a world-class web designer who creates beautiful, consistent web pages.'},
                            {'role': 'user', 'content': page_prompt}
                        ],
                        'temperature': 0.7,
                        'max_tokens': 8000,
                    },
                    timeout=60
                )
                
                if response.status_code == 200:
                    content = response.json()['choices'][0]['message']['content']
                    page_html = content.replace('```html', '').replace('```', '').strip()
                    
                    # Generate new project ID for this page
                    new_project_id = str(uuid.uuid4())
                    filename = f"page_{new_project_id}.html"
                    filepath = os.path.join(pages_dir, filename)
                    
                    # Save the generated page
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(page_html)
                    
                    # Construct public URL
                    web_url = request.build_absolute_uri(settings.MEDIA_URL + 'generated_pages/' + filename)
                    
                    # Save metadata
                    project_metadata = {
                        "project_id": new_project_id,
                        "project_name": f"{page_name.title()} Page",
                        "page_type": page_name,
                        "web_url": web_url,
                        "theme": parent_project.get('theme', 'dark'),
                        "parent_project": parent_project.get('project_id'),
                        "auto_generated": True,
                        "created_at": str(uuid.uuid1().time)
                    }
                    
                    projects[new_project_id] = project_metadata
                    save_projects(projects)
                    
                    generated_pages.append({
                        'page_name': page_name,
                        'project_id': new_project_id,
                        'web_url': web_url,
                        'original_link': page_link
                    })
                    
                    logger.info(f"Successfully generated {page_name} page: {web_url}")
                    
            except Exception as e:
                logger.error(f"Failed to auto-generate {page_name}: {e}")
                continue
    
    return generated_pages


def _generate_page_prompt_from_name(page_name, parent_project):
    """Generate an appropriate prompt based on the page name."""
    
    # Common page types and their descriptions
    page_templates = {
        'login': 'a beautiful login page with email and password fields, remember me checkbox, and forgot password link',
        'register': 'a registration page with username, email, password, and confirm password fields',
        'signup': 'a sign-up page with user registration form including name, email, and password',
        'contact': 'a contact page with a form including name, email, subject, and message fields',
        'about': 'an about page with company information, mission statement, and team section',
        'services': 'a services page showcasing different service offerings with cards and descriptions',
        'pricing': 'a pricing page with pricing tiers and feature comparisons',
        'dashboard': 'a dashboard page with statistics cards, charts, and data visualizations',
        'profile': 'a user profile page with avatar, personal information, and edit capabilities',
        'settings': 'a settings page with various configuration options organized in tabs or sections',
        'faq': 'an FAQ page with collapsible questions and answers',
        'terms': 'a terms of service page with legal text and sections',
        'privacy': 'a privacy policy page with data protection information',
        '404': 'a 404 error page with a friendly message and navigation back to home',
    }
    
    # Get description or use generic
    description = page_templates.get(page_name.lower(), f'a {page_name} page with relevant content and functionality')
    
    # Get theme from parent project
    theme = parent_project.get('theme', 'dark')
    
    prompt = f"""
    Create {description}.
    
    **CRITICAL REQUIREMENTS:**
    1. **Match Parent Style:** Use the SAME design aesthetic as the parent page
    2. **Theme:** {theme} theme with consistent colors and styling
    3. **Navigation:** Include a link back to the main page (index.html or home.html)
    4. **Modern Design:** Premium, beautiful UI with smooth animations
    5. **Responsive:** Mobile-friendly layout
    6. **Self-Contained:** All CSS and JS internal
    7. **CDN Links:** Include Chart.js CDN if using charts
    
    **Design Guidelines:**
    - Use modern, premium aesthetics
    - Smooth transitions and hover effects
    - Proper spacing and typography
    - Glassmorphism or gradient effects
    - Professional color scheme
    
    **OUTPUT:**
    Return ONLY the complete HTML code starting with <!DOCTYPE html>.
    NO markdown code fences.
    """
    
    return prompt
