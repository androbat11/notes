# Component Composition

> Phase 2 | Topic 9

## Why this matters
React's composition model — building complex UIs by combining simpler components — is its core power. The `children` prop is inversion of control: instead of configuring everything via props, you pass the thing you want rendered. Understanding composition is the difference between rigid, hard-to-reuse components and flexible, combinable ones.

## Sub-skills to master
```typescript
// children prop — the parent decides what goes inside
function Card({ children }: { children: React.ReactNode }) {
  return <div className="card">{children}</div>;
}
// Usage:
<Card>
  <h2>Title</h2>
  <p>Content here</p>
</Card>

// Named slots via props — for multiple injection points
interface LayoutProps {
  header: React.ReactNode;
  sidebar?: React.ReactNode;
  children: React.ReactNode;
  footer?: React.ReactNode;
}
function Layout({ header, sidebar, children, footer }: LayoutProps) { ... }
// Usage:
<Layout
  header={<AppHeader />}
  sidebar={<NavMenu />}
  footer={<Footer />}
>
  <PageContent />
</Layout>

// Lifting state up — move state to nearest common ancestor
function Parent() {
  const [selected, setSelected] = useState<string | null>(null);
  return (
    <>
      <ItemList onSelect={setSelected} />
      <ItemDetail id={selected} />
    </>
  );
}

// The "as" prop pattern — consumer controls the root element
interface TextProps {
  as?: React.ElementType;  // 'p' | 'span' | 'h1' | typeof CustomComponent
  children: React.ReactNode;
}
function Text({ as: Element = 'p', children }: TextProps) {
  return <Element>{children}</Element>;
}
<Text as="h1">Title</Text>
<Text as="span">Inline</Text>
```

### Composition vs Configuration
```typescript
// Configuration approach (inflexible)
<Modal
  title="Confirm"
  body="Are you sure?"
  footerButtonLabel="Confirm"
  showCancelButton
/>

// Composition approach (flexible, consumer controls everything)
<Modal>
  <Modal.Header>Confirm</Modal.Header>
  <Modal.Body>Are you sure?</Modal.Body>
  <Modal.Footer>
    <Button variant="ghost" onClick={onClose}>Cancel</Button>
    <Button variant="danger" onClick={onConfirm}>Delete</Button>
  </Modal.Footer>
</Modal>
```

## Exercise
**Part 1:** Build a `Layout` component accepting `header`, `sidebar` (optional), and `children`. The sidebar hides when not provided.

**Part 2:** Build a `Dialog` component:
- Accept `title: string` and `children: React.ReactNode`
- The **parent owns** the open/closed state — pass `isOpen` and `onClose` as props
- The dialog renders a backdrop and a centered panel
- Clicking the backdrop calls `onClose`

**Part 3:** Identify what state to lift when you have a `Tabs` component and a `TabPanels` component that are siblings — both need to know the active tab index. Where does the state live?

## Mastery checkpoint
1. What is **prop drilling** and at what point does it become a problem worth solving?
2. You have a `Button` component. A consumer wants to render it as an `<a>` tag (link) instead of a `<button>`. Implement the `as` prop pattern to support this.
3. When should you use a named slot prop (e.g. `footer={<Footer />}`) vs just using `children`? What does each communicate about the component's design intent?
