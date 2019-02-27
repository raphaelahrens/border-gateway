const toml = require('toml');
const fs = require('fs');

let config = {
    serviceName: 'http-proxy',
    logLevel: process.env.LOG_LEVEL || 'info',
    bind_addresses: [
        "127.0.0.1"
    ],
    bind_port: 5050,
    no_tls: false,
     change_origin_on: {
        https_req: false,
        http_req: false
    },
    domains: {},
    no_auth: false,
    auth_service: "http://localhost:5053/auth",
    configurationService: undefined,
    redis_host: undefined,
    redis_port: 6379,
    openidConnectProviderName: undefined
};


let configFromFile = toml.parse(fs.readFileSync('./config/config.toml'));

if(configFromFile[config.serviceName]) {
    Object.assign(config, configFromFile[config.serviceName]);
}

module.exports = config;
