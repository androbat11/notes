# Thinking in Components

> Phase 4 | Topic 1

## Why this matters
Breaking a UI mockup into components is a design skill that requires practice. Too coarse and components become hard to reuse; too fine and the tree becomes a maze. Developing this instinct is what separates developers who write readable, maintainable UIs from those who produce monolithic 500-line components.

## Sub-skills to master

### The decomposition heuristics
1. **Single responsibility:** each component does one thing — renders one UI concept
2. **Reuse potential:** would this chunk be useful in more than one place?
3. **State ownership:** a natural component boundary often appears where state is needed
4. **Visual grouping:** if a designer would give it a name, it probably deserves a component

### The process
```
1. Draw the UI on paper
2. Draw boxes around repeated elements → these become parameterized components
3. Draw boxes around distinct functional regions → these become structural components
4. Identify which box "owns" each piece of state → place state there
5. Name everything with clear, noun-first names
```

### Naming conventions
```typescript
// Clear, noun-first names
UserCard        // not: CardUser, UserCardComponent
FilterBar       // not: Filters, FilterThing
PaginationControls  // not: Paginator, Pages
LoadingSpinner  // not: Spinner (too generic), Loading (not a noun)
ErrorBoundary   // not: ErrorWrapper

// Container vs content distinction
UserList        // renders a list of UserCards
UserCard        // renders one user
UserCardSkeleton // loading state for UserCard
```

## Exercise
Given a job listings page with these UI elements:
- Top search bar with a text input and "Search" button
- A sidebar with filter checkboxes (job type, location, salary range)
- A result count ("47 jobs found")
- A list of job cards, each showing: company logo, title, company name, location, salary, tags, "Save" button, "Apply" button
- Pagination controls (prev/next, page numbers)
- A "Sort by" dropdown above the list

**On paper or in a text diagram:**
1. Draw the component tree — name every component
2. Indicate parent-child relationships
3. Place each piece of state at the correct component level:
   - Search query
   - Active filters
   - Current page
   - Sort option
   - Saved job IDs
   - Job results (from API)

## Mastery checkpoint
1. You're building a `DataTable` with 200 lines of JSX. What signals tell you it's time to extract a child component?
2. A component named `UserProfilePageContentSection` — what's wrong with this name?
3. You have a `Card` component that renders slightly differently in 4 places. At what point do you split it into 4 separate components vs. keep one with props? What's the heuristic?
