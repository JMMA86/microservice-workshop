class CircuitBreaker {
  constructor(maxFailures = 3, resetTimeoutMs = 30000) {
    this.maxFailures = maxFailures;
    this.resetTimeout = resetTimeoutMs;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failures = 0;
    this.lastFailure = null;
  }

  async call(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailure > this.resetTimeout) {
        this.state = 'HALF_OPEN';
        this.failures = 0;
      } else {
        throw new Error('Circuit breaker is open - authentication service unavailable');
      }
    }

    try {
      const result = await fn();
      
      // Success
      if (this.state === 'HALF_OPEN') {
        this.state = 'CLOSED';
      }
      this.failures = 0;
      return result;
    } catch (error) {
      this.failures++;
      this.lastFailure = Date.now();
      
      if (this.failures >= this.maxFailures) {
        this.state = 'OPEN';
      }
      throw error;
    }
  }

  getState() {
    return this.state;
  }

  getFailures() {
    return this.failures;
  }

  isOpen() {
    return this.state === 'OPEN';
  }

  isClosed() {
    return this.state === 'CLOSED';
  }

  isHalfOpen() {
    return this.state === 'HALF_OPEN';
  }
}

export default CircuitBreaker;