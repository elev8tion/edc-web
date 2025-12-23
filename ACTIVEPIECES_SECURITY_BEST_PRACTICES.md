# Activepieces Security Best Practices Guide

## Table of Contents

1. [API Token Management and Authentication](#1-api-token-management-and-authentication)
2. [Webhook Security and Validation](#2-webhook-security-and-validation)
3. [Flow Access Control and Permissions](#3-flow-access-control-and-permissions)
4. [Database Security in Activepieces Flows](#4-database-security-in-activepieces-flows)
5. [MCP Server Authentication Best Practices](#5-mcp-server-authentication-best-practices)
6. [Rate Limiting and Abuse Prevention](#6-rate-limiting-and-abuse-prevention)
7. [Example Secure Flow Configurations](#7-example-secure-flow-configurations)
8. [Production Deployment Checklist](#8-production-deployment-checklist)
9. [Additional Security Considerations](#9-additional-security-considerations)

---

## 1. API Token Management and Authentication

### 1.1 Credential Storage

Activepieces implements enterprise-grade credential security:

- **256-bit Encryption**: All credentials are stored with 256-bit encryption keys
- **No Retrieval API**: There is no API to retrieve credentials for users - credentials are only sent during flow processing, after which access is immediately revoked from the engine
- **Encrypted at Rest**: All credentials (OAuth tokens, API keys, database credentials) are encrypted in the data directory

### 1.2 Supported Authentication Methods

Activepieces supports multiple authentication methods for integrating with third-party services:

- **OAuth 2.0**: Standard OAuth flows for secure authorization
- **API Keys**: Static API key authentication
- **Bearer Tokens**: JWT-based token authentication
- **Basic Auth**: Username/password authentication
- **Custom Authentication**: Flexible authentication configuration for custom APIs

### 1.3 API Key Management Best Practices

#### Creating and Using API Keys

1. Navigate to **Platform Admin → Security → API Keys**
2. Create an API key with appropriate permissions
3. Store the API key securely (it will only be shown once)
4. Use the key as a Bearer token in API requests:

```javascript
// Example API request with Bearer token
const apiKey = 'your_api_key_here';

const response = await fetch('https://your-activepieces-instance.com/api/v1/endpoint', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  }
});
```

#### Security Best Practices

- **Never commit API keys to source control** - Use environment variables or secrets managers
- **Use separate keys for different environments** (development, staging, production)
- **Rotate API keys regularly** - Implement a key rotation schedule
- **Apply principle of least privilege** - Grant only necessary permissions to each key
- **Monitor API key usage** - Track and audit API key access via audit logs
- **Revoke unused keys** - Regularly review and remove keys that are no longer needed

### 1.4 JWT Secret Configuration

For self-hosted deployments, secure JWT secret generation is critical:

```bash
# Generate secure JWT secret (32 bytes)
openssl rand -hex 32

# Generate encryption key (16 bytes)
openssl rand -hex 16

# Generate database password
openssl rand -hex 16
```

Add to your `.env` file:

```bash
# CRITICAL SECURITY SETTINGS
AP_JWT_SECRET=your_generated_jwt_secret_here
AP_ENCRYPTION_KEY=your_generated_encryption_key_here
AP_POSTGRES_PASSWORD=your_generated_db_password_here
```

### 1.5 Environment Variable Security

**Never store sensitive values in:**
- Git repositories
- Docker images
- Configuration files committed to version control
- Client-side code

**Always use:**
- Environment variables
- Secrets management systems (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, Google Secret Manager)
- Docker secrets
- Kubernetes secrets

### 1.6 Connection Storage

Activepieces provides secure connection storage for API credentials:

- **Project-scoped connections**: Store credentials at the project level
- **Global connections**: Share credentials across multiple projects (Enterprise feature)
- **Predefined connections**: Pre-configure connections for embedded deployments
- **Credential masking**: All sensitive information is automatically censored in logs

---

## 2. Webhook Security and Validation

### 2.1 Webhook Authentication Methods

Activepieces supports the following webhook authentication methods (as of April 2024):

#### Header-Based Authentication

Secure webhook endpoints by verifying specific headers:

```javascript
// Example webhook trigger with header authentication
{
  "trigger": "webhook",
  "settings": {
    "authentication": {
      "type": "HEADER",
      "headerName": "X-Webhook-Secret",
      "expectedValue": "{{connections.webhook_secret}}"
    }
  }
}
```

#### Basic Authentication

Username and password-based webhook authentication:

```javascript
{
  "trigger": "webhook",
  "settings": {
    "authentication": {
      "type": "BASIC_AUTH",
      "username": "webhook_user",
      "password": "{{connections.webhook_password}}"
    }
  }
}
```

#### No Authentication (Not Recommended for Production)

Only use for testing or when the webhook source is already secured:

```javascript
{
  "trigger": "webhook",
  "settings": {
    "authentication": {
      "type": "NONE"
    }
  }
}
```

### 2.2 HMAC Signature Verification

**Current Status**: HMAC authentication is not natively supported in Activepieces but is a requested feature (GitHub Issue #7097).

**Workaround**: Implement HMAC verification in a custom code piece:

```javascript
// Custom code piece for HMAC verification
import crypto from 'crypto';

export const code = async (params) => {
  const { body, headers, secret } = params;

  // Get signature from header
  const receivedSignature = headers['x-webhook-signature'];

  // Calculate expected signature
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(body));
  const expectedSignature = hmac.digest('hex');

  // Compare signatures
  if (receivedSignature !== expectedSignature) {
    throw new Error('Invalid webhook signature');
  }

  // Signature is valid, continue processing
  return body;
};
```

### 2.3 Webhook Handshake Configuration

Some services require a handshake request for webhook verification:

```javascript
// Webhook trigger with handshake configuration
{
  "trigger": "webhook",
  "handshakeConfiguration": {
    "strategy": "CHALLENGE_RESPONSE",
    "challengeParameter": "hub.challenge"
  }
}
```

### 2.4 Webhook Security Best Practices

1. **Always use authentication** - Never expose webhook endpoints without authentication in production
2. **Use HTTPS only** - Many services require webhook URLs to be HTTPS
3. **Validate request origin** - Check IP addresses or other headers to verify the source
4. **Implement rate limiting** - Protect against webhook flooding attacks
5. **Log all webhook requests** - Monitor for suspicious activity
6. **Use unique webhook URLs** - Generate separate URLs for different integrations
7. **Implement timeout handling** - Set appropriate timeouts to prevent resource exhaustion
8. **Validate payload structure** - Verify the webhook payload matches expected schema

### 2.5 HTTPS/SSL Configuration

Setting up HTTPS is highly recommended (required by most webhook services):

```yaml
# Example Traefik configuration for SSL
version: '3.8'
services:
  activepieces:
    image: activepieces/activepieces:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.activepieces.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.activepieces.entrypoints=websecure"
      - "traefik.http.routers.activepieces.tls.certresolver=letsencrypt"
```

---

## 3. Flow Access Control and Permissions

### 3.1 Role-Based Access Control (RBAC)

Activepieces implements comprehensive RBAC for managing permissions:

#### User Roles

- **Admin**: Full access to all projects, flows, and settings
- **Editor**: Can create and modify flows
- **Viewer**: Read-only access to flows
- **Custom Roles**: Define custom permissions (Enterprise feature)

#### Permission Levels

- **Project-level**: Permissions scoped to specific projects
- **Folder-level**: Organize projects into folders with inherited permissions
- **Flow-level**: Individual flow access control

### 3.2 Project Permissions Structure

```javascript
// Example project permissions configuration
{
  "projectId": "proj_abc123",
  "permissions": {
    "users": [
      {
        "userId": "user_123",
        "role": "ADMIN",
        "canEdit": true,
        "canView": true,
        "canDelete": true,
        "canInvite": true
      },
      {
        "userId": "user_456",
        "role": "EDITOR",
        "canEdit": true,
        "canView": true,
        "canDelete": false,
        "canInvite": false
      },
      {
        "userId": "user_789",
        "role": "VIEWER",
        "canEdit": false,
        "canView": true,
        "canDelete": false,
        "canInvite": false
      }
    ]
  }
}
```

### 3.3 Single Sign-On (SSO) Integration

SSO integration is available on Business and Enterprise plans:

#### Supported SSO Providers

- **SAML 2.0**: Generic SAML integration
- **Google OAuth**: Google Workspace integration
- **GitHub OAuth**: GitHub organization authentication
- **Azure AD**: Microsoft Azure Active Directory
- **Okta**: Okta Identity Management
- **Custom SAML providers**: JumpCloud, OneLogin, etc.

#### SAML Configuration Example

```yaml
# SAML SSO Configuration
sso:
  enabled: true
  provider: saml
  saml:
    entryPoint: "https://idp.example.com/saml/sso"
    issuer: "activepieces-app"
    cert: |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKL0UG+mRTF...
      -----END CERTIFICATE-----
    binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
```

**Important SAML Note**: JumpCloud and some other providers do not provide the HTTP-Redirect binding by default. You must:
1. Enable HTTP-Redirect binding in your IDP
2. Verify that `Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"` appears in the exported metadata XML

### 3.4 Audit Logging

Activepieces maintains comprehensive audit logs (Enterprise feature):

- **User activity tracking**: All user actions are logged with timestamps
- **Flow execution logs**: Complete execution history with parameters
- **Permission changes**: Track all RBAC modifications
- **API access logs**: Monitor all API requests and responses
- **Authentication events**: Login attempts, SSO sessions, API key usage

#### Audit Log Data Points

- User identity
- Action performed
- Timestamp
- IP address
- User agent
- Affected resources
- Success/failure status

### 3.5 Publishing Flows

Control flow deployment with publishing workflow:

- **Draft versions**: Work on flows without affecting production
- **Published versions**: Locked, stable versions running in production
- **Version control**: Track all changes with built-in versioning
- **Rollback capability**: Revert to previous versions if needed

### 3.6 Access Control Best Practices

1. **Apply principle of least privilege** - Grant minimum necessary permissions
2. **Regular access reviews** - Audit user permissions quarterly
3. **Remove unused accounts** - Deactivate accounts for departed team members immediately
4. **Use SSO when possible** - Centralize authentication management
5. **Enable audit logging** - Monitor all security-relevant events
6. **Separate environments** - Use different projects for dev/staging/production
7. **Limit admin access** - Minimize the number of users with admin privileges
8. **Document permissions** - Maintain clear documentation of who has access to what

---

## 4. Database Security in Activepieces Flows

### 4.1 Database Connection Security

#### Secure Database Configuration

```bash
# PostgreSQL Configuration (Environment Variables)
AP_POSTGRES_HOST=your-db-host.example.com
AP_POSTGRES_PORT=5432
AP_POSTGRES_DATABASE=activepieces
AP_POSTGRES_USERNAME=ap_user
AP_POSTGRES_PASSWORD=your_secure_password_here  # Use openssl rand -hex 16

# Use SSL for database connections
AP_POSTGRES_SSL_ENABLED=true

# Redis Configuration (for caching and queues)
AP_REDIS_HOST=your-redis-host.example.com
AP_REDIS_PORT=6379
AP_REDIS_PASSWORD=your_redis_password_here
AP_REDIS_SSL_ENABLED=true
```

#### Connection String Security

**Never hardcode database credentials in flows:**

❌ **Bad Practice:**
```javascript
const connection = {
  host: 'db.example.com',
  user: 'admin',
  password: 'hardcoded_password',  // NEVER DO THIS
  database: 'production'
};
```

✅ **Good Practice:**
```javascript
// Use Activepieces connections
const connection = params.connections.postgres_db;

// Or reference from project variables
const dbConfig = {
  host: params.project.variables.DB_HOST,
  user: params.project.variables.DB_USER,
  password: params.project.variables.DB_PASSWORD,
  database: params.project.variables.DB_NAME,
  ssl: true
};
```

### 4.2 Database Access Patterns

#### Read-Only Access for Reporting

Create separate database users with limited permissions:

```sql
-- Create read-only user for Activepieces flows
CREATE USER activepieces_readonly WITH PASSWORD 'secure_password';

-- Grant read-only access to specific tables
GRANT CONNECT ON DATABASE production_db TO activepieces_readonly;
GRANT USAGE ON SCHEMA public TO activepieces_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO activepieces_readonly;

-- Prevent write operations
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM activepieces_readonly;
```

#### Write Access with Constraints

For flows that need write access, use constrained permissions:

```sql
-- Create user with limited write access
CREATE USER activepieces_writer WITH PASSWORD 'secure_password';

-- Grant access only to specific tables
GRANT CONNECT ON DATABASE production_db TO activepieces_writer;
GRANT USAGE ON SCHEMA public TO activepieces_writer;
GRANT SELECT, INSERT, UPDATE ON specific_table TO activepieces_writer;

-- Prevent deletion
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM activepieces_writer;
```

### 4.3 Data Masking and Encryption

#### Sensitive Data Handling

```javascript
// Example: Mask sensitive data in logs
export const code = async (params) => {
  const userData = params.user;

  // Mask sensitive fields before logging
  const maskedUser = {
    ...userData,
    ssn: userData.ssn ? '***-**-' + userData.ssn.slice(-4) : null,
    creditCard: userData.creditCard ? '****-****-****-' + userData.creditCard.slice(-4) : null,
    password: '[REDACTED]'
  };

  console.log('Processing user:', maskedUser);

  // Work with original data
  return userData;
};
```

#### Field-Level Encryption

```javascript
// Encrypt sensitive fields before storing
import crypto from 'crypto';

export const code = async (params) => {
  const { data, encryptionKey } = params;

  // Encrypt sensitive fields
  const algorithm = 'aes-256-cbc';
  const key = Buffer.from(encryptionKey, 'hex');
  const iv = crypto.randomBytes(16);

  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(data.sensitiveField, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  return {
    ...data,
    sensitiveField: {
      encrypted: encrypted,
      iv: iv.toString('hex')
    }
  };
};
```

### 4.4 Query Parameterization

Always use parameterized queries to prevent SQL injection:

❌ **Bad Practice (SQL Injection Vulnerable):**
```javascript
const query = `SELECT * FROM users WHERE email = '${userEmail}'`;
```

✅ **Good Practice (Parameterized):**
```javascript
const query = 'SELECT * FROM users WHERE email = $1';
const params = [userEmail];
```

### 4.5 Database Security Best Practices

1. **Use connection pooling** - Limit concurrent database connections
2. **Enable SSL/TLS** - Encrypt all database traffic
3. **Implement IP whitelisting** - Restrict database access to known IPs
4. **Use separate credentials per environment** - Dev, staging, and production should use different credentials
5. **Regular credential rotation** - Rotate database passwords periodically
6. **Monitor query performance** - Detect and prevent resource-intensive queries
7. **Backup encryption** - Ensure database backups are encrypted
8. **Audit database access** - Log all database operations from flows
9. **Limit connection lifetime** - Use short-lived database connections
10. **Implement query timeouts** - Prevent long-running queries from blocking resources

### 4.6 Data Retention and Compliance

Configure data retention policies:

```bash
# Configure log retention (environment variables)
AP_EXECUTION_DATA_RETENTION_DAYS=30  # Keep execution data for 30 days
AP_AUDIT_LOG_RETENTION_DAYS=90       # Keep audit logs for 90 days
```

---

## 5. MCP Server Authentication Best Practices

### 5.1 MCP Server Security Architecture

Activepieces MCP server implements multi-layered security:

- **Self-hosted deployment**: Ultimate data control within your infrastructure
- **SOC 2 Type II compliance**: Enterprise-grade security certification
- **OAuth2 flows**: Standard OAuth for app connections
- **MCP server URL as private API key**: The server URL acts as a security credential

### 5.2 MCP Server Configuration

#### Setup for AI Clients

1. **Access MCP Dashboard**: Navigate to **AI → MCP** in Activepieces
2. **Select AI Client**: Choose Claude Desktop, Cursor, or Windsurf
3. **Generate Server URL**: Create a unique MCP server endpoint
4. **Configure Client**: Add the server URL to your AI client configuration

#### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "activepieces": {
      "url": "https://your-activepieces-instance.com/api/v1/mcp/your-unique-token",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer your-api-key"
      }
    }
  }
}
```

#### Cursor Configuration

```json
{
  "mcp": {
    "servers": [
      {
        "name": "activepieces",
        "url": "https://your-activepieces-instance.com/api/v1/mcp/your-unique-token",
        "apiKey": "your-api-key"
      }
    ]
  }
}
```

### 5.3 API Key Management for MCP

#### Static API Keys

Use for simple, long-term integrations:

```javascript
// Static API key configuration
{
  "type": "STATIC_API_KEY",
  "key": "ap_live_1234567890abcdef",
  "expiresAt": null  // No expiration
}
```

**Pros:**
- Simple to implement
- No expiration unless manually revoked
- Easy to share across services

**Cons:**
- Limited security controls
- No automatic expiration
- Difficult to rotate without service interruption

#### OAuth Tokens (Recommended)

Use for enhanced security:

```javascript
// OAuth token configuration
{
  "type": "OAUTH2",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "expiresAt": "2024-12-31T23:59:59Z",
  "scope": "flows:read flows:execute"
}
```

**Pros:**
- Automatic token expiration
- Specific permission scopes
- Better security with refresh tokens
- Easier to revoke access

**Cons:**
- More complex setup
- Requires refresh logic

### 5.4 Token Lifecycle Management

#### Token Rotation Schedule

```javascript
// Automated token rotation
export const code = async (params) => {
  const { currentToken, expiresAt } = params;

  // Check if token expires within 7 days
  const expiryDate = new Date(expiresAt);
  const sevenDaysFromNow = new Date();
  sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

  if (expiryDate < sevenDaysFromNow) {
    // Trigger token rotation
    const newToken = await rotateToken(currentToken);

    // Update stored token
    await updateToken(newToken);

    return {
      rotated: true,
      newExpiresAt: newToken.expiresAt
    };
  }

  return {
    rotated: false,
    message: 'Token still valid'
  };
};
```

#### Token Lifespan Configuration

Balance security and usability:

```bash
# Short-lived tokens (high security)
AP_MCP_TOKEN_LIFETIME=3600  # 1 hour

# Medium-lived tokens (balanced)
AP_MCP_TOKEN_LIFETIME=86400  # 24 hours

# Long-lived tokens (convenience, lower security)
AP_MCP_TOKEN_LIFETIME=604800  # 7 days
```

### 5.5 Secrets Management for MCP

#### HashiCorp Vault Integration

```javascript
// Retrieve MCP credentials from Vault
export const code = async (params) => {
  const vault = require('node-vault')({
    apiVersion: 'v1',
    endpoint: params.vaultUrl,
    token: params.vaultToken
  });

  const secret = await vault.read('secret/data/activepieces/mcp');

  return {
    apiKey: secret.data.data.api_key,
    serverUrl: secret.data.data.server_url
  };
};
```

#### AWS Secrets Manager Integration

```javascript
// Retrieve MCP credentials from AWS Secrets Manager
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

export const code = async (params) => {
  const client = new SecretsManagerClient({ region: "us-east-1" });

  const command = new GetSecretValueCommand({
    SecretId: "activepieces/mcp/credentials"
  });

  const response = await client.send(command);
  const secret = JSON.parse(response.SecretString);

  return {
    apiKey: secret.api_key,
    serverUrl: secret.server_url
  };
};
```

### 5.6 MCP Permission Manifest

Review and configure MCP permissions:

```json
{
  "mcpPermissions": {
    "flows": {
      "read": true,
      "execute": true,
      "create": false,
      "update": false,
      "delete": false
    },
    "projects": {
      "read": true,
      "create": false,
      "update": false,
      "delete": false
    },
    "connections": {
      "read": false,
      "create": false,
      "update": false,
      "delete": false
    }
  }
}
```

### 5.7 MCP Security Best Practices

1. **Use OAuth over static keys** - Implement automatic token rotation
2. **Limit token lifespan** - Short-lived tokens reduce security risk
3. **Implement permission scoping** - Grant only necessary permissions
4. **Rotate tokens regularly** - Automated rotation every 30-90 days
5. **Store tokens in secrets managers** - Never hardcode in configuration files
6. **Monitor token usage** - Track and audit all MCP API calls
7. **Implement rate limiting** - Protect against abuse
8. **Use HTTPS exclusively** - All MCP communication should be encrypted
9. **Validate client certificates** - For additional authentication layer
10. **Regular security audits** - Review MCP configurations quarterly

---

## 6. Rate Limiting and Abuse Prevention

### 6.1 Built-in Rate Limit Handling

Activepieces automatically handles rate limits from external APIs:

- **Automatic retry mechanism**: Detects rate limit errors (429 Too Many Requests) and retries after appropriate delay
- **Exponential backoff**: Increases wait time between retries
- **Error handling**: Prevents workflow failures due to rate limiting

### 6.2 Queue-Based Throttling

Use the Queue piece for managing flow execution rates:

```javascript
// Queue configuration for rate limiting
{
  "queue": {
    "name": "api-requests",
    "mode": "FIFO",
    "settings": {
      "maxConcurrent": 5,  // Max 5 concurrent requests
      "delayBetweenJobs": 1000,  // 1 second between jobs
      "maxRetries": 3
    }
  }
}
```

#### Example: Rate-Limited API Calls

```javascript
// Flow with queue-based rate limiting
{
  "trigger": "schedule",
  "steps": [
    {
      "type": "queue.enqueue",
      "settings": {
        "queueName": "api-requests",
        "data": "{{trigger.items}}"
      }
    },
    {
      "type": "queue.process",
      "settings": {
        "queueName": "api-requests",
        "maxConcurrent": 5,
        "action": {
          "type": "http",
          "method": "POST",
          "url": "{{item.url}}",
          "body": "{{item.data}}"
        }
      }
    }
  ]
}
```

### 6.3 Flow Execution Limits

Configure execution limits to prevent abuse:

```bash
# Environment variables for execution limits
AP_MAX_CONCURRENT_FLOWS=100  # Maximum concurrent flow executions
AP_MAX_FLOW_DURATION=300000  # Max duration 5 minutes (milliseconds)
AP_MAX_FLOW_STEPS=100        # Maximum steps per flow
```

### 6.4 Webhook Rate Limiting

Implement rate limiting for webhook endpoints:

```javascript
// Custom rate limiting for webhooks
import rateLimit from 'express-rate-limit';

export const code = async (params) => {
  const { request, rateLimitConfig } = params;

  // Simple in-memory rate limiter
  const requests = new Map();
  const limit = rateLimitConfig.maxRequests || 100;
  const window = rateLimitConfig.windowMs || 60000; // 1 minute

  const clientId = request.headers['x-client-id'] || request.ip;
  const now = Date.now();

  // Get client's request history
  const clientRequests = requests.get(clientId) || [];

  // Remove old requests outside the time window
  const recentRequests = clientRequests.filter(time => now - time < window);

  // Check if limit exceeded
  if (recentRequests.length >= limit) {
    throw new Error('Rate limit exceeded. Please try again later.');
  }

  // Add current request
  recentRequests.push(now);
  requests.set(clientId, recentRequests);

  return { allowed: true, remaining: limit - recentRequests.length };
};
```

### 6.5 IP-Based Restrictions

For self-hosted deployments, implement IP whitelisting:

#### Nginx Configuration

```nginx
# Allow specific IP addresses
location /api/v1/webhooks {
    allow 192.168.1.0/24;
    allow 10.0.0.0/8;
    deny all;

    proxy_pass http://activepieces:3000;
}
```

#### Firewall Rules

```bash
# UFW firewall rules
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw allow from 10.0.0.0/8 to any port 3000
sudo ufw deny 3000
```

### 6.6 Abuse Prevention Strategies

#### Request Validation

```javascript
// Validate webhook payloads
export const code = async (params) => {
  const { body, maxPayloadSize } = params;

  // Check payload size
  const payloadSize = JSON.stringify(body).length;
  if (payloadSize > (maxPayloadSize || 1000000)) { // 1MB default
    throw new Error('Payload too large');
  }

  // Validate required fields
  const requiredFields = ['id', 'event', 'timestamp'];
  for (const field of requiredFields) {
    if (!body[field]) {
      throw new Error(`Missing required field: ${field}`);
    }
  }

  // Validate timestamp (prevent replay attacks)
  const requestTime = new Date(body.timestamp);
  const now = new Date();
  const maxAge = 300000; // 5 minutes

  if (now - requestTime > maxAge) {
    throw new Error('Request too old (possible replay attack)');
  }

  return { valid: true };
};
```

#### Monitoring and Alerting

```javascript
// Monitor for suspicious activity
export const code = async (params) => {
  const { executionStats, thresholds } = params;

  const alerts = [];

  // Check for high error rate
  const errorRate = executionStats.errors / executionStats.total;
  if (errorRate > (thresholds.errorRate || 0.1)) {
    alerts.push({
      type: 'HIGH_ERROR_RATE',
      severity: 'WARNING',
      message: `Error rate ${(errorRate * 100).toFixed(2)}% exceeds threshold`
    });
  }

  // Check for unusual execution volume
  if (executionStats.total > (thresholds.maxExecutions || 10000)) {
    alerts.push({
      type: 'HIGH_VOLUME',
      severity: 'WARNING',
      message: `Execution count ${executionStats.total} exceeds threshold`
    });
  }

  // Check for repeated failures from same source
  const failuresBySource = new Map();
  for (const execution of executionStats.recent) {
    if (execution.status === 'FAILED') {
      const count = failuresBySource.get(execution.source) || 0;
      failuresBySource.set(execution.source, count + 1);
    }
  }

  for (const [source, count] of failuresBySource) {
    if (count > (thresholds.maxFailuresPerSource || 10)) {
      alerts.push({
        type: 'REPEATED_FAILURES',
        severity: 'CRITICAL',
        message: `Source ${source} has ${count} failures`,
        action: 'CONSIDER_BLOCKING'
      });
    }
  }

  return { alerts };
};
```

### 6.7 Resource Protection

```bash
# Docker resource limits
services:
  activepieces:
    image: activepieces/activepieces:latest
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '0.5'
          memory: 1G
```

### 6.8 Rate Limiting Best Practices

1. **Implement graceful degradation** - Queue requests instead of rejecting them
2. **Use distributed rate limiting** - For multi-instance deployments (Redis-based)
3. **Provide rate limit headers** - Inform clients of their limits
4. **Different limits for different endpoints** - Apply appropriate limits based on resource cost
5. **Monitor rate limit metrics** - Track how often limits are hit
6. **Implement circuit breakers** - Prevent cascading failures
7. **Use adaptive rate limiting** - Adjust limits based on system load
8. **Whitelist trusted sources** - Allow higher limits for known partners
9. **Log rate limit violations** - Track potential abuse attempts
10. **Communicate limits clearly** - Document rate limits in API documentation

---

## 7. Example Secure Flow Configurations

### 7.1 Secure API Integration Flow

```json
{
  "displayName": "Secure API Integration",
  "triggers": [
    {
      "name": "webhook_trigger",
      "type": "webhook",
      "settings": {
        "authentication": {
          "type": "HEADER",
          "headerName": "X-API-Key",
          "expectedValue": "{{connections.api_secret}}"
        }
      }
    }
  ],
  "steps": [
    {
      "name": "validate_input",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { body } = params.request;\n  \n  // Input validation\n  if (!body || typeof body !== 'object') {\n    throw new Error('Invalid request body');\n  }\n  \n  // Sanitize input\n  const sanitized = {\n    email: String(body.email).trim().toLowerCase(),\n    name: String(body.name).trim(),\n    timestamp: new Date().toISOString()\n  };\n  \n  // Validate email format\n  const emailRegex = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;\n  if (!emailRegex.test(sanitized.email)) {\n    throw new Error('Invalid email format');\n  }\n  \n  return sanitized;\n};"
        }
      }
    },
    {
      "name": "call_external_api",
      "type": "http",
      "settings": {
        "method": "POST",
        "url": "{{connections.external_api.url}}",
        "headers": {
          "Authorization": "Bearer {{connections.external_api.token}}",
          "Content-Type": "application/json"
        },
        "body": "{{steps.validate_input.output}}",
        "timeout": 30000,
        "failureHandling": {
          "retries": 3,
          "retryDelay": 1000
        }
      }
    },
    {
      "name": "log_success",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { input, response } = params;\n  \n  // Log with masked sensitive data\n  const logEntry = {\n    timestamp: new Date().toISOString(),\n    email: input.email.replace(/(.{2})(.*)(@.*)/, '$1***$3'),\n    status: response.status,\n    success: true\n  };\n  \n  console.log('API call successful:', logEntry);\n  return logEntry;\n};"
        }
      }
    }
  ]
}
```

### 7.2 Database Operations with Security

```json
{
  "displayName": "Secure Database Operations",
  "triggers": [
    {
      "name": "schedule_trigger",
      "type": "schedule",
      "settings": {
        "cronExpression": "0 */6 * * *"
      }
    }
  ],
  "steps": [
    {
      "name": "query_database",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { Pool } = require('pg');\n  \n  // Use connection from Activepieces\n  const dbConfig = params.connections.postgres_readonly;\n  \n  const pool = new Pool({\n    host: dbConfig.host,\n    port: dbConfig.port,\n    database: dbConfig.database,\n    user: dbConfig.user,\n    password: dbConfig.password,\n    ssl: { rejectUnauthorized: true },\n    max: 10,\n    idleTimeoutMillis: 30000,\n    connectionTimeoutMillis: 10000\n  });\n  \n  try {\n    // Use parameterized query to prevent SQL injection\n    const query = 'SELECT id, email, created_at FROM users WHERE created_at > $1 LIMIT $2';\n    const values = [params.sinceDate, params.limit || 100];\n    \n    const result = await pool.query(query, values);\n    \n    // Mask sensitive data\n    const masked = result.rows.map(row => ({\n      ...row,\n      email: row.email.replace(/(.{2})(.*)(@.*)/, '$1***$3')\n    }));\n    \n    return masked;\n  } finally {\n    await pool.end();\n  }\n};"
        }
      }
    },
    {
      "name": "process_records",
      "type": "loop",
      "settings": {
        "items": "{{steps.query_database.output}}",
        "action": {
          "type": "code",
          "settings": {
            "sourceCode": {
              "code": "export const code = async (params) => {\n  const record = params.item;\n  \n  // Process record with encryption\n  const crypto = require('crypto');\n  const encryptionKey = params.connections.encryption_key;\n  \n  // Encrypt sensitive field\n  const cipher = crypto.createCipher('aes-256-cbc', encryptionKey);\n  let encrypted = cipher.update(record.email, 'utf8', 'hex');\n  encrypted += cipher.final('hex');\n  \n  return {\n    id: record.id,\n    encryptedEmail: encrypted,\n    processed: true\n  };\n};"
            }
          }
        }
      }
    }
  ]
}
```

### 7.3 Multi-Factor Authentication Flow

```json
{
  "displayName": "MFA Authentication Flow",
  "triggers": [
    {
      "name": "login_webhook",
      "type": "webhook",
      "settings": {
        "authentication": {
          "type": "HEADER",
          "headerName": "X-App-Secret",
          "expectedValue": "{{connections.app_secret}}"
        }
      }
    }
  ],
  "steps": [
    {
      "name": "validate_credentials",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { username, password } = params.request.body;\n  \n  // Validate input\n  if (!username || !password) {\n    throw new Error('Missing credentials');\n  }\n  \n  // Hash password for comparison\n  const crypto = require('crypto');\n  const hashedPassword = crypto\n    .createHash('sha256')\n    .update(password)\n    .digest('hex');\n  \n  // Verify against database (using parameterized query)\n  return {\n    username: username.toLowerCase().trim(),\n    passwordHash: hashedPassword\n  };\n};"
        }
      }
    },
    {
      "name": "check_user_exists",
      "type": "database.query",
      "settings": {
        "connection": "{{connections.postgres}}",
        "query": "SELECT id, username, password_hash, mfa_enabled FROM users WHERE username = $1",
        "parameters": ["{{steps.validate_credentials.output.username}}"]
      }
    },
    {
      "name": "verify_password",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { user, providedHash } = params;\n  \n  if (!user || user.password_hash !== providedHash) {\n    // Log failed attempt\n    console.log('Failed login attempt for:', user?.username || 'unknown');\n    throw new Error('Invalid credentials');\n  }\n  \n  return user;\n};"
        }
      }
    },
    {
      "name": "send_mfa_code",
      "type": "branch",
      "settings": {
        "condition": "{{steps.check_user_exists.output.mfa_enabled}}",
        "ifTrue": [
          {
            "name": "generate_mfa_code",
            "type": "code",
            "settings": {
              "sourceCode": {
                "code": "export const code = async (params) => {\n  const crypto = require('crypto');\n  \n  // Generate 6-digit code\n  const code = crypto.randomInt(100000, 999999).toString();\n  \n  // Store code with expiration (5 minutes)\n  const expiresAt = new Date();\n  expiresAt.setMinutes(expiresAt.getMinutes() + 5);\n  \n  return {\n    code: code,\n    expiresAt: expiresAt.toISOString()\n  };\n};"
              }
            }
          },
          {
            "name": "send_code_email",
            "type": "email.send",
            "settings": {
              "to": "{{steps.check_user_exists.output.email}}",
              "subject": "Your MFA Code",
              "body": "Your verification code is: {{steps.generate_mfa_code.output.code}}"
            }
          }
        ]
      }
    },
    {
      "name": "create_session",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { userId } = params;\n  const crypto = require('crypto');\n  \n  // Generate secure session token\n  const sessionToken = crypto.randomBytes(32).toString('hex');\n  \n  // Set expiration (1 hour)\n  const expiresAt = new Date();\n  expiresAt.setHours(expiresAt.getHours() + 1);\n  \n  return {\n    sessionToken: sessionToken,\n    userId: userId,\n    expiresAt: expiresAt.toISOString(),\n    createdAt: new Date().toISOString()\n  };\n};"
        }
      }
    }
  ]
}
```

### 7.4 Secure File Upload and Processing

```json
{
  "displayName": "Secure File Upload",
  "triggers": [
    {
      "name": "file_webhook",
      "type": "webhook",
      "settings": {
        "authentication": {
          "type": "BASIC_AUTH",
          "username": "{{connections.upload_user}}",
          "password": "{{connections.upload_pass}}"
        }
      }
    }
  ],
  "steps": [
    {
      "name": "validate_file",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const { file } = params.request;\n  \n  // Validate file type\n  const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];\n  if (!allowedTypes.includes(file.type)) {\n    throw new Error('Invalid file type');\n  }\n  \n  // Validate file size (10MB max)\n  const maxSize = 10 * 1024 * 1024;\n  if (file.size > maxSize) {\n    throw new Error('File too large');\n  }\n  \n  // Generate secure filename\n  const crypto = require('crypto');\n  const hash = crypto.createHash('sha256').update(file.name).digest('hex');\n  const ext = file.name.split('.').pop();\n  const secureFilename = `${hash}.${ext}`;\n  \n  return {\n    originalName: file.name,\n    secureFilename: secureFilename,\n    type: file.type,\n    size: file.size\n  };\n};"
        }
      }
    },
    {
      "name": "virus_scan",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  // Integrate with virus scanning service\n  // Example: ClamAV, VirusTotal API\n  \n  const scanResult = await scanFile(params.file);\n  \n  if (scanResult.infected) {\n    throw new Error('File failed virus scan');\n  }\n  \n  return { clean: true, scannedAt: new Date().toISOString() };\n};"
        }
      }
    },
    {
      "name": "store_file",
      "type": "storage.upload",
      "settings": {
        "connection": "{{connections.s3_storage}}",
        "bucket": "secure-uploads",
        "filename": "{{steps.validate_file.output.secureFilename}}",
        "encryption": "AES256",
        "acl": "private"
      }
    },
    {
      "name": "log_upload",
      "type": "database.insert",
      "settings": {
        "connection": "{{connections.postgres}}",
        "table": "file_uploads",
        "data": {
          "filename": "{{steps.validate_file.output.secureFilename}}",
          "original_name": "{{steps.validate_file.output.originalName}}",
          "type": "{{steps.validate_file.output.type}}",
          "size": "{{steps.validate_file.output.size}}",
          "uploaded_by": "{{trigger.headers.x-user-id}}",
          "uploaded_at": "{{$now}}"
        }
      }
    }
  ]
}
```

### 7.5 Encrypted Data Transfer Flow

```json
{
  "displayName": "Encrypted Data Transfer",
  "triggers": [
    {
      "name": "data_sync_schedule",
      "type": "schedule",
      "settings": {
        "cronExpression": "0 2 * * *"
      }
    }
  ],
  "steps": [
    {
      "name": "fetch_data",
      "type": "database.query",
      "settings": {
        "connection": "{{connections.source_db}}",
        "query": "SELECT * FROM sensitive_data WHERE synced = false LIMIT 1000"
      }
    },
    {
      "name": "encrypt_data",
      "type": "code",
      "settings": {
        "sourceCode": {
          "code": "export const code = async (params) => {\n  const crypto = require('crypto');\n  const { records, encryptionKey } = params;\n  \n  // Encryption configuration\n  const algorithm = 'aes-256-gcm';\n  const key = Buffer.from(encryptionKey, 'hex');\n  \n  const encrypted = records.map(record => {\n    // Generate unique IV for each record\n    const iv = crypto.randomBytes(16);\n    const cipher = crypto.createCipheriv(algorithm, key, iv);\n    \n    // Encrypt the entire record\n    let encrypted = cipher.update(JSON.stringify(record), 'utf8', 'hex');\n    encrypted += cipher.final('hex');\n    \n    // Get auth tag\n    const authTag = cipher.getAuthTag();\n    \n    return {\n      id: record.id,\n      data: encrypted,\n      iv: iv.toString('hex'),\n      authTag: authTag.toString('hex')\n    };\n  });\n  \n  return encrypted;\n};"
        }
      }
    },
    {
      "name": "transfer_data",
      "type": "http",
      "settings": {
        "method": "POST",
        "url": "{{connections.destination_api.url}}",
        "headers": {
          "Authorization": "Bearer {{connections.destination_api.token}}",
          "Content-Type": "application/json",
          "X-Encryption": "AES-256-GCM"
        },
        "body": "{{steps.encrypt_data.output}}",
        "ssl": {
          "verify": true,
          "minVersion": "TLSv1.2"
        }
      }
    },
    {
      "name": "mark_synced",
      "type": "database.update",
      "settings": {
        "connection": "{{connections.source_db}}",
        "query": "UPDATE sensitive_data SET synced = true, synced_at = NOW() WHERE id = ANY($1)",
        "parameters": ["{{steps.fetch_data.output.map(r => r.id)}}"]
      }
    }
  ]
}
```

---

## 8. Production Deployment Checklist

### 8.1 Pre-Deployment Security Checklist

- [ ] **Generate secure secrets**
  ```bash
  openssl rand -hex 32  # JWT_SECRET
  openssl rand -hex 16  # ENCRYPTION_KEY
  openssl rand -hex 16  # DB_PASSWORD
  ```

- [ ] **Configure HTTPS/SSL**
  - [ ] SSL certificate installed
  - [ ] TLS 1.2+ enforced
  - [ ] HTTP to HTTPS redirect enabled
  - [ ] HSTS headers configured

- [ ] **Database security**
  - [ ] Strong database password set
  - [ ] SSL/TLS enabled for database connections
  - [ ] Database user permissions limited (principle of least privilege)
  - [ ] Database backups encrypted
  - [ ] Backup retention policy configured

- [ ] **Environment variables**
  - [ ] All secrets stored in environment variables
  - [ ] No hardcoded credentials in code
  - [ ] `.env` file in `.gitignore`
  - [ ] Production secrets separate from development

- [ ] **Authentication**
  - [ ] SSO configured (if applicable)
  - [ ] API key rotation policy established
  - [ ] Password complexity requirements set
  - [ ] MFA enabled for admin accounts

- [ ] **Access control**
  - [ ] RBAC roles configured
  - [ ] User permissions reviewed
  - [ ] Admin access limited
  - [ ] Service accounts for automation only

### 8.2 Sandboxing Configuration

Choose appropriate sandboxing mode:

#### Multi-Tenant Setup (Recommended: V8 Sandboxing)

```bash
# V8 sandboxing - secure for multi-tenant
AP_EXECUTION_MODE=SANDBOXED
AP_SANDBOX_TYPE=V8

