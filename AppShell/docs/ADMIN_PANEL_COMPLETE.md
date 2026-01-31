# ADMIN_PANEL_COMPLETE.md - Complete React Admin Panel Guide

> **CRITICAL**: Complete reference for building the React admin panel
> **Last Updated**: 2026-01-31  
> **Read First**: Review [AGENTS.md](AGENTS.md) and [ADMIN_PANEL_SPEC.md](specs/ADMIN_PANEL_SPEC.md) before implementing
---

## Quick Reference Card

**File Purpose**: Complete React admin panel guide - forms, hooks, auth, and shadcn/ui setup.

**When to use this file**:
- Building admin CRUD forms
- Setting up React Query hooks
- Implementing admin authentication

**Critical sections**: §2 (Critical CSS Setup), §4 (Core Patterns), §5 (Feature Implementation)

**Common tasks**:
- Initialize shadcn/ui (REQUIRED first) → Section 2 (Critical CSS Setup)
- Create CRUD form → Section 5.1 (CRUD Form Pattern)
- Add React Query hook → Section 4.3 (React Query Hook Pattern)
- Implement status cascade → Section 5.3 (Status Cascade Implementation)
- Add rich text editor → Section 4.5 (Rich Text Editor Setup)

**Quick validation**:
```bash
# Verify CSS variables exist and build succeeds
grep "--background:" src/index.css && npm run build

# Run Phase 3 validation (after implementation)
.\scripts\validate-phase-3.ps1
```

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Critical CSS Setup](#2-critical-css-setup)
3. [Project Structure](#3-project-structure)
4. [Core Patterns](#4-core-patterns)
5. [Feature Implementation](#5-feature-implementation)
6. [Auth & Security](#6-auth--security)

---

## 1. Tech Stack

### Dependencies (LOCKED - DO NOT CHANGE)

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.0",
    "@tanstack/react-query": "^5.17.0",
    "@supabase/supabase-js": "^2.39.0",
    "react-hook-form": "^7.49.0",
    "@hookform/resolvers": "^3.3.0",
    "zod": "^3.22.0",
    "@sentry/react": "^7.92.0",
    "lucide-react": "^0.303.0",
    "tailwindcss": "^3.4.0",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-toast": "^1.1.5",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0"
  }
}
```

---

## 2. Critical CSS Setup

### BEFORE ANY COMPONENTS: Initialize shadcn/ui

```bash
npx shadcn-ui@latest init
```

**Answer prompts EXACTLY**:
- TypeScript? → yes
- Style? → Default
- Base color? → Slate
- Global CSS? → src/index.css
- CSS variables? → yes
- tailwind.config.js? → tailwind.config.js
- Import alias components? → @/components
- Import alias utils? → @/lib/utils
- React Server Components? → no

### Verify index.css (CRITICAL)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    /* ... (rest of dark mode variables) */
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

### Verify tailwind.config.js

```javascript
module.exports = {
  darkMode: ["class"],
  content: [
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        /* ... (rest of colors) */
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
```

**Checklist**:
- [ ] `src/index.css` has all CSS variables
- [ ] `tailwind.config.js` has `colors` mapping
- [ ] `tailwindcss-animate` installed and in plugins
- [ ] `darkMode: ["class"]` at top of config

---

## 3. Project Structure

```
src/
├── main.tsx                       # Entry point, Sentry init
├── App.tsx                        # Router setup
├── index.css                      # Global styles, Tailwind imports
│
├── components/
│   ├── ui/                        # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── select.tsx
│   │   ├── dialog.tsx
│   │   ├── toast.tsx
│   │   ├── card.tsx
│   │   ├── table.tsx
│   │   └── badge.tsx
│   ├── forms/
│   │   ├── domain-form.tsx
│   │   ├── skill-form.tsx
│   │   └── question-form.tsx
│   └── layout/
│       ├── app-layout.tsx
│       ├── sidebar.tsx
│       └── header.tsx
│
├── features/
│   ├── auth/
│   │   ├── login-page.tsx
│   │   ├── auth-provider.tsx
│   │   └── protected-route.tsx
│   ├── domains/
│   │   ├── domains-page.tsx
│   │   ├── domain-detail-page.tsx
│   │   └── components/
│   ├── skills/
│   │   ├── skills-page.tsx
│   │   └── components/
│   ├── questions/
│   │   ├── questions-page.tsx
│   │   ├── question-editor.tsx
│   │   ├── question-preview.tsx
│   │   └── components/
│   │       ├── multiple-choice-editor.tsx
│   │       ├── mcq-multi-editor.tsx
│   │       ├── text-input-editor.tsx
│   │       ├── boolean-editor.tsx
│   │       └── reorder-steps-editor.tsx
│   ├── publishing/
│   │   ├── publish-center-page.tsx
│   │   └── components/
│   └── import-export/
│       ├── import-page.tsx
│       └── export-page.tsx
│
├── hooks/
│   ├── use-domains.ts
│   ├── use-skills.ts
│   ├── use-questions.ts
│   ├── use-publish.ts
│   └── use-auth.ts
│
├── lib/
│   ├── supabase.ts               # Supabase client
│   ├── auth.ts                   # Auth utilities
│   ├── database.types.ts         # Generated Supabase types
│   └── utils.ts                  # cn() helper, etc.
│
├── schemas/                      # Zod validation schemas
│   ├── domain.schema.ts
│   ├── skill.schema.ts
│   └── question.schema.ts
│
├── pages/                        # Route components
│   ├── index.tsx                 # Dashboard
│   ├── login.tsx
│   ├── domains/
│   │   ├── index.tsx
│   │   └── [id].tsx
│   ├── skills/
│   │   └── [id].tsx
│   ├── questions/
│   │   └── [id].tsx
│   └── publish.tsx
│
└── utils/
    ├── format.ts
    └── export.ts
```

---

## 4. Core Patterns

### 4.1 Supabase Client Setup

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

### 4.2 React Query Setup

```typescript
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 3,
    },
  },
});

root.render(
  <QueryClientProvider client={queryClient}>
    <App />
  </QueryClientProvider>
);
```

### 4.3 React Query Hook Pattern

```typescript
// hooks/use-domains.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { domainSchema } from '@/lib/schemas';
import { z } from 'zod';

type Domain = z.infer<typeof domainSchema>;

export function useDomains() {
  return useQuery({
    queryKey: ['domains'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('domains')
        .select('*')
        .is('deleted_at', null)
        .order('sort_order');

      if (error) throw error;
      return data as Domain[];
    },
  });
}

export function useCreateDomain() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (domain: Omit<Domain, 'id' | 'created_at' | 'updated_at'>) => {
      const { data, error } = await supabase
        .from('domains')
        .insert(domain)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
    },
  });
}

