-- ================================================
-- ADVANCED FEATURES DATABASE MIGRATION (FIXED & COMPLETE)
-- ================================================

-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- 1. COMPANIES TABLE & SPECIALIZATION
-- ================================================

-- Create companies table if it doesn't exist
-- Minimal schema inferred from typical requirements
CREATE TABLE IF NOT EXISTS companies (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT UNIQUE,
  engineering_stream TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Note: No need for ALTER TABLE ADD COLUMN engineering_stream here
-- because we included it in the CREATE statement above.
-- But for safety in case table existed but missed the column:
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'companies') THEN
        ALTER TABLE companies ADD COLUMN IF NOT EXISTS engineering_stream TEXT;
    END IF;
END $$;

-- Add constraint for valid engineering streams
ALTER TABLE companies DROP CONSTRAINT IF EXISTS valid_engineering_stream;
ALTER TABLE companies ADD CONSTRAINT valid_engineering_stream 
CHECK (engineering_stream IN (
  'Computer Engineering',
  'Mechanical Engineering',
  'Civil Engineering',
  'Electrical Engineering',
  'Electronics Engineering',
  'Chemical Engineering',
  'Aerospace Engineering',
  'Biomedical Engineering',
  'Environmental Engineering',
  'Industrial Engineering'
));

-- Create index
CREATE INDEX IF NOT EXISTS idx_companies_engineering_stream ON companies(engineering_stream);

-- Enable RLS for companies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Companies can view own profile" ON companies;
CREATE POLICY "Companies can view own profile" ON companies
FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Companies can update own profile" ON companies;
CREATE POLICY "Companies can update own profile" ON companies
FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Public can view companies" ON companies;
CREATE POLICY "Public can view companies" ON companies
FOR SELECT USING (true);


-- ================================================
-- 2. STUDENT INTERESTS SELECTION
-- ================================================

-- Create student_interests table
CREATE TABLE IF NOT EXISTS student_interests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_email TEXT NOT NULL,
  interest_category TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_email, interest_category)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_student_interests_email ON student_interests(student_email);

-- Add RLS
ALTER TABLE student_interests ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Students can view own interests" ON student_interests;
CREATE POLICY "Students can view own interests" ON student_interests
FOR SELECT USING (student_email = (auth.jwt() ->> 'email'));

DROP POLICY IF EXISTS "Students can insert own interests" ON student_interests;
CREATE POLICY "Students can insert own interests" ON student_interests
FOR INSERT WITH CHECK (student_email = (auth.jwt() ->> 'email'));

DROP POLICY IF EXISTS "Students can delete own interests" ON student_interests;
CREATE POLICY "Students can delete own interests" ON student_interests
FOR DELETE USING (student_email = (auth.jwt() ->> 'email'));


-- ================================================
-- 3. COURSE RECOMMENDATION SYSTEM
-- ================================================

-- Add engineering_stream to courses table
ALTER TABLE courses ADD COLUMN IF NOT EXISTS engineering_stream TEXT;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS company_email TEXT;

-- Create course_tags table
CREATE TABLE IF NOT EXISTS course_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  UNIQUE(course_id, tag)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_tags_course_id ON course_tags(course_id);
CREATE INDEX IF NOT EXISTS idx_course_tags_tag ON course_tags(tag);

-- Add RLS policies for course_tags
ALTER TABLE course_tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view course tags" ON course_tags;
CREATE POLICY "Anyone can view course tags" ON course_tags
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Course owners can manage tags" ON course_tags;
CREATE POLICY "Course owners can manage tags" ON course_tags
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = course_tags.course_id
    AND courses.company_email = (auth.jwt() ->> 'email')
  )
);


-- ================================================
-- 4. MULTI-FILE PROJECT SUBMISSIONS
-- ================================================

-- Create project_submissions table
CREATE TABLE IF NOT EXISTS project_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_email TEXT NOT NULL,
  course_id INTEGER NOT NULL, 
  submission_type TEXT NOT NULL DEFAULT 'file_upload',
  git_link TEXT,
  status TEXT DEFAULT 'pending',
  grade NUMERIC(5,2),
  feedback TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  CHECK (submission_type IN ('git_link', 'file_upload'))
);

-- Create project_files table
CREATE TABLE IF NOT EXISTS project_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_format TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  public_url TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  FOREIGN KEY (submission_id) REFERENCES project_submissions(id) ON DELETE CASCADE,
  CHECK (file_type IN ('video', 'document'))
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_project_submissions_student ON project_submissions(student_email);
CREATE INDEX IF NOT EXISTS idx_project_submissions_course ON project_submissions(course_id);
CREATE INDEX IF NOT EXISTS idx_project_files_submission ON project_files(submission_id);

