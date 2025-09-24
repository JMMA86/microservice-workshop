# Resilience Patterns Implementation

## Circuit Breaker Pattern

### Why was it implemented?
To prevent cascading failures when downstream services fail and to provide graceful system degradation.

### What is it for?
- Avoids overloading already failing services
- Provides fast responses when services are unreachable
- Enables automatic recovery when services become available again

### Use Cases
- **Frontend → Auth API**: Protects the user interface against authentication failures
- **Auth API → Users API**: Prevents long timeouts when the user service fails
- **High Load**: Reduces the load on degraded services by allowing them to recover

### Implementation

#### Auth API (Go)
- **File**: `microservices/auth-api/circuitbreaker.go`
- **Configuration**: Maximum 3 failures, 30-second timeout
- **Integration**: Modified `user.go` to protect calls to the Users API
- **Monitoring**: Endpoint `/auth-api/circuit-breaker-status`

#### Frontend (JavaScript)
- **File**: `microservices/frontend/src/circuitbreaker.js`
- **Configuration**: Maximum 3 failures, 30-second timeout
- **Integration**: Modified `auth.js` to protect Auth API calls
- **Component**: `CircuitBreakerStatus.vue` for visual monitoring

### Circuit Breaker Statuses
- **CLOSED**: Normal operation
- **OPEN**: Service failing, immediate responses
- **HALF_OPEN**: Testing service recovery

---

## Horizontal Pod Autoscaler (HPA) Pattern

### Why was it implemented?
To automatically handle variable workloads without manual intervention and optimize resource usage.

### What is it for?
- Automatically scale pods based on CPU and memory
- Maintain performance during traffic spikes
- Reduce costs during periods of low load
- Eliminate the need for manual scaling

### Use Cases
- **Traffic Spikes**: Automatic scaling during high demand
- **Cost Optimization**: Reduction of replicas during low activity
- **Availability**: Keeps the service available under any load
- **Operational Efficiency**: Reduces manual intervention in operations

### Deployment

#### Services with HPA configured
| Service | Min Replicas | Max Replicas | CPU Target | Memory Target |
|----------|--------------|--------------|---------------|-------------|
| **auth-api** | 2 | 10 | 70% | 80% |
| **users-api** | 2 | 8 | 70% | 80% |
| **all-api** | 2 | 8 | 70% | 80% |
| **frontend** | 2 | 6 | 70% | - |

#### Terraform Configuration
- **File**: `infrastructure/terraform/modules/aks/main.tf`
- **Policies**: Aggressive scaling up, conservative scaling down
- **Metrics**: CPU and memory as main triggers
- **Stabilization**: 60s for scale-up, 300s for scale-down

### HPA Monitoring
```bash
# View status of all HPAs
kubectl get hpa

# Real-time monitoring
kubectl get hpa -w

# Specific details
kubectl describe hpa auth-api-hpa
```

---

## Quick Testing

### Circuit Breaker
```bash
# 1. Verify initial status
kubectl port-forward svc/auth-api 8080:8080 &
curl http://localhost:8080/auth-api/circuit-breaker-status

# 2. Open Circuit Breaker
kubectl scale deployment users-api --replicas=0
# Perform 3 login attempts to activate CB

# 3. Recovery
kubectl scale deployment users-api --replicas=1
# Wait 30s and log in successfully
```

### HPA
```bash
# 1. Generate load
kubectl run load-test --image=busybox --rm -it --restart=Never -- /bin/sh
while true; do wget -q -O- http://auth-api:8080/auth-api/version; done

# 2. Observe scaling
kubectl get hpa -w
kubectl get pods -l app=auth-api -w
```

---

## Combined Benefits

1. **Resilience**: Circuit breaker prevents failures, HPA manages load
2. **Availability**: System remains operational under any conditions
3. **Efficiency**: Automatically optimized resources
4. **User Experience**: Fast responses and reliable service