# Pros:
# - Secure isolation
# - No privileged Docker access needed
# - Safe for untrusted code

# Cons:
# - Slower than unsandboxed
# - Some limitations on available packages
```

#### Single-Tenant Setup (Option: No Sandboxing)

```bash
# No sandboxing - faster but less secure
AP_EXECUTION_MODE=UNSANDBOXED

# Pros:
# - 50x faster processing
# - Full system access
# - No Docker privileges required

# Cons:
# - Only for trusted code
# - Cannot allow user signups
# - Access to environment variables and filesystem
```

**Warning**: Never use `UNSANDBOXED` mode with user registrations enabled or untrusted code.

### 8.3 Storage Configuration

#### Database Storage (Default)

```bash
# Store logs and files in database
AP_FILE_STORAGE_TYPE=DATABASE

# Suitable for:
# - Most deployments
# - Low to medium traffic
# - Simple setup
```

#### S3 Storage (Recommended for Production)

```bash
# Use S3 for files and logs
AP_FILE_STORAGE_TYPE=S3
AP_S3_BUCKET=activepieces-production
AP_S3_REGION=us-east-1
AP_S3_ACCESS_KEY_ID=your_access_key
AP_S3_SECRET_ACCESS_KEY=your_secret_key
AP_S3_SIGNED_URL_ENABLED=true

