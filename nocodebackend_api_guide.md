# NoCodeBackend API Call Documentation
## Facts from Knowledge Base (1245 Frames from Tutorial Videos)

Based on analysis of the NoCodeBackend tutorial knowledge base, here are the verified facts about how the NoCodeBackend API actually works.

---

## 1. API Endpoint Structure

### General Format
```
{HTTP_METHOD} /{action}/{table_name}
```

### Verified Endpoints from Tutorials
The tutorials show these endpoint patterns:

**Create (POST):**
- `POST /create/clinics` - Create a new record in clinics table
- `POST /create/medicines` - Create a new record in medicines table
- `POST /create/doctors` - Create a new record in doctors table

**Read (GET):**
- `GET /read/clinics` - Retrieve all records from clinics
- `GET /read/clinics/{id}` - Retrieve a specific record by ID
- `GET /read/medicines` - Retrieve all records from medicines
- `GET /read/doctors` - Retrieve all records from doctors

**Search (POST):**
- `POST /search/clinics` - Search for records in clinics
- `POST /search/doctors` - Search for records in doctors
- `POST /search/medicines` - Search for records in medicines

**Update (PUT):**
- `PUT /update/clinics/{id}` - Update a record in clinics
- `PUT /update/doctors/{id}` - Update a record in doctors

**Delete (DELETE):**
- `DELETE /delete/clinics/{id}` - Delete a record from clinics
- `DELETE /delete/doctors/{id}` - Delete a record from doctors

---

## 2. Table Names and Instances - CRITICAL INFORMATION

### The Instance Parameter (Required)

**The Instance parameter is NOT a table reference - it is a DATABASE INSTANCE NAME.**

From the tutorial documentation:
- Instance format: `{number}_{database_name}` 
- Example: `32939_pharmacy`
- Type: String (query parameter or request body)
- Required: YES for all API calls

### How Instance Works

The Instance is used in two ways:

**1. Query Parameter (for GET requests):**
```
GET /read/medicines?Instance=32939_pharmacy&page=1&limit=10
```

**2. Request Body (for POST/PUT requests):**
```json
{
  "Instance": "32939_pharmacy",
  "pain_killers": "string",
  "manufactured_date": "2025-08-10",
  "expiry_date": "2025-08-10",
  "date_diff": "string"
}
```

### Table Naming Conventions

Table names in NoCodeBackend:
- Use lowercase names: `clinics`, `medicines`, `doctors`, `category`, `orders`, `products`, `reviews`
- No spaces or special characters
- Match the URL path exactly: if table is `medicines`, endpoint is `/read/medicines`

### Default Instance Example from Tutorials
The tutorial uses database instance: `32939_pharmacy`
- All API calls to this database include this Instance identifier
- Instance remains consistent across all CRUD operations on that database

---

## 3. POST Request Format for Creating Records

### Example 1: POST /create/medicines

**Request URL:**
```
POST http://localhost:3000/create/medicines
```

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body (from tutorial):**
```json
{
  "Instance": "32939_pharmacy",
  "pain_killers": "string",
  "manufactured_date": "2025-08-10",
  "expiry_date": "2025-08-10",
  "date_diff": "string"
}
```

**Response (HTTP 200):**
```json
{
  "status": "success",
  "data": [
    {
      "id": 2,
      "pain_killers": "Cough medicine",
      "manufactured_date": "2025-08-02T18:30:00.000Z",
      "expiry_date": "2026-08-09T18:30:00.000Z",
      "date_diff": "372 days"
    }
  ]
}
```

### Key Facts About POST Requests
1. Instance parameter is REQUIRED in the request body
2. Content-Type must be `application/json`
3. Response includes status and data array
4. Data array contains the created records with generated IDs

---

## 4. Query Parameters and Filtering

### Available Operators

From the tutorial filtering documentation:

| Operator | Example | Meaning |
|----------|---------|---------|
| `field` | `?status=active` | Equal (default) |
| `field[ne]` | `?status[ne]=inactive` | Not equal |
| `field[gt]` | `?price[gt]=100` | Greater than |
| `field[gte]` | `?date[gte]=2024-05-01` | Greater than or equal |
| `field[lt]` | `?score[lt]=500` | Less than |
| `field[lte]` | `?score[lte]=800` | Less than or equal |
| `field[in]` | `?type[in]=a,b,c` | In list (comma-separated) |
| `field[like]` | `?name[like]=john` | Partial match |

