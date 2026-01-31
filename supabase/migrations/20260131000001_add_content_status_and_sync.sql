-- Migration: add content_status enum, status column, and sync trigger
-- Adds `status` enum with values 'draft', 'live', 'published'
-- Keeps existing `is_published` boolean for backward compatibility
-- Adds trigger to ensure `is_published` reflects `status = 'published'`

DO $$
BEGIN
  -- Create enum if not exists
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_status') THEN
    CREATE TYPE public.content_status AS ENUM ('draft', 'live', 'published');
  END IF;
EXCEPTION WHEN duplicate_object THEN
  -- already exists
  NULL;
END$$;

-- Add status column to domains, skills, questions if missing
ALTER TABLE IF EXISTS public.domains
  ADD COLUMN IF NOT EXISTS status public.content_status DEFAULT 'draft'::public.content_status NOT NULL;

ALTER TABLE IF EXISTS public.skills
  ADD COLUMN IF NOT EXISTS status public.content_status DEFAULT 'draft'::public.content_status NOT NULL;

ALTER TABLE IF EXISTS public.questions
  ADD COLUMN IF NOT EXISTS status public.content_status DEFAULT 'draft'::public.content_status NOT NULL;

-- Populate status from existing is_published flag for existing rows
UPDATE public.domains SET status = CASE WHEN is_published THEN 'published' ELSE 'draft' END WHERE status IS NULL;
UPDATE public.skills SET status = CASE WHEN is_published THEN 'published' ELSE 'draft' END WHERE status IS NULL;
UPDATE public.questions SET status = CASE WHEN is_published THEN 'published' ELSE 'draft' END WHERE status IS NULL;

-- Create a function to keep is_published in sync with status
CREATE OR REPLACE FUNCTION public.sync_is_published_with_status()
RETURNS trigger AS $$
BEGIN
  -- Ensure is_published is true exactly when status = 'published'
  IF (NEW.status IS NOT NULL) THEN
    NEW.is_published := (NEW.status = 'published');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to keep columns in sync on insert or update
DROP TRIGGER IF EXISTS trg_sync_status_to_published ON public.domains;
CREATE TRIGGER trg_sync_status_to_published
  BEFORE INSERT OR UPDATE ON public.domains
  FOR EACH ROW EXECUTE FUNCTION public.sync_is_published_with_status();

DROP TRIGGER IF EXISTS trg_sync_status_to_published_skills ON public.skills;
CREATE TRIGGER trg_sync_status_to_published_skills
  BEFORE INSERT OR UPDATE ON public.skills
  FOR EACH ROW EXECUTE FUNCTION public.sync_is_published_with_status();

DROP TRIGGER IF EXISTS trg_sync_status_to_published_questions ON public.questions;
CREATE TRIGGER trg_sync_status_to_published_questions
  BEFORE INSERT OR UPDATE ON public.questions
  FOR EACH ROW EXECUTE FUNCTION public.sync_is_published_with_status();

-- Backfill is_published for rows where it might be NULL (defensive)
UPDATE public.domains SET is_published = (status = 'published') WHERE is_published IS NULL;
UPDATE public.skills SET is_published = (status = 'published') WHERE is_published IS NULL;
UPDATE public.questions SET is_published = (status = 'published') WHERE is_published IS NULL;