export function useUpdateDomain() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Domain> }) => {
      const { data, error } = await supabase
        .from('domains')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
    },
  });
}

export function useDeleteDomain() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('domains')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
    },
  });
}
```

### 4.4 Zod Schema Pattern

```typescript
// lib/schemas.ts
import { z } from 'zod';

export const domainSchema = z.object({
  id: z.string().uuid(),
  slug: z.string().regex(/^[a-z0-9_]+$/),
  title: z.string().min(1),
  description: z.string().nullable(),
  sort_order: z.number().int(),
  is_published: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
  deleted_at: z.string().nullable(),
});

export const domainInsertSchema = domainSchema.omit({
  id: true,
  created_at: true,
  updated_at: true,
  deleted_at: true,
});

export const skillSchema = z.object({
  id: z.string().uuid(),
  domain_id: z.string().uuid(),
  slug: z.string().regex(/^[a-z0-9_]+$/),
  title: z.string().min(1),
  description: z.string().nullable(),
  difficulty_level: z.number().int().min(1).max(5),
  sort_order: z.number().int(),
  is_published: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
  deleted_at: z.string().nullable(),
});

export const questionSchema = z.object({
  id: z.string().uuid(),
  skill_id: z.string().uuid(),
  type: z.enum(['multiple_choice', 'mcq_multi', 'text_input', 'boolean', 'reorder_steps']),
  content: z.string().min(1, 'Question text is required'),
  options: z.object({}).passthrough(), // Type-specific validation
  solution: z.object({}).passthrough(), // Type-specific validation
  explanation: z.string().optional(),
  points: z.number().int().min(1).default(1),
  is_published: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
  deleted_at: z.string().nullable(),
});
```

### 4.5 Rich Text Editor Setup (TipTap)

**CRITICAL**: Questions use rich text for `content` and `explanation` fields

#### Installation

```bash
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-underline @tiptap/extension-placeholder
```

#### TipTap Component

```typescript
// components/ui/rich-text-editor.tsx
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Underline from '@tiptap/extension-underline';
import Placeholder from '@tiptap/extension-placeholder';
import { Button } from './button';
import {
  Bold,
  Italic,
  Underline as UnderlineIcon,
  List,
  ListOrdered,
  Heading2,
} from 'lucide-react';

