# System Architecture Overview

## 1. Design Philosophy
* **Core Principle:** Offline-First, Local-First data architecture with cloud synchronization. All user data is stored locally first, with conflict-free replication to the cloud.
* **Constraint:** Must run on tablets without admin rights, support anonymous authentication, and handle network interruptions gracefully.

## 2. Technology Stack
| Layer | Technology | Version | Rationale |
| :--- | :--- | :--- | :--- |
| **Student App (Frontend)** | Flutter | >= 3.19.0 | Cross-platform mobile development with excellent offline support and native performance |
| **Admin Panel (Frontend)** | React | 18.2 | Mature ecosystem for complex admin interfaces with TypeScript support |
| **State Management (Student)** | Riverpod | ^2.5.0 | Declarative state management optimized for Flutter |
| **State Management (Admin)** | React Query | ^5.17.0 | Server state management with caching and synchronization |
| **Local Database (Student)** | Drift | ^2.15.0 | SQLite wrapper for Flutter with type-safe queries |
| **Backend** | Supabase | Latest | PostgreSQL with real-time subscriptions, authentication, and edge functions |
| **Backend Client (Student)** | supabase_flutter | ^2.0.0 | Official Flutter client with offline sync capabilities |
| **Backend Client (Admin)** | @supabase/supabase-js | ^2.39.0 | JavaScript client for admin operations |

## 3. High-Level Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Student App   │    │   Admin Panel   │    │     Supabase    │
│   (Flutter)     │◄──►│    (React)      │◄──►│  (PostgreSQL)   │
│                 │    │                 │    │                 │
│ • Local Drift DB│    │ • React Query   │    │ • Auth/RBAC     │
│ • Offline Sync  │    │ • CRUD Forms    │    │ • Real-time     │
│ • Anonymous Auth│    │ • Admin Auth    │    │ • RLS Policies  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Sync Layer    │
                    │ • Conflict Res. │
                    │ • Delta Sync    │
                    │ • Outbox Queue  │
                    └─────────────────┘
```
* **Flow:** Student actions → Local DB → Outbox → Sync to Supabase → Admin views real-time updates

## 4. Integration Points
* **External APIs:** None in MVP (Supabase handles all backend needs)
* **File Systems:** Local storage on device for offline data, no external file I/O

## 5. Security & Compliance
* **Authentication:** Anonymous auth for students (device-bound), email/password for admins
* **Data Protection:** RLS policies enforce access control, all data encrypted in transit and at rest via Supabase
* **Authorization:** Role-based access (student vs admin) enforced at database level