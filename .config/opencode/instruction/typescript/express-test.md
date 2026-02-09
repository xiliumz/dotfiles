# Express.js Testing Conventions

For general testing rules (mocking, private functions, test case design): @instruction/typescript/testing.md

---

## Test File Organization

### Directory Structure

```
tests/
├── schemas/              # Zod schema validation tests
├── repositories/         # Database query tests (mirror src/repositories/ structure)
├── controllers/          # HTTP handler tests
├── services/             # Business logic tests
├── helpers/              # Utility function tests
├── integration/          # End-to-end API tests
└── fixtures/             # Shared test data and utilities
```

### Naming Convention

- All test files use `.test.ts` suffix
- Mirror source directory structure (e.g., `tests/repositories/user/find-all.test.ts` ↔ `src/repositories/user/find-all.ts`)

---

## Schema Tests

Schema tests validate Zod schemas with valid and invalid data.

```typescript
import CREATE_USER_BODY_SCHEMA from '../../../src/schemas/user/create.schema'

describe('CREATE_USER_SCHEMA', () => {
  it.each([
    [{ email: 'foo@bar.com', name: 'FooBar', /* ... */ }],
    [{ email: 'foo@bar.com', name: 'Anya Forger', /* ... */ }],
  ])('accepts valid user data', (userDto) => {
    const result = CREATE_USER_BODY_SCHEMA.safeParse(userDto)
    expect(result.success).toBe(true)
  })

  it.each([
    [{ email: 'invalidemail' }],
    [null],
    [{ email: 'mail@example.com', phone_number: '88888888888a88888' }],
  ])('rejects invalid user data', (userDto) => {
    const result = CREATE_USER_BODY_SCHEMA.safeParse(userDto)
    expect(result.success).toBe(false)
  })
})
```

### Key Patterns

- Use `it.each()` for multiple valid/invalid cases
- Call `schema.safeParse()` for validation
- No mocking required - pure data validation

---

## Repository Tests

### Test File Location

Repository tests should be placed in `tests/repositories/` mirroring the source structure:

| Source File | Test File |
|-------------|-----------|
| `src/repositories/user/find-all.ts` | `tests/repositories/user/find-all.test.ts` |
| `src/repositories/project/insert.ts` | `tests/repositories/project/insert.test.ts` |
| `src/repositories/daily-weather-report/upsert.ts` | `tests/repositories/daily-weather-report/upsert.test.ts` |

Repository tests use real database connections via `databaseTest()` helper.

```typescript
import { PgClientPool, PgQueryRunner } from '@dayatani/core/types'
import { databaseTest } from '@dayatani/core/helpers'
import upsert from '../../../src/repositories/daily-weather-report/upsert'
import { Pool } from 'pg'

describe('upsert daily weather report', () => {
  let pgClientPool: PgClientPool

  beforeAll(() => {
    pgClientPool = new Pool({ connectionString: process.env.DATABASE_URL })
  })

  afterAll(async () => {
    await pgClientPool.end()
  })

  // Use prepareDb function to set up all required dependencies
  const prepareDb = async (
    client: PgQueryRunner,
    projectId: string,
    iotDeviceId: string,
  ): Promise<void> => {
    await client.query(`
      INSERT INTO project (id, name, location, start_date, end_date)
      VALUES ($1, 'Test Project', ST_GeographyFromText('POINT(106.8 -6.2)'), '2024-01-01', '2024-12-31')
    `, [projectId])

    await client.query(`
      INSERT INTO iot_device (id, name, code_name, location, altitude, nearest_farmer_name, project_id)
      VALUES ($1, 'Test Device', 'TEST001', ST_GeographyFromText('POINT(106.8 -6.2)'), 100, 'Test Farmer', $2)
    `, [iotDeviceId, projectId])
  }

  it('should insert new daily weather reports', async () => {
    const projectId = '11111111-1111-1111-1111-111111111111'
    const iotDeviceId = '22222222-2222-2222-2222-222222222222'
    const reportId1 = '33333333-3333-3333-3333-333333333333'

    await databaseTest(async (client) => {
      // Prepare: Use prepareDb to set up dependencies
      await prepareDb(client, projectId, iotDeviceId)

      const reports: DailyWeatherReport[] = [
        {
          id: reportId1,
          iot_device_id: iotDeviceId,
          date: '2024-09-09',
          report: { /* ... */ },
          produced_at: '2024-09-09T12:00:00Z',
        },
      ]

      // Execute
      await upsert(reports, client)

      // Assert: Verify database state
      const result = await client.query(`
        SELECT id, iot_device_id, date::TEXT, report, produced_at
        FROM daily_weather_report
      `)

      expect(result.rowCount).toBe(1)
      expect(result.rows[0]).toStrictEqual({
        id: reportId1,
        iot_device_id: iotDeviceId,
        date: '2024-09-09',
        report: { /* ... */ },
        produced_at: '2024-09-09T12:00:00Z',
      })
    }, pgClientPool)
  })
})
```

