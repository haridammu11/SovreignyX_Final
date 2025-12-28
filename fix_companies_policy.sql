-- ================================================
-- FIX: Allow Companies to Insert Own Profile
-- ================================================

-- The original migration missed the INSERT policy for the 'companies' table.
-- This prevents new companies from registering and existing users from auto-creating their profiles.

-- Drop the policy if it exists (to be safe/idempotent)
DROP POLICY IF EXISTS "Users can create their own company profile" ON companies;

-- Create the INSERT policy
-- Allows any authenticated user to insert a row into 'companies' 
-- AS LONG AS the new row's 'id' matches their auth.uid()
CREATE POLICY "Users can create their own company profile" ON companies
FOR INSERT WITH CHECK (auth.uid() = id);

-- Verify:
-- SELECT * FROM pg_policies WHERE tablename = 'companies';