# Benefits:
# - Reduces database load
# - Better scalability
# - Automatic backups
# - Cost-effective for large files
```

### 8.4 Network Security

#### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 22/tcp     # SSH (restrict to specific IPs)
sudo ufw deny 80/tcp      # Deny HTTP (redirect to HTTPS)
sudo ufw enable
```

#### IP Whitelisting

For database access:

```bash
# PostgreSQL pg_hba.conf
host    activepieces    ap_user    192.168.1.0/24    md5
host    activepieces    ap_user    10.0.0.0/8        md5
```

For Nginx reverse proxy:

```nginx
location /api/v1/admin {
    allow 192.168.1.0/24;
    allow 10.0.0.0/8;
    deny all;

    proxy_pass http://activepieces:3000;
}
```

### 8.5 Monitoring and Logging

#### Configure Audit Logging

```bash
# Enable comprehensive audit logs
AP_AUDIT_LOG_ENABLED=true
AP_AUDIT_LOG_RETENTION_DAYS=90

# Log levels
AP_LOG_LEVEL=INFO  # Use ERROR for production, DEBUG for troubleshooting
```

#### Set Up Monitoring

```yaml
# Prometheus monitoring
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=secure_password
```

#### Health Checks

```yaml
# Docker Compose health checks
services:
  activepieces:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 8.6 Backup and Disaster Recovery

#### Database Backups

```bash
# Automated PostgreSQL backups
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create encrypted backup
pg_dump -U ${AP_POSTGRES_USERNAME} \
        -h ${AP_POSTGRES_HOST} \
        ${AP_POSTGRES_DATABASE} | \
