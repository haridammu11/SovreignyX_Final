-- Supabase Schema Setup for LMS Application

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  profile_picture_url TEXT,
  bio TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  streak INTEGER DEFAULT 0,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create profiles table (additional user details)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  university TEXT,
  department TEXT,
  year_of_study INTEGER,
  enrollment_number TEXT,
  date_of_birth DATE,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  author_id UUID REFERENCES auth.users ON DELETE CASCADE,
  content TEXT,
  image_url TEXT,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create followers table
CREATE TABLE IF NOT EXISTS followers (
  id SERIAL PRIMARY KEY,
  follower_id UUID REFERENCES auth.users ON DELETE CASCADE,
  followed_id UUID REFERENCES auth.users ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, followed_id)
);

-- Create connections table (for friend requests)
CREATE TABLE IF NOT EXISTS connections (
  id SERIAL PRIMARY KEY,
  requester_id UUID REFERENCES auth.users ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users ON DELETE CASCADE,
  status TEXT DEFAULT 'pending', -- pending, accepted, rejected
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(requester_id, receiver_id)
);

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES posts ON DELETE CASCADE,
  author_id UUID REFERENCES auth.users ON DELETE CASCADE,
  content TEXT,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create post_likes table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS post_likes (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES posts ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create comment_likes table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS comment_likes (
  id SERIAL PRIMARY KEY,
  comment_id INTEGER REFERENCES comments ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- Create achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  icon TEXT,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  points INTEGER DEFAULT 0,
  rank INTEGER,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id SERIAL PRIMARY KEY,
  title TEXT,
  description TEXT,
  instructor_id UUID REFERENCES auth.users ON DELETE CASCADE,
  thumbnail_url TEXT,
  duration INTEGER, -- in minutes
  level TEXT, -- beginner, intermediate, advanced
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create enrollments table
CREATE TABLE IF NOT EXISTS enrollments (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  course_id INTEGER REFERENCES courses ON DELETE CASCADE,
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress INTEGER DEFAULT 0, -- percentage
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, course_id)
);

-- Create modules table
CREATE TABLE IF NOT EXISTS modules (
  id SERIAL PRIMARY KEY,
  course_id INTEGER REFERENCES courses ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  order_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id SERIAL PRIMARY KEY,
  module_id INTEGER REFERENCES modules ON DELETE CASCADE,
  title TEXT,
  content TEXT,
  video_url TEXT,
  duration INTEGER, -- in minutes
  order_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create quizzes table
CREATE TABLE IF NOT EXISTS quizzes (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER REFERENCES lessons ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  time_limit INTEGER, -- in minutes
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create quiz_questions table
CREATE TABLE IF NOT EXISTS quiz_questions (
  id SERIAL PRIMARY KEY,
  quiz_id INTEGER REFERENCES quizzes ON DELETE CASCADE,
  question TEXT,
  question_type TEXT, -- multiple_choice, true_false, short_answer
  points INTEGER DEFAULT 1,
  order_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create quiz_options table
CREATE TABLE IF NOT EXISTS quiz_options (
  id SERIAL PRIMARY KEY,
  question_id INTEGER REFERENCES quiz_questions ON DELETE CASCADE,
  option_text TEXT,
  is_correct BOOLEAN DEFAULT FALSE,
  order_index INTEGER
);

-- Create quiz_attempts table
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id SERIAL PRIMARY KEY,
  quiz_id INTEGER REFERENCES quizzes ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  score INTEGER,
  max_score INTEGER,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  time_taken INTEGER -- in seconds
);

-- Create chat_rooms table
CREATE TABLE IF NOT EXISTS chat_rooms (
  id SERIAL PRIMARY KEY,
  name TEXT,
  description TEXT,
  is_private BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create chat_room_members table
CREATE TABLE IF NOT EXISTS chat_room_members (
  id SERIAL PRIMARY KEY,
  chat_room_id INTEGER REFERENCES chat_rooms ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- member, admin
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chat_room_id, user_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  chat_room_id INTEGER REFERENCES chat_rooms ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users ON DELETE CASCADE,
  content TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  amount DECIMAL(10, 2),
  currency TEXT DEFAULT 'USD',
  payment_method TEXT, -- credit_card, paypal, etc.
  status TEXT, -- pending, completed, failed, refunded
  transaction_id TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create subscription_plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id SERIAL PRIMARY KEY,
  name TEXT,
  description TEXT,
  price DECIMAL(10, 2),
  currency TEXT DEFAULT 'USD',
  duration INTEGER, -- in days
  features JSONB, -- store plan features as JSON
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  plan_id INTEGER REFERENCES subscription_plans ON DELETE CASCADE,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'active', -- active, expired, cancelled
  payment_id INTEGER REFERENCES payments ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create certificates table
CREATE TABLE IF NOT EXISTS certificates (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  course_id INTEGER REFERENCES courses ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expiry_date TIMESTAMP WITH TIME ZONE,
  certificate_url TEXT
);

-- Set up Row Level Security (RLS) policies

-- Enable RLS for all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- Profiles table policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own profile" ON profiles
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
FOR UPDATE USING (auth.uid() = id);

-- Posts table policies
CREATE POLICY "Posts are viewable by everyone" ON posts
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own posts" ON posts
FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update their own posts" ON posts
FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own posts" ON posts
FOR DELETE USING (auth.uid() = author_id);

-- Followers table policies
CREATE POLICY "Followers are viewable by everyone" ON followers
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own follows" ON followers
FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete their own follows" ON followers
FOR DELETE USING (auth.uid() = follower_id);

-- Comments table policies
CREATE POLICY "Comments are viewable by everyone" ON comments
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own comments" ON comments
FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update their own comments" ON comments
FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own comments" ON comments
FOR DELETE USING (auth.uid() = author_id);

-- Post likes table policies
CREATE POLICY "Post likes are viewable by everyone" ON post_likes
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own post likes" ON post_likes
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own post likes" ON post_likes
FOR DELETE USING (auth.uid() = user_id);

-- Comment likes table policies
CREATE POLICY "Comment likes are viewable by everyone" ON comment_likes
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own comment likes" ON comment_likes
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comment likes" ON comment_likes
FOR DELETE USING (auth.uid() = user_id);

-- Achievements table policies
CREATE POLICY "Achievements are viewable by everyone" ON achievements
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert their own achievements" ON achievements
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Leaderboard table policies
CREATE POLICY "Leaderboard is viewable by everyone" ON leaderboard
FOR SELECT USING (TRUE);

-- Courses table policies
CREATE POLICY "Courses are viewable by everyone" ON courses
FOR SELECT USING (TRUE);

CREATE POLICY "Instructors can insert courses" ON courses
FOR INSERT WITH CHECK (auth.uid() = instructor_id);

CREATE POLICY "Instructors can update their own courses" ON courses
FOR UPDATE USING (auth.uid() = instructor_id);

-- Enrollments table policies
CREATE POLICY "Users can view their own enrollments" ON enrollments
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own enrollments" ON enrollments
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Modules table policies
CREATE POLICY "Modules are viewable by everyone" ON modules
FOR SELECT USING (TRUE);

-- Lessons table policies
CREATE POLICY "Lessons are viewable by everyone" ON lessons
FOR SELECT USING (TRUE);

-- Quizzes table policies
CREATE POLICY "Quizzes are viewable by everyone" ON quizzes
FOR SELECT USING (TRUE);

-- Quiz questions table policies
CREATE POLICY "Quiz questions are viewable by everyone" ON quiz_questions
FOR SELECT USING (TRUE);

-- Quiz options table policies
CREATE POLICY "Quiz options are viewable by everyone" ON quiz_options
FOR SELECT USING (TRUE);

-- Quiz attempts table policies
CREATE POLICY "Users can view their own quiz attempts" ON quiz_attempts
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own quiz attempts" ON quiz_attempts
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Chat rooms table policies
CREATE POLICY "Chat rooms are viewable by everyone" ON chat_rooms
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert chat rooms" ON chat_rooms
FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Chat room members table policies
CREATE POLICY "Chat room members are viewable by everyone" ON chat_room_members
FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert themselves as members" ON chat_room_members
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Messages table policies
CREATE POLICY "Messages are viewable by chat room members" ON messages
FOR SELECT USING (chat_room_id IN (
  SELECT chat_room_id FROM chat_room_members WHERE user_id = auth.uid()
));

CREATE POLICY "Users can insert messages in rooms they belong to" ON messages
FOR INSERT WITH CHECK (auth.uid() = sender_id AND chat_room_id IN (
  SELECT chat_room_id FROM chat_room_members WHERE user_id = auth.uid()
));

-- Payments table policies
CREATE POLICY "Users can view their own payments" ON payments
FOR SELECT USING (auth.uid() = user_id);

-- Subscription plans table policies
CREATE POLICY "Subscription plans are viewable by everyone" ON subscription_plans
FOR SELECT USING (TRUE);

-- User subscriptions table policies
CREATE POLICY "Users can view their own subscriptions" ON user_subscriptions
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions" ON user_subscriptions
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Certificates table policies
CREATE POLICY "Users can view their own certificates" ON certificates
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own certificates" ON certificates
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create triggers for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_connections_updated_at BEFORE UPDATE ON connections
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON modules
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quizzes_updated_at BEFORE UPDATE ON quizzes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quiz_questions_updated_at BEFORE UPDATE ON quiz_questions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quiz_attempts_updated_at BEFORE UPDATE ON quiz_attempts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rooms_updated_at BEFORE UPDATE ON chat_rooms
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create triggers for updating counters
-- Trigger for incrementing likes_count when a post is liked
CREATE OR REPLACE FUNCTION increment_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_post_likes_count_trigger
AFTER INSERT ON post_likes
FOR EACH ROW EXECUTE FUNCTION increment_post_likes_count();

-- Trigger for decrementing likes_count when a post like is removed
CREATE OR REPLACE FUNCTION decrement_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER decrement_post_likes_count_trigger
AFTER DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION decrement_post_likes_count();

-- Trigger for incrementing comments_count when a comment is added
CREATE OR REPLACE FUNCTION increment_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_post_comments_count_trigger
AFTER INSERT ON comments
FOR EACH ROW EXECUTE FUNCTION increment_post_comments_count();

-- Create function to handle new user creation
-- This function needs to be more robust to handle Google Sign-In users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user already exists in users table to prevent duplicate inserts
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
    INSERT INTO public.users (id, username, email, first_name, last_name, created_at, updated_at)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email), NEW.email, 
            COALESCE(NEW.raw_user_meta_data->>'first_name', ''), 
            COALESCE(NEW.raw_user_meta_data->>'last_name', ''), 
            NOW(), NOW());
  END IF;
  
  -- Check if profile already exists
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
    INSERT INTO public.profiles (id, created_at, updated_at)
    VALUES (NEW.id, NOW(), NOW());
  END IF;
  
  -- Check if leaderboard entry already exists
  IF NOT EXISTS (SELECT 1 FROM public.leaderboard WHERE user_id = NEW.id) THEN
    INSERT INTO public.leaderboard (user_id, points, rank, last_updated)
    VALUES (NEW.id, 0, 0, NOW());
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Insert sample data for testing
INSERT INTO subscription_plans (name, description, price, duration, features) VALUES
('Basic', 'Basic access to all courses', 9.99, 30, '{"courses": "all", "certificates": true, "support": "email"}'),
('Premium', 'Premium access with personalized learning paths', 19.99, 30, '{"courses": "all", "certificates": true, "support": "priority", "personal_mentor": true}'),
('Enterprise', 'Enterprise access for teams', 49.99, 30, '{"courses": "all", "certificates": true, "support": "24/7", "personal_mentor": true, "team_features": true}');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres, authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated;

-- Create student_interests table
CREATE TABLE IF NOT EXISTS student_interests (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  student_email TEXT NOT NULL,
  interest_category TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for student_interests
ALTER TABLE student_interests ENABLE ROW LEVEL SECURITY;

-- Student Interests policies (using DROP IF EXISTS to avoid errors on re-run)
DROP POLICY IF EXISTS "Students can view own interests" ON student_interests;
CREATE POLICY "Students can view own interests" ON student_interests
FOR SELECT USING (student_email = (auth.jwt() ->> 'email'));

DROP POLICY IF EXISTS "Students can insert own interests" ON student_interests;
CREATE POLICY "Students can insert own interests" ON student_interests
FOR INSERT WITH CHECK (student_email = (auth.jwt() ->> 'email'));

DROP POLICY IF EXISTS "Students can delete own interests" ON student_interests;
CREATE POLICY "Students can delete own interests" ON student_interests
FOR DELETE USING (student_email = (auth.jwt() ->> 'email'));