interface RichTextEditorProps {
  content: string;
  onChange: (html: string) => void;
  placeholder?: string;
}

export function RichTextEditor({ content, onChange, placeholder }: RichTextEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      Underline,
      Placeholder.configure({
        placeholder: placeholder || 'Start typing...',
      }),
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  if (!editor) {
    return null;
  }

  return (
    <div className="border rounded-md">
      {/* Toolbar */}
      <div className="flex gap-1 p-2 border-b bg-muted/50">
        <Button
          type="button"
          size="sm"
          variant={editor.isActive('bold') ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleBold().run()}
        >
          <Bold className="h-4 w-4" />
        </Button>

        <Button
          type="button"
          size="sm"
          variant={editor.isActive('italic') ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleItalic().run()}
        >
          <Italic className="h-4 w-4" />
        </Button>

        <Button
          type="button"
          size="sm"
          variant={editor.isActive('underline') ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleUnderline().run()}
        >
          <UnderlineIcon className="h-4 w-4" />
        </Button>

        <div className="w-px h-6 bg-border mx-1" />

        <Button
          type="button"
          size="sm"
          variant={editor.isActive('heading', { level: 2 }) ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        >
          <Heading2 className="h-4 w-4" />
        </Button>

        <Button
          type="button"
          size="sm"
          variant={editor.isActive('bulletList') ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleBulletList().run()}
        >
          <List className="h-4 w-4" />
        </Button>

        <Button
          type="button"
          size="sm"
          variant={editor.isActive('orderedList') ? 'default' : 'ghost'}
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
        >
          <ListOrdered className="h-4 w-4" />
        </Button>
      </div>

      {/* Editor */}
      <EditorContent
        editor={editor}
        className="prose prose-sm max-w-none p-4 min-h-[200px] focus:outline-none"
      />
    </div>
  );
}
```

#### Usage in Question Form

```typescript
// components/forms/question-form.tsx
import { RichTextEditor } from '@/components/ui/rich-text-editor';
import { useForm, Controller } from 'react-hook-form';

export function QuestionForm({ question, onSuccess }: QuestionFormProps) {
  const form = useForm<FormData>({
    defaultValues: {
      content: question?.content || '',
      explanation: question?.explanation || '',
      // ... other fields
    },
  });

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* Question Content */}
      <div>
        <label>Question Content</label>
        <Controller
          name="content"
          control={form.control}
          render={({ field }) => (
            <RichTextEditor
              content={field.value}
              onChange={field.onChange}
              placeholder="Enter the question..."
            />
          )}
        />
      </div>

      {/* Explanation */}
      <div>
        <label>Explanation (shown after answering)</label>
        <Controller
          name="explanation"
          control={form.control}
          render={({ field }) => (
            <RichTextEditor
              content={field.value || ''}
              onChange={field.onChange}
              placeholder="Explain the answer..."
            />
          )}
        />
      </div>

      {/* ... rest of form */}
    </form>
  );
}
```

#### TipTap Styling (Add to index.css)

```css
/* Prose styling for TipTap content */
.ProseMirror {
  outline: none;
}

