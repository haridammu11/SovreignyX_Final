-- Follow Request System - Database Verification & Testing Queries
-- Run these in Supabase SQL Editor to verify and debug the system

-- ============================================================================
-- 1. VERIFY TABLE STRUCTURE
-- ============================================================================

-- Check if connections table exists and has correct columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'connections'
ORDER BY ordinal_position;

-- Expected output:
-- id              | integer       | NO
-- requester_id    | uuid          | NO  
-- receiver_id     | uuid          | NO
-- status          | text          | NO
-- created_at      | timestamp     | NO
-- updated_at      | timestamp     | YES

-- ============================================================================
-- 2. CHECK EXISTING CONNECTIONS
-- ============================================================================

-- View all connections
SELECT id, requester_id, receiver_id, status, created_at 
FROM connections 
ORDER BY created_at DESC 
LIMIT 10;

-- ============================================================================
-- 3. TEST CASE 1: Create a follow request
-- ============================================================================

-- Replace UUIDs with actual user IDs from your system
INSERT INTO connections (requester_id, receiver_id, status, created_at)
VALUES (
  'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid,  -- User A requesting
  'f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb'::uuid,  -- User B receiving
  'pending',
  NOW()
)
ON CONFLICT DO NOTHING
RETURNING id, requester_id, receiver_id, status, created_at;

-- ============================================================================
-- 4. TEST CASE 2: Get pending requests for User B
-- ============================================================================

-- Check pending requests received by User B
SELECT id, requester_id, receiver_id, status, created_at
FROM connections
WHERE receiver_id = 'f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb'::uuid
  AND status = 'pending'
ORDER BY created_at DESC;

-- Expected output:
-- Should show the request created in Test Case 1 with status='pending'

-- ============================================================================
-- 5. TEST CASE 3: Check pending count for User B
-- ============================================================================

SELECT COUNT(*) as pending_requests_count
FROM connections
WHERE receiver_id = 'f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb'::uuid
  AND status = 'pending';

-- Expected output: Should show 1 (or more if you have multiple requests)

-- ============================================================================
-- 6. TEST CASE 4: Get outgoing requests for User A
-- ============================================================================

-- Check requests SENT by User A (not received)
SELECT id, requester_id, receiver_id, status, created_at
FROM connections
WHERE requester_id = 'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid
ORDER BY created_at DESC;

-- ============================================================================
-- 7. ACCEPT A FOLLOW REQUEST
-- ============================================================================

-- Update status from pending to accepted (replace XXX with actual request ID)
UPDATE connections
SET status = 'accepted', updated_at = NOW()
WHERE id = XXX  -- Replace XXX with actual connection ID
RETURNING id, status, updated_at;

-- Verify it was updated
SELECT id, requester_id, receiver_id, status, created_at
FROM connections
WHERE id = XXX;

-- ============================================================================
-- 8. REJECT A FOLLOW REQUEST
-- ============================================================================

-- Update status from pending to rejected
UPDATE connections
SET status = 'rejected', updated_at = NOW()
WHERE id = XXX  -- Replace XXX with actual connection ID
RETURNING id, status, updated_at;

-- ============================================================================
-- 9. DELETE/CANCEL A FOLLOW REQUEST
-- ============================================================================

-- Completely remove a follow request
DELETE FROM connections
WHERE id = XXX  -- Replace XXX with actual connection ID
RETURNING id, requester_id, receiver_id, status;

-- ============================================================================
-- 10. CHECK FOR DUPLICATE CONNECTIONS
-- ============================================================================

-- Find any duplicate connections between same two users
SELECT 
  requester_id, 
  receiver_id, 
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as ids
FROM connections
GROUP BY requester_id, receiver_id
HAVING COUNT(*) > 1;

-- If duplicates exist, keep only the latest one and delete others
-- WARNING: Run with caution!
DELETE FROM connections c1
WHERE c1.id NOT IN (
  SELECT DISTINCT ON (requester_id, receiver_id) id
  FROM connections
  ORDER BY requester_id, receiver_id, created_at DESC
);

-- ============================================================================
-- 11. CHECK ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- View RLS policies on connections table
SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'connections'
ORDER BY tablename, policyname;

-- Expected: Should see policies for users to read/insert/update their own connections

-- ============================================================================
-- 12. DETAILED FOLLOW REQUEST STATUS
-- ============================================================================

-- Get comprehensive follow request status between two specific users
SELECT 
  c.id,
  c.requester_id,
  u1.email as requester_email,
  c.receiver_id,
  u2.email as receiver_email,
  c.status,
  c.created_at,
  c.updated_at,
  CASE 
    WHEN c.status = 'pending' THEN 'Waiting for response'
    WHEN c.status = 'accepted' THEN 'Followers'
    WHEN c.status = 'rejected' THEN 'Request rejected'
  END as status_description
FROM connections c
JOIN users u1 ON c.requester_id = u1.id
JOIN users u2 ON c.receiver_id = u2.id
WHERE (c.requester_id = 'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid 
   OR c.receiver_id = 'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid)
ORDER BY c.created_at DESC;

-- ============================================================================
-- 13. STATISTICS QUERY
-- ============================================================================

-- Get overall follow request statistics
SELECT 
  (SELECT COUNT(*) FROM connections WHERE status = 'pending') as pending_requests,
  (SELECT COUNT(*) FROM connections WHERE status = 'accepted') as accepted_follows,
  (SELECT COUNT(*) FROM connections WHERE status = 'rejected') as rejected_requests,
  (SELECT COUNT(*) FROM connections) as total_connections;

-- ============================================================================
-- 14. FIX COMMON ISSUES
-- ============================================================================

-- If you see NULL values in status column, fix them:
UPDATE connections
SET status = 'pending'
WHERE status IS NULL;

-- If receiver_id column doesn't exist, you may need to rename it:
-- ALTER TABLE connections RENAME COLUMN target_user_id TO receiver_id;
-- or
-- ALTER TABLE connections RENAME COLUMN followed_id TO receiver_id;

-- ============================================================================
-- 15. RESET FOR TESTING (CAUTION!)
-- ============================================================================

-- Delete all connections (CAUTION: This removes all follow relationships!)
-- Only run if you want to start fresh for testing
-- DELETE FROM connections;

-- Delete only pending requests
DELETE FROM connections WHERE status = 'pending';

-- Delete only between specific users
DELETE FROM connections
WHERE (requester_id = 'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid 
   AND receiver_id = 'f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb'::uuid)
   OR (requester_id = 'f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb'::uuid 
   AND receiver_id = 'b50bcdef-d22c-4d4a-b561-c53db7809232'::uuid);

-- ============================================================================
-- QUICK REFERENCE - Most Important Queries
-- ============================================================================

-- 1. Create follow request (replace UUIDs)
-- INSERT INTO connections (requester_id, receiver_id, status, created_at)
-- VALUES ('UUID1'::uuid, 'UUID2'::uuid, 'pending', NOW());

-- 2. Get pending requests for user (replace UUID)
-- SELECT * FROM connections
-- WHERE receiver_id = 'UUID'::uuid AND status = 'pending';

-- 3. Get pending count for user (replace UUID)
-- SELECT COUNT(*) FROM connections
-- WHERE receiver_id = 'UUID'::uuid AND status = 'pending';

-- 4. Accept request (replace ID)
-- UPDATE connections SET status = 'accepted', updated_at = NOW() WHERE id = ID;

-- 5. Reject request (replace ID)
-- UPDATE connections SET status = 'rejected', updated_at = NOW() WHERE id = ID;