gpg --encrypt --recipient admin@example.com > \
${BACKUP_DIR}/activepieces_${DATE}.sql.gpg

# Rotate old backups (keep last 30 days)
find ${BACKUP_DIR} -name "*.sql.gpg" -mtime +30 -delete
```

#### Docker Volume Backups

```bash
# Backup Docker volumes
docker run --rm \
  -v activepieces_data:/data \
  -v /backups:/backup \
  alpine tar czf /backup/activepieces_data_$(date +%Y%m%d).tar.gz /data
```

### 8.7 Resource Limits

```yaml
# Docker Compose resource limits
version: '3.8'
services:
  activepieces:
    image: activepieces/activepieces:latest
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '0.5'
          memory: 1G
    environment:
      - AP_MAX_CONCURRENT_FLOWS=100
      - AP_MAX_FLOW_DURATION=300000
```

### 8.8 Update Strategy

#### Version Control

```bash
# Pin to specific version for stability
AP_VERSION=0.25.0

# Use image tag in docker-compose.yml
image: activepieces/activepieces:0.25.0
```

#### Update Process

1. **Test in staging environment**
2. **Backup database and volumes**
3. **Review changelog for breaking changes**
4. **Update image version**
5. **Run migrations** (if required)
6. **Monitor for errors**
7. **Rollback plan ready**

### 8.9 Compliance Configuration

#### GDPR Compliance

```bash
# Data retention settings
AP_EXECUTION_DATA_RETENTION_DAYS=30
AP_AUDIT_LOG_RETENTION_DAYS=90
AP_PERSONAL_DATA_RETENTION_DAYS=365

