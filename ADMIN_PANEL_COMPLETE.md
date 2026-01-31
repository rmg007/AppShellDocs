# ADMIN_PANEL_COMPLETE.md - Complete React Admin Panel Guide

> **CRITICAL**: Complete reference for building the Admin Panel
> **Last Updated**: 2026-01-31
> **Read First**: Review AGENT_MASTER.md before implementing

---

## Quick Reference Card

**File Purpose**: Complete React implementation guide - components, store, caching, and publish workflow.

**When to use this file**:
- Building React UI components or screens
- Implementing data fetching (React Query)
- Adding new form schemas (Zod)
- Managing global state (Auth, UI)

**Critical sections**: §3 (Project Structure), §4 (Core Patterns), §6 (Publish Workflow)

**Common tasks**:
- Create new page → Section 4.3 (Screen Pattern)
- Add data fetch → Section 4.2 (React Query Pattern)
- Add form → Section 5 (Forms & Validation)
- Handle auth → Section 4.1 (Auth Pattern)

**Quick validation**:
```bash
npm run type-check && npm run lint
```

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Project Structure](#2-project-structure)
3. [Core Patterns](#3-core-patterns)
4. [Feature Implementation](#4-feature-implementation)
5. [Forms & Validation](#5-forms--validation)
6. [Publish Workflow](#6-publish-workflow)
7. [Error Handling](#7-error-handling)

---

## 1. Tech Stack

### Dependencies (LOCKED - DO NOT CHANGE)

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.3",
    
    // State & Async
    "@tanstack/react-query": "^5.17.0",
    "zustand": "^4.5.0",
    
    // UI System
    "tailwindcss": "^3.4.1",
    "lucide-react": "^0.314.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.1",
    "@radix-ui/react-slot": "^1.0.2",
    
    // Forms
    "react-hook-form": "^7.49.3",
    "@hookform/resolvers": "^3.3.4",
    "zod": "^3.22.4",
    
    // Backend
    "@supabase/supabase-js": "^2.39.3",
    
    // Utils
    "date-fns": "^3.3.1",
    "sonner": "^1.3.1"
  },
  "devDependencies": {
    "vite": "^5.0.12",
    "typescript": "^5.3.3"
  }
}
```

---

## 2. Project Structure

```
src/
├── components/
│   ├── ui/                    # shadcn/ui primitives (button, input, etc.)
│   ├── layout/                # Sidebar, Header, PageShell
│   └── shared/                # TextEditor, DeleteConfirmDialog
│
├── features/
│   ├── auth/                  # Login, ProtectedRoute
│   ├── curriculum/            # Domains, Skills, Questions
│   │   ├── components/        # Feature-specific components
│   │   ├── hooks/             # Data hooks (useDomains, useSkills)
│   │   └── pages/             # Route components
│   └── publish/               # Publish workflow
│
├── lib/
│   ├── supabase.ts            # Typed client
│   ├── query-client.ts        # React Query config
│   └── utils.ts               # cn() helper
│
├── store/
│   └── use-auth-store.ts      # Global auth state
│
├── types/
│   └── database.types.ts      # Generated Supabase types
│
├── App.tsx                    # Routes
└── main.tsx                   # Providers (QueryClient, Toaster)
```

---

## 3. Core Patterns

### 3.1 Supabase Client (Typed)

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/database.types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient<Database>(supabaseUrl, supabaseKey);
```

### 3.2 React Query Pattern (Custom Hooks)

**ALWAYS** wrap queries in custom hooks. **NEVER** use `useQuery` directly in components.

```typescript
// src/features/curriculum/hooks/use-domains.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';

export function useDomains() {
  return useQuery({
    queryKey: ['domains'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('domains')
        .select('*')
        .order('sort_order');
        
      if (error) throw error;
      return data;
    }
  });
}

export function useCreateDomain() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (input: { title: string; slug: string }) => {
      const { data, error } = await supabase
        .from('domains')
        .insert(input)
        .select()
        .single();
        
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
      toast.success('Domain created');
    },
    onError: (error) => {
      toast.error(error.message);
    }
  });
}
```

### 3.3 Screen Pattern (PageShell)

```typescript
// src/features/curriculum/pages/domains-page.tsx
import { PageShell } from '@/components/layout/page-shell';
import { Button } from '@/components/ui/button';
import { useDomains } from '../hooks/use-domains';
import { DomainCard } from '../components/domain-card';

export default function DomainsPage() {
  const { data: domains, isLoading } = useDomains();

  return (
    <PageShell 
      title="Curriculum Domains" 
      description="Manage top-level subjects"
      actions={
        <Button>
          <PlusIcon className="mr-2 h-4 w-4" />
          New Domain
        </Button>
      }
    >
      {isLoading ? (
        <LoadingSkeleton />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {domains?.map((domain) => (
            <DomainCard key={domain.id} domain={domain} />
          ))}
        </div>
      )}
    </PageShell>
  );
}
```

---

## 4. Feature Implementation

### 4.1 Auth Context (Zustand + Supabase)

```typescript
// src/store/use-auth-store.ts
import { create } from 'zustand';
import { Session, User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

interface AuthState {
  session: Session | null;
  user: User | null;
  initialized: boolean;
  initialize: () => Promise<void>;
  signOut: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  user: null,
  initialized: false,
  
  initialize: async () => {
    // Get initial session
    const { data: { session } } = await supabase.auth.getSession();
    set({ session, user: session?.user ?? null, initialized: true });

    // Listen for changes
    supabase.auth.onAuthStateChange((_event, session) => {
      set({ session, user: session?.user ?? null });
    });
  },
  
  signOut: async () => {
    await supabase.auth.signOut();
    set({ session: null, user: null });
  }
}));
```

### 4.2 Protected Route

```typescript
// src/features/auth/protected-route.tsx
import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '@/store/use-auth-store';

export function ProtectedRoute() {
  const { user, initialized } = useAuthStore();

  if (!initialized) return <div>Loading...</div>;

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}
```

---

## 5. Forms & Validation

### 5.1 Zod Schema + React Hook Form

```typescript
// src/features/curriculum/components/domain-form.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Button } from '@/components/ui/button';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';

const domainSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 chars'),
  slug: z.string().regex(/^[a-z0-9_]+$/, 'Slug must be lowercase alphanumeric'),
  description: z.string().optional(),
});

type DomainFormValues = z.infer<typeof domainSchema>;

export function DomainForm({ onSubmit }: { onSubmit: (data: DomainFormValues) => void }) {
  const form = useForm<DomainFormValues>({
    resolver: zodResolver(domainSchema),
    defaultValues: {
      title: '',
      slug: '',
      description: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="title"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Title</FormLabel>
              <FormControl>
                <Input placeholder="Mathematics" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="slug"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Slug</FormLabel>
              <FormControl>
                <Input placeholder="mathematics" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Save Domain</Button>
      </form>
    </Form>
  );
}
```

---

## 6. Publish Workflow

### 6.1 Status Badge Component

```typescript
// src/components/shared/status-badge.tsx
import { Badge } from '@/components/ui/badge';

export function StatusBadge({ status }: { status: 'draft' | 'live' }) {
  return (
    <Badge 
      variant={status === 'live' ? 'success' : 'secondary'}
    >
      {status === 'live' ? 'Publised' : 'Draft'}
    </Badge>
  );
}
```

### 6.2 Publish Action

```typescript
// src/features/curriculum/hooks/use-publish.ts
export function usePublishDomain() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('domains')
        .update({ status: 'live' })
        .eq('id', id);
        
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
      toast.success('Domain published');
    }
  });
}
```

---

## 7. Error Handling

### 7.1 Global Error Boundary

Use `react-error-boundary` or simple class component to catch render errors.

### 7.2 API Error Handling

React Query handles loading/error states. Use `sonner` / `toast` for user feedback.

```typescript
const { isError, error } = useDomains();

if (isError) {
  return (
    <div className="p-4 border border-red-200 bg-red-50 text-red-900 rounded">
      Error loading domains: {error.message}
    </div>
  );
}
```

---

**END OF ADMIN_PANEL_COMPLETE.md**