.ProseMirror p.is-editor-empty:first-child::before {
  color: #adb5bd;
  content: attr(data-placeholder);
  float: left;
  height: 0;
  pointer-events: none;
}

.ProseMirror h2 {
  font-size: 1.5em;
  font-weight: 700;
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.ProseMirror ul,
.ProseMirror ol {
  padding-left: 1.5em;
  margin: 0.5em 0;
}

.ProseMirror strong {
  font-weight: 700;
}

.ProseMirror em {
  font-style: italic;
}

.ProseMirror u {
  text-decoration: underline;
}
```

---

## 5. Feature Implementation

### 5.1 CRUD Form Pattern (Create/Edit/Delete in ONE Component)

```typescript
// components/forms/domain-form.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useCreateDomain, useUpdateDomain, useDeleteDomain } from '@/hooks/use-domains';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { toast } from 'sonner';

const formSchema = z.object({
  slug: z.string().regex(/^[a-z0-9_]+$/),
  title: z.string().min(1),
  description: z.string().optional(),
  sort_order: z.number().int(),
  is_published: z.boolean(),
});

type FormData = z.infer<typeof formSchema>;

interface DomainFormProps {
  domain?: Domain;  // If editing
  onSuccess: () => void;
}

export function DomainForm({ domain, onSuccess }: DomainFormProps) {
  const isEditMode = !!domain;

  const createDomain = useCreateDomain();
  const updateDomain = useUpdateDomain();
  const deleteDomain = useDeleteDomain();

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: domain || {
      slug: '',
      title: '',
      description: '',
      sort_order: 0,
      is_published: false,
    },
  });

  const onSubmit = async (data: FormData) => {
    try {
      if (isEditMode) {
        await updateDomain.mutateAsync({ id: domain.id, updates: data });
        toast.success('Domain updated');
      } else {
        await createDomain.mutateAsync(data);
        toast.success('Domain created');
      }
      onSuccess();
    } catch (error) {
      toast.error('Failed to save domain');
    }
  };

  const handleDelete = async () => {
    if (!isEditMode) return;
    if (!confirm('Delete this domain?')) return;

    try {
      await deleteDomain.mutateAsync(domain.id);
      toast.success('Domain deleted');
      onSuccess();
    } catch (error) {
      toast.error('Failed to delete domain');
    }
  };

  const isPending = createDomain.isPending || updateDomain.isPending || deleteDomain.isPending;

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label>Slug</label>
        <Input {...form.register('slug')} placeholder="mathematics" />
        {form.formState.errors.slug && (
          <p className="text-sm text-destructive">{form.formState.errors.slug.message}</p>
        )}
      </div>

      <div>
        <label>Title</label>
        <Input {...form.register('title')} placeholder="Mathematics" />
      </div>

      <div>
        <label>Description</label>
        <Input {...form.register('description')} placeholder="Optional description" />
      </div>

      <div>
        <label>Sort Order</label>
        <Input type="number" {...form.register('sort_order', { valueAsNumber: true })} />
      </div>

      <div>
        <label>Published</label>
        <input type="checkbox" {...form.register('is_published')} />
      </div>

      <div className="flex gap-2">
        <Button type="submit" disabled={isPending}>
          {isEditMode ? 'Update' : 'Create'}
        </Button>

        {isEditMode && (
          <Button type="button" variant="destructive" onClick={handleDelete} disabled={isPending}>
            Delete
          </Button>
        )}
      </div>
    </form>
  );
}
```

### 5.2 List Page Pattern

```typescript
// features/domains/domains-page.tsx
import { useState } from 'react';
import { useDomains } from '@/hooks/use-domains';
import { Button } from '@/components/ui/button';
import { Dialog } from '@/components/ui/dialog';
import { DomainForm } from '@/components/forms/domain-form';