# Enable data export/deletion APIs
AP_GDPR_ENABLED=true
```

#### SOC 2 Compliance Features

- [ ] Encryption at rest enabled
- [ ] Encryption in transit (TLS 1.2+)
- [ ] Audit logging enabled
- [ ] Access controls configured
- [ ] Regular security audits scheduled
- [ ] Incident response plan documented

### 8.10 Security Headers

Configure security headers in reverse proxy:

```nginx
# Nginx security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

---

## 9. Additional Security Considerations

### 9.1 Flow Versioning and Rollback

Activepieces includes built-in version control:

#### Version Management

- **Automatic versioning**: New version created on each save
- **Version comparison**: View differences between versions
- **Rollback capability**: Restore previous versions instantly
- **Draft vs. Published**: Test changes before deploying

#### Security Benefits

```javascript
// Example: Automated version backup before changes
{
  "name": "backup_before_update",
  "type": "code",
  "settings": {
    "sourceCode": {
      "code": "export const code = async (params) => {\n  const { flowId, currentVersion } = params;\n  \n  // Create backup before making changes\n  const backup = {\n    flowId: flowId,\n    version: currentVersion,\n    timestamp: new Date().toISOString(),\n    backupReason: 'pre-update-snapshot'\n  };\n  \n  // Store backup metadata\n  await storeBackup(backup);\n  \n  return { backupCreated: true };\n};"
    }
  }
}
```