### Filtering Example
```
GET /read/medicines?Instance=32939_pharmacy&price[gte]=100&price[lte]=200&name[like]=john
```

### Pagination Parameters
- `page` - Page number (default: 1)
- `limit` - Records per page (default: 10)

**Example:**
```
GET /read/medicines?Instance=32939_pharmacy&page=1&limit=10&manufactured_date[gte]=2025-08-01
```

---

## 5. Successful API Calls from Tutorials

### Example 1: GET Request with Pagination
```
GET http://localhost:3000/read/medicines?Instance=32939_pharmacy&page=1&limit=10
```

**cURL Command (from tutorial):**
```bash
curl -X 'GET' \
  'http://localhost:3000/read/medicines?Instance=32939_pharmacy&page=1&limit=10' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer 666c2505b07436230b1240e27f7284c9e7d7d5ffbaf4dc657f4293451'
```

**Response (HTTP 200):**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "pain_killers": "Cough medicine",
      "manufactured_date": "2025-08-02T18:30:00.000Z",
      "expiry_date": "2026-08-09T18:30:00.000Z",
      "date_diff": "372 days"
    },
    {
      "id": 2,
      "pain_killers": "Cough medicine",
      "manufactured_date": "2025-03-01T18:30:00.000Z",
      "expiry_date": "2027-03-10T18:30:00.000Z",
      "date_diff": "740 days"
    }
  ],
  "metadata": {
    "page": 1,
    "limit": 10,
    "total": 2,
    "hasMore": false
  }
}
```

### Example 2: POST Request - Create Record
```bash
curl -X POST \
  http://localhost:3000/create/medicines \
  -H 'Content-Type: application/json' \
  -d '{
    "Instance": "32939_pharmacy",
    "pain_killers": "Aspirin",
    "manufactured_date": "2025-08-10",
    "expiry_date": "2026-08-10",
    "date_diff": "365 days"
  }'
```

**Response (HTTP 201):**
```json
{
  "status": "success",
  "data": [
    {
      "id": 3,
      "pain_killers": "Aspirin",
      "manufactured_date": "2025-08-10T00:00:00.000Z",
      "expiry_date": "2026-08-10T00:00:00.000Z",
      "date_diff": "365 days"
    }
  ]
}
```

### Example 3: GET with Advanced Filtering
```
GET http://localhost:3000/read/medicines?Instance=32939_pharmacy&page=1&limit=10&manufactured_date[gte]=2025-08-01&manufactured_date[lte]=2025-08-10
```

**Response shows filtered records based on date range**

---

## 6. Authentication

NoCodeBackend API uses Bearer token authentication:

```bash
curl -X GET \
  'http://localhost:3000/read/medicines?Instance=32939_pharmacy' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer {TOKEN}'
```

**Token Format:**
- Type: Bearer token
- Location: Authorization header
- Example: `Authorization: Bearer 666c2505b07436230b1240e27f7284c9e7d7d5ffbaf4dc657f4293451`

---

## 7. Response Status Codes

From the tutorial API documentation:

| Status | Meaning |
|--------|---------|
| 200 | Success (GET, POST with data) |
| 201 | Created (POST successful creation) |
| 400 | Bad request (missing/invalid parameters) |
| 500 | Server error (SQL syntax error, etc.) |

### Example Error Response:
```json
{
  "status": "failed",
  "error": "You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near '?' at line 1"
}
```

---

## 8. Server Information from Tutorials

**API Documentation Tool:** Swagger UI (OpenAPI 3.0)
- Accessible at: `http://localhost:3000/api-docs/?instance={Instance}#`

**Server URLs:**
- Local development: `http://localhost:3000`
- Production example: `http://app.nocodebackend.com`

---

## Key Takeaways

1. **Instance is mandatory** - Every API call requires the Instance parameter (database instance name)
2. **Table names are lowercase** - Use exact table names in URL paths
3. **POST requires full request body** - Instance goes in the body, not as query param
4. **GET uses query parameters** - Instance goes as `?Instance=value`
5. **Response format is consistent** - All successful responses have `status` and `data` fields
6. **Filtering is powerful** - Use field[operator] syntax for advanced queries
7. **Pagination is supported** - Use `page` and `limit` parameters
8. **Authentication required** - Bearer token in Authorization header

