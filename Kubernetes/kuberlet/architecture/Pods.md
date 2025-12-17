==_Pods_== are the smallest deployable units of computing that you can create and manage in Kubernetes. 

Resource: https://kubernetes.io/docs/concepts/workloads/pods/

## What is a pod?

A _Pod_ (as in a pod of whales or pea pod) is a group of one or more [containers](https://kubernetes.io/docs/concepts/containers/), with shared storage and network resources, and a specification for how to run the containers

* A Pod's contents are always co-located and co-scheduled, and run in a shared context.
* A Pod models an application-specific "logical host": it contains one or more application containers which are relatively tightly coupled.

## Detail

* The shared context of a Pod is a set of Linux namespaces, cgroups, and potentially other facets of isolation - the same things that isolate a [container](https://kubernetes.io/docs/concepts/containers/). Within a Pod's context, the individual applications may have further sub-isolations applied.*
* ==A Pod is similar to a set of containers with shared namespaces and shared filesystem volumes==.

## Pods flow

* **Pods that run a single container**. The "one-container-per-Pod" model is the most common Kubernetes use case; in this case, you can think of a Pod as a wrapper around a single container; Kubernetes manages Pods rather than managing the containers directly.
* **Pods that run multiple containers that need to work together**. A Pod can encapsulate an application composed of [multiple co-located containers](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers) that are tightly coupled and need to share resources.

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