### Key Patterns

- Use `databaseTest()` helper for database setup/teardown
- Create a `prepareDb()` function to set up all required dependencies in one place
- Insert dependencies in correct order (organization → role → user)
- Test multiple query variations using `Promise.all()`
- Use strict type assertions: `toStrictEqual<DtoType>()`
- Reuse `prepareDb` across multiple test cases with different parameters
- Use `beforeAll`/`afterAll` to manage the database connection pool
- No jest.mock() needed - real database calls

---

## Controller Tests

Controller tests mock dependencies and use `@jest-mock/express` for request/response.

```typescript
import * as bcrypt from '../../../src/helpers/bcrypt.util'
import * as insertUserModule from '../../../src/repositories/user/insert'
import * as dayaTaniCoreHelpers from '@dayatani/core/helpers'
import { getMockReq, getMockRes } from '@jest-mock/express'
import { StatusCodes } from 'http-status-codes'
import create from '../../../src/controllers/user/create.controller'

jest.mock('node:crypto', () => ({
  randomUUID: jest.fn()
    .mockReturnValueOnce('00000000-0000-0000-0000-000000000000')
    .mockReturnValue('11111111-1111-1111-1111-111111111111'),
}))

describe('User create controller', () => {
  let repositoryInsertSpy: jest.SpyInstance
  let generatePasswordHashSpy: jest.SpyInstance
  let runInTransactionSpy: jest.SpyInstance

  beforeEach(() => {
    jest.clearAllMocks()

    repositoryInsertSpy = jest.spyOn(insertUserModule, 'default')
    generatePasswordHashSpy = jest.spyOn(bcrypt, 'generatePasswordHash')
    runInTransactionSpy = jest.spyOn(dayaTaniCoreHelpers, 'runInTransaction')
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('creates new user and returns 201 status code', async () => {
    // Prepare
    const stubPgClient = { query: jest.fn(), release: jest.fn() }
    const stubPgClientPool = { query: jest.fn(), end: jest.fn() }

    repositoryInsertSpy.mockResolvedValue(undefined)
    generatePasswordHashSpy.mockResolvedValue('hashedPassword')
    runInTransactionSpy.mockImplementation(callback => callback(stubPgClient))

    const stubRequest = getMockReq({
      parsedBody: newUserDto,
      pgClientPool: stubPgClientPool,
      organizationId: null,
    })
    const { res: mockResponse } = getMockRes()

    // Execute
    await create(stubRequest, mockResponse)

    // Assert
    expect(repositoryInsertSpy).toHaveBeenCalledTimes(1)
    expect(repositoryInsertSpy).toHaveBeenCalledWith(
      { ...newUser, password: 'hashedPassword' },
      stubPgClient,
    )
    expect(mockResponse.status).toHaveBeenCalledWith(StatusCodes.CREATED)
    expect(mockResponse.json).toHaveBeenCalledWith({ id: newUserId })
  })

  it.each([
    [foreignKeyError, { field: 'project_id' }],
    [duplicateKeyError, { field: 'email' }],
  ])('returns 409 status code when error occurs', async (error, expectedResponse) => {
    // Similar pattern with error handling...
  })
})
```

### Key Patterns

- Use `getMockReq()` / `getMockRes()` from `@jest-mock/express`
- Stub database clients: `{ query: jest.fn(), release: jest.fn() }`
- Test error paths with `it.each()` for multiple scenarios

---

## Service/Helper Tests

### Pure Functions (No Dependencies)

```typescript
describe('calculateDueDates', () => {
  it.each([
    [
      { recurrence_interval: 13, duration_config: { is_dap_based: false, start_date: '2020-01-01' } },
      null,
      ['2020-01-01', '2020-01-14'],
    ],
    [
      { recurrence_interval: 2, duration_config: { is_dap_based: true } },
      { sowing_date: '2024-03-31' },
      ['2024-04-30', '2024-05-02'],
    ],
  ])('calculates correct due dates', (durationConfig, resource, expectedResult) => {
    const result = calculateDueDates(durationConfig, resource)
    expect(result).toStrictEqual(expectedResult)
  })
})
```

### Functions with Dependencies

```typescript
import * as bcrypt from '../../src/helpers/bcrypt.util'
import prepareUserInsertion from '../../src/services/prepare-user-insertion.service'

jest.mock('node:crypto', () => ({
  randomUUID: jest.fn().mockReturnValue('2ea4099b-981d-40ce-87a2-b9f7e9123cf7'),
}))

describe('prepareUserInsertion', () => {
  let generatePasswordHashSpy: jest.SpyInstance

  beforeEach(() => {
    jest.clearAllMocks()
    generatePasswordHashSpy = jest.spyOn(bcrypt, 'generatePasswordHash')
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('should prepare user insertion', async () => {
    // Prepare
    generatePasswordHashSpy.mockResolvedValue('hashedPassword')
    const createUserDto: CreateUserDto = { /* ... */ }

    // Execute
    const result = await prepareUserInsertion(createUserDto)

    // Assert
    expect(generatePasswordHashSpy).toHaveBeenCalledTimes(1)
    expect(generatePasswordHashSpy).toHaveBeenCalledWith('password123')
    expect(result).toStrictEqual({
      projects: [/* ... */],
      user: { /* ... */ },
    })
  })
})
```

