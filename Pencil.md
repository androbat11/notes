Design a modern, developer-focused programming blog website called "Tree". 

BRAND IDENTITY:
- Logo: A minimalist tree silhouette made of code brackets or binary nodes — 
  think of a tree whose branches are shaped like "</>", "{}", or connected 
  dots resembling a data structure tree. Dark green or deep forest green as 
  the primary brand color. The word "Tree" sits beside the logo in a clean, 
  modern monospace or geometric sans-serif font.

AESTHETIC DIRECTION:
- Theme: Dark mode first. Deep charcoal or near-black background (#0D1117 
  or #111827), with forest green (#22C55E or #16A34A) as the primary accent. 
  Off-white (#F0F0F0) for body text.
- Typography: Pair a strong geometric display font (like "Space Mono" or 
  "JetBrains Mono") for headings with a clean readable serif or sans-serif 
  for body text. Code snippets use a monospace font with syntax-highlighted 
  inline blocks.
- Vibe: Editorial tech magazine meets developer tool. Clean, structured, 
  breathable. No clutter. Think Increment Magazine or Josh Comeau's blog.

PAGES TO DESIGN (4 total):

1. HOME (Blog List Page)
   - Sticky top navigation bar with logo on the left and 4 links on the 
     right: Welcome, About, Blog, Reach Out
   - Hero section: Large headline ("Where Software Architecture Lives"), 
     short tagline, and a subtle animated tree or branching node graphic 
     in the background
   - Blog post grid/list below the hero:
     * Each card shows: Post title, category tag (e.g. "Design Patterns", 
       "Architecture", "Rust", "Node.js"), author name, date, read time, 
       and a small like count with a heart icon
     * Posts are sorted by relevance/popularity (most liked first)
     * Cards have a subtle hover effect with a green left border accent
   - No sidebar. Full-width content area.

2. BLOG POST (Article Page)
   - Full-width article layout with a max-width content column centered
   - Large post title at the top, metadata row (author, date, read time, 
     category tag)
   - Article body with beautiful typography, code block styling with 
     line numbers and syntax highlighting, section headings with green 
     accent marks
   - At the bottom of the article:
     * LIKE BUTTON: A large, satisfying heart/thumbs-up button with 
       like count. No dislike button. Clicking animates the icon.
     * COMMENTS SECTION: Open comments below. Each comment shows avatar 
       (initials-based), username, date, and comment text. A simple 
       comment input box at the top with a "Post Comment" button.

3. ABOUT PAGE
   - Clean centered layout
   - Short bio about the author (developer, passionate about software 
     architecture, design patterns, Rust, Node.js)
   - A visual timeline or icon grid of topics covered on the blog
   - Social links or GitHub link

4. REACH OUT PAGE
   - Minimal contact form: Name, Email, Message, Send button
   - A subtle decorative tree branch SVG illustration on the side
   - Email address displayed as an alternative

NAVIGATION:
- 4 items only: Welcome | About | Blog | Reach Out
- No dropdown menus
- Active page is underlined with a green accent

COMPONENTS & DETAILS:
- Category tags styled as small pill badges in dark green
- Code blocks with a dark terminal aesthetic and a copy button
- Smooth page transitions
- Mobile responsive layouts
- Footer: Logo, copyright, and social icons (GitHub, LinkedIn, Twitter/X)
- No ads, no sidebar, no clutter

INSPIRATION REFERENCES:
- Josh W. Comeau's blog (joshwcomeau.com) for layout feel
- Increment Magazine for editorial quality
- GitHub's dark theme for color palette grounding

**A few extra tips for Pencil specifically:**

- Generate the **Home** and **Blog Post** pages first — they carry the most design weight.
- After generating, ask it to **apply the same design system** to the remaining pages for consistency.
- If it gives you a light theme by default, explicitly tell it: _"Switch to dark mode, background #0D1117, accent color #22C55E."_