export function DomainsPage() {
  const { data: domains, isLoading, error } = useDomains();
  const [showDialog, setShowDialog] = useState(false);
  const [editingDomain, setEditingDomain] = useState<Domain | null>(null);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Domains</h1>
        <Button onClick={() => { setEditingDomain(null); setShowDialog(true); }}>
          Create Domain
        </Button>
      </div>

      <div className="grid gap-4">
        {domains?.map((domain) => (
          <div key={domain.id} className="border rounded p-4 flex justify-between items-center">
            <div>
              <h3 className="font-semibold">{domain.title}</h3>
              <p className="text-sm text-muted-foreground">{domain.description}</p>
              <div className="flex gap-2 mt-2">
                <Badge variant={domain.is_published ? 'default' : 'secondary'}>
                  {domain.is_published ? 'Published' : 'Draft'}
                </Badge>
              </div>
            </div>
            <Button variant="outline" onClick={() => { setEditingDomain(domain); setShowDialog(true); }}>
              Edit
            </Button>
          </div>
        ))}
      </div>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DomainForm
          domain={editingDomain || undefined}
          onSuccess={() => setShowDialog(false)}
        />
      </Dialog>
    </div>
  );
}
```

### 5.3 Status Cascade Implementation

**CRITICAL**: When updating domain/skill status, cascade to children

#### Cascade Hooks

```typescript
// hooks/use-cascade-status.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';

export function useCascadeDomainStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      domainId,
      newStatus
    }: {
      domainId: string;
      newStatus: boolean
    }) => {
      // Start transaction-like update
      // 1. Update domain
      const { error: domainError } = await supabase
        .from('domains')
        .update({ is_published: newStatus })
        .eq('id', domainId);

      if (domainError) throw domainError;

      // 2. Get all skills under this domain
      const { data: skills, error: skillsError } = await supabase
        .from('skills')
        .select('id')
        .eq('domain_id', domainId);

      if (skillsError) throw skillsError;

      // 3. Update all skills
      if (skills && skills.length > 0) {
        const { error: skillUpdateError } = await supabase
          .from('skills')
          .update({ is_published: newStatus })
          .eq('domain_id', domainId);

        if (skillUpdateError) throw skillUpdateError;

        // 4. Update all questions under those skills
        const skillIds = skills.map(s => s.id);
        const { error: questionError } = await supabase
          .from('questions')
          .update({ is_published: newStatus })
          .in('skill_id', skillIds);

        if (questionError) throw questionError;
      }
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
      queryClient.invalidateQueries({ queryKey: ['skills'] });
      queryClient.invalidateQueries({ queryKey: ['questions'] });

      toast.success(`Domain set to ${variables.newStatus ? 'published' : 'draft'} (cascaded to all children)`);
    },
    onError: (error) => {
      toast.error('Failed to update status');
      console.error(error);
    },
  });
}

export function useCascadeSkillStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      skillId,
      newStatus
    }: {
      skillId: string;
      newStatus: boolean
    }) => {
      // 1. Update skill
      const { error: skillError } = await supabase
        .from('skills')
        .update({ is_published: newStatus })
        .eq('id', skillId);

      if (skillError) throw skillError;

      // 2. Update all questions under this skill
      const { error: questionError } = await supabase
        .from('questions')
        .update({ is_published: newStatus })
        .eq('skill_id', skillId);

      if (questionError) throw questionError;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['skills'] });
      queryClient.invalidateQueries({ queryKey: ['questions'] });

      toast.success(`Skill set to ${variables.newStatus ? 'published' : 'draft'} (cascaded to all questions)`);
    },
    onError: (error) => {
      toast.error('Failed to update status');
      console.error(error);
    },
  });
}
```

#### Usage in Forms

```typescript
// components/forms/domain-form.tsx (Updated)
import { useCascadeDomainStatus } from '@/hooks/use-cascade-status';

