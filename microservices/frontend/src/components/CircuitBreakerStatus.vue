<template>
  <div class="circuit-breaker-status">
    <h4>Circuit Breaker Status</h4>
    <div class="status-item">
      <span class="label">Auth Service State:</span>
      <span :class="getStateClass(authStatus.state)">{{ authStatus.state }}</span>
    </div>
    <div class="status-item">
      <span class="label">Failures:</span>
      <span>{{ authStatus.failures }}</span>
    </div>
    <div v-if="authStatus.isOpen" class="alert alert-warning">
      ⚠️ Authentication service is currently unavailable
    </div>
    <div v-if="authStatus.isHalfOpen" class="alert alert-info">
      🔄 Authentication service is recovering
    </div>
    <div v-if="authStatus.isClosed" class="alert alert-success">
      ✅ Authentication service is healthy
    </div>
  </div>
</template>

<script>
export default {
  name: 'CircuitBreakerStatus',
  data() {
    return {
      authStatus: {
        state: 'CLOSED',
        failures: 0,
        isOpen: false,
        isClosed: true,
        isHalfOpen: false
      }
    }
  },
  mounted() {
    this.updateStatus()
    // Update status every 5 seconds
    this.statusInterval = setInterval(this.updateStatus, 5000)
  },
  beforeDestroy() {
    if (this.statusInterval) {
      clearInterval(this.statusInterval)
    }
  },
  methods: {
    updateStatus() {
      if (this.$auth && typeof this.$auth.getCircuitBreakerStatus === 'function') {
        this.authStatus = this.$auth.getCircuitBreakerStatus()
      }
    },
    getStateClass(state) {
      return {
        'state-closed': state === 'CLOSED',
        'state-open': state === 'OPEN',
        'state-half-open': state === 'HALF_OPEN'
      }
    }
  }
}
</script>

<style scoped>
.circuit-breaker-status {
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 5px;
  margin: 10px 0;
  font-size: 14px;
}

.status-item {
  margin: 5px 0;
}

.label {
  font-weight: bold;
  margin-right: 10px;
}

.state-closed {
  color: green;
  font-weight: bold;
}

.state-open {
  color: red;
  font-weight: bold;
}

.state-half-open {
  color: orange;
  font-weight: bold;
}

.alert {
  padding: 10px;
  margin: 10px 0;
  border-radius: 4px;
}

.alert-success {
  background-color: #d4edda;
  border-color: #c3e6cb;
  color: #155724;
}

.alert-warning {
  background-color: #fff3cd;
  border-color: #ffeaa7;
  color: #856404;
}

.alert-info {
  background-color: #d1ecf1;
  border-color: #bee5eb;
  color: #0c5460;
}
</style>