# Testing Anti-Patterns

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

1. **Never test mock behavior.**
2. **Never add test-only methods to production classes.**
3. **Never mock without understanding what the real dependency does.**

## Anti-Pattern 1: Testing Mock Behavior

**The violation:** asserting on the presence of a mock element. The test mounts a page, mocks the sidebar so it renders as a stub with a recognizable test-id, and asserts that the stub is in the document. The assertion passes because the mock rendered — not because the page wired up real navigation.

**Why this is wrong:**
- You're verifying the mock works, not that the component works
- Test passes when mock is present, fails when it's not
- Tells you nothing about real behavior

**your human partner's correction:** "Are we testing the behavior of a mock?"

**The fix:** test the real component (don't mock the sidebar) and assert on something a user can observe — for example, that an element with `role="navigation"` is in the document. If the sidebar genuinely must be mocked for isolation, assert on the page's behavior with the sidebar present, never on the mock itself.

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"

  IF testing mock existence:
    STOP - Delete the assertion or unmock the component

  Test real behavior instead
```

## Anti-Pattern 2: Test-Only Methods in Production

**The violation:** adding a method to a production class that exists only because tests need it. For example, a `Session` class gains a `destroy()` method whose only callers are `afterEach` hooks in test files. The method looks like part of the public API, but no production caller ever invokes it.

**Why this is wrong:**
- Production class polluted with test-only code
- Dangerous if accidentally called in production
- Violates YAGNI and separation of concerns
- Confuses object lifecycle with entity lifecycle

**The fix:** keep cleanup logic out of the production class entirely. Put it in a test helper (e.g. `cleanupSession(session)` in a `test-utils/` module) that reaches into the underlying resources directly. Tests call the helper; production code never sees it.

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"

  IF yes:
    STOP - Don't add it
    Put it in test utilities instead

  Ask: "Does this class own this resource's lifecycle?"

  IF no:
    STOP - Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

**The violation:** mocking a method without checking what side effects it has. The test is meant to exercise duplicate-server detection, but it pre-mocks the tool-catalog's discovery method to return nothing — and that method was the one writing the config the duplicate check reads. The second `addServer(config)` call should throw "duplicate", but it doesn't, because the first call never persisted anything.

**Why this is wrong:**
- Mocked method had side effect test depended on (writing config)
- Over-mocking to "be safe" breaks actual behavior
- Test passes for wrong reason or fails mysteriously

**The fix:** mock at the lowest meaningful level. If the only thing you actually need to skip is a slow external server startup, mock just the server-startup component — not the high-level orchestrator that also writes config the test depends on.

### Gate Function

```
BEFORE mocking any method:
  STOP - Don't mock yet

  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on any of those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at lower level (the actual slow/external operation)
    OR use test doubles that preserve necessary behavior
    NOT the high-level method the test depends on

  IF unsure what test depends on:
    Run test with real implementation FIRST
    Observe what actually needs to happen
    THEN add minimal mocking at the right level

  Red flags:
    - "I'll mock this to be safe"
    - "This might be slow, better mock it"
    - Mocking without understanding the dependency chain
```

## Anti-Pattern 4: Incomplete Mocks

**The violation:** building a mock response with only the fields your immediate test reads (e.g. `status` and `data`), even though the real API also returns a `metadata` object that downstream code consumes. The test passes because the mock satisfies the part of the contract under test. Production breaks the moment something accesses `response.metadata.requestId`.

**Why this is wrong:**
- **Partial mocks hide structural assumptions** - You only mocked fields you know about
- **Downstream code may depend on fields you didn't include** - Silent failures
- **Tests pass but integration fails** - Mock incomplete, real API complete
- **False confidence** - Test proves nothing about real behavior

**The Iron Rule:** Mock the COMPLETE data structure as it exists in reality, not just fields your immediate test uses.

**The fix:** mirror the real API response in full. Include every field the live response carries — `metadata`, timestamps, request IDs, anything documented or observable in real responses — even if your immediate test doesn't read them.

### Gate Function

```
BEFORE creating mock responses:
  Check: "What fields does the real API response contain?"

  Actions:
    1. Examine actual API response from docs/examples
    2. Include ALL fields system might consume downstream
    3. Verify mock matches real response schema completely

  Critical:
    If you're creating a mock, you must understand the ENTIRE structure
    Partial mocks fail silently when code depends on omitted fields

  If uncertain: Include all documented fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**The violation:** declaring implementation done with tests "to come later". Treating tests as a separate phase that lives after "complete", or as something to add when reviewers ask.

**Why this is wrong:**
- Testing is part of implementation, not optional follow-up
- TDD would have caught this
- Can't claim complete without tests

**The fix:** follow the TDD cycle — write the failing test, implement to pass, refactor, *then* claim complete. "Complete" without tests is "complete" without verification, which means it's not complete.

## When Mocks Become Too Complex

**Warning signs:**
- Mock setup longer than test logic
- Mocking everything to make test pass
- Mocks missing methods real components have
- Test breaks when mock changes

**your human partner's question:** "Do we need to be using a mock here?"

**Consider:** Integration tests with real components often simpler than complex mocks

## TDD Prevents These Anti-Patterns

**Why TDD helps:**
1. **Write test first** → Forces you to think about what you're actually testing
2. **Watch it fail** → Confirms test tests real behavior, not mocks
3. **Minimal implementation** → No test-only methods creep in
4. **Real dependencies** → You see what the test actually needs before mocking

**If you're testing mock behavior, you violated TDD** - you added mocks without watching test fail against real code first.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD - tests first |
| Over-complex mocks | Consider integration tests |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## The Bottom Line

**Mocks are tools to isolate, not things to test.**

If TDD reveals you're testing mock behavior, you've gone wrong.

Fix: Test real behavior or question why you're mocking at all.
