import Vue from 'vue'
import router from './router'
import store from './store'
import decode from 'jwt-decode'
import CircuitBreaker from './circuitbreaker'

/**
 * @var{string} LOGIN_URL The endpoint for logging in. This endpoint should be proxied by Webpack dev server
 *    and maybe nginx in production (cleaner calls and avoids CORS issues).
 */
const LOGIN_URL = (process.env.VUE_APP_AUTH_API_ADDRESS || 'http://auth-api') + "/login"
const ROLE_ADMIN = 'ADMIN'

// Initialize circuit breaker for auth service: 3 failures, 30 seconds timeout
const authServiceCB = new CircuitBreaker(3, 30000);

/**
* Auth Plugin
*
* (see https://vuejs.org/v2/guide/plugins.html for more info on Vue.js plugins)
*
* Handles login and token authentication using OAuth2.
*/
export default {

  /**
   * Install the Auth class.
   *
   * Creates a Vue-resource http interceptor to handle automatically adding auth headers
   * and refreshing tokens. Then attaches this object to the global Vue (as Vue.auth).
   *
   * @param {Object} Vue The global Vue.
   * @param {Object} options Any options we want to have in our plugin.
   * @return {void}
   */
  install (Vue, options) {
    Vue.http.interceptors.push((request, next) => {
      const token = store.state.auth.accessToken
      const hasAuthHeader = request.headers.has('Authorization')

      if (token && !hasAuthHeader) {
        this.setAuthHeader(request)
      }

      next()
    })

    Vue.prototype.$auth = Vue.auth = this
  },

  /**
   * Login
   *
   * @param {Object.<string>} creds The username and password for logging in.
   * @param {string|null} redirect The name of the Route to redirect to.
   * @return {Promise}
   */
  login (creds, redirect) {
    const params = {
      username: creds.username,
      password: creds.password
    }

    return authServiceCB.call(async () => {
      const response = await Vue.http.post(LOGIN_URL, params)
      
      this._storeToken(response)

      if (redirect) {
        router.push({ name: redirect })
      }

      return response
    })
    .catch((errorResponse) => {
      if (authServiceCB.isOpen()) {
        // Circuit breaker is open, show user-friendly message
        const error = {
          status: 503,
          body: {
            message: 'Authentication service is temporarily unavailable. Please try again later.'
          }
        }
        throw error
      }
      throw errorResponse
    })
  },

  /**
   * Logout
   *
   * Clear all data in our Vuex store (which resets logged-in status) and redirect back
   * to login form.
   *
   * @return {void}
   */
  logout () {
    store.commit('CLEAR_ALL_DATA')
    router.push({ name: 'login' })
  },

  /**
   * Set the Authorization header on a Vue-resource Request.
   *
   * @param {Request} request The Vue-Resource Request instance to set the header on.
   * @return {void}
   */
  setAuthHeader (request) {
    request.headers.set('Authorization', 'Bearer ' + store.state.auth.accessToken)
  },

  isAdmin () {
    const user = store.state.user
    return user.role === ROLE_ADMIN
  },

  isLoggedIn () {
    const auth = store.state.auth
    return auth.isLoggedIn
  },

  /**
   * Get circuit breaker status
   * 
   * @return {Object} Circuit breaker state and failures count
   */
  getCircuitBreakerStatus () {
    return {
      state: authServiceCB.getState(),
      failures: authServiceCB.getFailures(),
      isOpen: authServiceCB.isOpen(),
      isClosed: authServiceCB.isClosed(),
      isHalfOpen: authServiceCB.isHalfOpen()
    }
  },

  /**
   * Retry the original request.
   *
   * Let's retry the user's original target request that had recieved a invalid token response
   * (which we fixed with a token refresh).
   *
   * @param {Request} request The Vue-resource Request instance to use to repeat an http call.
   * @return {Promise}
   */
  _retry (request) {
    this.setAuthHeader(request)

    return Vue.http(request)
      .then((response) => {
        return response
      })
      .catch((response) => {
        return response
      })
  },

  /**
   * Store tokens
   *
   * Update the Vuex store with the access/refresh tokens received from the response from
   * the Oauth2 server.
   *
   * @private
   * @param {Response} response Vue-resource Response instance from an OAuth2 server.
   *      that contains our tokens.
   * @return {void}
   */
  _storeToken (response) {
    const auth = store.state.auth
    auth.isLoggedIn = true
    auth.accessToken = response.body.accessToken

    var userData = decode(auth.accessToken)

    const user = store.state.user
    user.name = userData.name
    user.role = userData.role

    store.commit('UPDATE_AUTH', auth)
    store.commit('UPDATE_USER', user)
  }
}
