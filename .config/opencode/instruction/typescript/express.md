# Express.js Conventions in TypeScript Project

## Router

### File Organization

- **Location**: `src/routes/` directory
- **Naming**: Kebab-case file names matching the resource (e.g., `user.ts`, `task-template.ts`)
- **Root Router**: `src/routes/index.ts` - Central entry point that combines all route modules

### Route Structure

```typescript
import { makeSafeAsync, requestValidator } from '@dayatani/core/middlewares'
import { Router } from 'express'
import CREATE_USER_BODY_SCHEMA from '../schemas/user/create.schema'
import create from '../controllers/user/create.controller'
import verifyAndExtractAccessTokenPayload from '../middlewares/verify-and-extract-access-token-payload'

const userRouter = Router()

userRouter.post(
  '/',
  verifyAndExtractAccessTokenPayload,                    // 1. Authentication
  extractOrganizationId,                                 // 2. Context extraction
  modulePermissionsValidator(...),                       // 3. Authorization
  requestValidator({ body: CREATE_USER_BODY_SCHEMA }),   // 4. Validation
  makeSafeAsync(create)                                  // 5. Controller handler
)

export default userRouter
```

### Middleware Chain Order

Routes follow a consistent middleware order:

1. **Authentication** - `verifyAndExtractAccessTokenPayload`
2. **Context Extraction** - `extractOrganizationId`, `parseAcceptLanguage`
3. **Authorization** - `modulePermissionsValidator`
4. **Request Validation** - `requestValidator`
5. **Controller Handler** - `makeSafeAsync(controllerFn)`

### Schema Composition

Combine multiple schemas using `.and()`:

```typescript
requestValidator({
  query: INDEX_USER_QUERY_PARAMETERS_SCHEMA.and(PAGINATION_QUERY_SCHEMA)
})
```

### Root Router Registration

```typescript
// src/routes/index.ts
const rootRouter = Router()
rootRouter.use('/auth', authRouter)
rootRouter.use('/users', userRouter)
rootRouter.use('/admin/diagnoses', adminDiagnosisRouter)
```

---

## Middleware

### File Organization

- **Location**: `src/middlewares/` directory
- **Naming**: Kebab-case descriptive names (e.g., `verify-and-extract-access-token-payload.ts`)

### Implementation Patterns

**Wrapping core middleware with configuration:**

```typescript
import PUBLIC_KEY_IDENTIFIER from '../constants/public-key-identifier'
import { verifyAndExtractAccessTokenPayload } from '@dayatani/core/middlewares'

export default verifyAndExtractAccessTokenPayload(PUBLIC_KEY_IDENTIFIER)
```

**File upload middleware:**

```typescript
import multer from 'multer'

const IMAGE_FIELD_NAME = 'image'
const requireImageFile = multer().single(IMAGE_FIELD_NAME)

export default requireImageFile
```

### Global Middleware Setup

```typescript
// src/app.ts
app.use(cors())
app.use(morgan(MORGAN_FORMAT))
app.use(compression())
app.use(express.json())
app.use(bodyParserErrorHandler)
app.use(createPgClientPoolInjector(pgClientPool))
app.use('/', rootRouter)
Sentry.setupExpressErrorHandler(app)
app.use(errorHandler)
```

---

## Schema Validation

### Validation Framework

- **Tool**: Zod
- **Location**: `src/schemas/` directory
- **Naming**: Schema files with `.schema.ts` suffix

### File Organization

```
src/schemas/
├── pagination-query.schema.ts
├── user/
│   ├── create.schema.ts
│   ├── index.schema.ts
│   └── update.schema.ts
└── role/
    ├── create.schema.ts
    └── index-query.schema.ts
```

### Schema Patterns

**Basic schema with DTO type satisfaction:**

```typescript
import type CreateUserDto from '../../types/dtos/user/create.dto'
import { z } from 'zod'

const CREATE_USER_BODY_SCHEMA = z.object({
  name: z.string().min(1),
  email: z.email().nullable(),
  is_active: z.boolean(),
  password: z.string().regex(PASSWORD_REGEX),
  phone_number: z.string().max(MAX_PHONE_NUMBER_LENGTH).regex(NUMERIC_REGEX),
  role_id: z.uuid() as ZodUuid,
  project_ids: z.array(z.uuid() as ZodUuid),
}) satisfies z.ZodType<CreateUserDto>

export default CREATE_USER_BODY_SCHEMA
```

