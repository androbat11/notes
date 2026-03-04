# Chaos Testing

Chaos testing (also called **chaos engineering**) is the practice of intentionally introducing failures and disturbances into a system to verify it can withstand unexpected conditions in production.

The goal is not to break things randomly — it is to **discover weaknesses before they cause real outages**.

> "Break things on purpose so they don't break unexpectedly."

---

## Core Principles

### 1. Build a Hypothesis Around Steady-State Behavior

Before injecting any failure, you must define what "normal" looks like for your system. Steady state is expressed in **measurable, observable metrics** — not vague descriptions.

Examples of steady-state metrics:
- p99 HTTP response latency < 300 ms
- Error rate < 0.5% of requests
- Order processing queue depth < 1000 messages
- CPU usage < 70% across all nodes

The hypothesis takes the form: _"We believe that [steady state] will continue to hold when [failure] is introduced."_ If the system deviates from steady state during the experiment, the hypothesis is falsified and you have found a real weakness.

Choosing the right metric matters — pick something that **directly reflects user experience**, not just internal health checks that may not correlate with actual impact.

---

### 2. Vary Real-World Events

The failures you inject must reflect events that can and do happen in production. Random or synthetic failures that have no real-world analog produce little useful signal.

Good sources for failure scenarios:
- **Past incidents** — your own post-mortems are the best input. If a database failover caused an outage 6 months ago, that is exactly what to test.
- **Dependency failure modes** — every external service, cloud provider, or third-party API will eventually fail. Know how each one fails and test against it.
- **Infrastructure realities** — hardware fails, networks partition, processes crash. The cloud does not protect you from this.

Categories of real-world events to vary:
- Node/instance termination
- Network latency and packet loss between services
- Downstream dependency returning errors or timing out
- Resource exhaustion (memory, file descriptors, disk)
- DNS resolution failures
- Clock drift between distributed nodes

The more closely your injected failures mirror real incidents, the more confidence the experiment gives you.

---

### 3. Run Experiments in Production

Staging and QA environments are useful for catching bugs, but they are **not reliable proxies for production**. They typically have:
- Different traffic volumes and patterns
- Fewer instances and no real autoscaling behavior
- Mocked or simplified external dependencies
- Different data distributions

A chaos experiment that passes in staging may still fail in production because the conditions are fundamentally different. The point of chaos engineering is to build confidence in the actual system your users interact with.

**Practical approach to running in production safely:**
- Start with a very small blast radius (e.g., 1% of instances or a single canary node).
- Have automated rollback or kill switches ready before starting.
- Run experiments during low-traffic periods at first.
- Ensure on-call engineers are aware and monitoring during the experiment.
- Never run experiments during planned high-traffic events (launches, sales).

As your confidence and tooling mature, you can increase scope and run experiments continuously.

---

### 4. Automate Experiments Continuously

A one-time chaos experiment tells you the system was resilient on that day. Continuous automated experiments tell you the system **remains** resilient as it evolves.

Systems change constantly — new deployments, dependency upgrades, configuration changes, scaling adjustments. Any of these can introduce regressions in resilience that a one-off experiment would never catch.

How to automate chaos experiments:
- Integrate them into your CI/CD pipeline so they run on every deployment.
- Schedule recurring experiments (e.g., weekly) against production to detect drift.
- Treat a failed chaos experiment the same as a failed unit test — block the release.
- Use tools like **Chaos Toolkit** or **LitmusChaos** that support declarative, version-controlled experiment definitions.

The goal is to make resilience verification as routine as functional testing.

---

### 5. Minimize Blast Radius

Every chaos experiment carries real risk. Blast radius is the scope of potential impact — how many users, services, or systems are affected if the experiment goes wrong or reveals a worse failure than expected.

Strategies to minimize blast radius:
- **Target a subset** — kill one pod out of ten, not all ten at once.
- **Use feature flags or traffic splitting** — expose only a percentage of traffic to the degraded condition.
- **Have a kill switch** — always be able to stop the experiment immediately and restore normal state.
- **Gradual escalation** — start with the smallest possible failure and increase magnitude only after confirming safe recovery.
- **Time-box experiments** — set a maximum duration; automatically restore if the experiment runs too long.

Minimizing blast radius is not about avoiding risk entirely — it is about taking **calculated, controlled risks** so that when you do find a weakness, the impact is limited and recoverable.

---

## What to Inject

| Failure Type          | Examples                                              |
|-----------------------|-------------------------------------------------------|
| **Infrastructure**    | Kill a VM, terminate a container, reboot a node       |
| **Network**           | Add latency, drop packets, partition network segments |
| **Resource pressure** | CPU stress, memory exhaustion, disk fill-up           |
| **Dependencies**      | Kill a database, make an external API return 500s     |
| **State corruption**  | Inject bad data, corrupt a cache, replay old messages |
| **Clock skew**        | Shift system time forward/backward                    |

---

## How to Run a Chaos Experiment

1. **Define steady state** — pick measurable metrics (e.g., p99 latency < 200 ms, error rate < 0.1%).
2. **Form a hypothesis** — "If we kill one pod, the service will continue serving traffic with no user-visible errors."
3. **Inject the failure** — using a tool or script, apply the failure to a subset of the system.
4. **Observe** — monitor metrics, logs, and alerts during the experiment.
5. **Analyze** — did the system match your hypothesis? If not, you found a real weakness.
6. **Fix and repeat** — remediate the issue, then re-run to confirm the fix holds.

---

## Tools

| Tool | Description |
|------|-------------|
| **Chaos Monkey** (Netflix) | Randomly terminates instances in production |
| **Gremlin** | SaaS platform; network, resource, and state attacks |
| **Chaos Toolkit** | Open-source, declarative experiment definitions in JSON/YAML |
| **LitmusChaos** | Kubernetes-native chaos framework (CNCF project) |
| **Pumba** | Docker chaos tool (network emulation, container kills) |
| **Toxiproxy** | TCP proxy for simulating network conditions in tests |

---

## Example: Killing a Kubernetes Pod

```bash
# Manually delete a pod to test self-healing
kubectl delete pod <pod-name> -n <namespace>

# Using LitmusChaos experiment
kubectl apply -f pod-delete-experiment.yaml
```

The system should reschedule the pod automatically. Monitor whether traffic was disrupted and for how long.

---

## Example: Network Latency with Toxiproxy

```bash
# Add 200ms latency to a downstream service
toxiproxy-cli toxic add my-service --type latency --attribute latency=200

# Run your tests / observe behavior

# Remove the toxic
toxiproxy-cli toxic remove my-service --toxicName latency_downstream
```

---

## Chaos Testing vs. Other Testing

| Test Type        | What it validates                          |
|------------------|--------------------------------------------|
| Unit tests       | Individual function correctness            |
| Integration tests| Component interaction                      |
| Load tests       | Behavior under high volume                 |
| **Chaos tests**  | Resilience under unexpected failures       |

---

## When to Start

- You have **observability** in place (metrics, logs, traces) — without it you cannot tell if the experiment succeeded.
- The system is stable enough that you have a clear steady state to compare against.
- Start with **non-production** environments first, then graduate to production with a small blast radius.

---

## Key Concepts

- **Blast radius** — the scope of impact of an experiment; always minimize it initially.
- **Steady state** — the measurable normal behavior of the system used as the baseline.
- **GameDay** — a scheduled event where a team intentionally breaks things and practices incident response.
- **Fault injection** — programmatically introducing errors into code paths or infrastructure.
