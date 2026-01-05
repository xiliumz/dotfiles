# Testing Rules in TypeScript Project

## Test Case Design

- **Avoid redundancy**: One test case covering multiple scenarios is preferable to multiple separate test cases
- **Combine scenarios**: If a function can handle mixed valid/invalid inputs, test them together in a single test case
- **Example**: Instead of separate tests for valid items and invalid items, include both in one test case with mixed data

```typescript
// ✅ Preferable - Single test case covering multiple scenarios
it("should process array with valid and invalid items", () => {
  const items = [
    { id: 1, name: "Valid Item" },
    { id: null, name: "Invalid Item" },
    { id: 2, name: "Another Valid" },
  ];
  
  const result = processItems(items);
  expect(result).toHaveLength(3);
  expect(result[1].processed).toBe(false); // Invalid item marked
});

// ❌ Not preferable - Redundant separate test cases
it("should process valid items", () => {
  /* ... */
});
it("should process invalid items", () => {
  /* ... */
});
```

## Private Functions

- **Private helper functions** that are exclusive to a main function should **not be exported or tested separately**
- Test them **indirectly through the main function** - ensure test cases cover all paths in the private function
- Example: Main function `A` uses private function `B` for readability. Test `A` with cases that exercise `B`'s logic

```typescript
// ✅ Correct - Private function only tested through public function
export function processData(items: Item[]) {
  return items.map(item => validateAndTransform(item));
}

// Private helper - not exported, not tested separately
function validateAndTransform(item: Item) {
  if (!item.id) return null;
  return { ...item, processed: true };
}

// Test validates both processData and validateAndTransform logic
it("should process data and handle invalid items", () => {
  const result = processData([
    { id: 1, name: "Valid" },
    { id: null, name: "Invalid" },
  ]);
  expect(result).toEqual([
    { id: 1, name: "Valid", processed: true },
    null,
  ]);
});

// ❌ Wrong - Exporting private function just for testing
export function validateAndTransform(item: Item) { /* ... */ } // Don't do this
```

- If you need to test a private function separately, **move it to a dedicated module/file** and make it public in that module

```typescript
// validateAndTransform.ts (new dedicated module)
export function validateAndTransform(item: Item) { /* ... */ }

// data-processor.ts (main module)
import { validateAndTransform } from "./validateAndTransform";

export function processData(items: Item[]) {
  return items.map(item => validateAndTransform(item));
}
```

## Mocking

- **Spy Declaration**: Declare spy variables at the describe level using `jest.SpyInstance` type
- **Setup**: Always call `jest.clearAllMocks()` first in beforeEach, then initialize spies with `jest.spyOn()`
- **Cleanup**: Restore all spies using `.mockRestore()` in afterEach
- **Module-Level Mocks**: Use `jest.mock()` at the top of the file for external dependencies
- **Test-Level Mocks**: Set behavior in the section of each test using `.mockImplementation()`, `.mockReturnValue()`, `.mockResolvedValue()`, etc.

### Complete Mocking Example

```typescript
import * as someModule from '../../src/some-module'
import { someFunction } from 'external-library'

jest.mock('../../src/logger')
jest.mock('external-library')

describe('myModule', () => {
  let moduleDefaultSpy: jest.SpyInstance
  let loggerSpy: jest.SpyInstance
  const mockSomeFunction = someFunction as jest.Mock

  beforeEach(() => {
    jest.clearAllMocks()
    moduleDefaultSpy = jest.spyOn(someModule, 'default')
    loggerSpy = jest.spyOn(logger, 'info')
  })

  afterEach(() => {
    moduleDefaultSpy.mockRestore()
    loggerSpy.mockRestore()
  })

  it('should process data and log results', async () => {
    // Prepare
    moduleDefaultSpy.mockImplementation(() => 'processed')
    loggerSpy.mockImplementation(() => Promise.resolve(undefined))
    mockSomeFunction.mockImplementation(() => 'external-result')

    // Execute
    const result = await myFunction()

    // Assert
    expect(result).toBe('expected')
    expect(loggerSpy).toHaveBeenCalledWith('data processed')
  })
})
```