---

## Integration Tests

Integration tests use real Express app with `supertest` and real database.

```typescript
import { JWT_ACCESS_TOKEN_FOR_TEST, JWT_PUBLIC_KEY_FOR_TEST } from '../../fixtures/tokens'
import buildApp from '../../../src/app'
import { Pool } from 'pg'
import { StatusCodes } from 'http-status-codes'
import request from 'supertest'

jest.mock('node:crypto', () => ({
  ...jest.requireActual('node:crypto'),
  randomUUID: jest.fn().mockReturnValue('1df892e8-213e-45bf-9a40-2bfc79f0ff1f'),
}))

describe('POST /users', () => {
  let existingJwtPublicKey: string | undefined
  let pgClientPool: Pool

  beforeAll(() => {
    pgClientPool = new Pool({ connectionString: process.env.DATABASE_URL })
    existingJwtPublicKey = process.env.PUBLIC_KEY
    process.env.PUBLIC_KEY = JWT_PUBLIC_KEY_FOR_TEST
  })

  afterAll(async () => {
    process.env.PUBLIC_KEY = existingJwtPublicKey
    await pgClientPool.query('TRUNCATE organization, role, project CASCADE')
    await pgClientPool.end()
  })

  it('creates a user', async () => {
    // Prepare: Set up database state
    const client = await pgClientPool.connect()
    await client.query('BEGIN')
    await client.query(
      `INSERT INTO organization (id, name) VALUES ($1, 'Pokemon')`,
      [mockOrganizationId]
    )
    await client.query('COMMIT')
    client.release()

    const createUserDto: CreateUserDto = { /* ... */ }
    const app = buildApp(pgClientPool, false)

    // Execute
    await request(app)
      .post('/users')
      .auth(JWT_ACCESS_TOKEN_FOR_TEST, { type: 'bearer' })
      .send(createUserDto)
      .expect(StatusCodes.CREATED)
      .expect(response => {
        expect(response.body).toStrictEqual({ id: '1df892e8-213e-45bf-9a40-2bfc79f0ff1f' })
      })

    // Assert: Verify database state
    const { rows } = await pgClientPool.query(
      `SELECT id, name, email FROM user_ WHERE id = $1`,
      ['1df892e8-213e-45bf-9a40-2bfc79f0ff1f']
    )
    expect(rows[0]).toStrictEqual({
      id: '1df892e8-213e-45bf-9a40-2bfc79f0ff1f',
      name: 'FooBar',
      email: 'foo@bar.com',
    })
  })
})
```

### Key Patterns

- Use `supertest` for HTTP requests
- Real Express app via `buildApp(pgClientPool, false)`
- Real database with direct `pgClientPool.query()` calls
- JWT tokens from `tests/fixtures/tokens.ts`
- Use `beforeAll`/`afterAll` for environment and database setup/cleanup
- Verify both HTTP response AND database state
- Use transactions for setup isolation
- Mock only external libraries (crypto for consistent UUIDs)

---

## Test Fixtures

### Location: `tests/fixtures/`

**tokens.ts** - Reusable test tokens:

```typescript
export const JWT_ACCESS_TOKEN_FOR_TEST = 'eyJhbGciOi...'
export const JWT_PUBLIC_KEY_FOR_TEST = '-----BEGIN PUBLIC KEY-----...'
export const JWT_PRIVATE_KEY_FOR_TEST = '-----BEGIN RSA PRIVATE KEY-----...'
export const JWT_USER_ID_FOR_TEST: UUID = '89696d7b-2021-4cf0-9aeb-3d8aec26d58c'
```

**Database setup helpers:**

```typescript
export const ensureUserExists = async (
  pg: PgLike,
  userId: UUID,
  name = 'Test User'
): Promise<void> => {
  await pg.query(`INSERT INTO organization ... ON CONFLICT DO NOTHING`)
  await pg.query(`INSERT INTO role ... ON CONFLICT DO NOTHING`)
  await pg.query(`INSERT INTO user_ ... ON CONFLICT DO NOTHING`)
}
```

---

## Test Type Summary

| Test Type | Location | Mocking | Database | Speed |
|-----------|----------|---------|----------|-------|
| **Schema** | `tests/schemas/` | None | No | Fast |
| **Repository** | `tests/repositories/` | None | Real DB | Medium |
| **Controller** | `tests/controllers/` | jest.spyOn() | Stubbed | Fast |
| **Service** | `tests/services/` | jest.spyOn() | No | Fast |
| **Helper** | `tests/helpers/` | jest.spyOn() | No | Fast |
| **Integration** | `tests/integration/` | Module mocks | Real DB | Slow |
