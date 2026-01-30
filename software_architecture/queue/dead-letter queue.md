# Dead-Letter Queue (DLQ)

## What is a Dead-Letter Queue?

A **Dead-Letter Queue (DLQ)** is a special message queue that stores messages that could not be successfully processed after a defined number of retry attempts. Instead of losing these messages or blocking the main queue, they are moved to the DLQ for later inspection, debugging, and reprocessing.

The term comes from postal services, where undeliverable mail is sent to a "dead letter office."

## Why Do We Need a DLQ?

| Problem Without DLQ | Solution With DLQ |
|---------------------|-------------------|
| Poison messages block the queue forever | Failed messages are moved out, queue continues |
| Failed messages are lost | Original messages are preserved |
| No visibility into failures | Centralized place to monitor and debug |
| No recovery path | Messages can be replayed after fixing issues |

## Core Concepts

### Message Lifecycle

```
┌──────────────────────────────────────────────────────────────────────┐
│                        MESSAGE LIFECYCLE                             │
└──────────────────────────────────────────────────────────────────────┘

  Producer                Main Queue                Consumer
     │                        │                        │
     │  1. Send message       │                        │
     │ ───────────────────▶   │                        │
     │                        │   2. Deliver message   │
     │                        │ ───────────────────▶   │
     │                        │                        │
     │                        │   3a. ACK (success)    │
     │                        │ ◀─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
     │                        │      Message deleted   │
     │                        │                        │
     │                        │        ─ OR ─          │
     │                        │                        │
     │                        │   3b. NACK (failure)   │
     │                        │ ◀─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
     │                        │      Retry or DLQ      │
     │                        │                        │
```

### Retry Flow with DLQ

```
┌──────────────────────────────────────────────────────────────────────┐
│                     RETRY FLOW WITH DLQ                              │
└──────────────────────────────────────────────────────────────────────┘

                         ┌─────────────┐
                         │   Message   │
                         │  Received   │
                         └──────┬──────┘
                                │
                                ▼
                         ┌─────────────┐
                         │   Process   │
                         │   Message   │
                         └──────┬──────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
             ┌─────────────┐         ┌─────────────┐
             │  ✅ Success │         │  ❌ Failure │
             └──────┬──────┘         └──────┬──────┘
                    │                       │
                    ▼                       ▼
             ┌─────────────┐         ┌─────────────┐
             │     ACK     │         │   Retry     │
             │   Delete    │         │   Count     │
             │   Message   │         │   < Max?    │
             └─────────────┘         └──────┬──────┘
                                            │
                                ┌───────────┴───────────┐
                                │                       │
                               YES                      NO
                                │                       │
                                ▼                       ▼
                         ┌─────────────┐         ┌─────────────┐
                         │   Requeue   │         │   Send to   │
                         │   (retry)   │         │     DLQ     │
                         └─────────────┘         └─────────────┘
```

## What Data Looks Like

### Original Message (in Main Queue)

```json
{
  "messageId": "msg-001-abc",
  "timestamp": "2026-01-29T10:00:00Z",
  "payload": {
    "orderId": "ORD-12345",
    "userId": "user-789",
    "items": [
      { "productId": "PROD-001", "quantity": 2, "price": 29.99 }
    ],
    "paymentMethod": {
      "type": "credit_card",
      "cardLast4": "4242",
      "expiryDate": "2025-12"
    },
    "shippingAddress": {
      "street": "123 Main St",
      "city": "Seattle",
      "zip": "98101"
    }
  }
}
```

### Same Message in DLQ (After Failures)

