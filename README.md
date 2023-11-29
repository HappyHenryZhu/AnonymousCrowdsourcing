# Anonymous CrowdSourcing

## Migration

**Network Configuration**
Configure blockchain network in the `network` object in `truffle-config.js`, e.g., 

a local network called `development`
```
development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 7545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
    },
```

**Deployment script**
```
truffle migrate --network <name>
```