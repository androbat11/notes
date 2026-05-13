Resource: https://en.wikipedia.org/wiki/Microkernel

# Micro-kernel

The microkernel is the minimum amount of software that can provide the mechanisms needed to implement an Operating system.

[![Microkernel Architecture Style - Mastering Software Architecture](https://raw.githubusercontent.com/RomeroGabriel/mastering-software-architecture/main/doc/images/arch_styles/microkernel_dbs.png)![Microkernel Architecture Style - Mastering Software Architecture](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTpmrvMHIFJNYKtTsfWJ142Wp0hp4yZU5qQTZZnwbuBIotuZjP9TO5VBF3p0mfb-oFBENw2Jw&s=10)](https://www.google.com/url?sa=t&source=web&rct=j&url=https%3A%2F%2Fromerogabriel.github.io%2Fmastering-software-architecture%2Farch_styles%2Fmicrokernel_arch%2F&ved=0CBUQjRxqFwoTCPjS28OAt5QDFQAAAAAdAAAAABAG&opi=89978449)

## Notes:
- Interprocess communication
- Thread management
- Address space
- Distributed systems
- Security

## Questions:
 * #### How to build system's that work when fail?
 * #### What is RAID storage?
 * #### **What is a checksum to detected socket error in *distributed systems*** ?
	 * In networking, checksums are used as follows. Before sending a message from one machine to another, compute a checksum over the bytes of the message. Then send both the message and the checksum to the destination. At the destination, the receiver computes a checksum over the incoming message as well; if this computed checksum matches the sent checksum, the receiver can feel some assurance that the data likely did not get corrupted during transmission.
		 * Comments | *Checksum* - In **distributed systems** the check the integrity of the data by applying the checksum. If I count the number of bytes sent before sending them and also check again when the message arrives, if the amount of bytes gotten it is not the same, we know we lust data. ![[Screenshot 2026-05-13 at 4.46.41 PM.png]]
	 * #### In a ***distributed system*** how do we know that the message gotten its **destination**? 
		 * The sender sends a message to the receiver and the receiver sends an **Acknowledge*** message to the **sender**.
		 * However, what should the sender do if it does not receive an acknowledgment?
			 * **Applying a timeout**: When the sender sends a message, the sender now sets a timer to go off after some period of time. If, in that time, no acknowledgment has been received, the sender concludes that the message has been lost. The sender then simply performs a retry of the send, sending the same message again with hopes that this time, it will get through. For this approach to work, the sender must keep a copy of the message around. This approach is called **timeout/retry**. 
			 * **Sequence acounter**: take less memory and works in the following way:
				 * the sender and receiver agree upon a start value (e.g., 1) for a counter that each side will maintain. Whenever a message is sent, the current value of the counter is sent along with the message; this counter value( ) serves as an ID for the message. After the message is sent, the sender then increments the value (to +1).
 * #### **Communication abstractions**: What abstraction of communication we must use when building a *distributed system*?
	 * Distributed shared memory: systems enable processes on different machines to share a large, virtual address space
 * #### Remote procedure call (RPC)
	 * Remote procedure call packages all have a simple goal: to make the process of executing code on a remote machine as simple and straight-forward as calling a local function.
	 * Stub-generator
	 * ```ts
	   interface {
			int func1(int arg1);
			int func2(int arg1, int arg2);

};
	   ```
 * 
 * What is UDP/IP

