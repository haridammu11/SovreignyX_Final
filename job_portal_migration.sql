-- ================================================
-- JOB PORTAL MIGRATION
-- ================================================

-- 1. JOBS TABLE
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  requirements TEXT,
  salary_range TEXT,
  location TEXT,
  job_type TEXT CHECK (job_type IN ('Remote', 'Onsite', 'Hybrid')),
  status TEXT DEFAULT 'Open' CHECK (status IN ('Open', 'Closed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for searching
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);

-- RLS for Jobs
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Anyone can view Open jobs
DROP POLICY IF EXISTS "Public can view open jobs" ON jobs;
CREATE POLICY "Public can view open jobs" ON jobs
FOR SELECT USING (status = 'Open');

-- Companies can manage their own jobs
DROP POLICY IF EXISTS "Companies can manage own jobs" ON jobs;
CREATE POLICY "Companies can manage own jobs" ON jobs
FOR ALL USING (auth.uid() = company_id);


-- 2. JOB APPLICATIONS TABLE
CREATE TABLE IF NOT EXISTS job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT, -- Snapshot of name at time of application
  student_email TEXT, -- Snapshot of email
  resume_url TEXT NOT NULL,
  cover_note TEXT,
  linkedin_url TEXT,
  github_url TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Reviewing', 'Interview', 'Offer', 'Rejected', 'Accepted')),
  ai_compatibility_score INTEGER, -- 0-100
  ai_summary TEXT, -- Short summary from AI
  ai_pros TEXT,    -- AI generated pros
  ai_cons TEXT,    -- AI generated cons
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(job_id, student_id)
);

-- Index for searching
CREATE INDEX IF NOT EXISTS idx_applications_job ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_applications_student ON job_applications(student_id);

-- RLS for Applications
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;

-- Students can view/create their own applications
DROP POLICY IF EXISTS "Students can manage own applications" ON job_applications;
CREATE POLICY "Students can manage own applications" ON job_applications
FOR ALL USING (auth.uid() = student_id);

-- Companies can view/update applications for their jobs
DROP POLICY IF EXISTS "Companies can view applications for their jobs" ON job_applications;
CREATE POLICY "Companies can view applications for their jobs" ON job_applications
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = job_applications.job_id
    AND jobs.company_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Companies can update applications for their jobs" ON job_applications;
CREATE POLICY "Companies can update applications for their jobs" ON job_applications
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = job_applications.job_id
    AND jobs.company_id = auth.uid()
  )
);


-- 3. STORAGE BUCKET FOR RESUMES
-- Create a new bucket 'resumes' if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('resumes', 'resumes', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
-- Allow authenticated students to upload resumes
DROP POLICY IF EXISTS "Students can upload resumes" ON storage.objects;
CREATE POLICY "Students can upload resumes" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow public/companies to read resumes (since public=true, this is implicit, but good to be explicit for restrictive setups)
-- For now, relying on public bucket access for simplicity in reading PDF viewers.


-- 4. EMAIL NOTIFICATION FUNCTION (Optional Draft)
-- Ideally handled via Edge Functions or Client-side triggers for this MVP.
