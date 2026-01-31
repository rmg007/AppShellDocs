# Screen Spec: Student Question Practice
**Route/Path:** `/practice/skill/:skillId`

## 1. Layout Structure
* **Header:** Progress indicator (Question X of Y), time spent, streak counter
* **Main Content:** Question content, answer input/options, submit button
* **Footer/Action Bar:** Previous/Next navigation (if enabled), hint button

## 2. UI Components & Elements
| Element ID | Type | Source Data | Interaction |
| :--- | :--- | :--- | :--- |
| `question_content` | Rich Text Display | `question.content` | Read-only, supports Markdown |
| `answer_options` | Radio Group / Checkbox Group | `question.options` | Single/multi select based on type |
| `text_input` | Text Field | N/A | For text_input questions |
| `btn_submit` | Button (Primary) | N/A | Triggers answer validation (WF-001) |
| `progress_bar` | Progress Bar | `session.questions_attempted / total` | Visual progress indicator |
| `streak_display` | Badge | `skill_progress.current_streak` | Shows current correct streak |

## 3. States
* **Loading:** Show question skeleton while loading from local DB
* **Answering:** Enable input fields and submit button
* **Submitted:** Show result (correct/incorrect), explanation, disable inputs
* **Session Complete:** Show summary stats, restart option

## 4. Edge Cases
* Network fails during submit? -> Queue for later sync, show offline indicator
* Question data corrupted? -> Skip to next question, log error
* Time limit exceeded? -> Auto-submit with partial credit