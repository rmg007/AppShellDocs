# Screen Spec: `[Screen Name]`
**Route/Path:** `/app/[route]`

## 1. Layout Structure
* **Header:** Contains [Title, Back Button, Search].
* **Main Content:** [Grid / Form / Canvas].
* **Footer/Action Bar:** [Save, Cancel, Export].

## 2. UI Components & Elements
| Element ID | Type | Source Data | Interaction |
| :--- | :--- | :--- | :--- |
| `btn_save` | Button (Primary) | N/A | Triggers `[WF-001]`. |
| `input_name`| Text Field | `User.Name` | Validates alphanumeric. |
| `list_items`| Data Grid | `Query: GetItems()`| Sortable by Date. |

## 3. States
* **Loading:** Show skeleton loader on `list_items`.
* **Empty:** Show "No items found" illustration.
* **Read-Only:** Disable all inputs if `status == 'Closed'`.

## 4. Edge Cases
* What happens if network fails during save? -> [Show Retry Modal]