-- Add RLS policies for project_submissions
ALTER TABLE project_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own submissions" ON project_submissions;
CREATE POLICY "Students can view own submissions" ON project_submissions
FOR SELECT USING ((auth.jwt() ->> 'email') = student_email);

DROP POLICY IF EXISTS "Students can insert own submissions" ON project_submissions;
CREATE POLICY "Students can insert own submissions" ON project_submissions
FOR INSERT WITH CHECK ((auth.jwt() ->> 'email') = student_email);

DROP POLICY IF EXISTS "Students can update own submissions" ON project_submissions;
CREATE POLICY "Students can update own submissions" ON project_submissions
FOR UPDATE USING ((auth.jwt() ->> 'email') = student_email);

DROP POLICY IF EXISTS "Course owners can view submissions" ON project_submissions;
CREATE POLICY "Course owners can view submissions" ON project_submissions
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = project_submissions.course_id
    AND courses.company_email = (auth.jwt() ->> 'email')
  )
);

DROP POLICY IF EXISTS "Course owners can grade submissions" ON project_submissions;
CREATE POLICY "Course owners can grade submissions" ON project_submissions
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = project_submissions.course_id
    AND courses.company_email = (auth.jwt() ->> 'email')
  )
);

-- Add RLS policies for project_files
ALTER TABLE project_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own files" ON project_files;
CREATE POLICY "Students can view own files" ON project_files
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_submissions
    WHERE project_submissions.id = project_files.submission_id
    AND project_submissions.student_email = (auth.jwt() ->> 'email')
  )
);

DROP POLICY IF EXISTS "Students can insert own files" ON project_files;
CREATE POLICY "Students can insert own files" ON project_files
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM project_submissions
    WHERE project_submissions.id = project_files.submission_id
    AND project_submissions.student_email = (auth.jwt() ->> 'email')
  )
);

DROP POLICY IF EXISTS "Students can delete own files" ON project_files;
CREATE POLICY "Students can delete own files" ON project_files
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_submissions
    WHERE project_submissions.id = project_files.submission_id
    AND project_submissions.student_email = (auth.jwt() ->> 'email')
  )
);

DROP POLICY IF EXISTS "Course owners can view submission files" ON project_files;
CREATE POLICY "Course owners can view submission files" ON project_files
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_submissions ps
    JOIN courses c ON c.id = ps.course_id
    WHERE ps.id = project_files.submission_id
    AND c.company_email = (auth.jwt() ->> 'email')
  )
);


-- ================================================
-- 6. HELPER FUNCTIONS
-- ================================================

-- Function to get recommended courses for a student
CREATE OR REPLACE FUNCTION get_recommended_courses(
  p_student_email TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  course_id INTEGER,
  course_title TEXT,
  course_description TEXT,
  company_name TEXT,
  rating NUMERIC,
  match_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH student_stream AS (
    SELECT 'Computer Engineering'::TEXT as engineering_stream 
  ),
  student_interests_list AS (
    SELECT array_agg(interest_category) as interests
    FROM student_interests
    WHERE student_email = p_student_email
  )
  SELECT 
    c.id,
    c.title,
    c.description,
    co.name as company_name,
    NULL::NUMERIC as rating,
    (
      -- Interest match score (50%)
      (
        SELECT COUNT(*)::NUMERIC / NULLIF(array_length(si.interests, 1), 0)
        FROM course_tags ct
        WHERE ct.course_id = c.id
        AND ct.tag = ANY(si.interests)
      ) * 0.5 +
      -- Stream match score (30%)
      CASE WHEN c.engineering_stream = ss.engineering_stream THEN 0.3 ELSE 0 END
    ) as match_score
  FROM courses c
  JOIN companies co ON co.email = c.company_email
  CROSS JOIN student_stream ss
  CROSS JOIN student_interests_list si
  WHERE c.engineering_stream = ss.engineering_stream
  ORDER BY match_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to update submission timestamp on file upload
CREATE OR REPLACE FUNCTION update_submission_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE project_submissions
  SET updated_at = NOW()
  WHERE id = NEW.submission_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
DROP TRIGGER IF EXISTS trigger_update_submission_timestamp ON project_files;
CREATE TRIGGER trigger_update_submission_timestamp
AFTER INSERT OR UPDATE ON project_files
FOR EACH ROW
EXECUTE FUNCTION update_submission_timestamp();