**Schema with transform:**

```typescript
const LOGIN_BODY_SCHEMA = z.object({
  phone: z.string(),
  password: z.string(),
  fcm_token: z.string().optional().nullable(),
}).transform((arg): LoginDto => ({
  phone: arg.phone,
  password: arg.password,
  fcm_token: arg.fcm_token ?? null,
}))
```

**Query schema with null fallback:**

```typescript
const INDEX_USER_QUERY_PARAMETERS_SCHEMA = z.object({
  name_search_term: z.string().nullable().catch(null),
  role_ids: z.array(z.uuid() as ZodUuid).nullable().catch(null),
  is_active: COERCE_STRING_TO_BOOLEAN_WITH_NULL_FALLBACK,
}) satisfies z.ZodType<IndexUserQueryDto>
```

### Usage in Routes

```typescript
requestValidator({
  body: CREATE_USER_BODY_SCHEMA,
  query: PAGINATION_QUERY_SCHEMA,
  path: MINI_ENTITY_SCHEMA,
  file: OVERLAID_IMAGE_FILE_SCHEMA
})
```

Validated data is accessible via `request.parsedBody` and `request.parsedQuery`.

---

## Controller

### File Organization

- **Location**: `src/controllers/` directory with hierarchical structure matching routes
- **Naming**: `{operation}.controller.ts` (e.g., `create.controller.ts`, `index.controller.ts`)

```
src/controllers/
├── health.controller.ts
├── auth/
│   ├── login.controller.ts
│   └── refresh.controller.ts
├── user/
│   ├── create.controller.ts
│   ├── index.controller.ts
│   ├── show.controller.ts
│   └── update.controller.ts
```

### Controller Type

Controllers implement the `Controller` type:

```typescript
type Controller = (request: Request, response: Response) => Promise<void>
```

### Implementation Patterns

**List controller:**

```typescript
const index: Controller = async (request, response) => {
  const pgClientPool = request.pgClientPool as PgClientPool
  const parsedQuery = request.parsedQuery as IndexUserQueryDto & PaginationConfig
  const organizationId = request.organizationId as UUID | null

  const [users, count] = await Promise.all([
    findAll(parsedQuery, pgClientPool, organizationId),
    countRepo(parsedQuery, pgClientPool, organizationId),
  ])

  response.status(StatusCodes.OK).json({ users, count } satisfies IndexUserDto)
}

export default index
```

**Create controller with transaction:**

```typescript
const create: Controller = async (request, response) => {
  const pgClientPool = request.pgClientPool as PgClientPool
  const createUserDto = request.parsedBody as CreateUserDto
  const userInsertionPack = await generateUserInsertionPack(createUserDto)

  try {
    const insertOperation = async (pgClient: PgClient): Promise<void> => {
      await validateSupervisor(createUserDto, pgClient)
      await execute(userInsertionPack, pgClient)
    }

    await runInTransaction(insertOperation, pgClientPool)
  } catch (error) {
    if (!isConflictRelatedError(error)) throw error
    const responseDto = buildConflictResponse(error)
    response.status(StatusCodes.CONFLICT).json(responseDto)
    return
  }

  response.status(StatusCodes.CREATED).json({ id: userInsertionPack.user.id })
}

export default create
```

### Key Patterns

1. **Type Assertion**: Extract typed values from request properties
   ```typescript
   const pgClientPool = request.pgClientPool as PgClientPool
   const parsedQuery = request.parsedQuery as IndexUserQueryDto
   ```

2. **Private Helper Functions**: Keep utility functions private within the controller file (not exported)

3. **Error Handling**: Try-catch with specific error type checking
   ```typescript
   try { ... }
   catch (error) {
     if (!isConflictRelatedError(error)) throw error
     response.status(StatusCodes.CONFLICT).json(responseDto)
     return
   }
   ```

4. **Response with `http-status-codes`**:
   ```typescript
   response.status(StatusCodes.OK).json(data)
   response.status(StatusCodes.CREATED).json({ id })
   response.status(StatusCodes.CONFLICT).send()
   ```

