var merge = require('webpack-merge')
var prodEnv = require('./prod.env')

module.exports = merge(prodEnv, {
  NODE_ENV: '"development"',
    VUE_APP_AUTH_API_ADDRESS: `"${process.env.VUE_APP_AUTH_API_ADDRESS}"`,
    VUE_APP_TODOS_API_ADDRESS: `"${process.env.VUE_APP_TODOS_API_ADDRESS}"`,
    VUE_APP_ZIPKIN_URL: `"${process.env.VUE_APP_ZIPKIN_URL}"`
})
