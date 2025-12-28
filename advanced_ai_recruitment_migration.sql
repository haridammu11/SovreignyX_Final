-- ================================================
-- Advanced AI Recruitment System - Database Schema Update
-- ================================================

-- Add new columns for multi-dimensional AI analysis
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_ats_score INTEGER;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_overall_score INTEGER;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_technical_score INTEGER;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_experience_score INTEGER;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_cultural_score INTEGER;

-- Store detailed analysis as JSON
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_detailed_analysis JSONB;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_linkedin_analysis JSONB;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_github_analysis JSONB;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_recommendation JSONB;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_applications_ats_score ON job_applications(ai_ats_score DESC);
CREATE INDEX IF NOT EXISTS idx_applications_overall_score ON job_applications(ai_overall_score DESC);

-- Add timestamp for when AI analysis was performed
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS ai_analyzed_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN job_applications.ai_ats_score IS 'ATS (Applicant Tracking System) compatibility score 0-100';
COMMENT ON COLUMN job_applications.ai_overall_score IS 'Overall candidate fit score 0-100';
COMMENT ON COLUMN job_applications.ai_technical_score IS 'Technical skills match score 0-100';
COMMENT ON COLUMN job_applications.ai_experience_score IS 'Experience level match score 0-100';
COMMENT ON COLUMN job_applications.ai_cultural_score IS 'Cultural fit and soft skills score 0-100';