```json
{
  "messageId": "msg-001-abc",
  "timestamp": "2026-01-29T10:00:00Z",
  "payload": {
    "orderId": "ORD-12345",
    "userId": "user-789",
    "items": [
      { "productId": "PROD-001", "quantity": 2, "price": 29.99 }
    ],
    "paymentMethod": {
      "type": "credit_card",
      "cardLast4": "4242",
      "expiryDate": "2025-12"
    },
    "shippingAddress": {
      "street": "123 Main St",
      "city": "Seattle",
      "zip": "98101"
    }
  },
  "dlqMetadata": {
    "originalQueue": "orders-queue",
    "failedAt": "2026-01-29T10:05:32Z",
    "retryCount": 3,
    "lastError": {
      "type": "PaymentError",
      "message": "Card expired: expiry date 2025-12 is in the past",
      "stackTrace": "at PaymentService.charge() line 142..."
    },
    "failureHistory": [
      { "attempt": 1, "timestamp": "2026-01-29T10:01:00Z", "error": "PaymentError: Card expired" },
      { "attempt": 2, "timestamp": "2026-01-29T10:02:00Z", "error": "PaymentError: Card expired" },
      { "attempt": 3, "timestamp": "2026-01-29T10:03:00Z", "error": "PaymentError: Card expired" }
    ]
  }
}
```

## Types of Failures

| Failure Type | Example | Retryable? | DLQ Action |
|--------------|---------|------------|------------|
| **Transient** | Network timeout, DB connection lost | Yes | Retry, then DLQ if persists |
| **Permanent** | Invalid data, business rule violation | No | Send to DLQ immediately |
| **Poison** | Malformed/unparseable message | No | Send to DLQ immediately |
| **Expired** | TTL exceeded | No | Send to DLQ or discard |
| **Resource** | Out of memory, disk full | Yes | Retry with backoff |

## Implementation Strategy

### Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                    SYSTEM ARCHITECTURE WITH DLQ                      │
└──────────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Service A  │     │  Service B  │     │  Service C  │
│  (Producer) │     │  (Producer) │     │  (Producer) │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │    MESSAGE BROKER      │
              │  (RabbitMQ/SQS/Kafka)  │
              └────────────┬───────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
   ┌───────────┐     ┌───────────┐     ┌───────────┐
   │  Queue A  │     │  Queue B  │     │  Queue C  │
   │  orders   │     │ payments  │     │  emails   │
   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         │                 │                 │
         ▼                 ▼                 ▼
   ┌───────────┐     ┌───────────┐     ┌───────────┐
   │ Consumer  │     │ Consumer  │     │ Consumer  │
   │  Orders   │     │ Payments  │     │  Emails   │
   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         │                 │                 │
         │ on failure      │ on failure      │ on failure
         │                 │                 │
         ▼                 ▼                 ▼
   ┌───────────┐     ┌───────────┐     ┌───────────┐
   │  DLQ A    │     │  DLQ B    │     │  DLQ C    │
   │orders-dlq │     │payments-  │     │emails-dlq │
   │           │     │   dlq     │     │           │
   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   MONITORING & ALERTS  │
              │   (CloudWatch/Grafana) │
              └────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │    DLQ PROCESSOR       │
              │  (Manual/Automated)    │
              └────────────────────────┘
```

### Step-by-Step Implementation

#### Step 1: Define Queue Configuration

```
┌─────────────────────────────────────────────────────────────────┐
│                    QUEUE CONFIGURATION                          │
└─────────────────────────────────────────────────────────────────┘

MAIN QUEUE: "orders-queue"
├── Max retries: 3
├── Retry delay: exponential backoff (1s, 2s, 4s)
├── Message TTL: 24 hours
└── DLQ: "orders-dlq"

DEAD-LETTER QUEUE: "orders-dlq"
├── Message TTL: 14 days (for investigation)
├── Max size: 10,000 messages
└── Alert threshold: 100 messages
```

#### Step 2: Consumer Logic with Retry

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONSUMER PSEUDOCODE                          │
└─────────────────────────────────────────────────────────────────┘

function processMessage(message):
    try:
        // Attempt to process
        result = businessLogic(message.payload)

        // Success - acknowledge and remove from queue
        queue.ack(message)
        log("Processed successfully", message.id)

    catch PermanentError as e:
        // Don't retry - send directly to DLQ
        dlq.send(message, error=e)
        queue.ack(message)  // Remove from main queue
        alert("Permanent failure", message.id, e)

    catch TransientError as e:
        // Check retry count
        if message.retryCount < MAX_RETRIES:
            // Requeue with incremented retry count
            delay = calculateBackoff(message.retryCount)
            queue.requeue(message, delay)
            log("Retrying", message.id, attempt=message.retryCount + 1)
        else:
            // Max retries exceeded - send to DLQ
            dlq.send(message, error=e)
            queue.ack(message)
            alert("Max retries exceeded", message.id, e)
```