export function DomainForm({ domain, onSuccess }: DomainFormProps) {
  const cascadeStatus = useCascadeDomainStatus();

  const handleStatusChange = async (newStatus: boolean) => {
    if (!domain) return;

    // Confirm cascade
    const confirmed = confirm(
      `Change status to ${newStatus ? 'published' : 'draft'}? This will also change all skills and questions under this domain.`
    );

    if (!confirmed) return;

    await cascadeStatus.mutateAsync({
      domainId: domain.id,
      newStatus,
    });
  };

  return (
    <form>
      {/* ... other fields */}

      <div>
        <label>Published</label>
        <input
          type="checkbox"
          checked={form.watch('is_published')}
          onChange={(e) => {
            if (isEditMode) {
              // Use cascade for existing domains
              handleStatusChange(e.target.checked);
            } else {
              // Direct update for new domains
              form.setValue('is_published', e.target.checked);
            }
          }}
        />
        {isEditMode && (
          <p className="text-sm text-muted-foreground mt-1">
            ⚠️ Changing status will cascade to all skills and questions
          </p>
        )}
      </div>
    </form>
  );
}
```

#### Alternative: Database-Side Cascade (Recommended)

**Create a database trigger for automatic cascade**:

```sql
-- Add to DATABASE_COMPLETE.md section
CREATE OR REPLACE FUNCTION cascade_domain_status()
RETURNS TRIGGER AS $$
BEGIN
  -- If domain status changed, cascade to children
  IF NEW.is_published IS DISTINCT FROM OLD.is_published THEN
    -- Update skills
    UPDATE public.skills
    SET is_published = NEW.is_published, updated_at = NOW()
    WHERE domain_id = NEW.id;

    -- Update questions (via skills)
    UPDATE public.questions
    SET is_published = NEW.is_published, updated_at = NOW()
    WHERE skill_id IN (
      SELECT id FROM public.skills WHERE domain_id = NEW.id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cascade_domain_status
  AFTER UPDATE ON public.domains
  FOR EACH ROW
  EXECUTE FUNCTION cascade_domain_status();
```

**If using database triggers, update the mutation**:

```typescript
// Simplified - trigger handles cascade
export function useUpdateDomain() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Domain> }) => {
      const { data, error } = await supabase
        .from('domains')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      // Database trigger handles cascade, just invalidate caches
      queryClient.invalidateQueries({ queryKey: ['domains'] });
      queryClient.invalidateQueries({ queryKey: ['skills'] });
      queryClient.invalidateQueries({ queryKey: ['questions'] });

      toast.success('Domain updated (changes cascaded)');
    },
  });
}
```

---

## 6. Auth & Security

### 6.1 Auth Hook

```typescript
// hooks/use-auth.ts
import { useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  return { user, session, loading };
}
```

### 6.2 Protected Route

```typescript
// features/auth/protected-route.tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/use-auth';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);

  useEffect(() => {
    if (user) {
      // Check if user is admin
      supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
        .then(({ data }) => {
          setIsAdmin(data?.role === 'admin' || data?.role === 'super_admin');
        });
    }
  }, [user]);

  if (loading || isAdmin === null) {
    return <div>Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (!isAdmin) {
    return <div>Unauthorized: Admin access required</div>;
  }

  return <>{children}</>;
}
```

### 6.3 Login Page

```typescript
// features/auth/login-page.tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardContent } from '@/components/ui/card';
import { toast } from 'sonner';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      navigate('/');
    } catch (error) {
      toast.error('Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40">
      <Card className="w-full max-w-md">
        <CardHeader>
          <h1 className="text-2xl font-bold">Admin Login</h1>
          <p className="text-sm text-muted-foreground">Sign in to manage curriculum</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label>Email</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div>
              <label>Password</label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            <Button type="submit" className="w-full" disabled={loading}>
              Sign In
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
```

### 6.3 Optimistic Updates Pattern

**Purpose**: Update UI immediately, rollback on error

```typescript
// hooks/use-domains.ts (with optimistic updates)
export function useUpdateDomain() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Domain> }) => {
      const { data, error } = await supabase
        .from('domains')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    // Optimistic update
    onMutate: async ({ id, updates }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['domains'] });

      // Snapshot previous value
      const previousDomains = queryClient.getQueryData<Domain[]>(['domains']);

      // Optimistically update
      queryClient.setQueryData<Domain[]>(['domains'], (old) => {
        if (!old) return [];
        return old.map(domain =>
          domain.id === id
            ? { ...domain, ...updates }
            : domain
        );
      });

      // Return context with snapshot
      return { previousDomains };
    },
    // Rollback on error
    onError: (err, variables, context) => {
      if (context?.previousDomains) {
        queryClient.setQueryData(['domains'], context.previousDomains);
      }
      toast.error('Update failed');
    },
    // Always refetch after success or error
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['domains'] });
    },
  });
}
```

### 6.4 Invitation Code UI (Super Admin)

#### Generate Invitation Code Dialog

```typescript
// features/invitations/components/generate-code-dialog.tsx
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from 'sonner';
import { Copy, Check } from 'lucide-react';

