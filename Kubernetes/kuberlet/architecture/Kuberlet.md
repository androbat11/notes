## What _is_ the **kubelet**?
* The **kubelet** is the primary **node agent** that runs on every worker node in a Kubernetes cluster.  Its job is to make sure that **containers described in Pod specs are running and healthy**.*

# 🧱 **What is a Worker (Worker Node) in Kubernetes?**

A **worker** — also called a **worker node** — is a _machine_ (physical or virtual) whose job is to **run your applications**.  
In Kubernetes, applications run inside **Pods**, and Pods run _only_ on worker nodes.

A worker is basically:

> **A machine that provides CPU, RAM, networking, and storage resources to run Pods.**

This is where the actual workloads live.


---
![[Pasted image 20251210150000.png]]
## Conclusion

A worker node has several critical components installed.  
Think of these as the "runtime engines" for Kubernetes workloads.
