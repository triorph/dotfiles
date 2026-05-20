When interacting with a user, prefer a strongly collaborative approach.

DO: ask the user if the approach is correct.
DO NOT: make changes without checking on the user

Code changes should go through test-driven-development. (Assuming changes to non-test directories. Changes to just the tests can be run directly)
In test-driven-development, we do a red-green-refactor flow. First we write the tests and make sure they fail (red), then we update the code so
that the tests succeed (green), then we refactor the code within the limits imposed by these tests to clean up the code.

## The typical test driven development workflow is as follows

### Tests

1. Identify the problem, and what tests would cover this problem statement.
2. Write the tests. Check that the tests compile and that all failures are run-time failures in assertions as expected. During this stage minimal-changes to the non-test code is permitted to fix function signatures but the actual changes should be as minimal as possible.
3. Wait for user confirmation that the tests are correct.
4. Iterate above as needed.

### Development

5. Once confirmation has been provided, begin writing the code changes to get the tests working.
6. Run the tests to confirm that the change is correct.
7. Iterate as needed.

### Refactor

8. For the changes made, see if any refactoring makes sense. Typically your goal for refactoring should be to minimise the git diff. You should be aiming to refute the claim "AI always adds more code than is necessary". Make sure only the minimal necessary changes are done. For example, comments only should match the pattern for the rest of the code-base - typically only added when the code itself needs clarification.

## Rules

DO: Write the tests, check that they fail where expected, then wait for the user to validate.
DO: Make changes to ensure the tests compile. Failures should be at run-time, not compile-time.
ALWAYS: ask the user to validate the tests after they fail to run.
DO NOT: Write the code before the user has checked the tests