---

## Repository

### File Organization

- **Location**: `src/repositories/` directory with hierarchical structure
- **Naming**: Kebab-case matching the operation (e.g., `find-all.ts`, `insert.ts`, `count.ts`)
- **Function Names**: Action verbs - `find`, `findAll`, `findOne`, `count`, `insert`, `update`, `destroy`, `upsert`

```
src/repositories/
├── user/
│   ├── find-all.ts
│   ├── find-one.ts
│   ├── find-batch.ts
│   ├── insert.ts
│   ├── update.ts
│   └── count.ts
└── role/
    ├── find-all.ts
    ├── insert.ts
    └── destroy.ts
```

### Implementation Patterns

**Find all with filtering:**

```typescript
const findAll = async (
  queryParameter: IndexUserQueryDto & PaginationConfig,
  pgQueryRunner: PgQueryRunner,
  organizationId: UUID | null,
): Promise<ShowSimpleUserDto[]> => {
  const result = await pgQueryRunner.query<ShowSimpleUserDto>(`--sql
    SELECT
      u.id,
      u.name,
      u.is_active,
      JSONB_BUILD_OBJECT('id', r.id, 'name', r.name) as role
    FROM user_ u
    JOIN role r ON u.role_id = r.id
    WHERE
      u.name ILIKE COALESCE($1, '%')
      AND ($2::UUID[] IS NULL OR r.id = ANY($2::UUID[]))
      AND ($3::BOOLEAN IS NULL OR u.is_active = $3::BOOLEAN)
      AND ($4::UUID IS NULL OR o.id = $4::UUID)
    ORDER BY u.name, u.id
    LIMIT $5
    OFFSET $6
  `, [
    formatForWildcardILike(queryParameter.name_search_term),
    queryParameter.role_ids,
    queryParameter.is_active,
    organizationId,
    queryParameter.limit,
    queryParameter.offset,
  ])

  return result.rows
}

export default findAll
```

**Count:**

```typescript
const count = async (
  queryParameter: IndexUserQueryDto,
  pgQueryRunner: PgQueryRunner,
  organizationId: UUID | null
): Promise<number> => {
  const result = await pgQueryRunner.query<{ count: number }>(`--sql
    SELECT COUNT(u.id)::INTEGER
    FROM user_ u
    JOIN role r ON u.role_id = r.id
    WHERE
      u.name ILIKE COALESCE($1, '%')
      AND ($2::UUID[] IS NULL OR u.role_id = ANY($2::UUID[]))
      AND ($3::UUID IS NULL OR o.id = $3::UUID)
  `, [
    formatForWildcardILike(queryParameter.name_search_term),
    queryParameter.role_ids,
    organizationId,
  ])

  return result.rows[0].count
}

export default count
```

**Insert:**

```typescript
const insert = async (user: User, pgClient: PgClient): Promise<void> => {
  await pgClient.query(`--sql
    INSERT INTO user_ (
      id,
      name,
      email,
      is_active,
      password,
      phone_number,
      role_id
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7)
  `, [
    user.id,
    user.name,
    user.email,
    user.is_active,
    user.password,
    user.phone_number,
    user.role_id,
  ])
}

export default insert
```

### Key Patterns

1. **SQL Comments**: Mark queries with `--sql` for IDE highlighting

2. **Parameterized Queries**: Use numbered parameters (`$1, $2, etc.`) to prevent SQL injection

3. **Type Generics**: Specify return type in queries
   ```typescript
   pgQueryRunner.query<ShowSimpleUserDto>(...)
   ```

4. **Null Coalescing in WHERE**: Handle optional filters
   ```sql
   WHERE
     u.name ILIKE COALESCE($1, '%')
     AND ($2::UUID[] IS NULL OR r.id = ANY($2::UUID[]))
   ```

5. **JSON Building**: Use PostgreSQL `JSONB_BUILD_OBJECT` for nested response structures

6. **Specialized Operations**:
   - Bulk operations: `insert-bulk.ts`, `bulk-destroy.ts`, `bulk-upsert.ts`
   - Locking queries: `is-exist-and-lock.ts`, `find-all-ids-and-lock.ts`