export function GenerateCodeDialog({ open, onOpenChange }: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const [email, setEmail] = useState('');
  const [expiresInDays, setExpiresInDays] = useState(7);
  const [generatedCode, setGeneratedCode] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    setLoading(true);
    try {
      const { data: code, error } = await supabase.rpc('generate_invitation_code', {
        p_email: email || null,
        p_expires_in_days: expiresInDays,
      });

      if (error) throw error;

      setGeneratedCode(code as string);
      toast.success('Invitation code generated');
    } catch (error) {
      toast.error('Failed to generate code');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    if (generatedCode) {
      navigator.clipboard.writeText(generatedCode);
      setCopied(true);
      toast.success('Code copied to clipboard');
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Generate Invitation Code</DialogTitle>
        </DialogHeader>

        {!generatedCode ? (
          <div className="space-y-4">
            <div>
              <label>Email (Optional)</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="newadmin@example.com"
              />
              <p className="text-sm text-muted-foreground mt-1">
                If provided, only this email can use the code
              </p>
            </div>

            <div>
              <label>Expires In (Days)</label>
              <Input
                type="number"
                value={expiresInDays}
                onChange={(e) => setExpiresInDays(parseInt(e.target.value))}
                min={1}
                max={365}
              />
            </div>

            <Button onClick={handleGenerate} disabled={loading} className="w-full">
              Generate Code
            </Button>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground mb-2">Invitation Code:</p>
              <p className="text-2xl font-mono font-bold">{generatedCode}</p>
            </div>

            <Button onClick={handleCopy} variant="outline" className="w-full">
              {copied ? (
                <>
                  <Check className="mr-2 h-4 w-4" />
                  Copied!
                </>
              ) : (
                <>
                  <Copy className="mr-2 h-4 w-4" />
                  Copy Code
                </>
              )}
            </Button>

            {email && (
              <p className="text-sm text-muted-foreground">
                This code can only be used by: <strong>{email}</strong>
              </p>
            )}

            <p className="text-sm text-muted-foreground">
              Expires in {expiresInDays} days
            </p>

            <Button
              onClick={() => {
                setGeneratedCode(null);
                setEmail('');
                onOpenChange(false);
              }}
              variant="outline"
              className="w-full"
            >
              Close
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
```

#### Invitation Codes Table

```typescript
// features/invitations/invitations-page.tsx
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { GenerateCodeDialog } from './components/generate-code-dialog';
import { Plus } from 'lucide-react';

export function InvitationsPage() {
  const [showGenerateDialog, setShowGenerateDialog] = useState(false);

  const { data: invitations, isLoading } = useQuery({
    queryKey: ['invitations'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('invitation_codes')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;
    },
  });

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Invitation Codes</h1>
          <p className="text-muted-foreground">Manage admin registration codes</p>
        </div>
        <Button onClick={() => setShowGenerateDialog(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Generate Code
        </Button>
      </div>

      {isLoading ? (
        <div>Loading...</div>
      ) : (
        <div className="border rounded-lg">
          <table className="w-full">
            <thead className="bg-muted/50">
              <tr>
                <th className="p-4 text-left">Code</th>
                <th className="p-4 text-left">Restricted Email</th>
                <th className="p-4 text-left">Expires</th>
                <th className="p-4 text-left">Status</th>
                <th className="p-4 text-left">Used By</th>
              </tr>
            </thead>
            <tbody>
              {invitations?.map((inv) => (
                <tr key={inv.id} className="border-t">
                  <td className="p-4 font-mono">{inv.code}</td>
                  <td className="p-4">{inv.email || '—'}</td>
                  <td className="p-4">
                    {inv.expires_at
                      ? new Date(inv.expires_at).toLocaleDateString()
                      : 'Never'}
                  </td>
                  <td className="p-4">
                    {inv.used_at ? (
                      <Badge variant="secondary">Used</Badge>
                    ) : !inv.is_active ? (
                      <Badge variant="destructive">Deactivated</Badge>
                    ) : inv.expires_at && new Date(inv.expires_at) < new Date() ? (
                      <Badge variant="destructive">Expired</Badge>
                    ) : (
                      <Badge variant="default">Active</Badge>
                    )}
                  </td>
                  <td className="p-4">
                    {inv.used_at
                      ? new Date(inv.used_at).toLocaleDateString()
                      : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <GenerateCodeDialog
        open={showGenerateDialog}
        onOpenChange={setShowGenerateDialog}
      />
    </div>
  );
}
```

---

## Implementation Checklist

**Phase 3: Admin Panel MVP Requirements**

### Core Features
- [ ] Admin authentication with role checking (`profiles.role`)
- [ ] Domain CRUD (create, read, update, soft delete)
- [ ] Skill CRUD with domain filtering
- [ ] Question CRUD with type-specific editors
- [ ] Publishing system with status cascade
- [ ] Import/Export functionality

### Technical Requirements
- [ ] React Query for all server state
- [ ] Zod validation schemas matching [ADMIN_PANEL_SPEC.md](specs/ADMIN_PANEL_SPEC.md)
- [ ] shadcn/ui components initialized
- [ ] Supabase RLS policies respected
- [ ] Soft deletes for offline sync compatibility
- [ ] Anonymous auth for students (separate from admin auth)

### Validation Steps
1. Run `npm run lint` and `npm run build` - no errors
2. Test all CRUD operations
3. Verify admin role checking works
4. Test publishing cascade functionality
5. Run `.\scripts\validate-phase-3.ps1` for final validation

### Key Business Rules
- **Admin Auth**: Check `profiles.role` only (NOT separate `user_roles` table)
- **Student Auth**: Anonymous auth with device-bound sessions
- **Publishing**: `is_published` cascades from domain → skills → questions
- **Soft Deletes**: Use `deleted_at` timestamp, never hard delete
- **Slugs**: Must be `^[a-z0-9_]+$` and unique within scope

### Related Documents
- [AGENTS.md](AGENTS.md) - Execution protocol and phase requirements
- [ADMIN_PANEL_SPEC.md](specs/ADMIN_PANEL_SPEC.md) - Detailed UI/UX specifications
- [SCHEMA.md](SCHEMA.md) - Database schema reference
- [DATA_MODEL.md](specs/DATA_MODEL.md) - Business rules and constraints

---

**END OF ADMIN_PANEL_COMPLETE.md**