#### Step 3: DLQ Processing Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                 DLQ PROCESSING WORKFLOW                         │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────┐
                    │ DLQ Message │
                    │  Received   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Analyze   │
                    │   Error     │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
   ┌───────────┐     ┌───────────┐     ┌───────────┐
   │   Code    │     │  External │     │   Bad     │
   │    Bug    │     │  Failure  │     │   Data    │
   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         │                 │                 │
         ▼                 ▼                 ▼
   ┌───────────┐     ┌───────────┐     ┌───────────┐
   │  Fix bug  │     │   Wait    │     │  Contact  │
   │  Deploy   │     │   for     │     │   user    │
   │           │     │  recovery │     │  or fix   │
   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Replay    │
                    │  Messages   │
                    │ to Main Q   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Verify     │
                    │  Success    │
                    └─────────────┘
```

### Exponential Backoff Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                  EXPONENTIAL BACKOFF                            │
└─────────────────────────────────────────────────────────────────┘

Retry │ Delay    │ Total Wait │ Purpose
──────┼──────────┼────────────┼─────────────────────────────
  1   │    1s    │     1s     │ Quick retry for brief glitches
  2   │    2s    │     3s     │ Slightly longer wait
  3   │    4s    │     7s     │ Service might be recovering
  4   │    8s    │    15s     │ Longer recovery window
  5   │   16s    │    31s     │ Extended issues
  →   │   DLQ    │     -      │ Give up, needs human attention

Formula: delay = baseDelay * (2 ^ retryCount)
With jitter: delay = baseDelay * (2 ^ retryCount) + random(0, 1000ms)
```

## Code Examples

### AWS SQS Configuration (Terraform)

```hcl
# Main Queue
resource "aws_sqs_queue" "orders_queue" {
  name                      = "orders-queue"
  message_retention_seconds = 86400  # 24 hours

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 3  # After 3 failures, send to DLQ
  })
}

# Dead-Letter Queue
resource "aws_sqs_queue" "orders_dlq" {
  name                      = "orders-dlq"
  message_retention_seconds = 1209600  # 14 days
}

# CloudWatch Alarm for DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "orders-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Alert when DLQ has more than 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.orders_dlq.name
  }
}
```

### RabbitMQ Configuration (Python)

```python
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()

# Declare DLQ first
channel.queue_declare(queue='orders-dlq', durable=True)

# Declare main queue with DLQ binding
channel.queue_declare(
    queue='orders-queue',
    durable=True,
    arguments={
        'x-dead-letter-exchange': '',
        'x-dead-letter-routing-key': 'orders-dlq',
        'x-message-ttl': 86400000  # 24 hours in ms
    }
)
```

### Consumer with Retry Logic (Node.js)

```javascript
const MAX_RETRIES = 3;

async function processMessage(message) {
  const retryCount = message.properties.headers['x-retry-count'] || 0;

  try {
    await businessLogic(JSON.parse(message.content));
    channel.ack(message);
    console.log(`✅ Processed: ${message.properties.messageId}`);

  } catch (error) {
    if (isPermanentError(error) || retryCount >= MAX_RETRIES) {
      // Send to DLQ
      await sendToDLQ(message, error, retryCount);
      channel.ack(message);
      console.log(`❌ Sent to DLQ: ${message.properties.messageId}`);
    } else {
      // Retry with backoff
      const delay = Math.pow(2, retryCount) * 1000;
      setTimeout(() => {
        channel.publish('', 'orders-queue', message.content, {
          headers: { 'x-retry-count': retryCount + 1 }
        });
        channel.ack(message);
      }, delay);
      console.log(`🔄 Retry ${retryCount + 1}: ${message.properties.messageId}`);
    }
  }
}

async function sendToDLQ(message, error, retryCount) {
  const dlqMessage = {
    originalMessage: JSON.parse(message.content),
    metadata: {
      originalQueue: 'orders-queue',
      failedAt: new Date().toISOString(),
      retryCount: retryCount,
      error: {
        type: error.name,
        message: error.message,
        stack: error.stack
      }
    }
  };

  channel.sendToQueue('orders-dlq', Buffer.from(JSON.stringify(dlqMessage)));
}
```