### 9.2 Code Execution Security

#### Sandboxed Execution

Workers execute flows in sandboxed environments:

- **Process isolation**: Each flow runs in a separate process
- **Resource limits**: CPU and memory constraints enforced
- **Timeout protection**: Automatic termination of long-running code
- **Network isolation** (optional): Restrict external network access

#### Custom Code Best Practices

```javascript
// Secure custom code example
export const code = async (params) => {
  // 1. Input validation
  if (!params.data || typeof params.data !== 'object') {
    throw new Error('Invalid input');
  }

  // 2. Sanitize user input
  const sanitized = {
    name: String(params.data.name).replace(/[<>]/g, ''),
    email: String(params.data.email).toLowerCase().trim()
  };

  // 3. Use try-catch for error handling
  try {
    // 4. Limit external API calls
    const response = await fetch(params.apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${params.connections.api_token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(sanitized),
      timeout: 10000  // 10 second timeout
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return await response.json();

  } catch (error) {
    // 5. Don't expose internal errors
    console.error('Internal error:', error);
    throw new Error('Processing failed');
  }
};
```

### 9.3 Third-Party Integration Security

#### OAuth Connection Security

```javascript
// Verify OAuth token before use
{
  "name": "verify_oauth_token",
  "type": "code",
  "settings": {
    "sourceCode": {
      "code": "export const code = async (params) => {\n  const { accessToken, expiresAt } = params.connections.oauth;\n  \n  // Check token expiration\n  const now = new Date();\n  const expiry = new Date(expiresAt);\n  \n  if (now >= expiry) {\n    throw new Error('OAuth token expired - please reconnect');\n  }\n  \n  // Verify token is still valid with provider\n  const verifyResponse = await fetch('https://provider.com/oauth/verify', {\n    headers: { 'Authorization': `Bearer ${accessToken}` }\n  });\n  \n  if (!verifyResponse.ok) {\n    throw new Error('OAuth token invalid - please reconnect');\n  }\n  \n  return { valid: true };\n};"
    }
  }
}
```

