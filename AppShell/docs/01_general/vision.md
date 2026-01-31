# AppShell - Product Vision

## 1. Executive Summary
* **The Pitch:** AppShell is an offline-first educational platform that enables students to practice skills through interactive questions while allowing administrators to manage curriculum content seamlessly.
* **Current Problem:** Traditional learning platforms require constant internet connectivity and lack robust offline capabilities, making them unsuitable for environments with unreliable network access. Content management is often cumbersome and not optimized for educational workflows.
* **Proposed Solution:** A dual-app system with a Flutter-based student app for offline learning and a React-based admin panel for content management, backed by Supabase for data synchronization and real-time updates.

## 2. Strategic Objectives
* **Primary Goal:** Deliver a reliable, offline-capable learning platform that ensures zero data loss and consistent user experience regardless of connectivity.
* **Secondary Goals:**
    * Enable efficient curriculum management for administrators
    * Provide comprehensive progress tracking and analytics
    * Support scalable content creation and publishing workflows

## 3. Target Audience
* **Primary User:** Students using tablets for skill practice in offline or low-connectivity environments
* **Secondary User:** Administrators and educators managing curriculum content and monitoring student progress

## 4. Scope & Boundaries
* **In Scope (MVP):** Student app with offline question practice, admin panel for CRUD operations on domains/skills/questions, Supabase backend with RLS, basic progress tracking and mastery calculation.
* **Out of Scope:** Advanced analytics dashboards, multi-tenant support, integration with external LMS systems, video content support, advanced gamification features beyond basic streaks.

## 5. Success Metrics (KPIs)
* System load time under 2 seconds for question transitions
* Zero data loss during sync operations
* 99.9% uptime for admin panel
* Successful offline-to-online sync in under 30 seconds for typical usage