## Monitoring Dashboard

```
┌──────────────────────────────────────────────────────────────────────┐
│                      DLQ MONITORING DASHBOARD                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DLQ Message Count (Last 24h)                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                            ▲   │  │
│  │                                                           ╱│   │  │
│  │                                                          ╱ │   │  │
│  │     ▲                                                   ╱  │   │  │
│  │    ╱│╲                                                 ╱   │   │  │
│  │   ╱ │ ╲                                               ╱    │   │  │
│  │  ╱  │  ╲___╱╲_____╱╲______________________________╱     │   │  │
│  │ ╱   │                                                      │   │  │
│  └─┴───┴──────────────────────────────────────────────────────┴───┘  │
│   00:00  04:00  08:00  12:00  16:00  20:00  24:00                     │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐       │
│  │  Orders DLQ     │  │  Payments DLQ   │  │  Emails DLQ     │       │
│  │  ────────────   │  │  ────────────   │  │  ────────────   │       │
│  │  Count: 23      │  │  Count: 7       │  │  Count: 156     │       │
│  │  Status: ⚠️     │  │  Status: ✅     │  │  Status: 🔴     │       │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘       │
│                                                                      │
│  Top Errors (Last 7 Days)                                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  PaymentError: Card expired              ████████████████  45% │  │
│  │  ValidationError: Missing field          ████████          22% │  │
│  │  TimeoutError: Database connection       ██████            18% │  │
│  │  ParseError: Invalid JSON                ████              10% │  │
│  │  Other                                   ██                 5% │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Best Practices

1. **One DLQ per main queue** - Easier to trace and debug
2. **Set appropriate TTL** - Long enough for investigation (7-14 days)
3. **Add rich metadata** - Original queue, timestamp, full error details
4. **Alert on DLQ depth** - Don't let messages pile up unnoticed
5. **Automate where possible** - Some failures can be auto-retried after delay
6. **Log everything** - Correlation IDs to trace message journey
7. **Test DLQ flow** - Intentionally send bad messages in staging

## Learning Resources

### Documentation
- [AWS SQS Dead-Letter Queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)
- [RabbitMQ Dead Letter Exchanges](https://www.rabbitmq.com/docs/dlx)
- [Azure Service Bus Dead-Lettering](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues)
- [Google Cloud Pub/Sub Dead-Letter Topics](https://cloud.google.com/pubsub/docs/dead-letter-topics)

### Patterns & Concepts
- [Enterprise Integration Patterns: Dead Letter Channel](https://www.enterpriseintegrationpatterns.com/patterns/messaging/DeadLetterChannel.html)
- [AWS Well-Architected: Async Messaging](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-interactions-in-a-distributed-system-to-mitigate-or-withstand-failures.html)

### Tutorials
- [Confluent: Kafka Dead Letter Queue](https://www.confluent.io/blog/kafka-connect-deep-dive-error-handling-dead-letter-queues/)

## Related Concepts

- [[Message Queue]] - The foundation that DLQs build upon
- [[Retry Pattern]] - How retries work before messages reach the DLQ
- [[Circuit Breaker]] - Another resilience pattern for handling failures
- [[Exponential Backoff]] - Strategy for spacing out retries
- [[Idempotency]] - Ensuring messages can be safely reprocessed