#### API Rate Limit Handling

```javascript
// Respect third-party API rate limits
{
  "name": "api_with_rate_limit",
  "type": "code",
  "settings": {
    "sourceCode": {
      "code": "export const code = async (params) => {\n  const maxRetries = 3;\n  let retryCount = 0;\n  \n  while (retryCount < maxRetries) {\n    try {\n      const response = await fetch(params.apiUrl, {\n        headers: { 'Authorization': `Bearer ${params.apiKey}` }\n      });\n      \n      // Check for rate limit\n      if (response.status === 429) {\n        const retryAfter = response.headers.get('Retry-After') || 60;\n        console.log(`Rate limited. Waiting ${retryAfter} seconds...`);\n        \n        await new Promise(resolve => \n          setTimeout(resolve, retryAfter * 1000)\n        );\n        \n        retryCount++;\n        continue;\n      }\n      \n      return await response.json();\n      \n    } catch (error) {\n      if (retryCount === maxRetries - 1) throw error;\n      retryCount++;\n    }\n  }\n};"
    }
  }
}
```

### 9.4 Secrets Rotation Strategy

#### Automated Secret Rotation

```bash
#!/bin/bash
# Rotate API keys monthly

# Generate new key
NEW_KEY=$(openssl rand -hex 32)

# Update in secrets manager
aws secretsmanager update-secret \
  --secret-id activepieces/api-key \
  --secret-string "{\"key\":\"${NEW_KEY}\"}"

# Update Activepieces configuration
kubectl set env deployment/activepieces \
  AP_API_KEY=${NEW_KEY}

# Verify new key works
curl -H "Authorization: Bearer ${NEW_KEY}" \
  https://activepieces.example.com/api/v1/health

# Deactivate old key after grace period
sleep 3600  # 1 hour grace period
# Revoke old key here
```

