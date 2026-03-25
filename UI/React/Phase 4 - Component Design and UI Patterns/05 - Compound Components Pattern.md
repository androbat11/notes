# Compound Components Pattern

> Phase 4 | Topic 5

## Why this matters
Compound components create APIs that feel native — like `<select>` and `<option>`, or `<table>` and `<tr>`. Instead of passing complex configuration objects, consumers build up the component declaratively with full control over structure. Libraries like Radix UI and Headless UI use this pattern extensively.

## Sub-skills to master
```typescript
// The pattern: parent manages state via context; children consume it implicitly

// 1. Create context for shared state
interface TabsContextValue {
  activeTab: string;
  setActiveTab: (id: string) => void;
}
const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error('Tab components must be inside <Tabs>');
  return ctx;
}

// 2. Parent component — owns state, provides context
function Tabs({ children, defaultTab }: { children: React.ReactNode; defaultTab: string }) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// 3. Child components — consume context implicitly
function TabList({ children }: { children: React.ReactNode }) {
  return <div role="tablist">{children}</div>;
}

function Tab({ id, children }: { id: string; children: React.ReactNode }) {
  const { activeTab, setActiveTab } = useTabs();
  return (
    <button
      role="tab"
      aria-selected={activeTab === id}
      onClick={() => setActiveTab(id)}
    >
      {children}
    </button>
  );
}

function TabPanel({ id, children }: { id: string; children: React.ReactNode }) {
  const { activeTab } = useTabs();
  if (activeTab !== id) return null;
  return <div role="tabpanel">{children}</div>;
}

// 4. Attach subcomponents as static properties (optional but common)
Tabs.List  = TabList;
Tabs.Tab   = Tab;
Tabs.Panel = TabPanel;

// Consumer usage — clean, declarative, full structural control
<Tabs defaultTab="profile">
  <Tabs.List>
    <Tabs.Tab id="profile">Profile</Tabs.Tab>
    <Tabs.Tab id="settings">Settings</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel id="profile"><ProfileForm /></Tabs.Panel>
  <Tabs.Panel id="settings"><SettingsForm /></Tabs.Panel>
</Tabs>
```

## Exercise
Build a compound `<Accordion>` component:

**API:**
```jsx
<Accordion>
  <Accordion.Item id="a">
    <Accordion.Trigger>Section A</Accordion.Trigger>
    <Accordion.Panel>Content for A</Accordion.Panel>
  </Accordion.Item>
  <Accordion.Item id="b">
    <Accordion.Trigger>Section B</Accordion.Trigger>
    <Accordion.Panel>Content for B</Accordion.Panel>
  </Accordion.Item>
</Accordion>
```

**Requirements:**
- `Accordion` owns which item is open (only one at a time)
- `Accordion.Trigger` has `aria-expanded` attribute set correctly
- `Accordion.Panel` animates open/close (CSS transition is fine)
- Consumers can insert their own elements between `Accordion.Item` children
- TypeScript — no `any`

## Mastery checkpoint
1. Why does the compound component pattern use context rather than prop drilling for the shared state?
2. How does this differ from just passing a bunch of props to a single `Accordion` component (the "configuration" approach)?
3. What happens if a consumer renders `<Accordion.Trigger>` outside of an `<Accordion>`? How should you handle this?