### 9.5 Incident Response

#### Security Incident Checklist

1. **Detection**
   - Monitor audit logs for suspicious activity
   - Set up alerts for failed authentication attempts
   - Track unusual API usage patterns

2. **Containment**
   - Immediately revoke compromised credentials
   - Block suspicious IP addresses
   - Disable affected user accounts

3. **Investigation**
   - Review audit logs
   - Identify scope of breach
   - Document timeline of events

4. **Remediation**
   - Rotate all potentially compromised secrets
   - Patch vulnerabilities
   - Update security configurations

5. **Recovery**
   - Restore from clean backups
   - Verify system integrity
   - Re-enable services gradually

6. **Post-Incident**
   - Conduct post-mortem analysis
   - Update security procedures
   - Train team on lessons learned

### 9.6 Security Reporting

#### Contact Information

For security vulnerabilities, contact:
- **Email**: security@activepieces.com
- **PGP Key**: Available on security page
- **Response Time**: Within 48 hours

#### Vulnerability Disclosure

Include in reports:
- Detailed description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested remediation (if any)

### 9.7 Regular Security Audits

#### Monthly Checklist

- [ ] Review user access permissions
- [ ] Audit API key usage
- [ ] Check for unused connections
- [ ] Review audit logs for anomalies
- [ ] Verify backup integrity
- [ ] Test disaster recovery procedures
- [ ] Update dependencies
- [ ] Review flow execution patterns

#### Quarterly Checklist

- [ ] Rotate API keys and secrets
- [ ] Review and update RBAC policies
- [ ] Conduct penetration testing
- [ ] Review compliance requirements
- [ ] Update incident response plan
- [ ] Security awareness training
- [ ] Third-party security assessment

### 9.8 Compliance and Certifications

#### SOC 2 Type II Compliance

Activepieces is SOC 2 Type II certified, ensuring:
- **Security**: Protection against unauthorized access
- **Availability**: System uptime and reliability
- **Confidentiality**: Sensitive data protection

#### GDPR Compliance

Features supporting GDPR:
- **Data portability**: Export user data on request
- **Right to erasure**: Delete user data completely
- **Data encryption**: Both at rest and in transit
- **Audit trails**: Complete data processing logs
- **Consent management**: Track user consent for data processing

#### HIPAA Considerations

For healthcare data:
- Self-host for complete data control
- Enable encryption at rest and in transit
- Implement comprehensive audit logging
- Use BAA-compliant infrastructure
- Regular security audits

---

## Summary

This comprehensive security guide covers all major aspects of Activepieces security:

1. **API Token Management**: 256-bit encryption, secure generation, rotation policies
2. **Webhook Security**: Header auth, basic auth, HMAC verification (custom implementation)
3. **Access Control**: RBAC, SSO integration, audit logging
4. **Database Security**: SSL connections, parameterized queries, least privilege access
5. **MCP Server**: OAuth2 flows, token management, secrets managers
6. **Rate Limiting**: Built-in handling, queue-based throttling, abuse prevention
7. **Secure Flows**: Complete examples with encryption, validation, MFA

### Key Takeaways

- **Defense in Depth**: Multiple layers of security protection
- **Principle of Least Privilege**: Grant minimum necessary permissions
- **Encryption Everywhere**: Data encrypted at rest and in transit
- **Regular Audits**: Continuous monitoring and security reviews
- **Incident Preparedness**: Clear response procedures
- **Compliance Ready**: SOC 2, GDPR, and HIPAA support

### Additional Resources

- **Official Documentation**: https://www.activepieces.com/docs
- **Security Practices**: https://www.activepieces.com/docs/security/practices
- **Community Forum**: https://community.activepieces.com
- **GitHub Repository**: https://github.com/activepieces/activepieces
- **Security Reporting**: security@activepieces.com

---

**Document Version**: 1.0
**Last Updated**: December 23, 2025
**Maintained By**: EDC Web Security Team
